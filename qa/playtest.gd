extends Node
## Engine-driven integration playtest. Uses real physics, actions and menu buttons.
## Test save data is isolated from the player's profile. No teleports during the delivery drive.

var game: Node3D
var checks: Array[Dictionary] = []
var measurements: Dictionary = {}
var failures: int = 0
var visual_test: bool = false
var frame_times: Array[float] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visual_test = OS.get_cmdline_user_args().has("--qa-visual")
	run.call_deferred()

func _process(delta: float) -> void:
	if visual_test and game.started and not get_tree().paused and delta > 0 and delta < 0.5:
		frame_times.append(delta)

func check(label: String, passed: bool, details: String = "") -> void:
	checks.append({"test": label, "passed": passed, "details": details})
	if not passed:
		failures += 1
	print("QA %s | %s | %s" % ["PASS" if passed else "FAIL", label, details])

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func tap(action: String) -> void:
	# UI/input belongs to the idle loop, not inside physics_frame's active-body iteration.
	await get_tree().process_frame
	var event = InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await frames(6)
	event = InputEventAction.new()
	event.action = action
	event.pressed = false
	Input.parse_input_event(event)
	await frames(6)

func press_button(prefix: String) -> bool:
	for button in game.ui.menu.find_children("*", "Button", true, false):
		if button.text.begins_with(prefix):
			button.call_deferred("emit_signal", "pressed")
			await get_tree().process_frame
			await get_tree().process_frame
			return true
	return false

func hold_for_cargo(unloading: bool) -> bool:
	# Wait for a stable parking state, then inject a real E key-down/up pair.
	# Waiting on a condition also tolerates a frame hitch during shader compilation.
	await get_tree().process_frame
	var key = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode = KEY_E
	key.pressed = true
	Input.parse_input_event(key)
	var finished = false
	for frame in 300:
		await get_tree().physics_frame
		finished = game.missions.job.is_empty() if unloading else (not game.missions.job.is_empty() and game.missions.job.stage == "delivery")
		if finished:
			break
		if frame % 60 == 59:
			print("QA HANDLE parked=%s key=%s progress=%.2f speed=%.2f" % [game.missions.can_handle(), Input.is_action_pressed("interact"), game.missions.handling, game.vehicle.speed_kph])
	key = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.keycode = KEY_E
	key.pressed = false
	Input.parse_input_event(key)
	return finished

func screenshot(name: String) -> void:
	if not visual_test or DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://qa/screenshots")
	get_viewport().get_texture().get_image().save_png("res://qa/screenshots/" + name + ".png")

func run() -> void:
	await frames(90)
	check("Main menu constructed", game.ui.screen == "main" and game.ui.menu.visible)
	await screenshot("01-main-menu")
	check("Play button starts game", (await press_button("Start your shift")) and game.started and game.ui.screen == "")
	game.traffic.enabled = false
	# Park traffic off the test road, rather than leaving frozen colliders in its lane.
	var traffic_positions: Array[Vector3] = []
	for car in game.traffic.cars:
		traffic_positions.append(car.body.position)
		car.body.position.y = -20
	# A straight stretch isolates control tests from traffic and scenery.
	game.vehicle.recover(Vector3(-116, 0, 120), 0)
	await frames(120)
	check("Suspension settles on four wheels", game.vehicle.grounded_wheels == 4, "height %.3f" % game.vehicle.position.y)
	var start: Vector3 = game.vehicle.position
	Input.action_press("accelerate")
	await frames(180)
	Input.action_release("accelerate")
	measurements.acceleration_speed_kph = game.vehicle.speed_kph
	check("Acceleration moves the rigid body", game.vehicle.speed_kph > 15 and game.vehicle.position.distance_to(start) > 9, "%.1f km/h, %.1f m" % [game.vehicle.speed_kph, game.vehicle.position.distance_to(start)])
	var yaw: float = game.vehicle.rotation.y
	Input.action_press("steer_left", 0.65)
	await frames(42)
	Input.action_release("steer_left")
	check("Tyre steering changes heading", absf(angle_difference(yaw, game.vehicle.rotation.y)) > 0.08, "yaw delta %.3f" % angle_difference(yaw, game.vehicle.rotation.y))
	Input.action_press("brake")
	await frames(90)
	Input.action_release("brake")
	check("Service braking slows the van", game.vehicle.speed_kph < 5, "%.1f km/h" % game.vehicle.speed_kph)
	Input.action_press("brake")
	await frames(110)
	Input.action_release("brake")
	check("Reverse engages after stopping", game.vehicle.signed_speed < -0.5, "%.2f m/s" % game.vehicle.signed_speed)
	Input.action_press("handbrake")
	await frames(100)
	Input.action_release("handbrake")
	check("Handbrake stops the van", game.vehicle.speed_kph < 2, "%.1f km/h" % game.vehicle.speed_kph)
	game.vehicle.recover(Vector3(-102, 0, 119), -PI / 2)
	await frames(70)
	var health: float = game.progress.condition
	Input.action_press("accelerate")
	await frames(210)
	Input.action_release("accelerate")
	check("Buildings stop the vehicle", game.vehicle.position.x < -88.0, "x %.2f" % game.vehicle.position.x)
	check("Collision severity causes damage", game.progress.condition < health, "condition %.1f" % game.progress.condition)
	await tap("headlights")
	check("Headlights toggle", game.vehicle.lights_on and game.vehicle.visual.headlights[0].visible)
	await tap("camera")
	check("Close chase camera", game.camera_rig.mode == 1)
	await tap("camera")
	check("Bonnet camera", game.camera_rig.mode == 2)
	await tap("camera")
	await tap("recover")
	await frames(100)
	check("Recovery returns upright to a lane", game.vehicle.grounded_wheels == 4 and game.vehicle.global_basis.y.dot(Vector3.UP) > 0.97)
	# Real collection -> road journey -> handover. Only setup is repositioned at the depot.
	game.vehicle.recover(HarborDistrict.SPAWN, PI / 2)
	game.progress.condition = 100
	await frames(100)
	await tap("dispatch")
	check("Dispatch board opens and pauses", game.ui.screen == "jobs" and get_tree().paused)
	await screenshot("02-contract-board")
	check("Contract accepted using its button", (await press_button("Accept contract")) and not game.missions.job.is_empty())
	check("Pickup information and route available", game.missions.target_index() == 0 and game.missions.route.size() >= 2)
	check("No second contract while one is active", not game.missions.accept(1))
	await hold_for_cargo(false)
	check("Held interaction loads cargo", not game.missions.job.is_empty() and game.missions.job.stage == "delivery")
	check("Loaded cargo changes physical vehicle mass", game.vehicle.cargo_mass == 120 and game.vehicle.mass == DeliveryVehicle.MASS + 120)
	await screenshot("03-driving")
	var old_money: int = game.progress.money
	game.traffic.enabled = true
	for i in game.traffic.cars.size():
		game.traffic.cars[i].body.position = traffic_positions[i]
	var waypoints = PackedVector3Array([Vector3(-113, 0, 119), Vector3(-116, 0, 101), Vector3(-116, 0, 31), Vector3(-116, 0, -34), Vector3(-116, 0, -92), Vector3(-109, 0, -109), Vector3(-100, 0, -110)])
	var reached = await drive_course(waypoints)
	check("Delivery destination reached by driving", reached and game.missions.distance_to_target() < 6.5, "%.1f m from bay, odometer %.1f m" % [game.missions.distance_to_target(), game.vehicle.odometer])
	game.vehicle.qa_control = false
	Input.action_press("handbrake")
	await frames(100)
	await hold_for_cargo(true)
	Input.action_release("handbrake")
	check("Delivery completes", game.missions.job.is_empty() and game.progress.completed == 1)
	check("Delivered cargo is physically unloaded", game.vehicle.cargo_mass == 0 and game.vehicle.mass == DeliveryVehicle.MASS)
	check("Reward credited to wallet", game.progress.money > old_money, "$%d -> $%d" % [old_money, game.progress.money])
	await screenshot("04-delivered")
	check("Fuel consumed gradually", game.progress.fuel > 85 and game.progress.fuel < 100, "%.2f%%" % game.progress.fuel)
	game.missions.make_offers()
	check("Repeat contracts originate at the last destination", not game.missions.offers.is_empty() and int(game.missions.offers[0].pickup) == 3)
	var path = game.district.road_route(Vector3(31, 0, 0), Vector3(31, 0, 132))
	var stays_on_roads = true
	for i in range(2, path.size() - 1):
		var a: Vector3 = path[i - 1]
		var b: Vector3 = path[i]
		if a.distance_to(b) > 0.1 and not ((absf(a.x - b.x) < 0.1 and a.x in HarborDistrict.ROAD_X) or (absf(a.z - b.z) < 0.1 and a.z in HarborDistrict.ROAD_Z)):
			stays_on_roads = false
	check("Navigation stays on the road graph", stays_on_roads)
	var ai_moved = false
	for i in game.traffic.cars.size():
		if game.traffic.cars[i].body.position.distance_to(traffic_positions[i]) > 15:
			ai_moved = true
	check("AI traffic circulates through the district", ai_moved)
	await test_loading_bay_access()
	await test_traffic_rules()
	game.vehicle.recover(HarborDistrict.SPAWN, PI / 2)
	await frames(100)
	old_money = game.progress.money
	check("Remote service cannot spend money or repair the van", not game.perform_service() and game.progress.money == old_money)
	await tap("district_map")
	check("District map opens and pauses gameplay", game.ui.screen == "map" and get_tree().paused)
	await screenshot("08-district-map")
	check("Map service route button works", (await press_button("Route to Coast Service")) and game.missions.service_waypoint and game.ui.screen == "" and not get_tree().paused)
	await tap("district_map")
	check("Map can restore the delivery route", (await press_button("Restore delivery route")) and not game.missions.service_waypoint and game.ui.screen == "")
	await tap("workshop")
	check("Remote workshop opens without allowing purchases", game.ui.screen == "workshop" and get_tree().paused and not game.purchase_upgrade("efficiency"))
	check("Remote workshop can set a service waypoint", (await press_button("Set service route")) and game.missions.service_waypoint and game.ui.screen == "")
	game.vehicle.recover(HarborDistrict.FUEL_POINT, 0)
	await frames(100)
	game.progress.fuel = 78
	game.progress.condition = 83
	var cost: int = game.systems.service_cost()
	old_money = game.progress.money
	await tap("interact")
	check("Fuel and repairs charge the quoted amount", game.progress.fuel > 99 and game.progress.condition == 100 and game.progress.money == old_money - cost, "service $%d" % cost)
	check("Successful service ends the navigation detour", not game.missions.service_waypoint)
	await tap("workshop")
	check("Workshop recognizes upright stationary parking", game.ui.screen == "workshop" and game.can_use_workshop())
	old_money = game.progress.money
	check("Workshop installs and charges a permanent upgrade", (await press_button("Install / $500")) and game.progress.upgrades.has("efficiency") and game.progress.money == old_money - 500)
	check("Rank-locked workshop upgrade remains unavailable", not game.purchase_upgrade("reinforcement"))
	await screenshot("09-workshop")
	await tap("pause")
	check("Escape returns from workshop to driving", game.ui.screen == "" and not get_tree().paused)
	game.district.set_clock(17.6)
	game.save_game()
	var restored = ProgressStore.new()
	restored.test_mode = true
	restored.load_progress()
	check("Atomic local save round-trips progress", restored.money == game.progress.money and restored.completed == 1 and restored.has_progress)
	check("Save retains upgrade, mileage and world clock", restored.upgrades.has("efficiency") and restored.total_distance > 250 and absf(restored.clock_hours - game.district.clock_hours) < 0.01)
	game.progress.settings.quality = 0
	game.apply_settings(false)
	check("Low graphics disables shadows", not game.district.sun.shadow_enabled)
	game.progress.settings.quality = 1
	game.apply_settings(false)
	check("Balanced graphics enables sun shadows", game.district.sun.shadow_enabled)
	game.progress.settings.invert_y = true
	game.apply_settings(false)
	check("Invert mouse setting reaches the camera", game.camera_rig.invert_y)
	await tap("pause")
	var paused_position: Vector3 = game.vehicle.position
	await frames(60)
	check("Pause freezes simulation", get_tree().paused and game.ui.screen == "pause" and game.vehicle.position.distance_to(paused_position) < 0.001)
	await screenshot("05-pause")
	check("Settings button works", (await press_button("Settings")) and game.ui.screen == "settings_pause")
	await screenshot("06-settings")
	check("Settings Done returns to pause", (await press_button("Done")) and game.ui.screen == "pause")
	check("Resume button works", (await press_button("Resume")) and not get_tree().paused and game.ui.screen == "")
	await tap("time_of_day")
	check("Night and street lights work", game.district.night and game.district.street_lights[0].visible)
	await screenshot("07-night")
	await tap("pause")
	check("Return to main menu", (await press_button("Main menu")) and game.ui.screen == "main" and not game.started)
	await frames(12)
	var menu_clock: float = game.district.clock_hours
	var menu_car: Vector3 = game.traffic.cars[0].body.position
	await frames(120)
	check("Main menu freezes clock and traffic", is_equal_approx(game.district.clock_hours, menu_clock) and game.traffic.cars[0].body.position == menu_car)
	check("Continue from main menu", (await press_button("Continue shift")) and game.started)
	await frames(12)
	measurements.end_fps = Engine.get_frames_per_second()
	measurements.draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	measurements.objects = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	if not frame_times.is_empty():
		frame_times.sort()
		var frame_sum = 0.0
		for duration in frame_times:
			frame_sum += duration
		measurements.render_average_fps = frame_times.size() / frame_sum
		measurements.render_median_ms = frame_times[frame_times.size() / 2] * 1000
		measurements.render_p95_ms = frame_times[int(frame_times.size() * 0.95)] * 1000
	var report = {"date": Time.get_datetime_string_from_system(), "engine": Engine.get_version_info().string, "renderer": DisplayServer.get_name(), "failures": failures, "checks": checks, "measurements": measurements}
	var report_file = FileAccess.open("res://qa/latest_visual_report.json" if visual_test else "res://qa/latest_headless_report.json", FileAccess.WRITE)
	if report_file:
		report_file.store_string(JSON.stringify(report, "\t"))
	print("QA RESULT: %d/%d passed" % [checks.size() - failures, checks.size()])
	game.quit_game(0 if failures == 0 else 1)

func test_loading_bay_access() -> void:
	game.traffic.enabled = false
	var positions: Array[Vector3] = []
	for car in game.traffic.cars:
		positions.append(car.body.position)
		car.body.position.y = -20
	var exits = [Vector3(-116, 0, 119), Vector3(-29, 0, -4), Vector3(124, 0, 94), Vector3(-116, 0, -110), Vector3(31, 0, 146), Vector3(116, 0, -117), Vector3(-124, 0, 26)]
	var bays = game.district.places.duplicate()
	bays.append({"name": "Coast Service", "position": HarborDistrict.FUEL_POINT})
	for i in bays.size():
		var start: Vector3 = bays[i].position
		var direction: Vector3 = exits[i] - start
		var yaw = atan2(-direction.x, -direction.z)
		game.vehicle.recover(start, yaw)
		game.vehicle.set_cargo_mass(220)
		await frames(100)
		var settled: bool = game.vehicle.grounded_wheels == 4 and game.vehicle.global_basis.y.dot(Vector3.UP) > 0.97
		var health: float = game.progress.condition
		var reached = await drive_course(PackedVector3Array([exits[i]]), false)
		game.vehicle.qa_control = false
		check("Loaded van can park and leave " + str(bays[i].name), settled and reached and game.progress.condition >= health - 2, "four-wheel parking %s; exit reached %s" % [settled, reached])
	game.vehicle.set_cargo_mass(0)
	for i in positions.size():
		game.traffic.cars[i].body.position = positions[i]
	game.traffic.enabled = true

func test_traffic_rules() -> void:
	# Isolated traffic fixtures use path coordinates. The delivery above still
	# uses the real driven journey, with the normal five-car pool running.
	game.traffic.enabled = false
	for car in game.traffic.cars:
		car.body.position.y = -20
	var car: Dictionary = game.traffic.cars[0]
	var path: Curve3D = car.path
	car.distance = path.get_closest_offset(Vector3(20, 0, -146))
	car.body.position = path.sample_baked(car.distance) + Vector3.UP * 0.79
	car.speed = car.cruise
	game.vehicle.recover(path.sample_baked(car.distance + 23), -PI / 2)
	await frames(80)
	game.traffic.enabled = true
	await frames(360)
	var gap: float = car.body.position.distance_to(game.vehicle.position)
	check("Traffic brakes behind a stopped player without overlap", car.speed < 1 and gap > 6.0, "speed %.2f m/s, gap %.1f m" % [car.speed, gap])
	game.vehicle.recover(HarborDistrict.SPAWN, PI / 2)
	var stopped_distance: float = car.distance
	await frames(150)
	check("Traffic resumes when the obstruction clears", car.distance > stopped_distance + 2 and car.speed > 1)
	game.traffic.enabled = false
	car.distance = path.get_closest_offset(Vector3(116, 0, -24))
	car.body.position = path.sample_baked(car.distance) + Vector3.UP * 0.79
	car.speed = 7
	game.district.traffic_time = 19
	game.traffic.enabled = true
	await frames(150)
	check("Traffic stops before a red central crossing", car.body.position.z < -13.5 and car.speed < 1.5, "z %.1f, speed %.2f" % [car.body.position.z, car.speed])
	game.district.traffic_time = 0
	var red_distance: float = car.distance
	await frames(150)
	check("Traffic moves again on green", car.distance > red_distance + 2 and car.speed > 1)
	# Restore every collider to its own path before continuing the integration run.
	for other in game.traffic.cars:
		other.body.position = other.path.sample_baked(other.distance) + Vector3.UP * 0.79

func drive_course(points: PackedVector3Array, record_delivery: bool = true) -> bool:
	var vehicle: DeliveryVehicle = game.vehicle
	vehicle.qa_control = true
	var index = 0
	var max_speed = 0.0
	for frame in 9000:
		var position = vehicle.global_position
		position.y = 0
		var distance = position.distance_to(points[index])
		if distance < (5.5 if index < points.size() - 1 else 3.3):
			if index == points.size() - 1:
				vehicle.qa_throttle = 0
				vehicle.qa_brake = 1
				await frames(75)
				if record_delivery:
					measurements.delivery_max_speed_kph = max_speed
					measurements.delivery_drive_seconds = frame / 60.0
				return true
			index += 1
		var local = vehicle.to_local(points[index])
		var angle = atan2(-local.x, -local.z)
		vehicle.qa_steer = clampf(angle / 0.40, -1, 1)
		var target_speed = 8.5 if absf(angle) < 0.18 else (5.4 if absf(angle) < 0.5 else 3.0)
		if index == points.size() - 1:
			target_speed = minf(target_speed, maxf(1.4, distance * 0.55))
		var difference = target_speed - vehicle.signed_speed
		vehicle.qa_throttle = clampf(difference * 0.65, 0, 0.8)
		vehicle.qa_brake = clampf(-difference * 0.3, 0, 1) if difference < -0.6 else 0.0
		max_speed = maxf(max_speed, vehicle.speed_kph)
		if frame % 600 == 0:
			print("QA DRIVE waypoint=%d position=%s speed=%.1f angle=%.2f" % [index, str(position), vehicle.speed_kph, angle])
		await get_tree().physics_frame
	vehicle.qa_throttle = 0
	vehicle.qa_brake = 1
	return false

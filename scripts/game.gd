extends Node3D
## Composition root. Simulation pauses as one subtree; UI and menu audio stay responsive.

var progress: ProgressStore
var simulation: Node3D
var world_viewport: SubViewport
var world_image: TextureRect
var district: HarborDistrict
var vehicle: DeliveryVehicle
var camera_rig: DrivingCamera
var traffic: HarborTraffic
var systems: VehicleSystems
var missions: DeliveryManager
var audio: GameAudio
var ui: DispatchUI
var started: bool = false
var play_time: float = 0
var _autosave: float = 0
var _service_cooldown: float = 0
var _qa: bool = false
var _pause_requested: int = -1
var _quitting: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Engine.max_fps = 60 if DisplayServer.get_name() != "headless" else 0
	get_tree().auto_accept_quit = false
	GameBindings.install()
	_qa = OS.get_cmdline_user_args().has("--qa") or OS.get_cmdline_user_args().has("--visual-probe") or OS.get_cmdline_user_args().has("--sandbox")
	progress = ProgressStore.new()
	progress.test_mode = _qa
	if not _qa:
		progress.load_progress()
		progress.load_settings()
	# Render 3D independently of the crisp native-resolution UI. Compatibility's
	# built-in scaling_3d_scale is unavailable, so use a real SubViewport instead.
	world_viewport = SubViewport.new()
	world_viewport.name = "WorldViewport"
	world_viewport.own_world_3d = true
	world_viewport.size = Vector2i(720, 405)
	world_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(world_viewport)
	world_image = TextureRect.new()
	world_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	world_image.texture = world_viewport.get_texture()
	world_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	world_image.stretch_mode = TextureRect.STRETCH_SCALE
	world_image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	world_image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_image)
	get_tree().root.size_changed.connect(_resize_world)
	simulation = Node3D.new()
	simulation.name = "Simulation"
	simulation.process_mode = Node.PROCESS_MODE_PAUSABLE
	world_viewport.add_child(simulation)
	district = HarborDistrict.new()
	simulation.add_child(district)
	district.set_clock(progress.clock_hours)
	vehicle = DeliveryVehicle.new()
	vehicle.name = "PlayerVan"
	vehicle.position = progress.saved_position + Vector3.UP * 0.95
	vehicle.rotation.y = progress.saved_yaw
	simulation.add_child(vehicle)
	camera_rig = DrivingCamera.new()
	camera_rig.target = vehicle
	simulation.add_child(camera_rig)
	traffic = HarborTraffic.new()
	traffic.player = vehicle
	traffic.district = district
	simulation.add_child(traffic)
	systems = VehicleSystems.new()
	systems.vehicle = vehicle
	systems.progress = progress
	simulation.add_child(systems)
	missions = DeliveryManager.new()
	missions.district = district
	missions.vehicle = vehicle
	missions.progress = progress
	simulation.add_child(missions)
	var marker = DestinationMarker.new()
	marker.missions = missions
	simulation.add_child(marker)
	audio = GameAudio.new()
	audio.vehicle = vehicle
	add_child(audio)
	ui = DispatchUI.new()
	ui.game = self
	add_child(ui)
	systems.message.connect(ui.notify)
	systems.collision_sound.connect(audio.collision)
	missions.notification.connect(ui.notify)
	missions.save_requested.connect(save_game)
	missions.delivery_completed.connect(func(_reward): audio.click())
	missions.restore()
	apply_settings()
	if OS.get_cmdline_user_args().has("--qa"):
		start_development_tool("res://qa/playtest.gd")
	if OS.get_cmdline_user_args().has("--visual-probe"):
		start_development_tool("res://qa/visual_probe.gd")
	if OS.get_cmdline_user_args().has("--quickstart"):
		start_game()

func start_development_tool(path: String) -> void:
	# QA scripts are intentionally excluded from desktop bundles. A developer
	# flag on a packaged game should explain this, rather than dereference null.
	if not ResourceLoader.exists(path):
		push_error("This development test requires the source project: " + path)
		quit_game(2)
		return
	var script = load(path)
	if script == null or not script.can_instantiate():
		push_error("Could not initialize development test: " + path)
		quit_game(2)
		return
	var runner = script.new()
	runner.game = self
	add_child(runner)

func _process(delta: float) -> void:
	# Applying pause only in idle processing avoids GodotPhysics' state-query list
	# being re-entered when a UI/deferred callback resumes in the middle of a tick.
	if _pause_requested >= 0:
		get_tree().paused = bool(_pause_requested)
		_pause_requested = -1
	if started and not get_tree().paused:
		play_time += delta
		_autosave += delta
		_service_cooldown = maxf(0, _service_cooldown - delta)
		if _autosave > 25:
			_autosave = 0
			save_game()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	if event.is_action_pressed("fullscreen"):
		progress.settings.fullscreen = not progress.settings.fullscreen
		apply_settings()
		return
	if event.is_action_pressed("pause"):
		if ui.screen.begins_with("settings_"):
			if ui.screen.ends_with("main"):
				ui.show_main()
			else:
				ui.show_pause()
		elif started:
			if get_tree().paused:
				resume_game()
			else:
				pause_game()
		get_viewport().set_input_as_handled()
		return
	if started and event.is_action_pressed("district_map"):
		if ui.screen == "map":
			resume_game()
		elif ui.screen == "":
			open_map()
		get_viewport().set_input_as_handled()
		return
	if started and event.is_action_pressed("workshop"):
		if ui.screen == "workshop":
			resume_game()
		elif ui.screen == "":
			open_workshop()
		get_viewport().set_input_as_handled()
		return
	if not started or get_tree().paused:
		return
	camera_rig.handle_mouse(event)
	if event.is_action_pressed("headlights"):
		vehicle.toggle_lights()
	elif event.is_action_pressed("camera"):
		camera_rig.cycle()
		ui.notify(["Chase camera", "Close chase camera", "Bonnet camera"][camera_rig.mode])
	elif event.is_action_pressed("recover"):
		recover_vehicle()
	elif event.is_action_pressed("time_of_day"):
		district.cycle_time()
		if district.night and not vehicle.lights_on:
			vehicle.toggle_lights()
		ui.notify("Time of day changed  •  H toggles headlights")
	elif event.is_action_pressed("dispatch"):
		prepare_menu()
		ui.show_jobs()
	elif event.is_action_pressed("telemetry"):
		ui.telemetry = not ui.telemetry
	elif event.is_action_pressed("interact"):
		if can_use_workshop() and _service_cooldown == 0:
			perform_service()

func start_game() -> void:
	started = true
	vehicle.enabled = true
	camera_rig.active = true
	traffic.enabled = true
	district.simulating = true
	_pause_requested = 0
	ui.hide_menu()
	if play_time < 1:
		ui.notify(progress.load_message if not progress.load_message.is_empty() else "Welcome to Harborline. Press J for a contract • M for the district map.", progress.load_message.is_empty())

func prepare_menu() -> void:
	save_game()
	_pause_requested = 1
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	for action in ["accelerate", "brake", "steer_left", "steer_right", "handbrake", "interact"]:
		Input.action_release(action)

func pause_game() -> void:
	prepare_menu()
	ui.show_pause()

func resume_game() -> void:
	_pause_requested = 0
	ui.hide_menu()
	camera_rig.active = true

func return_to_menu() -> void:
	save_game()
	_pause_requested = 0
	started = false
	vehicle.enabled = false
	camera_rig.active = false
	traffic.enabled = false
	district.simulating = false
	ui.show_main()

func open_map() -> void:
	prepare_menu()
	ui.show_map()

func open_workshop() -> void:
	prepare_menu()
	ui.show_workshop()

func can_use_workshop() -> bool:
	var position = vehicle.global_position
	position.y = 0
	return started and position.distance_to(HarborDistrict.FUEL_POINT) < 8 and vehicle.speed_kph < 2 and vehicle.grounded_wheels >= 3 and vehicle.global_basis.y.dot(Vector3.UP) > 0.7

func navigate_to_service(enabled: bool = true) -> void:
	missions.navigate_service(enabled)
	resume_game()
	ui.notify("Route set to Coast Service. Your contract and cargo are preserved." if enabled else "Service detour cleared • delivery navigation restored.")

func perform_service(kind: String = "full") -> bool:
	if not can_use_workshop():
		ui.notify("Park upright at Coast Service to refuel, repair or buy upgrades.", false)
		return false
	var result = systems.service(kind)
	_service_cooldown = 2
	if result:
		missions.navigate_service(false)
	save_game()
	return result

func purchase_upgrade(id: String) -> bool:
	if not can_use_workshop() or not CourierCareer.purchase(id, progress):
		return false
	ui.notify("Installed %s. Upgrade saved to your van." % CourierCareer.UPGRADES[id].name)
	save_game()
	return true

func accept_job(index: int) -> void:
	if missions.accept(index):
		resume_game()

func recover_vehicle() -> void:
	# Recovery stays near the player, snapping to the correct northbound road lane.
	var pos = vehicle.global_position
	var nearest_x = -120.0
	for x in HarborDistrict.ROAD_X:
		if absf(x - pos.x) < absf(nearest_x - pos.x):
			nearest_x = x
	var z = clampf(pos.z, -132, 132)
	if absf(z) < 20:
		z = 25.0
	var at = Vector3(nearest_x + 4, 0, z)
	# Avoid placing the van directly inside traffic.
	for car in traffic.cars:
		if car.body.global_position.distance_to(at) < 10:
			at.z = clampf(at.z + 13, -132, 132)
	vehicle.recover(at, 0)
	camera_rig.reset()
	if progress.fuel < 3:
		progress.fuel = 8
	systems.sync_vehicle()
	ui.notify("Recovered to the road. Cargo is safe. No recovery charge.")

func save_game() -> void:
	if not started:
		return
	progress.clock_hours = district.clock_hours
	if not progress.save_progress(vehicle.global_position, vehicle.global_rotation.y, missions.job):
		ui.notify("Could not write the local save. Check available disk space.", false)

func apply_settings(resize_window: bool = true) -> void:
	progress.validate_settings()
	district.set_quality(int(progress.settings.quality))
	camera_rig.sensitivity = float(progress.settings.sensitivity)
	camera_rig.invert_y = bool(progress.settings.invert_y)
	audio.apply_settings(progress.settings)
	if resize_window and DisplayServer.get_name() != "headless":
		if progress.settings.fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			var sizes = [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900)]
			DisplayServer.window_set_size(sizes[int(progress.settings.resolution)])
	_resize_world()
	if not progress.save_settings() and is_instance_valid(ui):
		ui.notify("Could not save your settings on this computer.", false)

func _resize_world() -> void:
	if not is_instance_valid(world_viewport):
		return
	var pixels = DisplayServer.window_get_size() if DisplayServer.get_name() != "headless" else Vector2i(960, 540)
	var render_scale: float = [0.65, 0.75, 1.0][int(progress.settings.quality)]
	world_viewport.size = Vector2i(maxi(320, int(pixels.x * render_scale)), maxi(180, int(pixels.y * render_scale)))

func quit_game(exit_code: int = 0) -> void:
	if _quitting:
		return
	_quitting = true
	save_game()
	_pause_requested = 0
	audio.shutdown()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit(exit_code)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_instance_valid(ui):
		quit_game()
	elif what == NOTIFICATION_APPLICATION_FOCUS_OUT and started and not _qa and is_instance_valid(ui) and ui.screen == "":
		pause_game()

extends SceneTree
## Non-rendering regression coverage for persistence and the gameplay rules.
## All disk fixtures use qa_logic_progress; the personal profile is untouched.

var checks: Array[Dictionary] = []
var failures: int = 0
var district: HarborDistrict
var vehicle: DeliveryVehicle
var missions: DeliveryManager
var systems: VehicleSystems
var fixture: Node3D

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool, details: String = "") -> void:
	checks.append({"test": label, "passed": passed, "details": details})
	if not passed:
		failures += 1
	print("LOGIC %s | %s | %s" % ["PASS" if passed else "FAIL", label, details])

func store() -> ProgressStore:
	var result = ProgressStore.new()
	result.test_mode = true
	result.test_slot = "qa_logic_progress"
	return result

func write_fixture(text: String) -> bool:
	var file = FileAccess.open(store().path(), FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(text)
	file.close()
	return true

func clear_disk_fixtures() -> void:
	for suffix in ["", ".bak", ".tmp", ".unreadable"]:
		var filename = store().path() + suffix
		if FileAccess.file_exists(filename):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(filename))

func run() -> void:
	GameBindings.install()
	var before = InputMap.action_get_events("accelerate").size()
	GameBindings.install()
	check("Input installation is idempotent", InputMap.action_get_events("accelerate").size() == before)
	check("Map and workshop have keyboard actions", InputMap.has_action("district_map") and InputMap.has_action("workshop"))
	check("Desktop renderer selects OpenGL Compatibility", ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility")
	check("Product rename preserves the existing save directory", OS.get_user_data_dir().replace("\\", "/").ends_with("godot/app_userdata/Harborline Dispatch"))
	check("Linux and Windows export presets exist", FileAccess.file_exists("res://export_presets.cfg"))
	test_persistence()
	test_career()
	# Only the vehicle fixture enters the tree; route logic needs no world meshes.
	district = HarborDistrict.new()
	fixture = Node3D.new()
	root.add_child(fixture)
	vehicle = DeliveryVehicle.new()
	vehicle.freeze = true
	fixture.add_child(vehicle)
	vehicle.set_physics_process(false)
	vehicle.enabled = true
	vehicle.grounded_wheels = 4
	systems = VehicleSystems.new()
	systems.vehicle = vehicle
	systems.progress = store()
	fixture.add_child(systems)
	systems.set_physics_process(false)
	missions = DeliveryManager.new()
	missions.district = district
	missions.vehicle = vehicle
	missions.progress = store()
	fixture.add_child(missions)
	missions.set_physics_process(false)
	test_routes_and_offers()
	test_missions()
	test_resources()
	clear_disk_fixtures()
	var report = {"date": Time.get_datetime_string_from_system(), "engine": Engine.get_version_info().string, "renderer": "headless / no rendering required", "failures": failures, "checks": checks}
	var file = FileAccess.open("res://qa/latest_logic_report.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	else:
		failures += 1
		push_error("Could not write the logic report.")
	fixture.queue_free()
	district.free()
	await process_frame
	await process_frame
	print("LOGIC RESULT: %d/%d passed" % [checks.size() - failures, checks.size()])
	quit(0 if failures == 0 else 1)

func test_persistence() -> void:
	clear_disk_fixtures()
	var original = store()
	original.money = 2133
	original.completed = 8
	original.earnings = 3870
	original.fuel = 79.5
	original.total_distance = 1245.5
	original.clock_hours = 21.2
	original.upgrades = {"efficiency": true, "cargo_rack": true}
	var contract = {"pickup": 0, "destination": 3, "stage": "delivery", "elapsed": 44.5, "cargo_condition": 89}
	check("Version 2 atomic save succeeds", original.save_progress(Vector3(-116, 0.8, -72), 0.23, contract))
	var loaded = store()
	loaded.load_progress()
	check("JSON numeric version is accepted", loaded.has_progress and loaded.money == 2133)
	check("Progression and upgrades round-trip", loaded.completed == 8 and loaded.upgrades.has("efficiency") and loaded.upgrades.has("cargo_rack") and loaded.earnings == 3870)
	check("Clock and odometer round-trip", is_equal_approx(loaded.clock_hours, 21.2) and is_equal_approx(loaded.total_distance, 1245.5))
	check("Active cargo and position round-trip", loaded.active_job.stage == "delivery" and loaded.active_job.cargo_condition == 89 and loaded.saved_position == Vector3(-116, 0, -72))
	original.money = 2200
	check("A second save creates a last-good backup", original.save_progress(Vector3.ZERO, 0, {}) and FileAccess.file_exists(original.path() + ".bak"))
	check("Corrupt primary fixture is writable", write_fixture("{interrupted write"))
	loaded = store()
	loaded.load_progress()
	check("Corrupt primary falls back to the last good save", loaded.has_progress and loaded.money == 2133 and loaded.load_message.contains("backup"))
	check("Recovered progress can be saved again", loaded.save_progress(Vector3.ZERO, 0, loaded.active_job))
	check("Unreadable primary is preserved for recovery", FileAccess.file_exists(loaded.path() + ".unreadable") and not loaded._read_data(loaded.path() + ".bak").is_empty())
	clear_disk_fixtures()
	check("Version 1 fixture is writable", write_fixture(JSON.stringify({"version": 1, "money": 777, "fuel": 91, "condition": 81, "completed": 3, "job": {"pickup": 0, "destination": 3, "stage": "delivery", "start_condition": 95, "elapsed": 32}})))
	loaded = store()
	loaded.load_progress()
	check("Version 1 progress migrates without resetting the wallet", loaded.has_progress and loaded.money == 777 and loaded.completed == 3 and loaded.upgrades.is_empty())
	check("New save fields have compatible defaults", loaded.total_distance == 0 and is_equal_approx(loaded.clock_hours, 16.3))
	check("Unsupported save versions are rejected", write_fixture('{"version":999,"money":9999}') and loaded._read_data(loaded.path()).is_empty())
	check("Fractional save versions are rejected", write_fixture('{"version":2.5,"money":9999}') and loaded._read_data(loaded.path()).is_empty())
	check("Non-object saves are rejected", write_fixture('[2,3]') and loaded._read_data(loaded.path()).is_empty())
	clear_disk_fixtures()
	check("Invalid-value fixture is writable", write_fixture(JSON.stringify({"version": 2, "money": "invalid", "fuel": -30, "condition": 900, "completed": -5, "position": [999, 1000, -999], "upgrades": {"efficiency": "yes", "reinforcement": true, "unknown": true}, "job": "invalid"})))
	loaded = store()
	loaded.load_progress()
	check("Untrusted save numbers are bounded", loaded.money == 650 and loaded.fuel == 0 and loaded.condition == 100 and loaded.completed == 0)
	check("Untrusted position cannot leave the district", loaded.saved_position == Vector3(165, 0, -190))
	check("Only known, boolean-owned upgrades are loaded", loaded.upgrades.size() == 1 and loaded.upgrades.has("reinforcement") and loaded.active_job.is_empty())
	check("Non-finite rule inputs use safe defaults", ProgressStore.number(NAN, 50, 0, 100) == 50 and ProgressStore.number(INF, 50, 0, 100) == 50 and ProgressStore.number(true, 50, 0, 100) == 50)
	loaded.settings = {"quality": 99, "resolution": "invalid", "master": NAN, "fullscreen": "yes", "invert_y": 1}
	loaded.validate_settings()
	check("Malformed settings are normalized before array indexing", loaded.settings.quality == 2 and loaded.settings.resolution == 0 and loaded.settings.fullscreen == false and loaded.settings.invert_y == false)
	check("Missing settings regain their defaults", loaded.settings.has("sensitivity") and loaded.settings.has("music") and is_equal_approx(loaded.settings.master, 0.75))
	check("QA settings never write the personal settings file", loaded.save_settings())

func test_career() -> void:
	check("Rank thresholds are stable", CourierCareer.rank_index(2) == 0 and CourierCareer.rank_index(3) == 1 and CourierCareer.rank_index(8) == 2 and CourierCareer.rank_index(15) == 3)
	check("Milestone rewards apply only when crossing a threshold", CourierCareer.milestone_reward(2, 3) == 125 and CourierCareer.milestone_reward(3, 4) == 0 and CourierCareer.milestone_reward(7, 8) == 250)
	check("Crossed milestones are accumulated once", CourierCareer.milestone_reward(0, 15) == 875 and CourierCareer.milestone_reward(15, 16) == 0)
	var progress = store()
	check("Rank-locked upgrade cannot be purchased", not CourierCareer.purchase("reinforcement", progress) and progress.money == 650)
	check("Unknown upgrade cannot debit the wallet", not CourierCareer.purchase("unknown", progress) and progress.money == 650)
	check("Economy tune debits its exact price", CourierCareer.purchase("efficiency", progress) and progress.money == 150 and progress.upgrades.has("efficiency"))
	check("An owned upgrade cannot be bought twice", not CourierCareer.purchase("efficiency", progress) and progress.money == 150)
	progress.completed = 3
	check("Insufficient funds cannot buy an unlocked upgrade", not CourierCareer.purchase("reinforcement", progress) and progress.money == 150)
	progress.money = 700
	check("Exact-price purchase never overdraws the wallet", CourierCareer.purchase("reinforcement", progress) and progress.money == 0)

func test_routes_and_offers() -> void:
	var legal = true
	var count = 0
	for source in district.places.size():
		for destination in district.places.size():
			if source == destination:
				continue
			var from: Vector3 = district.places[source].position
			var to: Vector3 = district.places[destination].position
			var route = district.road_route(from, to)
			legal = legal and route.size() >= 4 and route[0] == from and route[route.size() - 1] == to
			for i in range(2, route.size() - 1):
				var a = route[i - 1]
				var b = route[i]
				if a.distance_to(b) > 0.1:
					legal = legal and _is_road_leg(a, b)
			count += 1
	check("All business-to-business routes stay on the road graph", legal and count == 30, "%d directed routes with driveway attachments" % count)
	var valid_offers = true
	for source in district.places.size():
		vehicle.position = district.places[source].position
		var destinations: Dictionary = {}
		for completed in 6:
			missions.progress.completed = completed
			missions.make_offers()
			var unique: Dictionary = {}
			valid_offers = valid_offers and missions.offers.size() == 3
			for offer in missions.offers:
				valid_offers = valid_offers and int(offer.pickup) == source and int(offer.destination) != source and not unique.has(offer.destination) and offer.base >= 100 and offer.distance > 0
				unique[offer.destination] = true
				destinations[offer.destination] = true
		valid_offers = valid_offers and destinations.size() == 5
	check("Offer rotation reaches every destination from each business", valid_offers, "6 origins, 6 rotations, 3 unique offers each")
	vehicle.position = HarborDistrict.SPAWN
	missions.progress.completed = 0
	missions.make_offers()
	check("First contract uses the corrected road distance", missions.offers[0].destination == 3 and missions.offers[0].base == 231, "destination %d, base $%d, route %d m" % [missions.offers[0].destination, missions.offers[0].base, missions.offers[0].distance])
	check("New couriers receive standard contracts", missions.offers.all(func(offer): return offer.kind == "standard"))
	missions.progress.completed = 3
	missions.make_offers()
	check("Local Partner unlocks fragile work", missions.offers[1].kind == "fragile" and missions.offers[1].weight == 220)
	missions.progress.completed = 8
	missions.make_offers()
	check("Harbor Specialist unlocks priority work", missions.offers[2].kind == "priority" and missions.maximum_bonus(missions.offers[2]) == 105)

func test_missions() -> void:
	missions.progress = store()
	missions.progress.condition = 81
	missions.progress.active_job = {"pickup": 0, "destination": 3, "stage": "delivery", "start_condition": 95, "elapsed": 32}
	missions.restore()
	check("Legacy active cargo retains its incurred damage", not missions.job.is_empty() and missions.job.cargo_condition == 86 and missions.elapsed == 32 and missions.job.kind == "standard")
	check("Restored delivery reinstates payload mass", vehicle.cargo_mass == 120 and vehicle.mass == DeliveryVehicle.MASS + 120)
	var old_job = missions.job.duplicate(true)
	missions.navigate_service()
	check("Service detour preserves the active delivery", missions.target_position() == HarborDistrict.FUEL_POINT and missions.job == old_job and missions.has_navigation_target())
	missions.navigate_service(false)
	check("Ending a service detour restores the cargo route", missions.target_position() == district.places[3].position and missions.navigation_name() == "Northline Works")
	vehicle.position = district.places[3].position
	vehicle.speed_kph = 5
	check("Cargo cannot be handed over while moving", not missions.can_handle())
	vehicle.speed_kph = 0
	vehicle.grounded_wheels = 0
	check("Cargo cannot be handled in midair", not missions.can_handle())
	vehicle.grounded_wheels = 4
	vehicle.rotation.z = PI / 2
	check("Cargo cannot be handled by a tipped van", not missions.can_handle())
	vehicle.rotation = Vector3.ZERO
	check("Upright, stationary parking allows cargo handling", missions.can_handle())
	missions.progress.completed = 2
	missions.job.base = 200
	missions.job.cargo_condition = 90
	missions.job.deadline = 180
	missions.elapsed = 30
	var before = missions.progress.money
	missions.finish_handling()
	check("Delivery credits base, care, time and rank milestone", missions.last_reward == 370 and missions.progress.money == before + 370 and missions.progress.completed == 3 and missions.last_breakdown.milestone == 125)
	check("Delivery completion unloads the physical van", missions.job.is_empty() and vehicle.cargo_mass == 0 and vehicle.mass == DeliveryVehicle.MASS)
	before = missions.progress.money
	missions.finish_handling()
	check("A completed contract cannot pay twice", missions.progress.money == before and missions.progress.completed == 3)
	vehicle.position = HarborDistrict.SPAWN
	missions.make_offers()
	check("Dispatch accepts one valid offer", missions.accept(0))
	check("Dispatch rejects duplicate and out-of-range accepts", not missions.accept(1) and not missions.accept(-1) and not missions.accept(99))
	check("Pickup impact does not damage unloaded cargo", _pickup_is_safe())
	missions.finish_handling()
	check("Collection adds cargo mass and restarts its timer", missions.job.stage == "delivery" and missions.elapsed == 0 and missions.job.elapsed == 0 and vehicle.cargo_mass > 0)
	missions.job.kind = "fragile"
	missions.job.cargo_condition = 100.0
	missions._on_impact(5)
	var unprotected: float = 100 - missions.job.cargo_condition
	missions.job.cargo_condition = 100.0
	missions.progress.upgrades.cargo_rack = true
	missions._on_impact(5)
	check("Padded rack reduces fragile cargo damage by 35%", is_equal_approx(100 - float(missions.job.cargo_condition), unprotected * 0.65))
	systems.progress = missions.progress
	systems.progress.money = 1000
	systems.progress.condition = 40
	var cargo_condition: float = missions.job.cargo_condition
	systems.service("repair")
	check("Vehicle repairs cannot erase cargo damage", systems.progress.condition == 100 and missions.job.cargo_condition == cargo_condition)
	vehicle.position = district.places[int(missions.job.destination)].position
	missions.job.kind = "priority"
	missions.job.base = 200
	missions.job.cargo_condition = 100
	missions.elapsed = 0
	missions.finish_handling()
	check("On-time priority work earns its advertised $105 bonus", missions.last_reward == 305 and missions.last_breakdown.time == 60)
	vehicle.position = HarborDistrict.SPAWN
	missions.make_offers()
	missions.accept(0)
	missions.finish_handling()
	vehicle.position = district.places[int(missions.job.destination)].position
	var base: int = missions.job.base
	missions.elapsed = float(missions.job.deadline) + 10
	missions.finish_handling()
	check("Late delivery keeps base and care pay without a fine", missions.last_reward == base + 45 and missions.last_breakdown.time == 0)
	vehicle.position = HarborDistrict.SPAWN
	missions.make_offers()
	missions.accept(0)
	missions.finish_handling()
	before = missions.progress.money
	check("Returning a contract clears payload without charging money", missions.cancel() and missions.job.is_empty() and vehicle.cargo_mass == 0 and missions.progress.money == before)
	missions.progress.active_job = {"pickup": -10, "destination": 500, "stage": "delivery"}
	missions.restore()
	check("Invalid saved contracts cannot index outside the district", missions.job.is_empty() and missions.progress.active_job.is_empty() and vehicle.cargo_mass == 0)
	missions.navigate_service()
	check("Service navigation works without an active job", missions.has_navigation_target() and missions.route.size() > 1 and missions.navigation_name() == "Coast Service")

func _pickup_is_safe() -> bool:
	var before: float = missions.job.cargo_condition
	missions._on_impact(8)
	return missions.job.cargo_condition == before

func _is_road_leg(a: Vector3, b: Vector3) -> bool:
	return (is_equal_approx(a.x, b.x) and a.x in HarborDistrict.ROAD_X) or (is_equal_approx(a.z, b.z) and a.z in HarborDistrict.ROAD_Z)

func test_resources() -> void:
	systems.progress = store()
	vehicle.engine_load = 0.7
	vehicle.signed_speed = 8
	vehicle.odometer = 123
	systems._distance_at_last_tick = 0
	systems._physics_process(10)
	var normal_use = 100 - systems.progress.fuel
	check("Resource simulation records actual driven distance", systems.progress.total_distance == 123)
	systems._physics_process(0)
	check("Distance is not counted twice", systems.progress.total_distance == 123)
	systems.progress.fuel = 100
	systems.progress.upgrades.efficiency = true
	systems._physics_process(10)
	check("Economy tune reduces real fuel use by 25%", is_equal_approx(100 - systems.progress.fuel, normal_use * 0.75))
	systems.progress.fuel = 0
	systems.sync_vehicle()
	check("Empty tank disables engine thrust", not vehicle.fuel_available)
	systems.progress.condition = 100
	systems.progress.upgrades = {}
	systems._on_impact(5)
	var normal_damage = 100 - systems.progress.condition
	systems.progress.condition = 100
	systems.progress.upgrades.reinforcement = true
	systems._on_impact(5)
	check("Protective bumpers reduce impact damage by 25%", is_equal_approx(100 - systems.progress.condition, normal_damage * 0.75))
	systems.progress.condition = 0
	systems.sync_vehicle()
	check("A damaged van remains drivable after refueling", is_equal_approx(vehicle.engine_health, 0.6))
	systems.progress.money = 500
	systems.progress.fuel = 50
	systems.progress.condition = 80
	var fuel_price = systems.service_cost("fuel")
	check("Fuel-only service charges its quote and preserves damage", systems.service("fuel") and systems.progress.money == 500 - fuel_price and systems.progress.fuel == 100 and systems.progress.condition == 80)
	var balance = systems.progress.money
	var repair_price = systems.service_cost("repair")
	check("Repair-only service charges its quote", systems.service("repair") and systems.progress.money == balance - repair_price and systems.progress.condition == 100)
	balance = systems.progress.money
	check("Already serviced van incurs no extra charge", systems.service_cost() == 0 and systems.service() and systems.progress.money == balance)
	systems.progress.money = 0
	systems.progress.fuel = 0
	systems.progress.condition = 30
	check("Emergency fuel prevents a no-money soft lock", not systems.service() and systems.progress.fuel == 12 and systems.progress.money == 0 and vehicle.fuel_available)
	check("Emergency fuel does not grant free repairs", systems.progress.condition == 30)
	check("Unaffordable service cannot overdraw the wallet", not systems.service() and systems.progress.money == 0 and systems.progress.fuel == 12)
	check("Unknown service kind cannot change vehicle resources", not systems.service("invalid") and systems.progress.money == 0 and systems.progress.condition == 30)

class_name DeliveryManager
extends Node

signal notification(text: String, positive: bool)
signal job_changed
signal delivery_completed(reward: int)
signal save_requested

var district: HarborDistrict
var vehicle: DeliveryVehicle
var progress: ProgressStore
var job: Dictionary = {}
var offers: Array[Dictionary] = []
var handling: float = 0.0
var elapsed: float = 0.0
var last_reward: int = 0
var route = PackedVector3Array()
var _route_timer: float = 0.0
var service_waypoint: bool = false
var route_distance: float = 0.0
var last_breakdown: Dictionary = {}

func _ready() -> void:
	vehicle.impact.connect(_on_impact)

func restore() -> void:
	job = {}
	elapsed = 0
	handling = 0
	var saved = progress.active_job
	if saved.has("pickup") and saved.has("destination") and saved.has("stage"):
		var pickup = int(ProgressStore.number(saved.pickup, -1, -1, district.places.size()))
		var destination = int(ProgressStore.number(saved.destination, -1, -1, district.places.size()))
		if pickup >= 0 and pickup < district.places.size() and destination >= 0 and destination < district.places.size() and pickup != destination and saved.stage in ["pickup", "delivery"]:
			job = saved.duplicate(true)
			job.pickup = pickup
			job.destination = destination
			job["base"] = int(ProgressStore.number(job.get("base"), 160, 100, 2000))
			job["cargo"] = str(job.get("cargo", "Dispatch parcels")).left(80)
			job["kind"] = job.get("kind", "standard") if job.get("kind") in ["standard", "fragile", "priority"] else "standard"
			job["deadline"] = ProgressStore.number(job.get("deadline"), 180, 30, 900)
			job["weight"] = ProgressStore.number(job.get("weight"), 120, 0, 500)
			job["start_condition"] = ProgressStore.number(job.get("start_condition"), progress.condition, 0, 100)
			# v1 saves tracked van condition only; preserve already incurred damage.
			var old_damage = maxf(0, float(job.start_condition) - progress.condition)
			job["cargo_condition"] = ProgressStore.number(job.get("cargo_condition"), maxf(0, 100 - old_damage), 0, 100)
			elapsed = ProgressStore.number(job.get("elapsed"), 0, 0, 86400)
			job.elapsed = elapsed
			_sync_cargo()
			update_route()
			job_changed.emit()
			return
	if not saved.is_empty():
		progress.active_job = {}
		notification.emit("The saved contract was invalid. Your balance is safe; press J for a new job.", false)
	_sync_cargo()
	update_route()

func make_offers() -> void:
	offers.clear()
	var source = district.nearest_place(vehicle.global_position)
	if vehicle.global_position.distance_to(district.places[source].position) > 32:
		source = 0
	var order = [3, 1, 2, 4, 5, 0]
	# Rotate after each delivery, so return jobs and all destinations are available.
	for index in order.size():
		var destination: int = order[(index + progress.completed) % order.size()]
		if destination == source:
			continue
		var path = district.road_route(district.places[source].position, district.places[destination].position)
		var distance = 0.0
		for i in range(1, path.size()):
			distance += path[i - 1].distance_to(path[i])
		var rank = CourierCareer.rank_index(progress.completed)
		var kind = "standard"
		if rank >= 1 and offers.size() == 1:
			kind = "fragile"
		if rank >= 2 and offers.size() == 2:
			kind = "priority"
		var multiplier: float = CourierCareer.RANKS[rank].pay * (1.20 if kind == "fragile" else 1.12 if kind == "priority" else 1.0)
		offers.append({"pickup": source, "destination": destination, "cargo": district.places[destination].cargo, "kind": kind, "weight": 220.0 if kind == "fragile" else 120.0, "base": int((100 + int(distance * 0.32)) * multiplier), "distance": int(distance), "deadline": (80.0 + distance / 4.5) * (0.75 if kind == "priority" else 1.0), "stage": "pickup", "elapsed": 0.0, "start_condition": progress.condition, "cargo_condition": 100.0})
		if offers.size() == 3:
			break

func accept(index: int) -> bool:
	if not job.is_empty() or index < 0 or index >= offers.size():
		return false
	job = offers[index].duplicate(true)
	elapsed = 0
	handling = 0
	service_waypoint = false
	update_route()
	notification.emit("Contract accepted. Park in the collection bay and hold E to load.", true)
	job_changed.emit()
	save_requested.emit()
	return true

func cancel() -> bool:
	if job.is_empty():
		return false
	job.clear()
	elapsed = 0
	handling = 0
	_sync_cargo()
	update_route()
	job_changed.emit()
	notification.emit("Contract returned to dispatch. No charge • press J to choose new work.", true)
	save_requested.emit()
	return true

func target_index() -> int:
	if job.is_empty():
		return -1
	return int(job.pickup if job.stage == "pickup" else job.destination)

func target_position() -> Vector3:
	if service_waypoint:
		return HarborDistrict.FUEL_POINT
	return cargo_target_position()

func cargo_target_position() -> Vector3:
	var index = target_index()
	return district.places[index].position if index >= 0 else Vector3.ZERO

func distance_to_target() -> float:
	if job.is_empty():
		return 0
	var pos = vehicle.global_position
	pos.y = 0
	return pos.distance_to(cargo_target_position())

func has_navigation_target() -> bool:
	return service_waypoint or not job.is_empty()

func navigation_distance() -> float:
	var position = vehicle.global_position
	position.y = 0
	return position.distance_to(target_position()) if has_navigation_target() else 0.0

func navigation_name() -> String:
	return "Coast Service" if service_waypoint else district.places[target_index()].name if not job.is_empty() else "Harbor District"

func navigate_service(enabled: bool = true) -> void:
	service_waypoint = enabled
	update_route()
	job_changed.emit()

func in_zone() -> bool:
	return not job.is_empty() and distance_to_target() < 6.5

func can_handle() -> bool:
	return in_zone() and vehicle.speed_kph < 2.0 and vehicle.grounded_wheels >= 3 and vehicle.global_basis.y.dot(Vector3.UP) > 0.7

func _physics_process(delta: float) -> void:
	if not vehicle.enabled:
		return
	if not job.is_empty() and job.stage == "delivery":
		elapsed += delta
		job.elapsed = elapsed
	_route_timer += delta
	if _route_timer >= 0.7:
		_route_timer = 0
		update_route()
	if job.is_empty():
		return
	if can_handle() and Input.is_action_pressed("interact"):
		handling += delta
		if handling >= 1.8:
			finish_handling()
	else:
		handling = maxf(0, handling - delta * 2.5)

func finish_handling() -> void:
	handling = 0
	if not can_handle():
		return
	if job.stage == "pickup":
		job.stage = "delivery"
		job.start_condition = progress.condition
		elapsed = 0
		job.elapsed = 0
		notification.emit("Cargo secured. Deliver to %s." % district.places[int(job.destination)].name, true)
	else:
		var damage = 100 - float(job.cargo_condition)
		var care_bonus = int(maxf(0, 45 - damage * 3.0))
		var time_bonus = 30 if elapsed <= float(job.deadline) else 0
		if job.kind == "priority" and time_bonus > 0:
			time_bonus = 60
		last_reward = int(job.base) + care_bonus + time_bonus
		var milestone = CourierCareer.milestone_reward(progress.completed, progress.completed + 1)
		last_breakdown = {"base": int(job.base), "care": care_bonus, "time": time_bonus, "milestone": milestone, "cargo_condition": job.cargo_condition}
		last_reward += milestone
		progress.money += last_reward
		progress.earnings += last_reward
		progress.completed += 1
		var receipt = "DELIVERED  +$%d  •  Care $%d / On-time $%d" % [last_reward, care_bonus, time_bonus]
		if milestone > 0:
			receipt += " • %s +$%d" % [CourierCareer.rank_name(progress.completed), milestone]
		notification.emit(receipt, true)
		job.clear()
		delivery_completed.emit(last_reward)
	_sync_cargo()
	update_route()
	job_changed.emit()
	save_requested.emit()

func update_route() -> void:
	if not has_navigation_target():
		route = PackedVector3Array()
	else:
		route = district.road_route(vehicle.global_position, target_position())
	route_distance = 0
	for i in range(1, route.size()):
		route_distance += route[i - 1].distance_to(route[i])

func _sync_cargo() -> void:
	vehicle.set_cargo_mass(float(job.weight) if not job.is_empty() and job.stage == "delivery" else 0.0)

func _on_impact(severity: float) -> void:
	if not vehicle.enabled or job.is_empty() or job.stage != "delivery":
		return
	var damage = clampf((severity - 1.4) * 1.6, 0.3, 22)
	if job.kind == "fragile":
		damage *= 1.5
	if progress.upgrades.has("cargo_rack"):
		damage *= 0.65
	job.cargo_condition = maxf(0, float(job.cargo_condition) - damage)

func navigation_hint() -> String:
	if not has_navigation_target():
		return "M  District map • G  Workshop at Coast Service"
	var position = vehicle.global_position
	position.y = 0
	if position.distance_to(target_position()) < 9:
		return "Coast Service • stop to use E / G" if service_waypoint else "Destination bay • stop and hold E"
	# Ignore the tiny centerline attachment; guide toward the next road segment.
	for i in range(1, route.size()):
		if position.distance_to(route[i]) < 12:
			continue
		var local = vehicle.to_local(route[i])
		var angle = atan2(local.x, -local.z)
		if absf(angle) > 2.35:
			return "Turn around when clear • %d m remaining" % int(route_distance)
		if absf(angle) > 0.55:
			return "Turn %s • %d m remaining" % ["right" if angle > 0 else "left", int(route_distance)]
		return "Continue ahead • %d m remaining" % int(route_distance)
	return "Approaching %s" % navigation_name()

func maximum_bonus(offer: Dictionary) -> int:
	return 105 if offer.get("kind", "standard") == "priority" else 75

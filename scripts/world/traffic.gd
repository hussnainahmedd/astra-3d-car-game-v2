class_name HarborTraffic
extends Node3D
## Small fixed traffic pool. Rounded lane paths, predictive following and signal stops.

var district: HarborDistrict
var player: DeliveryVehicle
var cars: Array[Dictionary] = []
var enabled: bool = false

func _ready() -> void:
	var inner = _rounded_loop([Vector3(-116, 0, -146), Vector3(116, 0, -146), Vector3(116, 0, 146), Vector3(-116, 0, 146)], 13)
	var outer = _rounded_loop([Vector3(-124, 0, 154), Vector3(124, 0, 154), Vector3(124, 0, -154), Vector3(-124, 0, -154)], 16)
	var colors = [Color("b77856"), Color("628b88"), Color("beb9a0"), Color("536b7c"), Color("8b826e")]
	for i in 5:
		var route = inner if i < 3 else outer
		var body = CharacterBody3D.new()
		body.name = "Traffic%02d" % i
		body.collision_layer = 4
		body.collision_mask = 1 | 2 | 4
		add_child(body)
		Geometry.collider(body, Vector3(0, 0.18, 0), Vector3(1.9, 1.15, 4.25))
		var visual = VehicleVisual.new()
		body.add_child(visual)
		visual.build(false, colors[i])
		var distance = route.get_baked_length() * (i * 0.259 + 0.06)
		distance = fmod(distance, route.get_baked_length())
		body.position = route.sample_baked(distance) + Vector3.UP * 0.79
		var ahead = route.sample_baked(fmod(distance + 1, route.get_baked_length()))
		body.rotation.y = atan2(-(ahead.x - body.position.x), -(ahead.z - body.position.z))
		cars.append({"body": body, "visual": visual, "path": route, "distance": distance, "speed": 0.0, "cruise": 8.0 + i * 0.6})

func _rounded_loop(corners: Array, radius: float) -> Curve3D:
	var curve = Curve3D.new()
	curve.bake_interval = 0.65
	for i in corners.size():
		var previous: Vector3 = corners[(i - 1 + corners.size()) % corners.size()]
		var current: Vector3 = corners[i]
		var next: Vector3 = corners[(i + 1) % corners.size()]
		var entry = current + (previous - current).normalized() * radius
		var exit = current + (next - current).normalized() * radius
		for n in 13:
			var t = n / 12.0
			var p = entry.lerp(current, t).lerp(current.lerp(exit, t), t)
			curve.add_point(p)
	curve.add_point(curve.get_point_position(0))
	return curve

func _physics_process(delta: float) -> void:
	if not enabled:
		return
	# One consistent position snapshot per tick, rather than allocating the same
	# obstacle list for every car and giving later cars a different view of traffic.
	var obstacles = PackedVector3Array([player.global_position])
	for car in cars:
		obstacles.append(car.body.global_position)
	for car_index in cars.size():
		var car: Dictionary = cars[car_index]
		var body: CharacterBody3D = car.body
		var path: Curve3D = car.path
		var length = path.get_baked_length()
		var look = path.sample_baked(fmod(car.distance + 7.0, length))
		var direction = (look - Vector3(body.position.x, 0, body.position.z)).normalized()
		var desired_speed: float = car.cruise
		var ahead = path.sample_baked(fmod(car.distance + 18.0, length))
		var later_direction = (ahead - look).normalized()
		if direction.dot(later_direction) < 0.985:
			desired_speed = 4.4
		# Yield before central crossings while the vertical signal is red.
		if not district.vertical_green() and absf(direction.z) > 0.8:
			var before = -body.position.z * signf(direction.z)
			if before > 12 and before < 33:
				desired_speed = minf(desired_speed, maxf(0, (before - 15) * 0.8))
		for obstacle_index in obstacles.size():
			if obstacle_index == car_index + 1:
				continue
			var obstacle: Vector3 = obstacles[obstacle_index]
			var relative = obstacle - body.global_position
			relative.y = 0
			var forward_gap = relative.dot(direction)
			var sideways = absf(relative.dot(Vector3(direction.z, 0, -direction.x)))
			if forward_gap > 0 and forward_gap < 25 and sideways < 3.15:
				# A small stopping deadband avoids endless creeping toward a parked
				# van while leaving a useful bumper-to-bumper safety margin.
				desired_speed = minf(desired_speed, 0.0 if forward_gap < 8 else maxf(0, (forward_gap - 7.0) * 0.65))
		car.speed = move_toward(car.speed, desired_speed, delta * (4.8 if desired_speed < car.speed else 1.8))
		var next_distance = fmod(car.distance + car.speed * delta, length)
		var point = path.sample_baked(next_distance) + Vector3.UP * 0.79
		var motion = point - body.position
		var collision = body.move_and_collide(motion)
		if collision == null:
			car.distance = next_distance
		else:
			car.speed = 0.0
		body.rotation.y = lerp_angle(body.rotation.y, atan2(-direction.x, -direction.z), minf(1, delta * 5))
		car.visual.animate(car.speed, 0, desired_speed < 1, delta)

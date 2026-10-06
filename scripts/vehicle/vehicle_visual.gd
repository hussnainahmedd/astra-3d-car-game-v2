class_name VehicleVisual
extends Node3D
## Original metre-scale van and compact traffic vehicle assets.

var wheels: Array[Node3D] = []
var front_pivots: Array[Node3D] = []
var headlights: Array[SpotLight3D] = []
var tail_lamps: Array[MeshInstance3D] = []
var wheel_spin: float = 0.0
var is_van: bool = true
var wheel_batches: Array[MultiMesh] = []
var wheel_offsets: Array = []
var _braking: bool = false

func build(van: bool = true, paint: Color = Color("c9d6ca")) -> void:
	is_van = van
	var dark = Color("202e33")
	var glass = Color("284c5a")
	var trim = Color("d4d8c9")
	Geometry.part(self, "bevel", Vector3(0, 0, 0), Vector3(1.92, 0.58, 4.2), paint)
	Geometry.box(self, Vector3(0, -0.25, 0), Vector3(1.8, 0.16, 4.3), dark)
	if van:
		Geometry.part(self, "bevel", Vector3(0, 0.72, 0.7), Vector3(1.94, 1.48, 2.82), paint)
		Geometry.part(self, "bevel", Vector3(0, 1.49, 0.56), Vector3(1.91, 0.10, 3.1), trim)
		Geometry.part(self, "bevel", Vector3(0, 0.71, -1.16), Vector3(1.84, 1.33, 1.02), paint)
		var windshield = Geometry.box(self, Vector3(0, 0.86, -1.72), Vector3(1.63, 0.79, 0.04), glass)
		windshield.rotation.x = -0.12
		Geometry.box(self, Vector3(0, 0.33, -1.93), Vector3(1.90, 0.18, 0.39), paint)
		for side in [-1.0, 1.0]:
			Geometry.box(self, Vector3(side * 0.939, 0.90, -1.18), Vector3(0.03, 0.68, 0.76), glass)
			Geometry.box(self, Vector3(side * 0.984, 0.42, 0.7), Vector3(0.015, 0.32, 2.7), Color("2d6d6b"))
			Geometry.box(self, Vector3(side * 0.983, 0.78, 0.72), Vector3(0.013, 0.28, 1.86), Color("d7e0d1"))
			Geometry.box(self, Vector3(side * 0.99, 0.58, -0.72), Vector3(0.04, 0.06, 0.18), dark)
			Geometry.box(self, Vector3(side * 1.10, 0.62, -1.44), Vector3(0.25, 0.24, 0.16), dark)
			Geometry.text(self, "H A R B O R L I N E", Vector3(side * 0.993, 0.88, 0.72), 48, 0.0025, Color("264c4e"), side * PI / 2.0)
		Geometry.box(self, Vector3(0, 0.71, 2.121), Vector3(0.026, 1.42, 0.018), Color("7e8e89"))
		Geometry.box(self, Vector3(0, 1.07, 2.128), Vector3(1.38, 0.44, 0.02), glass)
		Geometry.text(self, "H / D", Vector3(0, 0.62, 2.146), 48, 0.005, Color("264c4e"))
	else:
		Geometry.box(self, Vector3(0, 0.51, 0.04), Vector3(1.65, 0.72, 2.18), glass)
		Geometry.box(self, Vector3(0, 0.91, 0.1), Vector3(1.68, 0.10, 2.23), paint)
		for side in [-1.0, 1.0]:
			Geometry.box(self, Vector3(side * 0.84, 0.56, 0.15), Vector3(0.08, 0.66, 0.09), paint)
		Geometry.box(self, Vector3(0, 0.29, -1.61), Vector3(1.88, 0.18, 0.90), paint)
	for z in [-2.14, 2.14]:
		Geometry.box(self, Vector3(0, -0.04, z), Vector3(1.95, 0.18, 0.12), dark)
	Geometry.box(self, Vector3(0, 0.14, -2.113), Vector3(0.94, 0.17, 0.018), dark)
	Geometry.box(self, Vector3(0, -0.04, 2.213), Vector3(0.42, 0.13, 0.01), Color("e8d8a8"))
	for side in [-1.0, 1.0]:
		Geometry.part(self, "box", Vector3(side * 0.70, 0.19, -2.122), Vector3(0.36, 0.18, 0.03), Color("f4e8bf"), 0, 0.5)
		var tail = Geometry.part(self, "box", Vector3(side * 0.80, 0.24, 2.14), Vector3(0.18, 0.35, 0.04), Color("853d32"), 0, 0.2)
		tail_lamps.append(tail)
		if van:
			var lamp = SpotLight3D.new()
			lamp.position = Vector3(side * 0.7, 0.25, -2.17)
			lamp.rotation.x = -0.08
			lamp.light_color = Color("ffe6bd")
			lamp.light_energy = 2.5
			lamp.spot_range = 42
			lamp.spot_angle = 28
			lamp.spot_attenuation = 0.6
			lamp.shadow_enabled = false
			lamp.visible = false
			add_child(lamp)
			headlights.append(lamp)
	for i in 4:
		var side = -1.0 if i % 2 == 0 else 1.0
		var front = i < 2
		var pivot = Node3D.new()
		pivot.position = Vector3(side * 0.95, -0.4, -1.34 if front else 1.35)
		add_child(pivot)
		if front:
			front_pivots.append(pivot)
		var spin = Node3D.new()
		pivot.add_child(spin)
		var tire = Geometry.part(spin, "cylinder", Vector3.ZERO, Vector3(0.69, 0.24, 0.69), Color("202729"))
		tire.rotation.z = PI / 2
		var rim = Geometry.part(spin, "cylinder", Vector3(side * 0.132, 0, 0), Vector3(0.40, 0.02, 0.40), Color("8e9b9e"))
		rim.rotation.z = PI / 2
		Geometry.box(spin, Vector3(side * 0.15, 0, 0), Vector3(0.02, 0.05, 0.30), dark)
		wheels.append(spin)
	_bake_body()
	_batch_wheels()
	_update_wheel_batches()

func _bake_body() -> void:
	# Merge fixed body parts into one surface per material, instead of dozens of draws.
	var surfaces: Dictionary = {}
	for child in get_children():
		if not child is MeshInstance3D or child in tail_lamps:
			continue
		var material = child.mesh.surface_get_material(0)
		var key = material.get_instance_id()
		if not surfaces.has(key):
			var tool = SurfaceTool.new()
			tool.begin(Mesh.PRIMITIVE_TRIANGLES)
			tool.set_material(material)
			surfaces[key] = tool
		surfaces[key].append_from(child.mesh, 0, child.transform)
		child.queue_free()
	var combined = ArrayMesh.new()
	for tool in surfaces.values():
		tool.commit(combined)
	var instance = MeshInstance3D.new()
	instance.mesh = combined
	add_child(instance)

func _batch_wheels() -> void:
	for part_index in 3:
		var multi = MultiMesh.new()
		multi.transform_format = MultiMesh.TRANSFORM_3D
		multi.mesh = wheels[0].get_child(part_index).mesh
		multi.instance_count = 4
		var offsets: Array[Transform3D] = []
		for i in 4:
			var part = wheels[i].get_child(part_index)
			offsets.append(part.transform)
			part.queue_free()
		wheel_batches.append(multi)
		wheel_offsets.append(offsets)
		var instance = MultiMeshInstance3D.new()
		instance.multimesh = multi
		add_child(instance)

func _update_wheel_batches() -> void:
	for part_index in wheel_batches.size():
		for i in 4:
			wheel_batches[part_index].set_instance_transform(i, wheels[i].get_parent().transform * wheels[i].transform * wheel_offsets[part_index][i])

func animate(speed: float, steer: float, brake: bool, delta: float) -> void:
	wheel_spin -= speed * delta / 0.345
	for wheel in wheels:
		wheel.rotation.x = wheel_spin
	for pivot in front_pivots:
		pivot.rotation.y = steer
	_update_wheel_batches()
	if brake != _braking:
		_braking = brake
		var color = Color("ff593d") if brake else Color("853d32")
		for tail in tail_lamps:
			tail.material_override = Geometry.material(color, 0.8 if brake else 0.15)

func set_headlights(enabled: bool) -> void:
	for lamp in headlights:
		lamp.visible = enabled

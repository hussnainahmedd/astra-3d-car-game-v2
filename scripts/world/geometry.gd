class_name Geometry
extends RefCounted
## Shared procedural meshes/materials. World scenery is instanced by material.

static var materials: Dictionary = {}
static var meshes: Dictionary = {}
static var grain: ImageTexture

static func material(color: Color, emission: float = 0.0) -> StandardMaterial3D:
	var key = str(color) + ":" + str(emission)
	if materials.has(key):
		return materials[key]
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	if color.to_html(false) in ["394447", "a7ac9c", "64716e", "989d8e", "8f9986", "d1cabb", "a36650", "a66d54", "b5b5a2"]:
		mat.albedo_texture = _grain_texture()
		mat.uv1_triplanar = true
		mat.uv1_world_triplanar = true
		mat.uv1_scale = Vector3.ONE * 0.55
	if emission > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = emission
	materials[key] = mat
	return mat

static func mesh(kind: String, color: Color, emission: float = 0.0) -> Mesh:
	var key = kind + str(color) + str(emission)
	if meshes.has(key):
		return meshes[key]
	if kind == "bevel":
		var rounded = _beveled_box()
		rounded.surface_set_material(0, material(color, emission))
		meshes[key] = rounded
		return rounded
	var m: PrimitiveMesh
	match kind:
		"cylinder":
			var c = CylinderMesh.new()
			c.top_radius = 0.5
			c.bottom_radius = 0.5
			c.height = 1.0
			c.radial_segments = 12
			m = c
		"cone":
			var c = CylinderMesh.new()
			c.top_radius = 0.08
			c.bottom_radius = 0.5
			c.height = 1.0
			c.radial_segments = 10
			m = c
		"sphere":
			var s = SphereMesh.new()
			s.radius = 0.5
			s.height = 1.0
			s.radial_segments = 12
			s.rings = 6
			m = s
		_:
			var b = BoxMesh.new()
			b.size = Vector3.ONE
			m = b
	m.material = material(color, emission)
	meshes[key] = m
	return m

static func _grain_texture() -> ImageTexture:
	if grain:
		return grain
	var image = Image.create(64, 64, false, Image.FORMAT_RGB8)
	var rng = RandomNumberGenerator.new()
	rng.seed = 438
	for y in 64:
		for x in 64:
			var value = rng.randf_range(0.81, 1.0)
			image.set_pixel(x, y, Color(value, value, value))
	image.generate_mipmaps()
	grain = ImageTexture.create_from_image(image)
	return grain

static func _beveled_box() -> ArrayMesh:
	var tool = SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a = 0.455
	for axis in 3:
		for sign_value in [-1.0, 1.0]:
			var normal = Vector3.ZERO
			normal[axis] = sign_value
			var vertices: Array[Vector3] = []
			for uv in [Vector2(-a, -a), Vector2(a, -a), Vector2(a, a), Vector2(-a, a)]:
				var point = normal * 0.5
				point[(axis + 1) % 3] = uv.x
				point[(axis + 2) % 3] = uv.y
				vertices.append(point)
			_face(tool, vertices, normal)
	for axis_a in 3:
		for axis_b in range(axis_a + 1, 3):
			var axis_c = 3 - axis_a - axis_b
			for sa in [-1.0, 1.0]:
				for sb in [-1.0, 1.0]:
					var normal = Vector3.ZERO
					normal[axis_a] = sa
					normal[axis_b] = sb
					var vertices: Array[Vector3] = []
					for pair in [Vector2(0.5, -a), Vector2(a, -a), Vector2(a, a), Vector2(0.5, a)]:
						var point = Vector3.ZERO
						point[axis_a] = sa * pair.x
						point[axis_b] = sb * (a if pair.x == 0.5 else 0.5)
						point[axis_c] = pair.y
						vertices.append(point)
					_face(tool, vertices, normal.normalized())
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				_face(tool, [Vector3(sx * 0.5, sy * a, sz * a), Vector3(sx * a, sy * 0.5, sz * a), Vector3(sx * a, sy * a, sz * 0.5)], Vector3(sx, sy, sz).normalized())
	# Indexed geometry can be safely merged with Godot's indexed primitive meshes.
	tool.index()
	return tool.commit()

static func _face(tool: SurfaceTool, points: Array, normal: Vector3) -> void:
	if (points[1] - points[0]).cross(points[2] - points[0]).dot(normal) > 0:
		points.reverse()
	for i in range(1, points.size() - 1):
		for index in [0, i, i + 1]:
			tool.set_normal(normal)
			tool.set_uv(Vector2(points[index].x, points[index].y))
			tool.add_vertex(points[index])

static func part(parent: Node3D, kind: String, at: Vector3, size: Vector3, color: Color, rotation_y: float = 0.0, emission: float = 0.0) -> MeshInstance3D:
	var instance = MeshInstance3D.new()
	instance.mesh = mesh(kind, color, emission)
	instance.position = at
	instance.scale = size
	instance.rotation.y = rotation_y
	parent.add_child(instance)
	return instance

static func box(parent: Node3D, at: Vector3, size: Vector3, color: Color, rotation_y: float = 0.0) -> MeshInstance3D:
	return part(parent, "box", at, size, color, rotation_y)

static func collider(parent: CollisionObject3D, at: Vector3, size: Vector3) -> CollisionShape3D:
	var node = CollisionShape3D.new()
	var shape = BoxShape3D.new()
	shape.size = size
	node.shape = shape
	node.position = at
	parent.add_child(node)
	return node

static func text(parent: Node3D, words: String, at: Vector3, font_size: int = 56, pixel_size: float = 0.012, color: Color = Color("ede9d9"), rotation_y: float = 0.0) -> Label3D:
	var label = Label3D.new()
	label.text = words
	label.font_size = font_size
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 0
	label.position = at
	label.rotation.y = rotation_y
	label.no_depth_test = false
	parent.add_child(label)
	return label

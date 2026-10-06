class_name SceneryBatch
extends RefCounted

var groups: Dictionary = {}
var parent: Node3D
var collision: StaticBody3D

func _init(root: Node3D) -> void:
	parent = root
	collision = StaticBody3D.new()
	collision.name = "SceneryCollision"
	collision.collision_layer = 1
	collision.collision_mask = 0
	parent.add_child(collision)

func add(kind: String, at: Vector3, size: Vector3, color: Color, yaw: float = 0.0, solid: bool = false, emission: float = 0.0) -> void:
	var key = kind + str(color) + str(emission)
	if not groups.has(key):
		groups[key] = {"mesh": Geometry.mesh(kind, color, emission), "color": color, "emission": emission, "transforms": []}
	var basis = Basis(Vector3.UP, yaw) * Basis.from_scale(size)
	groups[key].transforms.append(Transform3D(basis, at))
	if solid:
		var c = Geometry.collider(collision, at, size)
		c.rotation.y = yaw

func box(at: Vector3, size: Vector3, color: Color, solid: bool = false, yaw: float = 0.0) -> void:
	add("box", at, size, color, yaw, solid)

func finish() -> void:
	# Bake opaque scenery into a vertex-colored mesh. This is substantially faster
	# on VMware's virtual driver than a draw call for every primitive/material pair.
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var colors = PackedColorArray()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()
	for key in groups:
		var group = groups[key]
		if group.emission <= 0:
			var arrays = group.mesh.surface_get_arrays(0)
			var source_vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var source_normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
			var source_indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			for transform in group.transforms:
				var base = vertices.size()
				var normal_basis: Basis = transform.basis.inverse().transposed()
				for i in source_vertices.size():
					vertices.append(transform * source_vertices[i])
					normals.append((normal_basis * source_normals[i]).normalized())
					colors.append(group.color)
					uvs.append(Vector2.ZERO)
				for index in source_indices:
					indices.append(base + index)
			continue
		var batch = MultiMesh.new()
		batch.transform_format = MultiMesh.TRANSFORM_3D
		batch.mesh = group.mesh
		batch.instance_count = group.transforms.size()
		for i in group.transforms.size():
			batch.set_instance_transform(i, group.transforms[i])
		var node = MultiMeshInstance3D.new()
		node.multimesh = batch
		parent.add_child(node)
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var combined = ArrayMesh.new()
	combined.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material = StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.87
	material.albedo_texture = Geometry._grain_texture()
	material.uv1_triplanar = true
	material.uv1_world_triplanar = true
	material.uv1_scale = Vector3.ONE * 0.55
	combined.surface_set_material(0, material)
	var scenery = MeshInstance3D.new()
	scenery.name = "BakedDistrict"
	scenery.mesh = combined
	parent.add_child(scenery)
	groups.clear()

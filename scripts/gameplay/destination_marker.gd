class_name DestinationMarker
extends Node3D

var missions: DeliveryManager
var halo: MeshInstance3D
var diamond: MeshInstance3D
var label: Label3D
var time: float = 0

func _ready() -> void:
	# Godot 4.3's dummy renderer cannot update Label3D meshes reliably at accelerated
	# test speed. The headless physics suite does not need presentation geometry.
	if DisplayServer.get_name() == "headless":
		set_process(false)
		return
	var material = StandardMaterial3D.new()
	material.albedo_color = Color("e4b16c")
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var mesh = TorusMesh.new()
	mesh.inner_radius = 6.15
	mesh.outer_radius = 6.35
	mesh.rings = 32
	mesh.ring_segments = 6
	mesh.material = material
	halo = MeshInstance3D.new()
	halo.mesh = mesh
	halo.position.y = 0.27
	add_child(halo)
	diamond = Geometry.box(self, Vector3(0, 7, 0), Vector3(0.8, 0.8, 0.8), Color("e6bc7a"))
	diamond.material_override = material
	label = Geometry.text(self, "", Vector3(0, 8.7, 0), 46, 0.012, Color("f4deb3"))
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 8
	label.outline_modulate = Color("234347")

func _process(delta: float) -> void:
	time += delta
	visible = missions.has_navigation_target()
	if not visible:
		return
	global_position = missions.target_position()
	diamond.rotation = Vector3(PI / 4, time * 0.4, PI / 4)
	diamond.position.y = 7 + sin(time * 2) * 0.3
	label.text = "%s\n%d m" % ["COAST SERVICE" if missions.service_waypoint else missions.district.places[missions.target_index()].short, int(missions.navigation_distance())]

class_name HarborDistrict
extends Node3D
## Deliberately composed 360 x 400 m district, with a nine-node road network.

const ROAD_X = [-120.0, 0.0, 120.0]
const ROAD_Z = [-150.0, 0.0, 150.0]
const ASPHALT = Color("394447")
const STONE = Color("a7ac9c")
const LINE = Color("d4d6bd")
const GRASS = Color("738579")
const TEAL = Color("326d6c")
const SPAWN = Vector3(-100, 0, 119)
const FUEL_POINT = Vector3(-141, 0, 26)

var places: Array[Dictionary] = [
	{"name": "Harborline Depot", "short": "DEPOT", "position": SPAWN, "color": Color("75bfb1"), "cargo": "Dispatch parcels"},
	{"name": "Foundry Market", "short": "MARKET", "position": Vector3(-29, 0, -18), "color": Color("e2b36f"), "cargo": "Fresh produce"},
	{"name": "Pier 04 • Freight", "short": "PIER 04", "position": Vector3(140, 0, 94), "color": Color("84bbc7"), "cargo": "Marine supplies"},
	{"name": "Northline Works", "short": "WORKS", "position": Vector3(-100, 0, -110), "color": Color("dba278"), "cargo": "Workshop parts"},
	{"name": "Tide & Timber Café", "short": "CAFÉ", "position": Vector3(31, 0, 132), "color": Color("bdc786"), "cargo": "Coffee & provisions"},
	{"name": "Eastbank Clinic", "short": "CLINIC", "position": Vector3(99, 0, -117), "color": Color("8ab5b3"), "cargo": "Medical supplies"}
]
var batch: SceneryBatch
var sun: DirectionalLight3D
var environment: Environment
var sky_material: ProceduralSkyMaterial
var street_lights: Array[OmniLight3D] = []
var signal_lamps: Array[MeshInstance3D] = []
var clock_hours: float = 16.3
var traffic_time: float = 0.0
var night: bool = false
var quality: int = 0
var sun_strength: float = 0.65
var ambient_strength: float = 0.42
var _light_tick: float = 0.0
var simulating: bool = false

func _ready() -> void:
	_setup_lighting()
	batch = SceneryBatch.new(self)
	_build_ground()
	_build_roads()
	_build_blocks()
	_build_waterfront()
	_build_details()
	batch.finish()
	_update_lighting()

func _setup_lighting() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky = Sky.new()
	sky_material = ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("638d9d")
	sky_material.sky_horizon_color = Color("d6d8bc")
	sky_material.ground_bottom_color = Color("677d75")
	sky_material.ground_horizon_color = Color("c0c6ae")
	sky_material.sky_curve = 0.18
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("b5cbd2")
	environment.ambient_light_energy = 0.65
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.fog_enabled = true
	environment.fog_light_color = Color("aabbb7")
	environment.fog_density = 0.0018
	environment.fog_sky_affect = 0.3
	var world_environment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-36, -32, 0)
	sun.light_color = Color("ffe2b0")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 90
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	sun.directional_shadow_blend_splits = true
	sun.shadow_bias = 0.04
	add_child(sun)

func _build_ground() -> void:
	batch.box(Vector3(-35, -0.7, 0), Vector3(430, 1.4, 435), GRASS, true)
	batch.box(Vector3(-15, -0.03, 0), Vector3(315, 0.08, 345), Color("8f9986"))
	# Low distant hill silhouettes rather than a hard horizon or empty void.
	for i in 12:
		var x = -410.0 + i * 63
		var height = 65.0 + sin(i * 1.9) * 26
		batch.add("sphere", Vector3(x, 3, -345 - absf(sin(i * 2.0)) * 85), Vector3(210, height * 2, 190), Color("657f78"))
	for i in 7:
		batch.add("sphere", Vector3(-340, 3, -180 + i * 90), Vector3(240, 95 + i * 9, 165), Color("60796a"))
	# Physical district edges are fenced, with taller invisible safety only over the sea.
	for z in [-204.0, 204.0]:
		batch.box(Vector3(-28, 0.6, z), Vector3(350, 1.2, 0.45), Color("8a948b"), true)
	batch.box(Vector3(-207, 0.6, 0), Vector3(0.45, 1.2, 408), Color("8a948b"), true)
	batch.box(Vector3(178, 0.58, 0), Vector3(0.8, 1.16, 408), Color("abb0a0"), true)
	Geometry.collider(batch.collision, Vector3(184, 7, 0), Vector3(4, 14, 420))

func _build_roads() -> void:
	for x in ROAD_X:
		batch.box(Vector3(x, 0.018, 0), Vector3(14, 0.04, 314), ASPHALT)
		for side in [-1.0, 1.0]:
			batch.box(Vector3(x + side * 8.3, 0.095, 0), Vector3(2.6, 0.18, 314), STONE)
			for z in range(-144, 148, 6):
				if absf(z) > 13 and absf(z) < 137:
					batch.box(Vector3(x + side * 6.35, 0.045, z), Vector3(0.12, 0.012, 5.9), LINE)
		for z in range(-135, 139, 9):
			if absf(z) > 14:
				batch.box(Vector3(x, 0.05, z), Vector3(0.13, 0.014, 4.3), Color("c6ba8b"))
	for z in ROAD_Z:
		batch.box(Vector3(0, 0.027, z), Vector3(254, 0.04, 14), ASPHALT)
		for side in [-1.0, 1.0]:
			batch.box(Vector3(0, 0.10, z + side * 8.3), Vector3(254, 0.18, 2.6), STONE)
			for x in range(-114, 118, 6):
				if absf(x) > 13 and absf(x) < 106:
					batch.box(Vector3(x, 0.055, z + side * 6.35), Vector3(5.9, 0.012, 0.12), LINE)
		for x in range(-105, 108, 9):
			if absf(x) > 14:
				batch.box(Vector3(x, 0.057, z), Vector3(4.3, 0.012, 0.13), Color("c6ba8b"))
	# Intersections overwrite pavements; crosswalks and stop bars make the road hierarchy readable.
	for x in ROAD_X:
		for z in ROAD_Z:
			batch.box(Vector3(x, 0.20, z), Vector3(19.2, 0.04, 19.2), ASPHALT)
			for s in [-1.0, 1.0]:
				for n in range(-4, 5):
					batch.box(Vector3(x + n * 1.28, 0.233, z + s * 11.3), Vector3(0.67, 0.012, 2.2), LINE)
					batch.box(Vector3(x + s * 11.3, 0.233, z + n * 1.28), Vector3(2.2, 0.012, 0.67), LINE)
				batch.box(Vector3(x + s * 3.5, 0.07, z + s * 14.1), Vector3(5.8, 0.014, 0.32), LINE)
			if z == 0:
				_signal(Vector3(x - 8.7, 0, 8.7))
				_signal(Vector3(x + 8.7, 0, -8.7))
	# Driveways are flush and wide enough for the van: no impassable curbs.
	_driveway(Vector3(-104, 0.12, 119), Vector3(31, 0.10, 28))
	_driveway(Vector3(-100, 0.12, -110), Vector3(31, 0.10, 27))
	_driveway(Vector3(-29, 0.12, -14), Vector3(21, 0.10, 23))
	_driveway(Vector3(139, 0.12, 94), Vector3(34, 0.10, 27))
	_driveway(Vector3(31, 0.12, 135), Vector3(25, 0.10, 24))
	_driveway(Vector3(103, 0.12, -117), Vector3(32, 0.10, 27))
	_driveway(Vector3(-141, 0.12, 26), Vector3(37, 0.10, 34))
	for place in places:
		_loading_bay(place.position, place.color)
	_loading_bay(FUEL_POINT, Color("d6a65e"))

func _driveway(at: Vector3, size: Vector3) -> void:
	batch.box(at, size, Color("64716e"))

func _loading_bay(at: Vector3, color: Color) -> void:
	for side in [-1.0, 1.0]:
		batch.box(at + Vector3(side * 3.8, 0.183, 0), Vector3(0.18, 0.025, 10), color)
		batch.box(at + Vector3(0, 0.183, side * 5), Vector3(7.6, 0.025, 0.18), color)
	for i in 5:
		batch.box(at + Vector3(-2.8 + i * 1.4, 0.19, -4.5), Vector3(0.48, 0.015, 0.75), color, false, -0.4)

func _build_blocks() -> void:
	# Southwest logistics yard / depot, opening directly onto Dock Road.
	_building(Vector3(-77, 0, 117), Vector3(24, 7.5, 31), Color("d1cabb"), "", false)
	batch.box(Vector3(-89.1, 2.4, 116), Vector3(0.05, 4.6, 6), Color("697b78"))
	for i in 9:
		batch.box(Vector3(-89.16, 0.5 + i * 0.48, 116), Vector3(0.04, 0.035, 5.9), Color("9ea8a0"))
	batch.box(Vector3(-89.5, 5.45, 116), Vector3(0.8, 0.2, 9), TEAL)
	Geometry.text(self, "HARBORLINE\nD I S P A T C H", Vector3(-89.15, 6.35, 117), 60, 0.009, Color("285554"), -PI / 2)
	for i in 3:
		_crates(Vector3(-94, 0.2, 130 + i * 2.2))
	_building(Vector3(-49, 0, 81), Vector3(28, 11, 28), Color("bca58c"), "PORT AUTHORITY", true)
	_building(Vector3(-77, 0, 35), Vector3(43, 8, 27), Color("a66d54"), "COASTAL STORAGE", false)
	_building(Vector3(-31, 0, 33), Vector3(19, 13, 26), Color("bdbcb1"), "", true)
	_park(Vector3(-38, 0, 115), Vector2(24, 26))
	# Northwest: converted foundry market and the repair works.
	_building(Vector3(-35, 0, -44), Vector3(41, 8.5, 29), Color("a36650"), "FOUNDRY  /  MARKET", true)
	batch.box(Vector3(-35, 3.3, -28.4), Vector3(42, 0.2, 3.1), Color("346f68"))
	for i in 5:
		batch.box(Vector3(-52 + i * 8.5, 1.8, -27.1), Vector3(0.14, 3.6, 0.14), Color("475a53"))
	_building(Vector3(-77, 0, -110), Vector3(25, 8, 40), Color("b5b5a2"), "NORTHLINE WORKS", false)
	batch.box(Vector3(-89.6, 2.2, -110), Vector3(0.03, 4.1, 8), Color("516966"))
	Geometry.text(self, "NORTHLINE\nWORKS", Vector3(-89.7, 6.3, -110), 56, 0.010, Color("2b5557"), -PI / 2)
	_building(Vector3(-36, 0, -113), Vector3(29, 16, 36), Color("b2a893"), "", true)
	_park(Vector3(-86, 0, -48), Vector2(26, 36))
	# Southeast: café, row houses and a small green square.
	_building(Vector3(33, 0, 112), Vector3(27, 6.5, 19), Color("d5c4a4"), "TIDE & TIMBER", true)
	batch.box(Vector3(33, 3.2, 122.6), Vector3(29, 0.25, 3.2), TEAL)
	for p in [Vector3(18, 0, 130), Vector3(48, 0, 130)]:
		batch.add("cylinder", p + Vector3.UP * 0.8, Vector3(1.6, 0.12, 1.6), Color("9b7350"))
		batch.add("cylinder", p + Vector3.UP * 0.4, Vector3(0.16, 0.8, 0.16), Color("454f45"))
	_building(Vector3(91, 0, 111), Vector3(26, 10.5, 30), Color("b7977a"), "EASTBANK APARTMENTS", true)
	for i in 3:
		_building(Vector3(30 + i * 27, 0, 31), Vector3(22, 10 + i * 2, 26), [Color("c3bba5"), Color("b48b72"), Color("96a5a0")][i], "", true)
	_park(Vector3(55, 0, 73), Vector2(65, 34))
	# Northeast: clinic and civic buildings.
	_building(Vector3(88, 0, -94), Vector3(39, 11, 23), Color("c6d0c0"), "EASTBANK  +  CLINIC", true)
	Geometry.text(self, "EASTBANK +", Vector3(88, 5.8, -105.6), 60, 0.010, Color("387579"), PI)
	_building(Vector3(34, 0, -113), Vector3(25, 15, 36), Color("bdaf96"), "", true)
	_building(Vector3(89, 0, -36), Vector3(29, 9, 27), Color("b69c84"), "MARITIME SUPPLY", true)
	_building(Vector3(35, 0, -35), Vector3(29, 11, 28), Color("aaa999"), "DOCKSIDE STUDIOS", true)
	_park(Vector3(53, 0, -72), Vector2(55, 20))
	_build_service_station()

func _building(at: Vector3, size: Vector3, color: Color, sign_text: String, windows: bool) -> void:
	batch.box(at + Vector3.UP * size.y * 0.5, size, color, true)
	batch.box(at + Vector3.UP * 0.38, Vector3(size.x + 0.25, 0.75, size.z + 0.25), Color("68756e"))
	batch.box(at + Vector3.UP * (size.y + 0.12), Vector3(size.x + 0.65, 0.24, size.z + 0.65), Color("717c73"))
	batch.box(at + Vector3.UP * (size.y + 0.3), Vector3(size.x - 0.65, 0.18, size.z - 0.65), Color("8c978a"))
	batch.box(at + Vector3(2, size.y + 0.9, 2), Vector3(3.5, 1.25, 2.5), Color("9a9f90"))
	var front_z = at.z + size.z * 0.5 + 0.035
	var glass = Color("35505a")
	if windows:
		for floor_index in range(1, int(size.y / 3.3) + 1):
			var y = floor_index * 3.05 - 0.4
			if y + 1 > size.y:
				continue
			for i in range(int(size.x / 5)):
				var x = at.x - size.x / 2 + 2.6 + i * 5
				batch.box(Vector3(x, y, front_z), Vector3(2.3, 1.65, 0.04), glass)
				batch.box(Vector3(x, y - 0.89, front_z + 0.09), Vector3(2.5, 0.12, 0.2), STONE)
				batch.box(Vector3(x, y, front_z + 0.04), Vector3(0.07, 1.65, 0.06), Color("92a49c"))
			for i in range(int(size.z / 5)):
				var z = at.z - size.z / 2 + 2.6 + i * 5
				for side in [-1.0, 1.0]:
					batch.box(Vector3(at.x + side * (size.x / 2 + 0.035), y, z), Vector3(0.04, 1.65, 2.3), glass)
	else:
		for i in range(int(size.x / 4)):
			batch.box(Vector3(at.x - size.x / 2 + 2 + i * 4, size.y - 1.7, front_z), Vector3(2.6, 1.3, 0.04), glass)
	batch.box(Vector3(at.x, 1.4, front_z + 0.012), Vector3(1.8, 2.8, 0.05), Color("355553"))
	if not sign_text.is_empty():
		batch.box(Vector3(at.x, 4.7, front_z + 0.035), Vector3(minf(size.x - 1, 23), 1.1, 0.12), TEAL)
		Geometry.text(self, sign_text, Vector3(at.x, 4.72, front_z + 0.11), 58, 0.008)

func _park(at: Vector3, size: Vector2) -> void:
	batch.box(at + Vector3.UP * 0.06, Vector3(size.x, 0.1, size.y), Color("789079"))
	batch.box(at + Vector3.UP * 0.12, Vector3(size.x, 0.04, 2.1), Color("b6b69e"))
	for side in [-1.0, 1.0]:
		_tree(at + Vector3(side * size.x * 0.32, 0, -size.y * 0.24), 1.0)
		_tree(at + Vector3(side * size.x * 0.31, 0, size.y * 0.29), 0.9)
		_bench(at + Vector3(side * 4.5, 0, 2.8))

func _tree(at: Vector3, size: float = 1.0) -> void:
	batch.add("cylinder", at + Vector3.UP * 2.0 * size, Vector3(0.4, 4, 0.4) * size, Color("75644d"), 0, true)
	batch.add("sphere", at + Vector3(0, 4.8, 0) * size, Vector3(4.3, 5.0, 4.2) * size, Color("426d57"))
	batch.add("sphere", at + Vector3(1.1, 5.6, 0.4) * size, Vector3(3.2, 3.4, 3.2) * size, Color("557c59"))

func _bench(at: Vector3) -> void:
	batch.box(at + Vector3(0, 0.6, 0), Vector3(2.8, 0.12, 0.65), Color("97754e"))
	batch.box(at + Vector3(0, 1.03, 0.3), Vector3(2.8, 0.6, 0.10), Color("97754e"))
	for side in [-1, 1]:
		batch.box(at + Vector3(side * 1.03, 0.3, 0), Vector3(0.10, 0.6, 0.55), Color("465655"))

func _crates(at: Vector3) -> void:
	batch.box(at + Vector3.UP * 0.55, Vector3(1.7, 1.1, 1.5), Color("b69563"), true)
	for side in [-1.0, 1.0]:
		batch.box(at + Vector3(side * 0.57, 0.6, 0.76), Vector3(0.13, 1.1, 0.025), Color("766548"))

func _build_service_station() -> void:
	_building(Vector3(-153, 0, 53), Vector3(25, 5.7, 17), Color("b4baa8"), "COAST  /  SERVICE", false)
	batch.box(Vector3(-143, 4.8, 24), Vector3(23, 0.4, 18), Color("cfbd94"))
	batch.box(Vector3(-143, 4.54, 24), Vector3(23, 0.12, 18), TEAL)
	for x in [-152, -134]:
		batch.box(Vector3(x, 2.3, 18), Vector3(0.28, 4.6, 0.28), Color("748981"), true)
	for z in [20, 30]:
		batch.box(Vector3(-148, 0.95, z), Vector3(1.0, 1.9, 0.8), Color("bdc2ac"), true)
		batch.box(Vector3(-147.48, 1.32, z), Vector3(0.03, 0.43, 0.57), Color("244448"))
		batch.box(Vector3(-148, 0.34, z), Vector3(1.2, 0.28, 1.1), TEAL)
	Geometry.text(self, "FUEL  +  REPAIR", Vector3(-143, 4.82, 33.08), 54, 0.008)

func _build_waterfront() -> void:
	if DisplayServer.get_name() != "headless":
		_build_water_surface()
	_build_quay()

func _build_water_surface() -> void:
	var water = MeshInstance3D.new()
	var plane = PlaneMesh.new()
	plane.size = Vector2(1700, 1900)
	water.mesh = plane
	water.position = Vector3(1000, -0.8, 0)
	var mat = ShaderMaterial.new()
	mat.shader = load("res://assets/water.gdshader")
	water.material_override = mat
	add_child(water)

func _build_quay() -> void:
	batch.box(Vector3(151, 0.04, 0), Vector3(51, 0.08, 370), Color("989d8e"))
	for z in range(-185, 194, 8):
		batch.box(Vector3(173, 0.62, z), Vector3(0.2, 1.2, 0.2), Color("4c6865"), true)
	batch.box(Vector3(173, 1.1, 0), Vector3(0.10, 0.1, 380), Color("52716c"))
	batch.box(Vector3(173, 0.64, 0), Vector3(0.10, 0.08, 380), Color("52716c"))
	for i in 5:
		var z = -126.0 + i * 27
		var color = [Color("507e7a"), Color("a05f44"), Color("9c9d7c")][i % 3]
		batch.box(Vector3(151, 1.55, z), Vector3(11.5, 3.1, 5), color, true)
		for n in 14:
			batch.box(Vector3(145.21, 1.6, z - 2.2 + n * 0.34), Vector3(0.05, 2.85, 0.07), color.lightened(0.11))
		if i % 2 == 0:
			batch.box(Vector3(151, 4.65, z), Vector3(11.5, 3.1, 5), Color("bd9a68"), true)
	# Small cargo vessel and a dockside gantry form a memorable landmark.
	batch.box(Vector3(198, 1.0, -55), Vector3(17, 4, 78), Color("385657"))
	batch.box(Vector3(198, 3.2, -55), Vector3(16.5, 0.4, 76), Color("b1a98d"))
	batch.box(Vector3(198, 6.0, -26), Vector3(12, 5.5, 15), Color("bfc7b8"))
	batch.box(Vector3(198, 9.2, -26), Vector3(12, 1.4, 14), Color("405e66"))
	for i in 3:
		batch.box(Vector3(198, 5, -76 + i * 14), Vector3(10, 3.6, 11), Color("99774e"))
	for z in [-44, -22]:
		for x in [142, 164]:
			batch.box(Vector3(x, 12, z), Vector3(0.85, 24, 0.85), Color("bc965b"), true)
		batch.box(Vector3(165, 24, z), Vector3(49, 1.2, 1.2), Color("bc965b"))
		batch.box(Vector3(163, 25.3, z), Vector3(47, 0.13, 0.14), Color("a9804d"))
	batch.box(Vector3(185, 17.5, -33), Vector3(0.10, 13, 0.10), Color("555b50"))
	batch.box(Vector3(185, 11, -33), Vector3(3, 0.6, 5), Color("8b764e"))
	_building(Vector3(153, 0, 127), Vector3(25, 7.5, 25), Color("b9b7a1"), "PIER 04", false)
	Geometry.text(self, "04", Vector3(140.43, 5.0, 127), 100, 0.038, Color("326b6b"), -PI / 2)
	for z in [110, 112.5, 115]:
		_crates(Vector3(137, 0.2, z))

func _build_details() -> void:
	for x in [-130.5, 10.5, 130.5]:
		for z in [-132, -77, -22, 37, 95, 140]:
			_lamp(Vector3(x, 0, z), x < 0)
	for x in [-173, -158, -186]:
		for z in [-158, -100, -38, 85, 138, 172]:
			_tree(Vector3(x, 0, z), 0.95 + absf(sin(z * 0.3)) * 0.4)
	for x in [-93, -65, -34, 29, 67, 99]:
		_tree(Vector3(x, 0, -177), 1.1)
		_tree(Vector3(x, 0, 176), 1.0)
	# Curated street furniture and signs, kept clear of road and loading lanes.
	for x in [-108, 12, 108]:
		batch.add("cylinder", Vector3(x, 1.3, 13), Vector3(0.1, 2.6, 0.1), Color("758782"))
		batch.box(Vector3(x, 2.4, 13), Vector3(3.5, 0.7, 0.10), TEAL)
		Geometry.text(self, "DOCK STREET", Vector3(x, 2.4, 13.06), 40, 0.008)
	for p in [Vector3(-110, 0, 76), Vector3(110, 0, 51), Vector3(10, 0, -59)]:
		batch.add("cylinder", p + Vector3.UP * 1.5, Vector3(0.085, 3, 0.085), Color("7c8c85"))
		batch.box(p + Vector3.UP * 2.75, Vector3(0.9, 1.05, 0.08), Color("d9d8bc"))
		Geometry.text(self, "40", p + Vector3(0, 2.8, 0.06), 66, 0.010, Color("35504f"))
	for p in [Vector3(-55, 0, -22), Vector3(21, 0, 122), Vector3(161, 0, 69)]:
		batch.add("cylinder", p + Vector3.UP * 0.55, Vector3(0.75, 1.1, 0.75), TEAL, 0, true)
	for p in [Vector3(-104, 0, 140), Vector3(-104, 0, 98), Vector3(132, 0, 105), Vector3(148, 0, 105)]:
		batch.add("cylinder", p + Vector3.UP * 0.52, Vector3(0.22, 1.04, 0.22), Color("caab66"), 0, true)
	# Parked cars have real simple colliders; driveways remain clear.
	for data in [[Vector3(-109, 0.72, 56), 0.0, Color("a2937a")], [Vector3(109, 0.72, -61), PI, Color("53766f")], [Vector3(71, 0.72, 138), PI / 2, Color("996956")]]:
		var parked = VehicleVisual.new()
		parked.position = data[0]
		parked.rotation.y = data[1]
		add_child(parked)
		parked.build(false, data[2])
		var shape = Geometry.collider(batch.collision, data[0] + Vector3.UP * 0.2, Vector3(1.92, 1.35, 4.25))
		shape.rotation.y = data[1]

func _lamp(at: Vector3, facing_east: bool) -> void:
	var side = 1 if facing_east else -1
	batch.add("cylinder", at + Vector3.UP * 3.8, Vector3(0.14, 7.6, 0.14), Color("4d6462"), 0, true)
	batch.box(at + Vector3(side * 0.75, 7.5, 0), Vector3(1.65, 0.12, 0.12), Color("4d6462"))
	batch.add("box", at + Vector3(side * 1.45, 7.42, 0), Vector3(0.7, 0.12, 0.36), Color("f3d19a"), 0, false, 0.7)
	var light = OmniLight3D.new()
	light.position = at + Vector3(side * 1.4, 6.7, 0)
	light.light_color = Color("ffd394")
	light.omni_range = 19
	light.light_energy = 1.3
	light.shadow_enabled = false
	light.visible = false
	add_child(light)
	street_lights.append(light)

func _signal(at: Vector3) -> void:
	batch.add("cylinder", at + Vector3.UP * 2.0, Vector3(0.12, 4.0, 0.12), Color("4d6462"))
	batch.box(at + Vector3.UP * 3.65, Vector3(0.5, 1.3, 0.4), Color("243d3e"))
	var lamp = Geometry.part(self, "sphere", at + Vector3(0, 3.7, 0), Vector3(0.27, 0.27, 0.44), Color("95bd7c"), 0, 0.5)
	signal_lamps.append(lamp)

func _process(delta: float) -> void:
	if not simulating:
		return
	clock_hours = fmod(clock_hours + delta / 240.0, 24.0)
	traffic_time += delta
	_light_tick += delta
	if _light_tick > 0.5:
		_light_tick = 0
		_update_lighting()

func vertical_green() -> bool:
	return fmod(traffic_time, 24.0) < 17.0

func _update_lighting() -> void:
	night = clock_hours >= 19.7 or clock_hours < 6.0
	var daylight = 0.10 if night else clampf(1.0 - (clock_hours - 17.0) / 3.0, 0.18, 1.0)
	sun.light_energy = sun_strength * daylight
	sun.rotation_degrees.x = -32 if night else -maxf(9, 56 - (clock_hours - 12) * 5.1)
	sun.light_color = Color("abc9eb") if night else Color("ffe1ac")
	environment.ambient_light_energy = 0.23 if night else ambient_strength
	environment.ambient_light_color = Color("7b9aaa") if night else Color("b4cbd0")
	sky_material.sky_top_color = Color("142b42") if night else Color("6392a4")
	sky_material.sky_horizon_color = Color("456071") if night else Color("dedcc2")
	environment.fog_light_color = Color("233f4d") if night else Color("aebfba")
	for light in street_lights:
		light.visible = night
	for lamp in signal_lamps:
		lamp.material_override = Geometry.material(Color("8dd099") if vertical_green() else Color("ec8064"), 0.5)

func set_quality(value: int) -> void:
	quality = value
	sun.shadow_enabled = value > 0
	sun.directional_shadow_max_distance = 70 if value == 1 else 110
	get_viewport().msaa_3d = Viewport.MSAA_DISABLED if value < 2 else Viewport.MSAA_2X

func cycle_time() -> void:
	if clock_hours < 15:
		clock_hours = 17.8
	elif clock_hours < 19:
		clock_hours = 21.0
	else:
		clock_hours = 12.5
	_update_lighting()

func set_clock(value: float) -> void:
	clock_hours = wrapf(value, 0, 24)
	_update_lighting()

func nearest_place(pos: Vector3) -> int:
	var best = 0
	var distance = INF
	for i in places.size():
		var d = pos.distance_to(places[i].position)
		if d < distance:
			distance = d
			best = i
	return best

func road_route(from: Vector3, to: Vector3) -> PackedVector3Array:
	# Tiny grid graph with virtual driveway attachment. Manhattan routing is sufficient here.
	var start = _road_projection(from)
	var end = _road_projection(to)
	var nodes: Array[Vector3] = []
	for x in ROAD_X:
		for z in ROAD_Z:
			nodes.append(Vector3(x, 0, z))
	nodes.append(start)
	nodes.append(end)
	var distances: Array[float] = []
	var previous: Array[int] = []
	var visited: Array[bool] = []
	for i in nodes.size():
		distances.append(INF)
		previous.append(-1)
		visited.append(false)
	distances[9] = 0
	for step in nodes.size():
		var current = -1
		for i in nodes.size():
			if not visited[i] and (current == -1 or distances[i] < distances[current]):
				current = i
		if current == -1 or distances[current] == INF:
			break
		visited[current] = true
		for j in nodes.size():
			if visited[j]:
				continue
			var same_street_x = absf(nodes[current].x - nodes[j].x) < 0.1 and nodes[current].x in ROAD_X
			var same_street_z = absf(nodes[current].z - nodes[j].z) < 0.1 and nodes[current].z in ROAD_Z
			if same_street_x or same_street_z or nodes[current].distance_to(nodes[j]) < 0.01:
				var cost = distances[current] + nodes[current].distance_to(nodes[j])
				if cost < distances[j]:
					distances[j] = cost
					previous[j] = current
	var result = PackedVector3Array([to])
	var cursor = 10
	while cursor != -1:
		result.append(nodes[cursor])
		cursor = previous[cursor]
	result.append(from)
	result.reverse()
	return result

func _road_projection(pos: Vector3) -> Vector3:
	var result = Vector3.ZERO
	var best = INF
	for x in ROAD_X:
		var candidate = Vector3(x, 0, clampf(pos.z, -150, 150))
		if candidate.distance_to(pos) < best:
			best = candidate.distance_to(pos)
			result = candidate
	for z in ROAD_Z:
		var candidate = Vector3(clampf(pos.x, -120, 120), 0, z)
		if candidate.distance_to(pos) < best:
			best = candidate.distance_to(pos)
			result = candidate
	return result

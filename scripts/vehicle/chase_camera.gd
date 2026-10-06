class_name DrivingCamera
extends Node3D

var target: DeliveryVehicle
var camera: Camera3D
var mode: int = 0
var sensitivity: float = 1.0
var invert_y: bool = false
var orbit: float = 0.0
var pitch: float = 0.0
var active: bool = false
var _smoothed_heading: float = 0.0
var _focus = Vector3.ZERO
var _initialized: bool = false
var _camera_position = Vector3.ZERO
var _camera_position_ready: bool = false

func _ready() -> void:
	camera = Camera3D.new()
	camera.current = true
	camera.fov = 64
	camera.near = 0.15
	camera.far = 950
	add_child(camera)

func handle_mouse(event: InputEvent) -> void:
	if not active:
		return
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		orbit -= event.relative.x * 0.004 * sensitivity
		pitch = clampf(pitch + event.relative.y * 0.0025 * sensitivity * (-1 if invert_y else 1), -0.2, 0.42)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	if not active:
		camera.global_position = target.global_position + Vector3(-10, 4.8, 11)
		camera.look_at(target.global_position + Vector3(-4.5, 0.8, 0))
		_initialized = false
		_camera_position_ready = false
		return
	var heading = target.global_rotation.y
	if not _initialized:
		_smoothed_heading = heading
		_focus = target.global_position
		_initialized = true
	_smoothed_heading = lerp_angle(_smoothed_heading, heading, 1.0 - exp(-delta * 5.0))
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		orbit = lerp_angle(orbit, 0, 1.0 - exp(-delta * 2.5))
		pitch = lerpf(pitch, 0, 1.0 - exp(-delta * 2.5))
	_focus = _focus.lerp(target.global_position, 1.0 - exp(-delta * 13))
	var forward = Vector3.FORWARD.rotated(Vector3.UP, _smoothed_heading)
	if mode == 2:
		var bonnet_position = target.to_global(Vector3(0, 1.48, -1.82))
		_place_camera(bonnet_position, delta)
		camera.look_at(camera.global_position + Vector3.FORWARD.rotated(Vector3.UP, heading + orbit) * 20 + Vector3(0, -1.2 - pitch * 8, 0))
		camera.fov = 74
		return
	var distance = 9.8 if mode == 0 else 6.4
	var height = 4.2 if mode == 0 else 2.7
	var look_point = _focus + Vector3.UP * 1.15 + forward * 2.0
	var offset = Vector3(0, height + pitch * 8, distance).rotated(Vector3.UP, _smoothed_heading + orbit)
	var desired = _focus + offset
	var ray = PhysicsRayQueryParameters3D.create(look_point, desired, 1)
	ray.exclude = [target.get_rid()]
	var hit = target.get_world_3d().direct_space_state.intersect_ray(ray)
	if not hit.is_empty():
		desired = hit.position + hit.normal * 0.35
	_place_camera(desired, delta)
	camera.look_at(look_point)
	camera.fov = lerpf(camera.fov, 64.0 + target.speed_kph * 0.065, delta * 2)

func _place_camera(desired: Vector3, delta: float) -> void:
	if not _camera_position_ready:
		_camera_position = desired
		_camera_position_ready = true
	else:
		_camera_position = _camera_position.lerp(desired, 1.0 - exp(-delta * 12.0))
	camera.global_position = _camera_position

func cycle() -> void:
	mode = (mode + 1) % 3
	reset()

func reset() -> void:
	orbit = 0
	pitch = 0
	_initialized = false
	_camera_position_ready = false

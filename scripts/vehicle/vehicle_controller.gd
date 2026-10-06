class_name DeliveryVehicle
extends RigidBody3D
## Four raycast springs and load-limited tyre forces on a real rigid body.
## Local -Z is forward; physics is SI units. Input is separate from the solver.

signal impact(severity: float)

const MASS = 1750.0
const WHEELBASE = 2.69
const RADIUS = 0.345
const REST_LENGTH = 0.60
const SPRING_RATE = 34500.0
const DAMPING = 4200.0
const WHEEL_POINTS = [Vector3(-0.95, 0.16, -1.34), Vector3(0.95, 0.16, -1.34), Vector3(-0.95, 0.16, 1.35), Vector3(0.95, 0.16, 1.35)]

var visual: VehicleVisual
var enabled: bool = false
var fuel_available: bool = true
var engine_health: float = 1.0
var cargo_mass: float = 0.0
var throttle: float = 0.0
var brake_input: float = 0.0
var steering: float = 0.0
var handbrake: bool = false
var speed_kph: float = 0.0
var signed_speed: float = 0.0
var grounded_wheels: int = 0
var lights_on: bool = false
var odometer: float = 0.0
var engine_load: float = 0.0
var qa_control: bool = false
var qa_throttle: float = 0.0
var qa_steer: float = 0.0
var qa_brake: float = 0.0
var recovery_transform: Transform3D
var _pending_reset: bool = false
var _previous_velocity = Vector3.ZERO
var _impact_cooldown: float = 0.0
var _reverse_wait: float = 0.0

func _ready() -> void:
	mass = MASS
	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = Vector3(0, -0.30, 0.12)
	inertia = Vector3(3000, 3200, 1000)
	linear_damp = 0.06
	angular_damp = 1.7
	contact_monitor = true
	max_contacts_reported = 6
	continuous_cd = true
	can_sleep = false
	collision_layer = 2
	collision_mask = 1 | 4
	var physics_mat = PhysicsMaterial.new()
	physics_mat.friction = 0.25
	physics_mat.bounce = 0.03
	physics_material_override = physics_mat
	Geometry.collider(self, Vector3(0, 0.43, 0), Vector3(1.90, 1.80, 4.18))
	visual = VehicleVisual.new()
	add_child(visual)
	visual.build(true)
	recovery_transform = transform

func _physics_process(delta: float) -> void:
	var forward = -global_basis.z
	signed_speed = linear_velocity.dot(forward)
	speed_kph = linear_velocity.length() * 3.6
	if enabled:
		odometer += Vector2(linear_velocity.x, linear_velocity.z).length() * delta
	_impact_cooldown = maxf(0, _impact_cooldown - delta)
	var gas = Input.get_action_strength("accelerate") if enabled else 0.0
	var stopping = Input.get_action_strength("brake") if enabled else 0.0
	var turn = Input.get_axis("steer_right", "steer_left") if enabled else 0.0
	handbrake = Input.is_action_pressed("handbrake") or not enabled
	if qa_control:
		gas = clampf(qa_throttle, 0, 1) if enabled else 0.0
		stopping = clampf(qa_brake, 0, 1) if enabled else 0.0
		turn = clampf(qa_steer, -1, 1) if enabled else 0.0
		handbrake = false
	# S stops before engaging reverse. Releasing the key also clears the delay.
	var target_throttle = gas
	brake_input = 0.0
	if stopping > 0:
		target_throttle = 0
		if signed_speed > 0.65:
			brake_input = stopping
			_reverse_wait = 0
		else:
			_reverse_wait += delta
			if _reverse_wait > 0.30:
				target_throttle = -stopping * 0.65
			else:
				brake_input = stopping
	else:
		_reverse_wait = 0
	if gas > 0 and signed_speed < -0.6:
		brake_input = gas
		target_throttle = 0
	if not fuel_available:
		target_throttle = 0
	if absf(throttle) < 0.01 and absf(target_throttle) < 0.01:
		throttle = 0
	throttle = move_toward(throttle, target_throttle, delta * 1.8)
	var max_steer = lerpf(0.52, 0.19, clampf(absf(signed_speed) / 23.0, 0, 1))
	steering = move_toward(steering, turn * max_steer, delta * 1.35)
	engine_load = absf(throttle)
	visual.animate(signed_speed, steering, brake_input > 0.1 or handbrake, delta)
	if global_position.y < -5:
		recover()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if _pending_reset:
		state.transform = recovery_transform
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		_previous_velocity = Vector3.ZERO
		_pending_reset = false
		return
	var body_transform = state.transform
	var up = body_transform.basis.y
	var forward = -body_transform.basis.z
	var right = body_transform.basis.x
	var space = state.get_space_state()
	grounded_wheels = 0
	for i in 4:
		var local_point: Vector3 = WHEEL_POINTS[i]
		var origin = body_transform * local_point
		var query = PhysicsRayQueryParameters3D.create(origin, origin - up * (REST_LENGTH + RADIUS), 1)
		query.exclude = [get_rid()]
		var hit = space.intersect_ray(query)
		if hit.is_empty():
			visual.wheels[i].get_parent().position.y = local_point.y - REST_LENGTH
			continue
		grounded_wheels += 1
		var length = maxf(0.08, origin.distance_to(hit.position) - RADIUS)
		var arm: Vector3 = hit.position - body_transform.origin
		var velocity = state.linear_velocity + state.angular_velocity.cross(arm)
		var compression = REST_LENGTH - length
		var spring_force = clampf(compression * SPRING_RATE - velocity.dot(up) * DAMPING, 0, 19000)
		state.apply_force(up * spring_force, origin - body_transform.origin)
		var tyre_forward = forward.rotated(up, steering if i < 2 else 0.0)
		var tyre_right = right.rotated(up, steering if i < 2 else 0.0)
		var along = velocity.dot(tyre_forward)
		var sideways = velocity.dot(tyre_right)
		var traction = spring_force * (0.99 if not (handbrake and i >= 2) else 0.43)
		# Front and rear lateral tyre forces create natural yaw, rather than rotating the body.
		var lateral = clampf(-sideways * 2800.0, -traction, traction)
		var drive = 0.0
		if i >= 2:
			var torque_falloff = 1.0 - clampf(absf(along) / (28.0 if throttle >= 0 else 8.0), 0, 1)
			drive = throttle * 4100.0 * torque_falloff * engine_health
		var braking = brake_input * 7800.0 + (11500.0 if handbrake and i >= 2 else 0.0)
		var roll = 75.0 + absf(along) * 12.0
		var longitudinal = drive - clampf(along * 1900.0, -braking - roll, braking + roll)
		longitudinal = clampf(longitudinal, -traction, traction)
		# Low application point transfers believable weight while keeping a loaded van stable.
		var tyre_arm = arm + up * 0.13
		state.apply_force(tyre_right * lateral + tyre_forward * longitudinal, tyre_arm)
		visual.wheels[i].get_parent().position.y = local_point.y - length
	state.apply_central_force(-state.linear_velocity * state.linear_velocity.length() * 0.65)
	# Mild anti-roll damping; not an upright lock, collisions still pitch and roll the vehicle.
	if grounded_wheels > 1:
		state.apply_torque(-forward * state.angular_velocity.dot(forward) * 1450.0)
	if state.get_contact_count() > 0 and _impact_cooldown <= 0:
		var loss = (_previous_velocity - state.linear_velocity).length()
		if loss > 1.8:
			impact.emit(loss)
			_impact_cooldown = 0.8
	_previous_velocity = state.linear_velocity

func recover(at: Vector3 = Vector3.INF, yaw: float = 0.0) -> void:
	if at != Vector3.INF:
		recovery_transform = Transform3D(Basis(Vector3.UP, yaw), at + Vector3.UP * 0.94)
	_pending_reset = true
	throttle = 0
	steering = 0
	brake_input = 0
	_reverse_wait = 0
	_impact_cooldown = 1.0

func set_cargo_mass(value: float) -> void:
	cargo_mass = clampf(value, 0, 500)
	mass = MASS + cargo_mass

func toggle_lights() -> void:
	lights_on = not lights_on
	visual.set_headlights(lights_on)

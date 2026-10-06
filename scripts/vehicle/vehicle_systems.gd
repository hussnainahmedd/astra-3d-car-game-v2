class_name VehicleSystems
extends Node

signal message(text: String, positive: bool)
signal collision_sound(severity: float)

var vehicle: DeliveryVehicle
var progress: ProgressStore
var _distance_at_last_tick: float = 0
var _fuel_warning: bool = false
var _condition_warning: bool = false

func _ready() -> void:
	vehicle.impact.connect(_on_impact)
	sync_vehicle()

func sync_vehicle() -> void:
	vehicle.fuel_available = progress.fuel > 0
	# A worn van remains usable; repairs restore power without stranding the player.
	vehicle.engine_health = lerpf(0.60, 1.0, progress.condition / 100.0)

func _physics_process(delta: float) -> void:
	if not vehicle.enabled:
		return
	# A full tank lasts comfortably over half an hour of active play.
	var use = (0.008 + vehicle.engine_load * 0.027 + absf(vehicle.signed_speed) * 0.0007) * delta
	if progress.upgrades.has("efficiency"):
		use *= 0.75
	progress.fuel = maxf(0, progress.fuel - use)
	sync_vehicle()
	progress.total_distance += maxf(0, vehicle.odometer - _distance_at_last_tick)
	_distance_at_last_tick = vehicle.odometer
	if progress.fuel < 15 and not _fuel_warning:
		_fuel_warning = true
		message.emit("Low fuel. Coast Service is west of Dock Street.", false)
	if progress.condition < 35 and not _condition_warning:
		_condition_warning = true
		message.emit("Van needs repairs. Reduced engine power • visit Coast Service.", false)

func _on_impact(severity: float) -> void:
	if not vehicle.enabled:
		return
	var damage = clampf((severity - 1.4) * 1.6, 0.3, 22)
	if progress.upgrades.has("reinforcement"):
		damage *= 0.75
	progress.condition = maxf(0, progress.condition - damage)
	sync_vehicle()
	collision_sound.emit(severity)
	if damage > 3:
		message.emit("Impact  •  Vehicle condition −%d%%" % int(ceil(damage)), false)

func service_cost(kind: String = "full") -> int:
	var fuel_price = (100 - progress.fuel) * 0.85 if kind in ["full", "fuel"] else 0.0
	var repair_price = (100 - progress.condition) * 2.6 if kind in ["full", "repair"] else 0.0
	return int(ceil(maxf(0, fuel_price + repair_price)))

func service(kind: String = "full") -> bool:
	if kind not in ["full", "fuel", "repair"]:
		return false
	var price = service_cost(kind)
	if progress.money < price:
		# A small free emergency top-up prevents a zero-fuel soft lock.
		if progress.fuel < 8:
			progress.fuel = 12
			sync_vehicle()
			message.emit("Emergency top-up: fuel restored to 12%. Try fuel-only service with G.", true)
		else:
			message.emit("Service costs $%d. Press G for fuel-only or repair-only options." % price, false)
		return false
	progress.money -= price
	if kind in ["full", "fuel"]:
		progress.fuel = 100
		_fuel_warning = false
	if kind in ["full", "repair"]:
		progress.condition = 100
		_condition_warning = false
	sync_vehicle()
	message.emit("%s  •  $%d" % [{"full": "Refueled & repaired", "fuel": "Tank filled", "repair": "Van repaired"}[kind], price], true)
	return true

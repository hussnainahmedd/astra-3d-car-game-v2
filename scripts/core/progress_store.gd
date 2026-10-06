class_name ProgressStore
extends RefCounted
## Versioned saves with validation, v1 migration and a last-good backup.

const VERSION = 2
const DEFAULT_SETTINGS = {"quality": 1, "resolution": 0, "fullscreen": false, "master": 0.75, "music": 0.18, "effects": 0.75, "sensitivity": 1.0, "invert_y": false}

var money: int = 650
var fuel: float = 100.0
var condition: float = 100.0
var completed: int = 0
var earnings: int = 0
var total_distance: float = 0
var saved_position = HarborDistrict.SPAWN
var saved_yaw: float = PI / 2
var active_job: Dictionary = {}
var upgrades: Dictionary = {}
var clock_hours: float = 16.3
var settings: Dictionary = DEFAULT_SETTINGS.duplicate()
var test_mode: bool = false
var test_slot: String = "qa_progress"
var last_save_ok: bool = true
var has_progress: bool = false
var load_message: String = ""

func path() -> String:
	return "user://%s.json" % test_slot.get_file().get_basename() if test_mode else "user://progress.json"

static func number(value: Variant, fallback: float, low: float, high: float) -> float:
	if not (value is int or value is float) or not is_finite(float(value)):
		return fallback
	return clampf(float(value), low, high)

func _read_data(filename: String) -> Dictionary:
	if not FileAccess.file_exists(filename):
		return {}
	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null or file.get_length() > 1024 * 1024:
		return {}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {}
	var data: Dictionary = parser.data
	# JSON parses all numbers as floats. Array membership in GDScript is type
	# sensitive, so checking a JSON float against [1, 2] rejects a valid save.
	var version = number(data.get("version"), 0, 0, 1000000)
	if version != floor(version) or int(version) not in [1, VERSION]:
		return {}
	return data

func load_progress() -> void:
	load_message = ""
	var data = _read_data(path())
	if data.is_empty():
		data = _read_data(path() + ".bak")
		if not data.is_empty():
			load_message = "Recovered your last good save from the local backup."
		elif FileAccess.file_exists(path()):
			load_message = "The local save could not be read. A fresh shift is available; the old file is preserved."
			return
		else:
			return
	money = int(number(data.get("money"), 650, 0, 1000000000))
	fuel = number(data.get("fuel"), 100, 0, 100)
	condition = number(data.get("condition"), 100, 0, 100)
	completed = int(number(data.get("completed"), 0, 0, 1000000))
	earnings = int(number(data.get("earnings"), 0, 0, 1000000000))
	total_distance = number(data.get("distance"), 0, 0, 1000000000)
	clock_hours = number(data.get("clock"), 16.3, 0, 23.999)
	var pos = data.get("position", [-100, 0, 119])
	if pos is Array and pos.size() == 3:
		saved_position = Vector3(number(pos[0], -100, -190, 165), 0, number(pos[2], 119, -190, 190))
	saved_yaw = wrapf(number(data.get("yaw"), PI / 2, -1000, 1000), -PI, PI)
	active_job = {}
	upgrades = {}
	if data.get("job", {}) is Dictionary:
		active_job = data.get("job", {}).duplicate(true)
	var owned = data.get("upgrades", {})
	if owned is Dictionary:
		for id in CourierCareer.UPGRADES:
			if owned.get(id) is bool and owned[id]:
				upgrades[id] = true
	has_progress = true

func save_progress(position: Vector3, yaw: float, job: Dictionary) -> bool:
	saved_position = Vector3(position.x, 0, position.z)
	saved_yaw = yaw
	active_job = job.duplicate(true)
	var data = {"version": VERSION, "money": money, "fuel": fuel, "condition": condition, "completed": completed, "earnings": earnings, "distance": total_distance, "position": [position.x, 0, position.z], "yaw": yaw, "job": job, "upgrades": upgrades, "clock": clock_hours}
	var file = FileAccess.open(path() + ".tmp", FileAccess.WRITE)
	if file == null:
		last_save_ok = false
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.flush()
	var write_ok = file.get_error() == OK
	file.close()
	if not write_ok:
		last_save_ok = false
		return false
	# Keep the last valid primary, never replace a good backup with a corrupt file.
	if not _read_data(path()).is_empty():
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path()), ProjectSettings.globalize_path(path() + ".bak")) != OK:
			last_save_ok = false
			return false
	elif FileAccess.file_exists(path()):
		# Preserve an unreadable primary for manual recovery before a new save.
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path()), ProjectSettings.globalize_path(path() + ".unreadable")) != OK:
			last_save_ok = false
			return false
	last_save_ok = DirAccess.rename_absolute(ProjectSettings.globalize_path(path() + ".tmp"), ProjectSettings.globalize_path(path())) == OK
	has_progress = has_progress or last_save_ok
	return last_save_ok

func load_settings() -> void:
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		for key in settings:
			settings[key] = config.get_value("settings", key, settings[key])
	validate_settings()

func validate_settings() -> void:
	for key in DEFAULT_SETTINGS:
		if not settings.has(key):
			settings[key] = DEFAULT_SETTINGS[key]
	settings.quality = int(number(settings.quality, 1, 0, 2))
	settings.resolution = int(number(settings.resolution, 0, 0, 3))
	for key in ["master", "music", "effects"]:
		settings[key] = number(settings[key], DEFAULT_SETTINGS[key], 0, 1)
	settings.sensitivity = number(settings.sensitivity, 1.0, 0.3, 2.0)
	for key in ["fullscreen", "invert_y"]:
		if not settings[key] is bool:
			settings[key] = false

func save_settings() -> bool:
	if test_mode:
		return true
	var config = ConfigFile.new()
	for key in settings:
		config.set_value("settings", key, settings[key])
	if config.save("user://settings.cfg.tmp") != OK:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path("user://settings.cfg.tmp"), ProjectSettings.globalize_path("user://settings.cfg")) == OK

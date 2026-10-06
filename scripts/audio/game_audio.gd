class_name GameAudio
extends Node
## Original synthesized sounds; no external or licensed audio required.

var vehicle: DeliveryVehicle
var engine: AudioStreamPlayer
var road: AudioStreamPlayer
var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var crash_player: AudioStreamPlayer
var _engine_pitch: float = 0.8

func _ready() -> void:
	for bus in ["Music", "Effects"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	engine = _player(_synthesize("engine", 1.0, true), "Effects", -24)
	road = _player(_synthesize("road", 2.0, true), "Effects", -45)
	ambience = _player(_synthesize("sea", 3.0, true), "Effects", -26)
	music = _player(_synthesize("music", 8.0, true), "Music", -23)
	ui_player = _player(_synthesize("ui", 0.11, false), "Effects", -17, false)
	crash_player = _player(_synthesize("crash", 0.38, false), "Effects", -12, false)

func _player(stream: AudioStreamWAV, bus: String, volume: float, start: bool = true) -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.bus = bus
	player.volume_db = volume
	add_child(player)
	if start and DisplayServer.get_name() != "headless":
		player.play()
	return player

func _synthesize(kind: String, duration: float, looping: bool) -> AudioStreamWAV:
	var rate = 22050
	var count = int(rate * duration)
	var data = PackedByteArray()
	data.resize(count * 2)
	var rng = RandomNumberGenerator.new()
	rng.seed = 711
	var filtered = 0.0
	for i in count:
		var t = float(i) / rate
		var noise = rng.randf_range(-1, 1)
		filtered = lerpf(filtered, noise, 0.04)
		var sample = 0.0
		match kind:
			"engine":
				sample = sin(TAU * 55 * t) * 0.45 + sin(TAU * 110 * t) * 0.22 + sin(TAU * 165 * t) * 0.13 + sin(TAU * 220 * t) * 0.055
				sample *= 0.87 + sin(TAU * 22 * t) * 0.10
			"road":
				sample = filtered * 0.9 + noise * 0.035
			"sea":
				sample = filtered * (0.7 + sin(TAU * t / duration) * 0.3)
			"music":
				var fade = pow(sin(PI * t / duration), 2)
				sample = (sin(TAU * 110 * t) + sin(TAU * 164.875 * t) * 0.4 + sin(TAU * 220 * t) * 0.25 + sin(TAU * 277.125 * t) * 0.3) * fade * 0.18
			"ui":
				sample = sin(TAU * 740 * t) * exp(-t * 42) * 0.35
			"crash":
				sample = (filtered * 2.2 + noise * 0.15 + sin(TAU * 62 * t) * 0.35) * exp(-t * 13)
		data.encode_s16(i * 2, int(clampf(sample, -0.98, 0.98) * 32767))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = count
	return stream

func _process(delta: float) -> void:
	if not is_instance_valid(vehicle):
		return
	var driving = vehicle.enabled and not get_tree().paused
	var speed = absf(vehicle.signed_speed)
	var gear = clampi(int(speed / 6.3), 0, 4)
	var revs = 0.8 + (speed - gear * 5.2) * 0.095 + vehicle.engine_load * 0.38
	_engine_pitch = lerpf(_engine_pitch, revs, minf(1, delta * 5))
	engine.pitch_scale = _engine_pitch
	engine.volume_db = (-27 + vehicle.engine_load * 7 + minf(speed, 20) * 0.15) if driving and vehicle.fuel_available else -65
	road.volume_db = (-39 + minf(speed, 25) * 0.45) if driving else -65
	music.volume_db = -29 if driving else -23

func apply_settings(settings: Dictionary) -> void:
	for item in [["Master", "master"], ["Music", "music"], ["Effects", "effects"]]:
		var index = AudioServer.get_bus_index(item[0])
		var value: float = settings[item[1]]
		AudioServer.set_bus_volume_db(index, linear_to_db(maxf(0.001, value)))
		AudioServer.set_bus_mute(index, value <= 0.001)

func click() -> void:
	if DisplayServer.get_name() != "headless":
		ui_player.play()

func collision(severity: float) -> void:
	crash_player.volume_db = clampf(-20 + severity, -18, -5)
	if DisplayServer.get_name() != "headless":
		crash_player.play()

func shutdown() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null

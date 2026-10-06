extends Node
## Reproducible visual review views, with measured wall-clock frame times.

var game: Node3D
var samples: Array[float] = []
var sampling: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	run.call_deferred()

func _process(delta: float) -> void:
	if sampling:
		samples.append(delta)

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://qa/screenshots")
	get_viewport().get_texture().get_image().save_png("res://qa/screenshots/" + name + ".png")
	print("PROBE captured ", name)

func wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout

func run() -> void:
	await wait(4)
	await capture("review-01-menu")
	game.start_game()
	game.ui.telemetry = true
	game.vehicle.recover(Vector3(4, 0, 119), 0)
	await wait(3)
	await capture("review-02-town")
	for quality in [0, 1, 2]:
		game.progress.settings.quality = quality
		game.apply_settings(false)
		await wait(2)
		samples.clear()
		sampling = true
		await wait(5)
		sampling = false
		samples.sort()
		var sum = 0.0
		for sample in samples:
			sum += sample
		print("PERFORMANCE quality=%d avg=%.1f fps median=%.1f ms p95=%.1f ms draw_calls=%d" % [quality, samples.size() / sum, samples[samples.size() / 2] * 1000, samples[int(samples.size() * 0.95)] * 1000, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
		await capture("review-quality-%d" % quality)
	game.progress.settings.quality = 1
	game.apply_settings(false)
	game.vehicle.recover(Vector3(116, 0, 62), PI)
	await wait(4)
	await capture("review-03-waterfront")
	game.vehicle.recover(Vector3(-4, 0, 27), PI)
	await wait(3)
	game.district.clock_hours = 21
	game.district._update_lighting()
	game.vehicle.toggle_lights()
	await wait(3)
	await capture("review-04-night")
	game.quit_game()

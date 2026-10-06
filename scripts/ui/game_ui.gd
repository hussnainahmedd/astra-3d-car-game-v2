class_name DispatchUI
extends CanvasLayer
## The native Control-based front end. HUD drawing keeps layout and draw cost small.

const INK = Color("102a32")
const PAPER = Color("eeeadd")
const MUTED = Color("9eb3ad")
const MINT = Color("81bcb0")
const AMBER = Color("e9b477")

var game: Node3D
var root: Control
var hud: Control
var menu: Control
var minimap: DistrictMinimap
var screen: String = "main"
var toast: String = ""
var toast_time: float = 0
var toast_positive: bool = true
var telemetry: bool = false
var last_button: Button
var font: Font
var _styles: Dictionary = {}
var toast_label: Label
var _hud_tick: float = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.draw.connect(_draw_hud)
	root.add_child(hud)
	minimap = DistrictMinimap.new()
	minimap.district = game.district
	minimap.vehicle = game.vehicle
	minimap.missions = game.missions
	minimap.traffic = game.traffic
	hud.add_child(minimap)
	toast_label = Label.new()
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.add_theme_color_override("font_outline_color", INK)
	toast_label.add_theme_constant_override("outline_size", 5)
	hud.add_child(toast_label)
	show_main()

func _process(delta: float) -> void:
	toast_time = maxf(0, toast_time - delta)
	hud.visible = game.started and screen == ""
	toast_label.visible = toast_time > 0
	_hud_tick += delta
	if hud.visible and DisplayServer.get_name() != "headless" and _hud_tick >= 1.0 / 30.0:
		_hud_tick = 0
		minimap.position = Vector2(32, root.size.y - 259)
		minimap.size = Vector2(226, 199)
		toast_label.position = Vector2((root.size.x - 600) / 2, 249)
		toast_label.size = Vector2(600, 74)
		hud.queue_redraw()
		minimap.queue_redraw()

func notify(words: String, positive: bool = true) -> void:
	toast = words
	toast_positive = positive
	toast_time = 6
	if is_instance_valid(toast_label):
		toast_label.text = words
		toast_label.add_theme_color_override("font_color", PAPER if positive else AMBER)

func _box(canvas: Control, rect: Rect2, color: Color, radius: int = 8, border: Color = Color.TRANSPARENT) -> void:
	var key = str(color) + str(radius) + str(border)
	if not _styles.has(key):
		var style = StyleBoxFlat.new()
		style.bg_color = color
		style.set_corner_radius_all(radius)
		if border.a > 0:
			style.border_color = border
			style.set_border_width_all(1)
		_styles[key] = style
	_styles[key].draw(canvas.get_canvas_item(), rect)

func _text(words: String, at: Vector2, size: int = 18, color: Color = PAPER) -> void:
	hud.draw_string(font, at + Vector2(0, size), words, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _draw_hud() -> void:
	var w = hud.size.x
	var h = hud.size.y
	var vehicle: DeliveryVehicle = game.vehicle
	var progress: ProgressStore = game.progress
	var missions: DeliveryManager = game.missions
	_box(hud, Rect2(30, 25, 34, 34), MINT, 5)
	_text("H", Vector2(38, 25), 24, INK)
	_text("HARBORLINE", Vector2(76, 22), 18)
	_text("D I S P A T C H", Vector2(77, 46), 10, MUTED)
	_box(hud, Rect2(w - 247, 24, 215, 66), Color(0.06, 0.14, 0.17, 0.9), 8)
	_text("SHIFT BALANCE", Vector2(w - 231, 34), 10, MUTED)
	_text("$ %s" % _money(progress.money), Vector2(w - 231, 48), 25)
	var hour = int(game.district.clock_hours)
	var minute = int(fmod(game.district.clock_hours, 1.0) * 60)
	_text("%02d:%02d  /  HARBOR DISTRICT" % [hour, minute], Vector2(w - 247, 99), 11, MUTED)
	_box(hud, Rect2(32, 88, 333, 176 if not missions.job.is_empty() else 150), Color(0.06, 0.14, 0.17, 0.94), 8)
	hud.draw_rect(Rect2(32, 105, 3, 36), MINT)
	if missions.job.is_empty():
		_text("ON YOUR OWN SCHEDULE", Vector2(50, 103), 11, MINT)
		_text("Your next mile starts here.", Vector2(50, 126), 20)
		_text("Press J to browse delivery contracts", Vector2(50, 159), 13, MUTED)
		_text("%d delivered  /  $%d earned" % [progress.completed, progress.earnings], Vector2(50, 183), 11, MUTED)
		_text(CourierCareer.rank_name(progress.completed) + "  /  " + CourierCareer.next_goal(progress.completed).split(" to ")[0], Vector2(50, 208), 10, MINT)
	else:
		var pickup = missions.job.stage == "pickup"
		_text("01 / COLLECTION" if pickup else "02 / DELIVERY", Vector2(50, 102), 11, MINT if pickup else AMBER)
		_text(game.district.places[missions.target_index()].name, Vector2(50, 124), 21)
		_text(str(missions.job.cargo), Vector2(50, 155), 13, MUTED)
		var distance = missions.distance_to_target()
		_text("%d m" % int(distance), Vector2(50, 187), 23, AMBER)
		_text("BASE $%d  +  UP TO $%d BONUS" % [int(missions.job.base), missions.maximum_bonus(missions.job)], Vector2(134, 197), 10, MUTED)
		var cargo = "CARGO %d%%" % int(missions.job.cargo_condition) if not pickup else "LOAD %d KG" % int(missions.job.weight)
		var remaining = maxf(0, float(missions.job.deadline) - missions.elapsed)
		var timing = "%d:%02d BONUS WINDOW" % [int(remaining) / 60, int(remaining) % 60] if not pickup and remaining > 0 else "NO LATE PENALTY"
		_text("%s  •  %s" % [cargo, timing], Vector2(50, 231), 10, AMBER if not pickup and missions.job.cargo_condition < 80 else MUTED)
	if missions.has_navigation_target():
		# Compass chevron points to the destination relative to the van's heading.
		var local = vehicle.to_local(missions.target_position())
		var angle = atan2(local.x, -local.z)
		var center = Vector2(w / 2, 42)
		_box(hud, Rect2(center - Vector2(46, 18), Vector2(92, 41)), Color(0.06, 0.14, 0.17, 0.9), 20)
		var triangle = PackedVector2Array()
		for point in [Vector2(0, -10), Vector2(7, 7), Vector2(0, 3), Vector2(-7, 7)]:
			triangle.append(center + point.rotated(angle))
		hud.draw_colored_polygon(triangle, AMBER)
		var hint = missions.navigation_hint()
		var hint_width = font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		_text(hint, Vector2((w - hint_width) / 2, 91), 13, PAPER)
		if missions.service_waypoint:
			_text("SERVICE DETOUR  •  %d m by road" % int(missions.route_distance), Vector2(w / 2 - 122, 119), 11, MINT)
	# Map caption, understated legend, and two useful gauges.
	_box(hud, Rect2(30, h - 284, 230, 249), Color(0.06, 0.14, 0.17, 0.93), 8)
	_text("HARBOR DISTRICT", Vector2(44, h - 279), 10, MUTED)
	_text("● YOU    ━ ROUTE    ■ SERVICE", Vector2(45, h - 56), 9, MUTED)
	_box(hud, Rect2(w - 258, h - 214, 226, 179), Color(0.06, 0.14, 0.17, 0.94), 8)
	_text("%02d" % int(vehicle.speed_kph), Vector2(w - 240, h - 213), 64)
	_text("KM/H", Vector2(w - 123, h - 165), 12, MUTED)
	var gear = "R" if vehicle.signed_speed < -0.45 else "D"
	if vehicle.speed_kph < 1:
		gear = "N"
	_box(hud, Rect2(w - 74, h - 191, 25, 29), Color("2d4a4d"), 4)
	_text(gear, Vector2(w - 68, h - 189), 19, MINT)
	_text("FUEL", Vector2(w - 239, h - 124), 10, MUTED)
	_text("%d%%" % int(progress.fuel), Vector2(w - 85, h - 124), 10, PAPER)
	_gauge(Vector2(w - 239, h - 102), 188, progress.fuel / 100, MINT if progress.fuel > 15 else AMBER)
	_text("CONDITION", Vector2(w - 239, h - 85), 10, MUTED)
	_text("%d%%" % int(progress.condition), Vector2(w - 85, h - 85), 10)
	_gauge(Vector2(w - 239, h - 64), 188, progress.condition / 100, MINT if progress.condition > 40 else AMBER)
	if vehicle.handbrake:
		_text("PARKING BRAKE", Vector2(w - 240, h - 143), 10, AMBER)
	elif vehicle.lights_on:
		_text("LIGHTS ON", Vector2(w - 240, h - 143), 10, MINT)
	var prompt = ""
	var sub = ""
	if missions.in_zone():
		if not missions.can_handle():
			prompt = "Stop inside the loading bay"
			sub = "Below 2 km/h, upright, with wheels on the ground • R to recover"
		else:
			prompt = "HOLD  E   /   " + ("LOAD CARGO" if missions.job.stage == "pickup" else "COMPLETE DELIVERY")
			sub = "Keep the van stationary"
	elif vehicle.global_position.distance_to(HarborDistrict.FUEL_POINT) < 8:
		prompt = "E   /   REFUEL + REPAIR  •  $%d" % game.systems.service_cost()
		sub = "G  Workshop • fuel-only, repairs and permanent upgrades"
	elif game.play_time < 22 and missions.job.is_empty():
		prompt = "Welcome to your first shift. Press J to find a job."
		sub = "Take your time. There are no failed deliveries."
	if not prompt.is_empty():
		var width = maxf(430, font.get_string_size(prompt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 44)
		var left = (w - width) / 2
		_box(hud, Rect2(left, h - 142, width, 73), INK, 8, Color("48645e"))
		_text(prompt, Vector2(left + 20, h - 130), 16, PAPER)
		_text(sub, Vector2(left + 20, h - 103), 11, MUTED)
		if missions.handling > 0:
			_gauge(Vector2(left + 1, h - 73), width - 2, missions.handling / 1.8, AMBER)
	var controls = "WASD  DRIVE    SPACE  BRAKE    J  JOBS    M  MAP    G  WORKSHOP    C  CAMERA    R  RECOVER    ESC  PAUSE"
	var controls_width = font.get_string_size(controls, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
	_text(controls, Vector2((w - controls_width) / 2, h - 27), 10, MUTED)
	if toast_time > 0:
		_box(hud, Rect2((w - 620) / 2, 245, 620, 80), INK, 6, MINT if toast_positive else AMBER)
	if telemetry:
		_text("%d FPS  /  %.1f ms  /  wheels %d  /  %.1f m/s" % [Engine.get_frames_per_second(), Performance.get_monitor(Performance.TIME_PROCESS) * 1000, vehicle.grounded_wheels, vehicle.signed_speed], Vector2(395, 12), 12, AMBER)

func _gauge(at: Vector2, width: float, value: float, color: Color) -> void:
	hud.draw_rect(Rect2(at, Vector2(width, 4)), Color("3d5353"))
	hud.draw_rect(Rect2(at, Vector2(width * clampf(value, 0, 1), 4)), color)

func _money(value: int) -> String:
	var s = str(value)
	var result = ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			result += ","
		result += s[i]
	return result

func clear_menu() -> void:
	if is_instance_valid(menu):
		menu.hide()
		menu.queue_free()
	menu = Control.new()
	menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	last_button = null

func hide_menu() -> void:
	screen = ""
	if is_instance_valid(menu):
		menu.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _panel(at: Vector2, size: Vector2, color: Color = INK) -> Panel:
	var panel = Panel.new()
	panel.position = at
	panel.size = size
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(9)
	style.border_color = Color("39535a")
	style.set_border_width_all(1)
	panel.add_theme_stylebox_override("panel", style)
	menu.add_child(panel)
	return panel

func _label(parent: Control, words: String, at: Vector2, size: Vector2, point_size: int = 18, color: Color = PAPER) -> Label:
	var label = Label.new()
	label.text = words
	label.position = at
	label.size = size
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", point_size)
	parent.add_child(label)
	return label

func _button(parent: Control, words: String, at: Vector2, size: Vector2, callback: Callable, primary: bool = false) -> Button:
	var button = Button.new()
	button.text = words
	button.position = at
	button.size = size
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", INK if primary else PAPER)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_focus_color", INK if primary else PAPER)
	for state in ["normal", "hover", "pressed", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = (MINT if primary else Color("213c43")) if state in ["normal", "focus"] else Color("b6d0b9")
		style.set_corner_radius_all(5)
		style.set_content_margin_all(12)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = AMBER
			style.set_border_width_all(2)
		button.add_theme_stylebox_override(state, style)
	button.pressed.connect(func(): game.audio.click(); callback.call())
	parent.add_child(button)
	if last_button == null:
		button.grab_focus.call_deferred()
	last_button = button
	return button

func _backdrop() -> void:
	var dark = ColorRect.new()
	dark.color = Color(0.025, 0.07, 0.09, 0.72)
	dark.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu.add_child(dark)

func show_main() -> void:
	clear_menu()
	screen = "main"
	var background = ColorRect.new()
	background.color = Color(0.035, 0.10, 0.125, 0.94)
	background.set_anchors_and_offsets_preset(Control.PRESET_LEFT_WIDE)
	background.offset_right = 506
	menu.add_child(background)
	_label(menu, "H / D     INDEPENDENT COASTAL LOGISTICS", Vector2(48, 49), Vector2(415, 30), 11, MINT)
	_label(menu, "HARBORLINE", Vector2(44, 133), Vector2(440, 65), 47)
	_label(menu, "D I S P A T C H", Vector2(48, 200), Vector2(410, 50), 30, MINT)
	_label(menu, "The last mile. Your own way.", Vector2(48, 288), Vector2(410, 35), 20)
	_label(menu, "A van. A harbor. A shift that's yours.\nCollect cargo, take the coastal roads,\nand build a little business of your own.", Vector2(48, 337), Vector2(405, 80), 15, MUTED)
	_button(menu, "Continue shift   →" if game.progress.has_progress else "Start your shift   →", Vector2(48, 452), Vector2(365, 54), game.start_game, true)
	_button(menu, "Settings", Vector2(48, 520), Vector2(176, 45), func(): show_settings("main"))
	_button(menu, "Quit", Vector2(237, 520), Vector2(176, 45), game.quit_game)
	_label(menu, "WASD  Drive     J  Dispatch     E  Load / deliver\nC  Camera     H  Lights     N  Time of day", Vector2(48, 603), Vector2(410, 52), 12, MUTED)
	_label(menu, "NATIVE DESKTOP PREVIEW   /   v0.2   /   OFFLINE", Vector2(48, 680), Vector2(420, 24), 10, MUTED)
	if not game.progress.load_message.is_empty():
		var status = _label(menu, game.progress.load_message, Vector2(48, 409), Vector2(405, 40), 11, AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var caption = _label(menu, "HARBOR DISTRICT\nA SMALL PLACE. PLENTY OF ROADS.", Vector2.ZERO, Vector2(390, 57), 14, PAPER)
	caption.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	caption.position = Vector2(root.size.x - 416, root.size.y - 87)

func show_pause() -> void:
	clear_menu()
	screen = "pause"
	_backdrop()
	var panel = _panel((root.size - Vector2(434, 538)) / 2, Vector2(434, 538))
	_label(panel, "OFF THE CLOCK", Vector2(32, 25), Vector2(370, 22), 11, MINT)
	_label(panel, "Shift paused.", Vector2(32, 59), Vector2(370, 49), 34)
	_label(panel, "Your progress is saved locally." if game.progress.last_save_ok else "Save failed • your shift is still in memory.", Vector2(32, 113), Vector2(370, 27), 13, MUTED if game.progress.last_save_ok else AMBER)
	_button(panel, "Resume driving", Vector2(32, 167), Vector2(370, 48), game.resume_game, true)
	_button(panel, "Recover to the road", Vector2(32, 227), Vector2(370, 44), func(): game.recover_vehicle(); game.resume_game())
	_button(panel, "Settings", Vector2(32, 282), Vector2(370, 44), func(): show_settings("pause"))
	_button(panel, "Main menu", Vector2(32, 337), Vector2(370, 44), game.return_to_menu)
	_button(panel, "Save & quit", Vector2(32, 392), Vector2(370, 44), game.quit_game)
	_label(panel, "RMB + mouse: look around   /   F11: fullscreen\nN: cycle daylight   /   F3: performance", Vector2(32, 465), Vector2(375, 44), 12, MUTED)

func show_jobs() -> void:
	clear_menu()
	screen = "jobs"
	_backdrop()
	var panel = _panel((root.size - Vector2(956, 482)) / 2, Vector2(956, 482))
	_label(panel, "HARBORLINE  /  DISPATCH BOARD", Vector2(29, 24), Vector2(800, 25), 12, MINT)
	_label(panel, "Good work. Just down the road.", Vector2(29, 57), Vector2(800, 46), 29)
	_label(panel, "%s  •  %s" % [CourierCareer.rank_name(game.progress.completed), CourierCareer.next_goal(game.progress.completed)], Vector2(30, 113), Vector2(885, 27), 12, MINT)
	if not game.missions.job.is_empty():
		var job = game.missions.job
		_label(panel, "%s → %s\n%s • %s • base $%d" % [game.district.places[int(job.pickup)].name, game.district.places[int(job.destination)].name, job.cargo, str(job.kind).capitalize(), int(job.base)], Vector2(29, 158), Vector2(890, 95), 20)
		_label(panel, "Cargo %d%% • no late penalties. Repairs do not restore damaged cargo." % int(job.cargo_condition), Vector2(29, 264), Vector2(890, 30), 14, MUTED)
		_button(panel, "Return contract • no fee", Vector2(29, 335), Vector2(325, 44), func(): game.missions.cancel(); show_jobs())
	else:
		game.missions.make_offers()
		var pickup = game.district.places[int(game.missions.offers[0].pickup)].name
		_label(panel, "COLLECTION AT  " + pickup.to_upper() + "   /   No late penalties", Vector2(30, 143), Vector2(885, 22), 11, MUTED)
		for i in game.missions.offers.size():
			var offer = game.missions.offers[i]
			var left = 28 + i * 303
			var card = Panel.new()
			card.position = Vector2(left, 179)
			card.size = Vector2(288, 228)
			var style = StyleBoxFlat.new()
			style.bg_color = Color("203a41")
			style.set_corner_radius_all(6)
			card.add_theme_stylebox_override("panel", style)
			panel.add_child(card)
			_label(card, "0%d  /  %s CONTRACT" % [i + 1, str(offer.kind).to_upper()], Vector2(17, 14), Vector2(260, 25), 10, MINT)
			_label(card, game.district.places[int(offer.destination)].name, Vector2(17, 47), Vector2(262, 32), 20)
			_label(card, str(offer.cargo), Vector2(17, 90), Vector2(260, 28), 13, MUTED)
			_label(card, "%d m   /   $%d + bonus" % [offer.distance, offer.base], Vector2(17, 125), Vector2(260, 29), 17, AMBER)
			_label(card, "Care + time bonus up to $%d  /  %d kg" % [game.missions.maximum_bonus(offer), int(offer.weight)], Vector2(17, 157), Vector2(260, 20), 10, MUTED)
			_button(card, "Accept contract   →", Vector2(17, 182), Vector2(254, 36), func(): game.accept_job(i), i == 0)
	_button(panel, "Back to the road   /   Esc", Vector2(641, 424), Vector2(285, 38), game.resume_game)

func show_settings(return_screen: String) -> void:
	clear_menu()
	screen = "settings_" + return_screen
	_backdrop()
	var panel = _panel((root.size - Vector2(616, 664)) / 2, Vector2(616, 664))
	_label(panel, "MAKE YOURSELF AT HOME", Vector2(30, 24), Vector2(550, 25), 11, MINT)
	_label(panel, "Settings", Vector2(30, 51), Vector2(550, 48), 33)
	_label(panel, "Changes apply immediately and are saved on this computer.", Vector2(30, 107), Vector2(550, 24), 12, MUTED)
	_option(panel, "Graphics", ["VM Low · 65% render, no shadows", "Balanced · 75% render, shadows", "High · 100% render + 2× AA"], int(game.progress.settings.quality), 155, func(index): game.progress.settings.quality = index; game.apply_settings())
	_option(panel, "Window size", ["960 × 540", "1152 × 648", "1280 × 720", "1600 × 900"], int(game.progress.settings.resolution), 210, func(index): game.progress.settings.resolution = index; game.apply_settings())
	var fullscreen = CheckButton.new()
	fullscreen.text = "Fullscreen   /   F11"
	fullscreen.position = Vector2(247, 256)
	fullscreen.size = Vector2(335, 36)
	fullscreen.button_pressed = bool(game.progress.settings.fullscreen)
	fullscreen.toggled.connect(func(value): game.progress.settings.fullscreen = value; game.apply_settings())
	panel.add_child(fullscreen)
	_slider(panel, "Master volume", "master", 313, 0, 1)
	_slider(panel, "Music volume", "music", 362, 0, 1)
	_slider(panel, "Effects volume", "effects", 411, 0, 1)
	_slider(panel, "Mouse sensitivity", "sensitivity", 460, 0.3, 2.0)
	var invert = CheckButton.new()
	invert.text = "Invert vertical mouse look"
	invert.position = Vector2(247, 502)
	invert.size = Vector2(339, 36)
	invert.button_pressed = bool(game.progress.settings.invert_y)
	invert.toggled.connect(func(value): game.progress.settings.invert_y = value; game.apply_settings(false))
	panel.add_child(invert)
	_label(panel, "VM tip: use 960 × 540 and VM Low if the frame rate dips.\nMouse orbit: hold right mouse button while driving.", Vector2(30, 552), Vector2(556, 48), 12, MUTED)
	_button(panel, "Done", Vector2(30, 612), Vector2(556, 40), func(): show_main() if return_screen == "main" else show_pause(), true)

func show_map() -> void:
	clear_menu()
	screen = "map"
	_backdrop()
	var panel = _panel((root.size - Vector2(1030, 652)) / 2, Vector2(1030, 652))
	_label(panel, "KNOW YOUR NEXT MILE", Vector2(28, 20), Vector2(940, 25), 11, MINT)
	_label(panel, "Harbor District", Vector2(28, 47), Vector2(940, 48), 31)
	var map = DistrictMinimap.new()
	map.district = game.district
	map.vehicle = game.vehicle
	map.missions = game.missions
	map.traffic = game.traffic
	map.show_labels = true
	map.position = Vector2(28, 112)
	map.size = Vector2(595, 485)
	panel.add_child(map)
	var progress: ProgressStore = game.progress
	_label(panel, "YOUR BUSINESS", Vector2(649, 115), Vector2(350, 25), 11, MINT)
	_label(panel, CourierCareer.rank_name(progress.completed), Vector2(649, 146), Vector2(350, 32), 23)
	var goal = _label(panel, CourierCareer.next_goal(progress.completed), Vector2(649, 185), Vector2(350, 49), 14, MUTED)
	goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label(panel, "%d deliveries  /  $%d lifetime earnings\n%.2f km driven  /  $%d available" % [progress.completed, progress.earnings, progress.total_distance / 1000, progress.money], Vector2(649, 240), Vector2(350, 60), 14, PAPER)
	var target = _label(panel, "ROUTE: %s\n%d m by road\n%s" % [game.missions.navigation_name(), int(game.missions.route_distance), game.missions.navigation_hint()], Vector2(649, 325), Vector2(350, 90), 14, AMBER)
	target.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_button(panel, "Route to Coast Service", Vector2(649, 437), Vector2(350, 44), game.navigate_to_service, true)
	if game.missions.service_waypoint:
		_button(panel, "Restore delivery route", Vector2(649, 489), Vector2(350, 40), func(): game.navigate_to_service(false))
	_button(panel, "Workshop / upgrades", Vector2(649, 544), Vector2(350, 40), game.open_workshop)
	_label(panel, "● YOU    ━ ROUTE    ■ SERVICE   /   NORTH UP", Vector2(28, 612), Vector2(600, 25), 11, MUTED)
	_button(panel, "Back to driving / M / Esc", Vector2(649, 602), Vector2(350, 37), game.resume_game)

func show_workshop() -> void:
	clear_menu()
	screen = "workshop"
	_backdrop()
	var panel = _panel((root.size - Vector2(950, 640)) / 2, Vector2(950, 640))
	var available: bool = game.can_use_workshop()
	_label(panel, "COAST SERVICE  /  KEEP YOUR BUSINESS MOVING", Vector2(28, 22), Vector2(880, 26), 11, MINT)
	_label(panel, "Workshop", Vector2(28, 55), Vector2(700, 46), 32)
	_label(panel, "$%s  •  %s" % [_money(game.progress.money), CourierCareer.rank_name(game.progress.completed)], Vector2(28, 108), Vector2(880, 26), 15, AMBER)
	_label(panel, "Ready for service and upgrades." if available else "Drive to Coast Service and park upright below 2 km/h to use the workshop.", Vector2(28, 145), Vector2(894, 29), 13, MUTED)
	for i in 3:
		var kind: String = ["fuel", "repair", "full"][i]
		var title: String = ["Fuel only", "Repair only", "Full service"][i]
		var cost: int = game.systems.service_cost(kind)
		var button = _button(panel, "%s  /  $%d" % [title, cost], Vector2(28 + i * 305, 190), Vector2(284, 45), func(): game.perform_service(kind); show_workshop())
		# Allow the emergency top-up even when a full tank is unaffordable.
		button.disabled = not available or (game.progress.money < cost and game.progress.fuel >= 8)
	_label(panel, "PERMANENT VAN UPGRADES", Vector2(28, 260), Vector2(880, 25), 11, MINT)
	var index = 0
	for id in CourierCareer.UPGRADES:
		var upgrade: Dictionary = CourierCareer.UPGRADES[id]
		var y = 299 + index * 77
		_label(panel, upgrade.name, Vector2(28, y), Vector2(565, 27), 19)
		_label(panel, upgrade.description, Vector2(28, y + 31), Vector2(565, 24), 13, MUTED)
		var owned: bool = game.progress.upgrades.has(id)
		var locked: bool = CourierCareer.rank_index(game.progress.completed) < int(upgrade.rank)
		var words = "Installed" if owned else "Unlock: " + CourierCareer.RANKS[int(upgrade.rank)].name if locked else "Install / $%d" % int(upgrade.price)
		var button = _button(panel, words, Vector2(621, y + 3), Vector2(300, 44), func(): game.purchase_upgrade(id); show_workshop())
		button.disabled = not available or not CourierCareer.can_purchase(id, game.progress)
		index += 1
	if toast_time > 0:
		var status = _label(panel, toast, Vector2(28, 540), Vector2(570, 60), 12, MINT if toast_positive else AMBER)
		status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if not available:
		_button(panel, "Set service route", Vector2(621, 540), Vector2(300, 35), game.navigate_to_service, true)
	_button(panel, "Back to driving / Esc", Vector2(621, 584), Vector2(300, 30), game.resume_game)

func _option(parent: Control, words: String, choices: Array, selected: int, y: float, callback: Callable) -> void:
	_label(parent, words, Vector2(30, y + 5), Vector2(206, 32), 16)
	var option = OptionButton.new()
	option.position = Vector2(247, y)
	option.size = Vector2(339, 40)
	option.add_theme_font_size_override("font_size", 14)
	for choice in choices:
		option.add_item(choice)
	option.selected = selected
	option.item_selected.connect(callback)
	parent.add_child(option)

func _slider(parent: Control, words: String, key: String, y: float, low: float, high: float) -> void:
	_label(parent, words, Vector2(30, y), Vector2(220, 28), 16)
	var slider = HSlider.new()
	slider.position = Vector2(247, y + 2)
	slider.size = Vector2(294, 25)
	slider.min_value = low
	slider.max_value = high
	slider.step = 0.01
	slider.value = game.progress.settings[key]
	var value = _label(parent, "%d" % int(slider.value * 100), Vector2(553, y), Vector2(40, 28), 13, MINT)
	slider.value_changed.connect(func(number): game.progress.settings[key] = number; value.text = "%d" % int(number * 100); game.apply_settings(false))
	parent.add_child(slider)

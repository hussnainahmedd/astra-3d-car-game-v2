class_name GameBindings
extends RefCounted
## A single action map, deliberately independent of vehicle code for future rebinding UI.

static func install() -> void:
	var bindings = {
		"accelerate": [KEY_W, KEY_UP], "brake": [KEY_S, KEY_DOWN],
		"steer_left": [KEY_A, KEY_LEFT], "steer_right": [KEY_D, KEY_RIGHT],
		"handbrake": [KEY_SPACE], "headlights": [KEY_H], "camera": [KEY_C],
		"recover": [KEY_R], "pause": [KEY_ESCAPE], "interact": [KEY_E],
		"dispatch": [KEY_J], "time_of_day": [KEY_N], "telemetry": [KEY_F3],
		"fullscreen": [KEY_F11], "district_map": [KEY_M], "workshop": [KEY_G]
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			if not InputMap.action_has_event(action, event):
				InputMap.action_add_event(action, event)

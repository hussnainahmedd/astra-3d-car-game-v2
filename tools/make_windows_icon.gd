extends SceneTree
## Derive an installer ICO from the project's original SVG; no new branding.

func _initialize() -> void:
	var image = Image.load_from_file("res://assets/icon.svg")
	if image == null or image.is_empty():
		push_error("Could not load the existing project icon")
		quit(1)
		return
	image.resize(256, 256, Image.INTERPOLATE_LANCZOS)
	var png = image.save_png_to_buffer()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://builds/branding"))
	var file = FileAccess.open("res://builds/branding/icon.ico", FileAccess.WRITE)
	if file == null:
		quit(1)
		return
	file.store_16(0)
	file.store_16(1)
	file.store_16(1)
	for value in [0, 0, 0, 0]:
		file.store_8(value)
	file.store_16(1)
	file.store_16(32)
	file.store_32(png.size())
	file.store_32(22)
	file.store_buffer(png)
	file.close()
	print("Generated installer icon from assets/icon.svg")
	quit(0)

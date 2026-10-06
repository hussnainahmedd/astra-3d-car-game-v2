extends SceneTree
## Packs only the runtime project and its imported resource references.
## The development engine also works as a standalone Godot PCK runtime.

var packer = PCKPacker.new()
var count: int = 0
var failed: bool = false

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://builds/phase1-linux")
	var result = packer.pck_start("res://builds/phase1-linux/Harborline.pck.tmp")
	if result != OK:
		push_error("Cannot create development pack: %s" % error_string(result))
		quit(1)
		return
	add_file("res://project.godot")
	for directory in ["res://scenes", "res://scripts", "res://assets"]:
		add_directory(directory)
	# This cache registers class_name scripts without requiring an editor scan at launch.
	add_file("res://.godot/global_script_class_cache.cfg")
	var imports = DirAccess.open("res://.godot/imported")
	if imports:
		for filename in imports.get_files():
			if filename.begins_with("icon.svg-"):
				add_file("res://.godot/imported/" + filename)
	# Finish the temporary pack before replacing the playable development pack.
	var flush_result = packer.flush()
	if failed or flush_result != OK:
		push_error("Development pack was not replaced because packing failed.")
		quit(1)
	else:
		result = DirAccess.rename_absolute(ProjectSettings.globalize_path("res://builds/phase1-linux/Harborline.pck.tmp"), ProjectSettings.globalize_path("res://builds/phase1-linux/Harborline.pck"))
		if result != OK:
			push_error("Could not replace development pack: " + error_string(result))
			quit(1)
		else:
			print("Packed %d runtime files into builds/phase1-linux/Harborline.pck" % count)
			quit(0)

func add_directory(path: String) -> void:
	var directory = DirAccess.open(path)
	if directory == null:
		push_error("Required runtime directory is missing: " + path)
		failed = true
		return
	for filename in directory.get_files():
		add_file(path.path_join(filename))
	for child in directory.get_directories():
		add_directory(path.path_join(child))

func add_file(path: String) -> void:
	var result = packer.add_file(path, path)
	if result != OK:
		push_error("Could not pack %s: %s" % [path, error_string(result)])
		failed = true
	else:
		count += 1

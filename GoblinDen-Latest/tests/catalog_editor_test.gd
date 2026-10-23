extends SceneTree
const Catalog = preload("res://scripts/design_catalog.gd")
const Model = preload("res://addons/goblinden_data/data_model.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	var model = Model.new()
	model.base_dir = "user://catalog-test/"
	DirAccess.make_dir_recursive_absolute(model.base_dir)
	for category in Catalog.CATEGORIES:
		var source := Catalog.ROOT + str(category) + ".json"
		DirAccess.copy_absolute(source, model.base_dir + str(category) + ".json")
	model.load_all()
	check(model.errors.is_empty(), "Every original catalog file validates")
	check(not model.set_value("items", "iron_sword", "id", "other_id"), "Editor refuses changes to permanent IDs")
	check(model.set_value("items", "iron_sword", "name", "Goblin Test Blade"), "Display names are editable")
	model.set_value("items", "iron_sword", "attack", 17)
	check(model.is_dirty() and model.save_all(), "Valid edits save successfully")
	check(FileAccess.file_exists(model.base_dir + "items.json.bak"), "Save keeps a previous-version backup")
	var reloaded = Model.new()
	reloaded.base_dir = model.base_dir
	reloaded.load_all()
	check(reloaded.find_entry("items", "iron_sword").name == "Goblin Test Blade" and reloaded.find_entry("items", "iron_sword").attack == 17, "Saved names and values persist after reopening")
	var previous := FileAccess.get_file_as_string(model.base_dir + "monsters.json")
	model.set_value("monsters", "vault_hunger", "hp", -10)
	check(not model.save_all(), "Invalid monster health rejects save")
	check(FileAccess.get_file_as_string(model.base_dir + "monsters.json") == previous, "Rejected save leaves files intact")
	model.reset_entry("monsters", "vault_hunger")
	model.set_value("items", "iron_sword", "name", "Pending edit")
	var path: String = model.base_dir + "spells.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(Catalog.ROOT + "spells.json") + "\n")
	file.close()
	check(not model.save_all() and str(model.errors).contains("outside this editor"), "External file changes block conflicting saves")
	check(FileAccess.get_file_as_string(model.base_dir + "items.json").contains("Goblin Test Blade"), "Conflict preserves the last saved data")
	model.load_all()
	model.set_value("items", "iron_sword", "name", "")
	check(not model.save_all(), "Empty display names reject save")
	model.reset_entry("items", "iron_sword")
	model.set_value("items", "iron_sword", "level", 1.5)
	check(not model.save_all(), "Fractional required levels reject save")
	model.reset_entry("items", "iron_sword")
	model.set_value("items", "iron_sword", "icon_id", "unknown_icon")
	check(not model.save_all(), "Unknown icon IDs reject save")
	for category in Catalog.CATEGORIES:
		for extension in [".json", ".json.bak", ".json.tmp"]:
			DirAccess.remove_absolute(model.base_dir + str(category) + extension)
	DirAccess.remove_absolute(model.base_dir)
	print("Catalog editor save/validation checks; failures: ", failures)
	quit(failures)

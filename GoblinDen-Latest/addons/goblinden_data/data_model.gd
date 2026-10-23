@tool
extends RefCounted
const Catalog = preload("res://scripts/design_catalog.gd")
var base_dir: String = Catalog.ROOT
var documents: Dictionary = {}
var originals: Dictionary = {}
var hashes: Dictionary = {}
var errors := PackedStringArray()

func load_all() -> void:
	documents.clear()
	originals.clear()
	hashes.clear()
	errors.clear()
	for category in Catalog.CATEGORIES:
		var path := base_dir + str(category) + ".json"
		var text := FileAccess.get_file_as_string(path)
		var parser := JSON.new()
		if parser.parse(text) != OK or not parser.data is Dictionary:
			errors.append("Cannot read " + str(category) + ": " + parser.get_error_message())
			continue
		documents[category] = parser.data
		originals[category] = parser.data.duplicate(true)
		hashes[category] = text.sha256_text()
	if errors.is_empty():
		errors = Catalog.validate(documents)

func find_entry(category: String, id: String) -> Dictionary:
	for entry in documents.get(category, {}).get("records", []):
		if str(entry.id) == id:
			return entry
	return {}

func set_value(category: String, id: String, field: String, value) -> bool:
	if Catalog.PROTECTED.has(field):
		return false
	var entry := find_entry(category, id)
	if entry.is_empty() or not entry.has(field):
		return false
	entry[field] = value
	return true

func is_dirty() -> bool:
	return documents != originals

func dirty_categories() -> Array:
	var result := []
	for category in documents:
		if documents[category] != originals.get(category):
			result.append(category)
	return result

func reset_entry(category: String, id: String) -> void:
	for i in range(documents[category].records.size()):
		if str(documents[category].records[i].id) == id:
			documents[category].records[i] = originals[category].records[i].duplicate(true)
			return

func save_all() -> bool:
	errors = Catalog.validate(documents)
	if not errors.is_empty():
		return false
	var changed := dirty_categories()
	if changed.is_empty():
		return true
	# Check every file, including files supplying references to edited definitions.
	for category in Catalog.CATEGORIES:
		var path := base_dir + str(category) + ".json"
		if FileAccess.get_file_as_string(path).sha256_text() != hashes.get(category):
			errors.append(str(category) + " changed outside this editor. Copy your edits, then reload before saving.")
	if not errors.is_empty():
		return false
	# Stage the entire save before replacing anything.
	var staged := []
	for category in changed:
		var path := base_dir + str(category) + ".json"
		var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
		if file == null:
			errors.append("Cannot write " + str(category) + ". Check folder permissions.")
			_cleanup_staged(staged)
			return false
		file.store_string(JSON.stringify(documents[category], "  ") + "\n")
		file.flush()
		var write_error := file.get_error()
		file.close()
		staged.append(path)
		if write_error != OK:
			errors.append("Write failed for " + str(category))
			_cleanup_staged(staged)
			return false
	var committed := []
	for path in staged:
		if FileAccess.file_exists(path + ".bak"):
			if DirAccess.remove_absolute(path + ".bak") != OK:
				errors.append("Cannot rotate backup for " + str(path).get_file())
				_rollback(committed)
				_cleanup_staged(staged)
				return false
		if DirAccess.rename_absolute(path, path + ".bak") != OK:
			errors.append("Cannot back up " + str(path).get_file())
			_rollback(committed)
			_cleanup_staged(staged)
			return false
		if DirAccess.rename_absolute(path + ".tmp", path) != OK:
			DirAccess.rename_absolute(path + ".bak", path)
			errors.append("Cannot replace " + str(path).get_file())
			_rollback(committed)
			_cleanup_staged(staged)
			return false
		committed.append(path)
	for category in changed:
		originals[category] = documents[category].duplicate(true)
		hashes[category] = FileAccess.get_file_as_string(base_dir + str(category) + ".json").sha256_text()
	Catalog.clear_cache()
	return true

func _cleanup_staged(paths: Array) -> void:
	for path in paths:
		if FileAccess.file_exists(str(path) + ".tmp"):
			DirAccess.remove_absolute(str(path) + ".tmp")

func _rollback(paths: Array) -> void:
	for path in paths:
		DirAccess.remove_absolute(path)
		if DirAccess.rename_absolute(str(path) + ".bak", path) != OK:
			errors.append("Restore failed. Recover the .bak file for " + str(path).get_file())

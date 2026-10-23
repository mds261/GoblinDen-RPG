@tool
extends RefCounted
## Shared source of truth for runtime gameplay and the Godot data editor.
const ROOT := "res://data/catalog/"
const CATEGORIES := ["items", "monsters", "classes", "evolutions", "spells", "companions", "summons", "npcs", "travelers", "rooms", "stations", "landmarks", "interactables", "campaigns", "quests", "skills", "attributes", "equipment_slots", "labels"]
const PROTECTED := ["id", "index", "cell", "kind", "room", "pos", "point", "role", "base_class", "evolutions", "special_id", "service", "class", "evolution", "room_1", "room_2", "key"]
static var cache: Dictionary = {}

static func document(category: String) -> Dictionary:
	var parser := JSON.new()
	var result := parser.parse(FileAccess.get_file_as_string(ROOT + category + ".json"))
	if result != OK or not parser.data is Dictionary:
		push_error("Cannot read game data: " + category)
		return {}
	return parser.data

static func decode(value):
	if value is Dictionary:
		if value.get("_type") == "Vector2":
			return Vector2(float(value.x), float(value.y))
		if value.get("_type") == "Color":
			return Color(float(value.r), float(value.g), float(value.b), float(value.a))
		var result := {}
		for key in value:
			result[key] = decode(value[key])
		return result
	if value is Array:
		var result := []
		for entry in value:
			result.append(decode(entry))
		return result
	return value

static func table(category: String) -> Dictionary:
	if not cache.has(category):
		var entries := {}
		for entry in document(category).get("records", []):
			entries[str(entry.id)] = decode(entry)
		cache[category] = entries
	return cache[category]

static func record(category: String, id: String) -> Dictionary:
	return table(category).get(id, {})

static func entries(category: String) -> Array:
	return table(category).values().duplicate(true)

static func display(category: String, id: String, fallback: String = "") -> String:
	return str(record(category, id).get("name", fallback if fallback != "" else id))

static func class_table(category: String) -> Dictionary:
	var result := table(category).duplicate(true)
	for id in result:
		var special: Dictionary = record("spells", str(result[id].get("special_id", "")))
		result[id].special_name = special.get("name", "Special")
		result[id].special_cooldown = special.get("cooldown", 4.0)
	return result

static func loot_table() -> Dictionary:
	var result := {}
	for id in table("items"):
		if record("items", id).has("speed_mult"):
			result[id] = record("items", id).duplicate(true)
	return result

static func campaigns() -> Array:
	var result := entries("campaigns")
	for campaign in result:
		campaign.title = campaign.name
		for key in ["room_1", "room_2"]:
			var resolved := []
			for placement in campaign[key]:
				var monster: Dictionary = record("monsters", str(placement.enemy_id)).duplicate(true)
				monster.enemy_id = placement.enemy_id
				monster.pos = placement.pos
				resolved.append(monster)
			campaign[key] = resolved
	return result

static func room_names() -> Array:
	var result := []
	for room in entries("rooms"):
		result.append(room.name)
	return result

static func stations() -> Array:
	var result := entries("stations")
	for station in result:
		station.title = "E  " + str(station.name)
	return result

static func actions() -> Dictionary:
	var result := {}
	for id in table("spells"):
		if record("spells", id).get("kind") == "hotbar":
			result[id] = record("spells", id).duplicate(true)
	return result

static func attribute_defaults() -> Dictionary:
	var result := {}
	for entry in entries("attributes"):
		result[entry.id] = int(entry.starting_value)
	return result

static func clear_cache() -> void:
	cache.clear()

static func validate(documents: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	var schema = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "schema.json"))
	if not schema is Dictionary:
		return PackedStringArray(["The editor schema is missing or invalid."])
	for category in CATEGORIES:
		if not documents.has(category) or not documents[category] is Dictionary:
			errors.append("Missing category: " + category)
			continue
		var doc: Dictionary = documents[category]
		if doc.get("schema_version") != 1 or not doc.get("records") is Array:
			errors.append(category + ": invalid file structure")
			continue
		var seen := {}
		for entry in doc.records:
			if not entry is Dictionary:
				errors.append(category + ": entry must be an object")
				continue
			var id := str(entry.get("id", ""))
			var prefix: String = category + "/" + id + ": "
			if not schema[category].has(id) or seen.has(id):
				errors.append(prefix + "unknown or duplicate stable ID")
				continue
			seen[id] = true
			for field in schema[category][id]:
				if not entry.has(field):
					errors.append(prefix + "missing field " + field)
					continue
				var value = entry[field]
				var expected: String = schema[category][id][field]
				var valid := (expected == "number" and (value is int or value is float)) or (expected == "string" and value is String) or (expected == "bool" and value is bool) or (expected == "array" and value is Array) or (expected == "object" and value is Dictionary)
				if not valid:
					errors.append(prefix + field + " must be " + expected)
					continue
				if field == "name" and str(value).strip_edges().is_empty():
					errors.append(prefix + "display name cannot be empty")
				if expected == "number":
					if not is_finite(float(value)):
						errors.append(prefix + field + " must be finite")
					if field in ["hp", "stack", "level", "max_hp", "cooldown_mult", "speed_mult", "attack_cooldown", "special_cooldown"] and float(value) <= 0 and not (category == "items" and field == "max_hp"):
						errors.append(prefix + field + " must be greater than zero")
					if field in ["speed", "damage", "base_damage", "attack", "cost", "scrap", "xp", "cooldown", "range", "radius", "attack_range", "reward_scrap", "reward_xp", "kill_target", "starting_value"] and float(value) < 0:
						errors.append(prefix + field + " cannot be negative")
					if field in ["armor", "armor_bonus", "crit_chance", "crit_bonus", "defense"] and (float(value) < 0 or float(value) > 1):
						errors.append(prefix + field + " must be between 0 and 1")
					if field in ["hp", "max_hp", "damage", "base_damage", "attack", "level", "stack", "health", "heal", "cost", "scrap", "xp", "reward_scrap", "reward_xp", "kill_target", "starting_value"] and floorf(float(value)) != float(value):
						errors.append(prefix + field + " must be a whole number")
				if field == "icon_path" and str(value) != "" and (not str(value).begins_with("res://") or not FileAccess.file_exists(str(value)) or str(value).get_extension().to_lower() not in ["png", "jpg", "jpeg", "webp", "svg"]):
					errors.append(prefix + "icon path must refer to an image in this project")
				if field == "cooldown" and category == "spells" and entry.get("kind") == "class_special" and float(value) <= 0:
					errors.append(prefix + "class special cooldown must be greater than zero")
				if field == "slot" and str(value) not in ["necklace","helmet","weapon","shield","armor","legs","boots","ring"]:
					errors.append(prefix + "invalid equipment slot")
				if field == "loot" and str(value) != "" and not schema.items.has(str(value)):
					errors.append(prefix + "unknown loot item ID")
				if field == "skill" and not schema.skills.has(str(value)):
					errors.append(prefix + "unknown skill ID")
				if field == "icon_id" and not (schema.items.has(str(value)) or str(value) in ["potion","scrap","backpack","chest","scroll"]):
					errors.append(prefix + "unknown icon ID")
		if seen.size() != schema[category].size():
			errors.append(category + ": stable records cannot be deleted or have IDs changed")
	return errors

static func apply_summon(actor: Node, id: String) -> void:
	var definition := record("summons", id)
	actor.display_name = str(definition.name)
	actor.max_hp = int(definition.hp)
	actor.hp = actor.max_hp
	actor.speed = float(definition.speed)
	actor.damage = int(definition.damage)
	actor.attack_range = float(definition.attack_range)

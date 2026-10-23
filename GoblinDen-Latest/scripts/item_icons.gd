extends RefCounted
## One canonical icon mapping for UI, world loot and rewards.
const ATLAS = preload("res://assets/items/item_atlas.png")
const IDS := [
	"wood", "ore", "herb", "fish", "rust_sword", "iron_sword",
	"axe", "club", "bow", "staff", "shield", "cloth_armor",
	"helmet", "legs", "boots", "ring", "necklace", "rusty_sword",
	"hunter_shortbow", "priest_rosary", "captain_sword", "rogue_stiletto", "mage_ember_staff", "paladin_greatsword",
	"hero_dawnbreaker", "potion", "scrap", "backpack", "chest", "scroll"
]
static var cache: Dictionary = {}
static func get_icon(id: String) -> Texture2D:
	var definition: Dictionary = preload("res://scripts/design_catalog.gd").record("items", id)
	var path := str(definition.get("icon_path", ""))
	if path != "" and ResourceLoader.exists(path):
		return load(path) as Texture2D
	id = str(definition.get("icon_id", id))
	if not IDS.has(id):
		return null
	if not cache.has(id):
		var index := IDS.find(id)
		var cell := Vector2(ATLAS.get_width() / 6.0, ATLAS.get_height() / 5.0)
		var icon := AtlasTexture.new()
		icon.atlas = ATLAS
		icon.region = Rect2(Vector2(index % 6, index / 6) * cell, cell)
		icon.filter_clip = true
		cache[id] = icon
	return cache[id]

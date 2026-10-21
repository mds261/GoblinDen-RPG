extends RefCounted
## Persistent save/load using ConfigFile. Saves progression between runs.
## Stores to user://goblin_den_save.cfg

# Versioned for the single-goblin opening. Older prototype saves could begin
# with a fully recruited roster, so this update intentionally starts clean once.
const SAVE_PATH := "user://goblin_den_save_single_start_v2.cfg"

static func save(game: Node2D) -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progression", "scrap", game.scrap)
	cfg.set_value("progression", "blade_level", game.blade_level)
	cfg.set_value("progression", "trap_level", game.trap_level)
	cfg.set_value("progression", "shaman_level", game.shaman_level)
	cfg.set_value("progression", "potions", game.potions)
	cfg.set_value("progression", "max_potions", game.max_potions)
	cfg.set_value("progression", "campaign_index", game.campaign_index)
	cfg.set_value("progression", "captain_defeated", game.captain_defeated)
	cfg.set_value("progression", "completed", game.completed)
	# Player state
	var player = game.player
	cfg.set_value("player", "level", player.level)
	cfg.set_value("player", "xp", player.xp)
	cfg.set_value("player", "xp_to_next", player.xp_to_next)
	cfg.set_value("player", "class_id", player.class_id)
	cfg.set_value("player", "evolution_id", player.evolution_id)
	cfg.set_value("player", "attack_damage", player.attack_damage)
	cfg.set_value("player", "trap_bonus_damage", player.trap_bonus_damage)
	cfg.set_value("player", "ranged_bonus_damage", player.ranged_bonus_damage)
	cfg.set_value("player", "magic_bonus_damage", player.magic_bonus_damage)
	cfg.set_value("player", "equipped_loot_id", player.equipped_loot_id)
	# Loot & recruits
	cfg.set_value("unlocks", "loot", game.unlocked_loot)
	cfg.set_value("unlocks", "recruits", game.recruited_ids)
	# Stats tracking
	if game.has_method("get_stats"):
		var stats: Dictionary = game.get_stats()
		for key in stats:
			cfg.set_value("stats", key, stats[key])
	cfg.save(SAVE_PATH)

static func load_data(game: Node2D) -> bool:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return false
	var player = game.player
	# Restore progression
	game.scrap = int(cfg.get_value("progression", "scrap", 0))
	game.blade_level = int(cfg.get_value("progression", "blade_level", 1))
	game.trap_level = int(cfg.get_value("progression", "trap_level", 1))
	game.shaman_level = int(cfg.get_value("progression", "shaman_level", 1))
	game.potions = int(cfg.get_value("progression", "potions", 1))
	game.max_potions = int(cfg.get_value("progression", "max_potions", 2))
	game.campaign_index = int(cfg.get_value("progression", "campaign_index", 0))
	game.captain_defeated = bool(cfg.get_value("progression", "captain_defeated", false))
	game.completed = bool(cfg.get_value("progression", "completed", false))
	# Restore player state
	player.level = int(cfg.get_value("player", "level", 1))
	player.xp = int(cfg.get_value("player", "xp", 0))
	player.xp_to_next = int(cfg.get_value("player", "xp_to_next", 100))
	player.attack_damage = int(cfg.get_value("player", "attack_damage", 25))
	player.trap_bonus_damage = int(cfg.get_value("player", "trap_bonus_damage", 0))
	player.ranged_bonus_damage = int(cfg.get_value("player", "ranged_bonus_damage", 0))
	player.magic_bonus_damage = int(cfg.get_value("player", "magic_bonus_damage", 0))
	# Restore class/evolution
	var saved_class: String = str(cfg.get_value("player", "class_id", "blade"))
	var saved_evo: String = str(cfg.get_value("player", "evolution_id", ""))
	player.equipped_loot_id = str(cfg.get_value("player", "equipped_loot_id", ""))
	player.apply_class_and_gear(saved_class, saved_evo, false)
	# Restore loot array
	var saved_loot = cfg.get_value("unlocks", "loot", [])
	if saved_loot is Array:
		game.unlocked_loot.assign(saved_loot)
	# Restore recruit IDs
	var saved_recruits = cfg.get_value("unlocks", "recruits", [])
	if saved_recruits is Array:
		game.recruited_ids.assign(saved_recruits)
	return true

static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

static func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)

static func get_playtime(cfg: ConfigFile = ConfigFile.new()) -> float:
	cfg.load(SAVE_PATH)
	return float(cfg.get_value("stats", "total_playtime", 0.0))

extends RefCounted
## Contextual tutorial hint system. Shows guided tips for first-time interactions.
## Tracks which hints have been shown via a meta dict on the game node.

const HINTS := {
	"first_spawn": "Welcome home. Walk through the den tunnels to explore, then follow the eastern route toward daylight.",
	"near_forge": "The FORGE reforges your blade for more damage. Spend scrap to power up!",
	"near_rest": "Rest at the FIRE to restore HP, revive allies, and refill Bloodmoss Potions.",
	"near_training": "The TRAINING PIT lets you evolve into advanced specializations at Level 2+.",
	"near_archery": "The ARCHERY & TRAP SHOP upgrades trap damage and ranged precision.",
	"near_shaman": "The SHAMAN HUT brews healing potions and enhances your hex power.",
	"near_recruit": "The RECRUITMENT HUT lets you hire goblin followers to fight alongside you.",
	"near_treasure": "The TREASURE ROOM lets you equip stolen human weapons with unique tradeoffs.",
	"near_war_room": "The WAR ROOM launches escalating raid campaigns against human invaders.",
	"first_class_switch": "Press [1] Blade  [2] Archer  [3] Knight  [4] Mage to switch class at any time in the Den.",
	"first_special": "Press [Q] or Right Click to unleash your class Special Skill!",
	"first_dodge": "Press [SHIFT] to dodge — you get brief invulnerability during the dodge burst.",
	"first_evolution": "Press [C] to cycle class evolutions once you reach Level 2! Each evolution has unique powers.",
	"first_potion": "Press [F] to drink a Bloodmoss Potion — restores HP and coats weapons in venom.",
	"first_combat_room": "Follow the eastern tunnels toward daylight. Side chambers hold optional dangers.",
	"first_loot": "Stolen human weapons have stat tradeoffs. Press [I] to cycle equipped gear.",
	"first_codex": "Press [TAB] to open the Tribe Codex — your full status overview.",
	"first_scrap": "Scrap is your currency. Collect it from fallen enemies and spend it at Den facilities.",
	"first_level_up": "Level up to unlock Class Evolutions! Each level boosts your stats.",
	"first_party": "Your Goblin Party fights alongside you! Recruit up to 4 specialists.",
	"save_loaded": "Save data loaded! Your progression has been restored.",
	"save_created": "Progress auto-saved! It will be restored when you restart.",
}

static func should_show(game: Node2D, hint_id: String) -> bool:
	if not game.has_meta("tutorial_shown"):
		game.set_meta("tutorial_shown", {})
	var shown: Dictionary = game.get_meta("tutorial_shown")
	return not shown.has(hint_id)

static func mark_shown(game: Node2D, hint_id: String) -> void:
	if not game.has_meta("tutorial_shown"):
		game.set_meta("tutorial_shown", {})
	var shown: Dictionary = game.get_meta("tutorial_shown")
	shown[hint_id] = true
	game.set_meta("tutorial_shown", shown)

static func get_text(hint_id: String) -> String:
	if HINTS.has(hint_id):
		return HINTS[hint_id]
	return ""

static func show_if_new(game: Node2D, hint_id: String) -> bool:
	if should_show(game, hint_id):
		mark_shown(game, hint_id)
		if game.has_method("show_notice"):
			game.show_notice("💡 " + get_text(hint_id))
		return true
	return false

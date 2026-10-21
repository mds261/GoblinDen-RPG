extends RefCounted
## Central design data from the Goblin Perspective RPG Concept Document:
## Core classes, class evolutions, story-driven human loot, den facilities,
## inverted RPG goblin party roster, and escalating human adventuring campaigns.

const CLASSES := {
	"blade": {
		"id": "blade",
		"key": 1,
		"name": "BLADE GOBLIN",
		"role": "Fast melee striker",
		"summary": "Dual blades, crits, bleed, dodge, mobility",
		"max_hp": 100,
		"speed": 220.0,
		"base_damage": 25,
		"attack_range": 84.0,
		"attack_cooldown": 0.38,
		"armor": 0.0,
		"crit_chance": 0.22,
		"bleed_dps": 6,
		"poison_dps": 0,
		"ranged": false,
		"special_name": "SHADOW FLURRY",
		"special_cooldown": 3.8,
		"tint": Color(1.0, 1.0, 1.0),
		"evolutions": ["assassin", "berserker"]
	},
	"archer": {
		"id": "archer",
		"key": 2,
		"name": "ARCHER GOBLIN",
		"role": "Ranged hunter",
		"summary": "Bows, traps, poison arrows, stealth, kiting",
		"max_hp": 88,
		"speed": 236.0,
		"base_damage": 22,
		"attack_range": 370.0,
		"attack_cooldown": 0.42,
		"armor": 0.0,
		"crit_chance": 0.20,
		"bleed_dps": 0,
		"poison_dps": 6,
		"ranged": true,
		"special_name": "VENOM STARFALL",
		"special_cooldown": 3.2,
		"tint": Color(0.88, 1.05, 0.86),
		"evolutions": ["hunter", "beastmaster"]
	},
	"knight": {
		"id": "knight",
		"key": 3,
		"name": "KNIGHT GOBLIN",
		"role": "Front-line tank",
		"summary": "Shielding, armor, taunts, blocks, stuns, ally protection",
		"max_hp": 140,
		"speed": 192.0,
		"base_damage": 28,
		"attack_range": 90.0,
		"attack_cooldown": 0.45,
		"armor": 0.25,
		"crit_chance": 0.12,
		"bleed_dps": 3,
		"poison_dps": 0,
		"ranged": false,
		"special_name": "IRONQUAKE BULWARK",
		"special_cooldown": 4.2,
		"tint": Color(0.95, 0.96, 1.06),
		"evolutions": ["warlord", "guardian"]
	},
	"mage": {
		"id": "mage",
		"key": 4,
		"name": "MAGE GOBLIN",
		"role": "Fragile spellcaster",
		"summary": "Fire, poison, curses, crowd control, burst damage",
		"max_hp": 82,
		"speed": 208.0,
		"base_damage": 32,
		"attack_range": 350.0,
		"attack_cooldown": 0.48,
		"armor": 0.05,
		"crit_chance": 0.18,
		"bleed_dps": 0,
		"poison_dps": 7,
		"ranged": true,
		"special_name": "ASTRAL HEX NOVA",
		"special_cooldown": 4.0,
		"tint": Color(1.04, 0.86, 1.08),
		"evolutions": ["shaman", "warlock", "necromancer"]
	}
}

const EVOLUTIONS := {
	"assassin": {
		"id": "assassin",
		"base_class": "blade",
		"name": "ASSASSIN",
		"special_name": "NIGHTSTEP EXECUTION",
		"summary": "Lethal backstabs (+40% crit, venom + bleed burst, shadow step)",
		"hp_bonus": 15,
		"damage_bonus": 10,
		"speed_bonus": 28.0,
		"armor_bonus": 0.05,
		"crit_bonus": 0.28,
		"aura_color": Color("7cd49c")
	},
	"berserker": {
		"id": "berserker",
		"base_class": "blade",
		"name": "BERSERKER",
		"special_name": "BLOODSTORM CYCLONE",
		"summary": "Frenzied cleaver (+40 HP, lifesteal on hit, faster swings when wounded)",
		"hp_bonus": 40,
		"damage_bonus": 14,
		"speed_bonus": 16.0,
		"armor_bonus": 0.10,
		"crit_bonus": 0.12,
		"aura_color": Color("e35d44")
	},
	"hunter": {
		"id": "hunter",
		"base_class": "archer",
		"name": "HUNTER",
		"special_name": "PREDATOR'S ARROWSTORM",
		"summary": "3-arrow spread volley, armor-shredding razor traps, +25% crit",
		"hp_bonus": 20,
		"damage_bonus": 11,
		"speed_bonus": 22.0,
		"armor_bonus": 0.05,
		"crit_bonus": 0.25,
		"aura_color": Color("9ad96c")
	},
	"beastmaster": {
		"id": "beastmaster",
		"base_class": "archer",
		"name": "BEASTMASTER",
		"special_name": "PACK HUNT",
		"summary": "Summons a loyal Cave Fang Wolf companion & marks prey for the pack",
		"hp_bonus": 30,
		"damage_bonus": 9,
		"speed_bonus": 18.0,
		"armor_bonus": 0.08,
		"crit_bonus": 0.15,
		"aura_color": Color("d9a85b")
	},
	"warlord": {
		"id": "warlord",
		"base_class": "knight",
		"name": "WARLORD",
		"special_name": "CHIEFTAIN'S WARCRY",
		"summary": "Goblin Chief's Warcry buffs all goblin allies (+35% damage) & shockwave slams",
		"hp_bonus": 45,
		"damage_bonus": 13,
		"speed_bonus": 15.0,
		"armor_bonus": 0.12,
		"crit_bonus": 0.12,
		"aura_color": Color("f0b85d")
	},
	"guardian": {
		"id": "guardian",
		"base_class": "knight",
		"name": "GUARDIAN",
		"special_name": "AEGIS DOME",
		"summary": "Impenetrable bulwark (+65 HP, +20% armor, reflects blocked damage)",
		"hp_bonus": 65,
		"damage_bonus": 8,
		"speed_bonus": 6.0,
		"armor_bonus": 0.20,
		"crit_bonus": 0.08,
		"aura_color": Color("7fb8e6")
	},
	"shaman": {
		"id": "shaman",
		"base_class": "mage",
		"name": "SHAMAN",
		"special_name": "ANCESTRAL BLOOM",
		"summary": "Tribal healing pulse restores goblin party HP & coats weapons in venom",
		"hp_bonus": 30,
		"damage_bonus": 10,
		"speed_bonus": 14.0,
		"armor_bonus": 0.08,
		"crit_bonus": 0.12,
		"aura_color": Color("6cd995")
	},
	"warlock": {
		"id": "warlock",
		"base_class": "mage",
		"name": "WARLOCK",
		"special_name": "SOULFIRE METEOR",
		"summary": "Explosive hellfire bolts & life-draining abyssal curses",
		"hp_bonus": 20,
		"damage_bonus": 18,
		"speed_bonus": 12.0,
		"armor_bonus": 0.05,
		"crit_bonus": 0.20,
		"aura_color": Color("d668b8")
	},
	"necromancer": {
		"id": "necromancer",
		"base_class": "mage",
		"name": "NECROMANCER",
		"special_name": "GRAVE LEGION",
		"summary": "Raises fallen human bones as Risen Skeleton minions to fight for the den",
		"hp_bonus": 25,
		"damage_bonus": 12,
		"speed_bonus": 10.0,
		"armor_bonus": 0.08,
		"crit_bonus": 0.15,
		"aura_color": Color("8fd9c8")
	}
}

const LOOT_ITEMS := {
	"rusty_sword": {
		"id": "rusty_sword",
		"name": "Rusty Human Sword",
		"damage": 4,
		"max_hp": 0,
		"speed_mult": 1.0,
		"cooldown_mult": 1.0,
		"crit_bonus": 0.0,
		"armor_bonus": 0.0,
		"tradeoff": "Practical scavenged iron",
		"lore": "\"Standard militia issue. Chipped, blood-stained, and now goblin property.\""
	},
	"hunter_shortbow": {
		"id": "hunter_shortbow",
		"name": "Outrider's Recurve Bow",
		"damage": 8,
		"max_hp": 0,
		"speed_mult": 1.06,
		"cooldown_mult": 0.94,
		"crit_bonus": 0.08,
		"armor_bonus": 0.0,
		"tradeoff": "Lightweight (+6% move & attack speed)",
		"lore": "\"Carved from border-forest yew. Smells of pine resin and human arrogance.\""
	},
	"priest_rosary": {
		"id": "priest_rosary",
		"name": "Sun-Cleric's Relic Censer",
		"damage": 7,
		"max_hp": 25,
		"speed_mult": 1.0,
		"cooldown_mult": 0.95,
		"crit_bonus": 0.0,
		"armor_bonus": 0.05,
		"tradeoff": "Blessed metal (+25 HP, +5% armor)",
		"lore": "\"Still warm with stolen prayers. The gold chain makes a fine goblin belt.\""
	},
	"captain_sword": {
		"id": "captain_sword",
		"name": "Knight Captain's Sword",
		"damage": 18,
		"max_hp": 15,
		"speed_mult": 0.96,
		"cooldown_mult": 1.10,
		"crit_bonus": 0.05,
		"armor_bonus": 0.05,
		"tradeoff": "Strength +3 | Too Large: Attack speed -10%",
		"lore": "\"The previous owner probably wants this back.\""
	},
	"rogue_stiletto": {
		"id": "rogue_stiletto",
		"name": "Trapfinder's Twin Stiletto",
		"damage": 12,
		"max_hp": 0,
		"speed_mult": 1.10,
		"cooldown_mult": 0.84,
		"crit_bonus": 0.15,
		"armor_bonus": 0.0,
		"tradeoff": "Balanced for ambush (+16% attack speed, +15% crit)",
		"lore": "\"Forged for guild assassins in the dark. Fits a goblin grip like a claw.\""
	},
	"mage_ember_staff": {
		"id": "mage_ember_staff",
		"name": "Court Mage's Ember Staff",
		"damage": 20,
		"max_hp": -10,
		"speed_mult": 1.0,
		"cooldown_mult": 0.88,
		"crit_bonus": 0.12,
		"armor_bonus": 0.0,
		"tradeoff": "Volatile Focus (-10 Max HP, +12% spell & skill haste)",
		"lore": "\"Bound with rubies from the Royal Academy. Crackles when pointed at humans.\""
	},
	"paladin_greatsword": {
		"id": "paladin_greatsword",
		"name": "Royal Paladin's Sunblade",
		"damage": 26,
		"max_hp": 35,
		"speed_mult": 0.92,
		"cooldown_mult": 1.12,
		"crit_bonus": 0.08,
		"armor_bonus": 0.12,
		"tradeoff": "Massive Relic: +35 HP & +12% Armor | Attack speed -12%",
		"lore": "\"Inscribed with a royal oath to purge the caves. Irony is heavy.\""
	},
	"hero_dawnbreaker": {
		"id": "hero_dawnbreaker",
		"name": "Legendary Hero's Dawnbreaker",
		"damage": 35,
		"max_hp": 50,
		"speed_mult": 1.05,
		"cooldown_mult": 0.90,
		"crit_bonus": 0.20,
		"armor_bonus": 0.15,
		"tradeoff": "Mythic Trophy (+35 Dmg, +50 HP, +20% Crit, +15% Armor)",
		"lore": "\"Bards sang that this blade could never fall to monsters. The bards were wrong.\""
	}
}

const PARTY_ROSTER := [
	{
		"id": "goblin_blade",
		"name": "BLADE GOBLIN",
		"role": "blade",
		"cost": 4,
		"max_hp": 95,
		"speed": 225.0,
		"damage": 17,
		"range": 72.0,
		"summary": "Fast melee flanker who slips past shields to cut down the human backline"
	},
	{
		"id": "goblin_archer",
		"name": "ARCHER GOBLIN",
		"role": "archer",
		"cost": 4,
		"max_hp": 75,
		"speed": 200.0,
		"damage": 14,
		"range": 310.0,
		"summary": "Peppers human healers & mages with poisoned arrows from behind cover"
	},
	{
		"id": "goblin_knight",
		"name": "KNIGHT GOBLIN",
		"role": "knight",
		"cost": 5,
		"max_hp": 135,
		"speed": 188.0,
		"damage": 19,
		"range": 82.0,
		"summary": "Armored front-liner who pins enemies down behind a scavenged iron shield"
	},
	{
		"id": "goblin_mage",
		"name": "MAGE GOBLIN",
		"role": "mage",
		"cost": 5,
		"max_hp": 78,
		"speed": 204.0,
		"damage": 21,
		"range": 300.0,
		"summary": "Fragile spellcaster who hurls explosive hex bolts into clustered raiders"
	}
]

const CAMPAIGNS := [
	{
		"index": 0,
		"title": "TIER 1 (LV 1-5): THE BREACH INCURSION",
		"subtitle": "Border militia and the Iron Captain have broken into the outer tunnels.",
		"chokepoints": false,
		"room_1": [
			{"pos": Vector2(640, 340), "name": "SCOUT", "role": "knight", "hp": 60, "speed": 110.0, "damage": 15, "scrap": 3, "xp": 35, "loot": "rusty_sword"},
			{"pos": Vector2(880, 445), "name": "GUARD", "role": "knight", "hp": 80, "speed": 95.0, "damage": 18, "scrap": 3, "xp": 45, "loot": ""}
		],
		"room_2": [
			{"pos": Vector2(760, 360), "name": "IRON CAPTAIN", "role": "boss", "hp": 180, "speed": 115.0, "damage": 25, "scrap": 8, "xp": 120, "loot": "captain_sword"}
		]
	},
	{
		"index": 1,
		"title": "TIER 2 (LV 5-15): GUILD SCOUTING PARTY",
		"subtitle": "Warriors, ranged archers, and a healing priest coordinate their advance.",
		"chokepoints": true,
		"room_1": [
			{"pos": Vector2(600, 330), "name": "GUILD WARRIOR", "role": "knight", "hp": 115, "speed": 105.0, "damage": 20, "scrap": 4, "xp": 55, "loot": ""},
			{"pos": Vector2(830, 250), "name": "WOODLAND RANGER", "role": "ranger", "hp": 80, "speed": 122.0, "damage": 17, "scrap": 4, "xp": 55, "loot": "hunter_shortbow"},
			{"pos": Vector2(890, 460), "name": "NOVICE PRIEST", "role": "priest", "hp": 78, "speed": 100.0, "damage": 14, "scrap": 4, "xp": 65, "loot": "priest_rosary"}
		],
		"room_2": [
			{"pos": Vector2(650, 360), "name": "SHIELD VANGUARD", "role": "knight", "hp": 155, "speed": 105.0, "damage": 24, "scrap": 5, "xp": 80, "loot": ""},
			{"pos": Vector2(870, 300), "name": "GUILD PYROMANCER", "role": "mage", "hp": 135, "speed": 102.0, "damage": 28, "scrap": 7, "xp": 110, "loot": "mage_ember_staff"},
			{"pos": Vector2(890, 455), "name": "SHRINE CLERIC", "role": "priest", "hp": 95, "speed": 100.0, "damage": 15, "scrap": 4, "xp": 75, "loot": ""}
		]
	},
	{
		"index": 2,
		"title": "TIER 3 (LV 15-30): VETERAN MONSTER HUNTERS",
		"subtitle": "Trap-hunting rogues, veteran knights, and monster-slaying specialists.",
		"chokepoints": true,
		"room_1": [
			{"pos": Vector2(580, 360), "name": "VETERAN KNIGHT", "role": "knight", "hp": 160, "speed": 108.0, "damage": 24, "scrap": 5, "xp": 80, "loot": ""},
			{"pos": Vector2(730, 220), "name": "TRAPFINDER ROGUE", "role": "rogue", "hp": 110, "speed": 150.0, "damage": 22, "scrap": 5, "xp": 85, "loot": "rogue_stiletto"},
			{"pos": Vector2(890, 330), "name": "CROSSBOW ARBALEST", "role": "ranger", "hp": 105, "speed": 120.0, "damage": 23, "scrap": 5, "xp": 80, "loot": ""},
			{"pos": Vector2(910, 480), "name": "ABBEY PRIEST", "role": "priest", "hp": 110, "speed": 102.0, "damage": 16, "scrap": 5, "xp": 85, "loot": ""}
		],
		"room_2": [
			{"pos": Vector2(690, 360), "name": "HUNTMASTER VANE", "role": "boss", "hp": 290, "speed": 126.0, "damage": 34, "scrap": 10, "xp": 190, "loot": "rogue_stiletto"},
			{"pos": Vector2(880, 250), "name": "ARCANE INQUISITOR", "role": "mage", "hp": 140, "speed": 105.0, "damage": 30, "scrap": 6, "xp": 110, "loot": ""},
			{"pos": Vector2(880, 470), "name": "HIGH CONFESSOR", "role": "priest", "hp": 125, "speed": 104.0, "damage": 18, "scrap": 6, "xp": 105, "loot": ""}
		]
	},
	{
		"index": 3,
		"title": "TIER 4 (LV 30+): ROYAL PALADIN CRUSADE",
		"subtitle": "Royal knights, court mages, and a Grand Paladin sent by the Crown.",
		"chokepoints": true,
		"room_1": [
			{"pos": Vector2(580, 280), "name": "ROYAL TEMPLAR", "role": "knight", "hp": 210, "speed": 112.0, "damage": 29, "scrap": 6, "xp": 115, "loot": ""},
			{"pos": Vector2(610, 450), "name": "CROWN GUARDIAN", "role": "knight", "hp": 210, "speed": 108.0, "damage": 28, "scrap": 6, "xp": 115, "loot": ""},
			{"pos": Vector2(860, 250), "name": "COURT ARCHMAGE", "role": "mage", "hp": 160, "speed": 108.0, "damage": 35, "scrap": 7, "xp": 130, "loot": "mage_ember_staff"},
			{"pos": Vector2(900, 460), "name": "SUN BISHOP", "role": "priest", "hp": 150, "speed": 105.0, "damage": 20, "scrap": 6, "xp": 125, "loot": ""}
		],
		"room_2": [
			{"pos": Vector2(680, 360), "name": "GRAND PALADIN AURELIUS", "role": "boss", "hp": 400, "speed": 122.0, "damage": 42, "scrap": 14, "xp": 280, "loot": "paladin_greatsword"},
			{"pos": Vector2(860, 240), "name": "ROYAL LONGBOWMAN", "role": "ranger", "hp": 155, "speed": 128.0, "damage": 28, "scrap": 6, "xp": 120, "loot": ""},
			{"pos": Vector2(890, 480), "name": "CATHEDRAL ORACLE", "role": "priest", "hp": 160, "speed": 106.0, "damage": 22, "scrap": 7, "xp": 135, "loot": ""}
		]
	},
	{
		"index": 4,
		"title": "ENDGAME: LEGENDARY HERO PARTY",
		"subtitle": "The realm's undefeated Hero Party descends to finish your goblin tribe.",
		"chokepoints": true,
		"room_1": [
			{"pos": Vector2(560, 340), "name": "CHAMPION VANGUARD", "role": "knight", "hp": 250, "speed": 116.0, "damage": 32, "scrap": 8, "xp": 150, "loot": ""},
			{"pos": Vector2(720, 210), "name": "NIGHTBLADE ASSASSIN", "role": "rogue", "hp": 180, "speed": 160.0, "damage": 30, "scrap": 8, "xp": 150, "loot": ""},
			{"pos": Vector2(870, 290), "name": "ARCH-SORCERESS", "role": "mage", "hp": 185, "speed": 112.0, "damage": 38, "scrap": 8, "xp": 160, "loot": ""},
			{"pos": Vector2(910, 470), "name": "SAINT OF LIGHT", "role": "priest", "hp": 180, "speed": 108.0, "damage": 24, "scrap": 8, "xp": 160, "loot": ""}
		],
		"room_2": [
			{"pos": Vector2(650, 360), "name": "THE DAWN HERO", "role": "boss", "hp": 540, "speed": 132.0, "damage": 48, "scrap": 20, "xp": 450, "loot": "hero_dawnbreaker"},
			{"pos": Vector2(580, 230), "name": "HERO'S SHIELD-SWORN", "role": "knight", "hp": 240, "speed": 114.0, "damage": 30, "scrap": 7, "xp": 150, "loot": ""},
			{"pos": Vector2(790, 215), "name": "HERO'S SHADOW", "role": "rogue", "hp": 175, "speed": 158.0, "damage": 28, "scrap": 7, "xp": 150, "loot": ""},
			{"pos": Vector2(880, 340), "name": "HERO'S DEADEYE", "role": "ranger", "hp": 175, "speed": 130.0, "damage": 30, "scrap": 7, "xp": 150, "loot": ""},
			{"pos": Vector2(890, 495), "name": "HERO'S HIGH SAINT", "role": "priest", "hp": 190, "speed": 110.0, "damage": 24, "scrap": 8, "xp": 170, "loot": ""}
		]
	}
]

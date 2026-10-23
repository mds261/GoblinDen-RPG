extends RefCounted
const Catalog = preload("res://scripts/design_catalog.gd")
## Central design data from the Goblin Perspective RPG Concept Document:
## Core classes, class evolutions, story-driven human loot, den facilities,
## inverted RPG goblin party roster, and escalating human adventuring campaigns.

static var CLASSES: Dictionary = Catalog.class_table("classes")

static var EVOLUTIONS: Dictionary = Catalog.class_table("evolutions")

static var LOOT_ITEMS: Dictionary = Catalog.loot_table()

static var PARTY_ROSTER: Array = Catalog.entries("companions")

static var CAMPAIGNS: Array = Catalog.campaigns()


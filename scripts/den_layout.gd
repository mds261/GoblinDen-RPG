extends RefCounted
## Stable combat IDs 0-6; new safe rooms are appended for save compatibility.
const TREASURY := 7
const ARMORY := 8
const STRATEGY := 9
const ROOM_FLOOR := Rect2(110, 170, 932, 435)
const STATIONS := [
	{"cell": 0, "room": ARMORY, "pos": Vector2(350, 350), "title": "E  FORGE"},
	{"cell": 1, "room": 0, "pos": Vector2(410, 350), "title": "E  REST"},
	{"cell": 2, "room": STRATEGY, "pos": Vector2(350, 350), "title": "E  TRAINING"},
	{"cell": 3, "room": ARMORY, "pos": Vector2(760, 350), "title": "E  ARCHERY/TRAPS"},
	{"cell": 4, "room": 0, "pos": Vector2(750, 350), "title": "E  SHAMAN HUT"},
	{"cell": 5, "room": STRATEGY, "pos": Vector2(800, 350), "title": "E  RECRUIT PARTY"},
	{"cell": 6, "room": TREASURY, "pos": Vector2(575, 350), "title": "E  TREASURE/LOOT"},
	{"cell": 7, "room": STRATEGY, "pos": Vector2(575, 430), "title": "E  WAR TABLE"}
]
const PORTALS := {
	0: [
		{"to": TREASURY, "pos": Vector2(150, 365), "spawn": Vector2(920, 365), "title": "TREASURE ROOM"},
		{"to": ARMORY, "pos": Vector2(575, 170), "spawn": Vector2(575, 490), "title": "ARMORY"},
		{"to": STRATEGY, "pos": Vector2(575, 550), "spawn": Vector2(575, 245), "title": "STRATEGY ROOM"}
	],
	TREASURY: [
		{"to": 0, "pos": Vector2(1010, 365), "spawn": Vector2(235, 365), "title": "MAIN HALL"},
		{"to": ARMORY, "pos": Vector2(575, 170), "spawn": Vector2(225, 365), "title": "ARMORY"}
	],
	ARMORY: [
		{"to": 0, "pos": Vector2(575, 550), "spawn": Vector2(575, 250), "title": "MAIN HALL"},
		{"to": TREASURY, "pos": Vector2(150, 365), "spawn": Vector2(575, 245), "title": "TREASURE ROOM"},
		{"to": STRATEGY, "pos": Vector2(1010, 365), "spawn": Vector2(235, 365), "title": "STRATEGY ROOM"}
	],
	STRATEGY: [
		{"to": 0, "pos": Vector2(575, 170), "spawn": Vector2(575, 470), "title": "MAIN HALL"},
		{"to": ARMORY, "pos": Vector2(150, 365), "spawn": Vector2(920, 365), "title": "ARMORY"}
	]
}
static func is_safe(room: int) -> bool:
	return room == 0 or room in [TREASURY, ARMORY, STRATEGY]
static func station_position(cell: int) -> Vector2:
	return STATIONS[cell]["pos"]
static func station_room(cell: int) -> int:
	return STATIONS[cell]["room"]
static func footprint(cell: int) -> Rect2:
	var size := Vector2(104, 42) if cell != 1 else Vector2(64, 44)
	return Rect2(station_position(cell) - size * 0.5 + Vector2(0, -4), size)

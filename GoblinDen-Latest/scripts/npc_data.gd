extends RefCounted
## Names and dialogue are provisional; stable IDs are used by the save system.
static var RESIDENTS: Array = _residents()
static func _residents() -> Array:
	var residents: Array = preload("res://scripts/design_catalog.gd").entries("npcs")
	var layout = preload("res://scripts/starting_caves.gd")
	for resident in residents:
		if layout.connected(int(resident.room)):
			resident.point = layout.point(int(resident.room),resident.point)
			resident.room = 0
	return residents


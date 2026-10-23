extends RefCounted
## Shared visual/collision/navigation geometry for the three quest floors.
const FIRST := 13
const LAST := 15
const SIZE := Vector2(2880, 1920)
const TILE := 64
const ROOMS := [Rect2(128,128,640,448),Rect2(992,128,640,448),Rect2(1856,128,896,576),Rect2(128,832,640,448),Rect2(992,832,640,448),Rect2(1856,832,896,448),Rect2(992,1536,640,256),Rect2(1856,1536,896,256)]
const CORRIDORS := [Rect2(768,288,224,128),Rect2(1632,288,224,128),Rect2(1232,576,144,256),Rect2(768,992,224,128),Rect2(1632,992,224,128),Rect2(1232,1280,144,256),Rect2(2304,1280,144,256)]
const ARENA := Rect2(1856,832,896,960)
static func is_dungeon(room: int) -> bool:
	return room >= FIRST and room <= LAST
static func point(original: Vector2, floor_id: int) -> Vector2:
	return Vector2(SIZE.x - original.x, original.y) if floor_id == 14 else original
static func rect(original: Rect2, floor_id: int) -> Rect2:
	return Rect2(SIZE.x - original.end.x, original.position.y, original.size.x, original.size.y) if floor_id == 14 else original
static func walkable(world_point: Vector2, floor_id: int) -> bool:
	# Navigation and physics both use the same occupied 64px wall cells.
	var cell_center := (world_point / float(TILE)).floor() * TILE + Vector2.ONE * TILE * 0.5
	var p := point(cell_center, floor_id)
	if floor_id == LAST and ARENA.has_point(p):
		return true
	for room in ROOMS + CORRIDORS:
		if room.has_point(p):
			return true
	return false
static func entry(floor_id: int) -> Vector2:
	return point(Vector2(256,288), floor_id)
static func stairs(floor_id: int) -> Vector2:
	return point(Vector2(1450,1664), floor_id)
static func seals(floor_id: int) -> Array:
	var locations := [Vector2(2350,400),Vector2(440,1050)] if floor_id == 13 else [Vector2(2350,400),Vector2(2350,1664)]
	return [point(locations[0],floor_id),point(locations[1],floor_id)]

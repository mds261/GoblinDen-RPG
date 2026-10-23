extends RefCounted
## One physical map. Legacy room IDs only identify placements and saved loot.
const SIZE := Vector2(4608,2816)
const TILE := 64
const IDS := [0,7,8,9,1,2,3,4]
const CHAMBERS := {
	0:Rect2(128,1024,1024,640),7:Rect2(128,192,768,512),
	8:Rect2(128,1984,896,640),9:Rect2(1344,1984,896,640),
	1:Rect2(1408,1088,768,512),2:Rect2(2496,1088,896,640),
	3:Rect2(2496,192,896,576),4:Rect2(3648,1024,832,704)
}
const NAMES := {0:"HEARTH HALL",7:"TREASURE ALCOVE",8:"ARMORY",9:"TRIBE QUARTERS",1:"WATCH TUNNELS",2:"THE BREACH",3:"ROOTVEIN NEST",4:"DAYLIGHT GROTTO"}
const TUNNELS := [Rect2(1152,1248,256,192),Rect2(2176,1248,320,192),Rect2(3392,1248,256,192),Rect2(448,704,192,320),Rect2(448,1664,192,320),Rect2(1024,2208,320,192),Rect2(1696,1600,192,384),Rect2(2848,768,192,320),Rect2(896,384,1600,192)]
const EXIT := Vector2(4320,1376)
const CHEST := Vector2(360,1472)
const START := Vector2(640,1408)
static func connected(room: int) -> bool:
	return room in IDS
static func point(room: int, old: Vector2) -> Vector2:
	if not connected(room):
		return old
	var bounds: Rect2 = CHAMBERS[room].grow(-96)
	var uv := (old-Vector2(100,160))/Vector2(952,440)
	return bounds.position+uv.clamp(Vector2.ZERO,Vector2.ONE)*bounds.size
static func walkable(p: Vector2) -> bool:
	var center := (p/64.0).floor()*64.0+Vector2(32,32)
	for id in IDS:
		var rect: Rect2 = CHAMBERS[id]
		if rect.has_point(center):
			# Clip chamber corners into rock; tunnels meet flat wall faces.
			var q := (center-rect.get_center()).abs()
			if q.x+q.y<rect.size.x*0.5+rect.size.y*0.5-92:
				return true
	for tunnel in TUNNELS:
		if tunnel.has_point(center):
			return true
	return false
static func zone(p: Vector2) -> int:
	for id in IDS:
		if CHAMBERS[id].has_point(p):
			return id
	return -1
static func safe(p: Vector2) -> bool:
	return zone(p) in [0,7,8,9]

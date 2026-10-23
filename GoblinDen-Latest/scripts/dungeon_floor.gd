extends Node2D
const Layout = preload("res://scripts/dungeon_layout.gd")
const Materials = preload("res://assets/descent/stone_materials.png")
const Chambers = preload("res://assets/descent/chamber_floors.png")
var room_id := 13
var walls: Array[StaticBody2D] = []
var active := false
func _ready() -> void:
	z_index = -1
	# Merge contiguous wall tiles into rows: bounded collider count, same geometry as AStar.
	for y in range(30):
		var start := -1
		for x in range(46):
			var solid := x < 45 and not Layout.walkable(Vector2(x*64+32,y*64+32), room_id)
			if solid and start < 0:
				start = x
			if not solid and start >= 0:
				var wall := StaticBody2D.new()
				wall.position = Vector2((start+x)*32,y*64+32)
				var shape := RectangleShape2D.new()
				shape.size = Vector2((x-start)*64,64)
				var collision := CollisionShape2D.new()
				collision.shape = shape
				wall.add_child(collision)
				add_child(wall)
				walls.append(wall)
				start = -1
	set_collision_active(active)
func set_collision_active(enabled: bool) -> void:
	active = enabled
	for wall in walls:
		wall.collision_layer = 1 if enabled else 0
		wall.collision_mask = 2 if enabled else 0
func _draw() -> void:
	var half := Materials.get_size() * 0.5
	var tint: Color = [Color(0.92,1.0,0.91),Color(0.88,0.94,1.0),Color(1.0,0.92,0.79)][room_id-13]
	for y in range(30):
		for x in range(45):
			var tile := Rect2(x*64,y*64,64,64)
			var open := Layout.walkable(tile.get_center(),room_id)
			var origin := Vector2.ZERO if open else Vector2(half.x,0)
			var sample := Rect2(origin + Vector2(x%4,y%4) * half / 4.0,half / 4.0)
			draw_texture_rect_region(Materials,tile,sample,tint if open else Color(0.38,0.42,0.39))
			if open:
				var chamber_half := Chambers.get_size()*0.5
				var room_rect := Rect2()
				var room_index := 0
				for i in range(Layout.ROOMS.size()):
					var bounds: Rect2 = Layout.rect(Layout.ROOMS[i],room_id)
					var from := ((bounds.position-Vector2.ONE*32.0)/64.0).ceil()*64.0
					var end := ((bounds.end-Vector2.ONE*32.0)/64.0).ceil()*64.0
					bounds = Rect2(from,end-from)
					if bounds.has_point(tile.get_center()):
						room_rect = bounds
						room_index = (i+room_id-13)%3
						break
				if room_id == 15 and Layout.ARENA.has_point(tile.get_center()):
					room_rect = Rect2(1856,832,896,960)
					room_index = 3
				if room_rect.size.x > 0:
					var uv := Rect2(Vector2(room_index%2,room_index/2)*chamber_half+(tile.position-room_rect.position)/room_rect.size*chamber_half,tile.size/room_rect.size*chamber_half)
					draw_texture_rect_region(Chambers,tile,uv,tint)
				# Soft contact shade meets the exact shared collision boundary.
				for direction in [Vector2.UP,Vector2.LEFT,Vector2.RIGHT,Vector2.DOWN]:
					if not Layout.walkable(tile.get_center()+direction*64,room_id):
						for depth in range(8):
							var from := tile.position
							var to := from+Vector2(64,0)
							if direction == Vector2.UP:
								from.y += depth*2
								to.y = from.y
							elif direction == Vector2.DOWN:
								from.y += 64-depth*2
								to.y = from.y
							else:
								from.x += depth*2 if direction == Vector2.LEFT else 64-depth*2
								to = from+Vector2(0,64)
							draw_line(from,to,Color(0.01,0.015,0.01,0.23-float(depth)*0.027),2)
			elif Layout.walkable(tile.get_center()+Vector2(0,64),room_id):
				# Painted exposed vertical masonry, all of it within solid cells.
				var face := Rect2(tile.position+Vector2(0,24),Vector2(64,40))
				var region := Rect2(Vector2((x%4)*half.x/4.0,half.y),Vector2(half.x/4.0,half.y*0.45))
				draw_texture_rect_region(Materials,face,region,tint)
				draw_line(tile.position+Vector2(0,24),tile.position+Vector2(64,24),Color(0.55,0.49,0.31,0.5),2)
				draw_line(tile.position+Vector2(0,63),tile.position+Vector2(64,63),Color(0.02,0.025,0.02,0.8),3)

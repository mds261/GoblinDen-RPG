extends Node2D
const Layout = preload("res://scripts/starting_caves.gd")
const MATERIAL = preload("res://assets/descent/starting_cave_materials.png")
var walls: Array[StaticBody2D] = []
func _ready() -> void:
	z_index = -2
	for y in range(44):
		var start := -1
		for x in range(73):
			var solid := x<72 and not Layout.walkable(Vector2(x*64+32,y*64+32))
			if solid and start<0:
				start = x
			if not solid and start>=0:
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
func set_collision_active(active: bool) -> void:
	for wall in walls:
		wall.collision_layer = 1 if active else 0
		wall.collision_mask = 2 if active else 0
func _draw() -> void:
	var half := MATERIAL.get_size()*0.5
	for y in range(44):
		for x in range(72):
			var tile := Rect2(x*64,y*64,64,64)
			var p := tile.get_center()
			var open := Layout.walkable(p)
			var zone := Layout.zone(p)
			var swatch := Vector2(1,0) if not open else (Vector2(1,1) if zone==3 else (Vector2(0,1) if zone in [0,7,8,9] else Vector2.ZERO))
			var uv := Rect2(swatch*half+Vector2(x%6,y%6)*half/6.0,half/6.0)
			draw_texture_rect_region(MATERIAL,tile,uv,Color.WHITE if open else Color(0.42,0.43,0.40))
			if open:
				for direction in [Vector2.UP,Vector2.DOWN,Vector2.LEFT,Vector2.RIGHT]:
					if not Layout.walkable(p+direction*64):
						for depth in range(10):
							var from := tile.position
							var to := from+Vector2(64,0)
							if direction==Vector2.DOWN:
								from.y += 64-depth*2
								to.y = from.y
							elif direction==Vector2.UP:
								from.y += depth*2
								to.y = from.y
							else:
								from.x += depth*2 if direction==Vector2.LEFT else 64-depth*2
								to = from+Vector2(0,64)
							draw_line(from,to,Color(0.025,0.018,0.012,0.32-depth*0.03),2)
			elif Layout.walkable(p+Vector2(0,64)):
				# Warm exposed wall face above the walkable edge.
				draw_texture_rect_region(MATERIAL,Rect2(tile.position+Vector2(0,22),Vector2(64,42)),uv,Color(0.85,0.78,0.65))
				draw_line(tile.position+Vector2(0,64),tile.end,Color(0.07,0.04,0.02,0.8),3)
	# Soft daylight wash at the only surface exit.
	for ring in range(10,0,-1):
		draw_circle(Layout.EXIT+Vector2(65,0),ring*17,Color(0.9,0.92,0.64,0.015))

extends Node2D
const Art = preload("res://scripts/descent_art.gd")
const SHEET = preload("res://assets/descent/dungeon_dressing.png")
var kind := 0
var age := 0.0
var sprite: Texture2D
func _ready() -> void:
	z_as_relative = false
	z_index = int(position.y) - 1
	var cell := Vector2i(SHEET.get_size()) / Vector2i(3,2)
	sprite = Art.trimmed(SHEET,Rect2i(Vector2i(kind%3,kind/3)*cell,cell),"dressing_%d" % kind)
func _process(delta: float) -> void:
	if kind <= 1:
		age += delta
		queue_redraw()
func _draw() -> void:
	if sprite == null:
		return
	if kind <= 1:
		var glow := Vector2(0,-24)
		for ring in range(9,0,-1):
			draw_circle(glow,float(ring)*11.0,Color(1,0.55,0.16,0.008*(1+sin(age*4+position.x)*0.08)))
	var box: Vector2 = [Vector2(55,98),Vector2(80,100),Vector2(75,135),Vector2(75,65),Vector2(88,65),Vector2(175,200)][kind]
	draw_texture_rect(sprite,Art.fitted(sprite,Vector2.ZERO,box,0.86),false)

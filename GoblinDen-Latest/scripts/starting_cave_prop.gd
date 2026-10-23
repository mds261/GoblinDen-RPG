extends Node2D
const Art = preload("res://scripts/descent_art.gd")
const SHEET = preload("res://assets/descent/starting_cave_props.png")
var kind := 0
var caption := ""
var game: Node2D
func _ready() -> void:
	z_index = int(position.y)-1
func _process(_delta: float) -> void:
	if not caption.is_empty():
		queue_redraw()
func _draw() -> void:
	var texture: Texture2D
	var box := Vector2(105,140)
	if kind==4:
		texture = Art.prop(4)
		box = Vector2(105,90)
	else:
		var regions := [Rect2i(0,0,768,548),Rect2i(768,0,768,520),Rect2i(0,548,768,476),Rect2i(768,520,768,504)]
		texture = Art.trimmed(SHEET,regions[kind],"starting_prop_%d"%kind)
		box = [Vector2(100,145),Vector2(260,240),Vector2(195,130),Vector2(210,170)][kind]
	draw_texture_rect(texture,Art.fitted(texture,Vector2.ZERO,box,0.82),false)
	if game!=null and not caption.is_empty() and game.player.position.distance_to(position)<220:
		var font := ThemeDB.fallback_font
		var p := Vector2(-font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x*0.5,-box.y-3)
		draw_string_outline(font,p,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,4,Color(0.03,0.04,0.02,0.95))
		draw_string(font,p,caption,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("dfcf9c"))

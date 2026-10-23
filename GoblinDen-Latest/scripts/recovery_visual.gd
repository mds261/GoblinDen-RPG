extends Node2D
## World art follows loot records; inventory and persistence stay in RpgSystems.
const Art = preload("res://scripts/descent_art.gd")
const SHEET = preload("res://assets/descent/recovery_bundle.png")
var record: Dictionary = {}
var rpg: Node2D
var monster := false

func _process(_delta: float) -> void:
	visible = not record.is_empty() and int(record.room)==rpg.game.current_room
	if not visible:
		return
	position = record.position + (Vector2(22,12) if monster else Vector2.ZERO)
	z_index = clampi(int(position.y),-4000,3800)
	queue_redraw()

func _draw() -> void:
	if record.is_empty():
		return
	var texture := Art.trimmed(SHEET,Rect2i(Vector2i.ZERO,Vector2i(SHEET.get_size())),"recovery_bundle")
	var size := Vector2(43,34) if monster else Vector2(72,54)
	var nearby: bool = rpg.game.player.position.distance_to(record.position)<100.0
	# A soft contact shadow grounds the bundle without a hovering icon.
	draw_set_transform(Vector2(0,3),0,Vector2(1,0.32))
	draw_circle(Vector2.ZERO,size.x*0.39,Color(0.07,0.05,0.025,0.30))
	if nearby:
		draw_arc(Vector2.ZERO,size.x*0.48,0,TAU,48,Color(0.78,0.76,0.45,0.48),1.5,true)
	draw_set_transform(Vector2.ZERO)
	draw_texture_rect(texture,Art.fitted(texture,Vector2.ZERO,size,0.80),false)
	if not monster and nearby:
		var seconds := maxi(0,int(record.remaining))
		var text := "Recover gear · %02d:%02d" % [seconds/60,seconds%60]
		var font := ThemeDB.fallback_font
		var point := Vector2(-font.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x*0.5,-49)
		draw_string_outline(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,3,Color(0.06,0.07,0.04,0.95))
		draw_string(font,point,text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("dfd6b2"))

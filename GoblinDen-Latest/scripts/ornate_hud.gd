extends Control
## Compact vitals, quiet location text, and only useful combat status.
var game: Node2D
var portraits: Dictionary = {}
var face: Font
const GOLD = Color("ad9360")
const PALE = Color("e9dec4")
const MUTED = Color("b4b7a4")
func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	face = SystemFont.new()
	face.font_names = PackedStringArray(["Georgia", "DejaVu Serif", "serif"])
	for id in ["blade", "archer", "knight", "mage"]:
		portraits[id] = load("res://assets/goblin_class_%s.png" % id)
func _process(_delta: float) -> void:
	visible = not get_tree().paused
	queue_redraw()
func text_at(value: String, point: Vector2, size_px: int = 12, color: Color = PALE, width: float = -1, serif: bool = false) -> void:
	draw_string(face if serif else ThemeDB.fallback_font,point+Vector2(0,1),value,HORIZONTAL_ALIGNMENT_LEFT,width,size_px,Color(0,0,0,0.9))
	draw_string(face if serif else ThemeDB.fallback_font,point,value,HORIZONTAL_ALIGNMENT_LEFT,width,size_px,color)
func bar(at: Vector2, width: float, height: float, value: float, maximum: float, color: Color) -> void:
	draw_rect(Rect2(at-Vector2.ONE,Vector2(width+2,height+2)),GOLD.darkened(0.55))
	draw_rect(Rect2(at,Vector2(width,height)),Color("0c1110"))
	var fill := clampf(value/maxf(1,maximum),0,1)*width
	if fill > 0:
		draw_rect(Rect2(at,Vector2(fill,height)),color.darkened(0.15))
		draw_line(at,at+Vector2(fill,0),color.lightened(0.3),1)
func frame() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025,0.042,0.036,0.89)
	style.border_color = Color(0.5,0.43,0.29,0.75)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style
func ability(at: Vector2, key: String, title: String, detail: String, ready: bool) -> void:
	draw_style_box(frame(),Rect2(at,Vector2(58,43)))
	text_at(key,at+Vector2(8,15),11,GOLD)
	text_at(detail,at+Vector2(8,33),12,PALE if ready else MUTED)
	text_at(title,at+Vector2(1,-6),10,MUTED)
func _draw() -> void:
	if game == null or not is_instance_valid(game.player):
		return
	var p = game.player
	var r = game.rpg
	draw_style_box(frame(),Rect2(20,18,310,91))
	var center := Vector2(57,58)
	draw_circle(center,28,Color("111a14"))
	draw_arc(center,28,0,TAU,48,GOLD,1,true)
	var portrait: Texture2D = portraits.get(p.class_id)
	if portrait != null:
		draw_texture_rect(portrait,Rect2(33,27,48,56),false)
	text_at("%s  ·  %d" % [p.get_class_title(),p.level],Vector2(96,37),14,PALE,220,true)
	bar(Vector2(96,47),214,13,p.hp,p.max_hp,Color("9e453d"))
	text_at("%d / %d" % [p.hp,p.max_hp],Vector2(168,58),10)
	if r != null:
		bar(Vector2(96,67),103,6,r.mana,r.max_mana(),Color("41768b"))
		bar(Vector2(207,67),103,6,r.stamina,100,Color("768951"))
		text_at("Mana %d" % r.mana,Vector2(96,87),10,MUTED)
		text_at("Stamina %d" % r.stamina,Vector2(207,87),10,MUTED)
	bar(Vector2(96,96),214,3,p.xp,p.xp_to_next,Color("aa8b50"))
	text_at("Lv %d" % p.level,Vector2(43,98),11,GOLD)
	text_at(game.room_label.text.to_upper(),Vector2(365,37),18,PALE,510,true)
	draw_line(Vector2(365,48),Vector2(665,48),Color(0.61,0.52,0.33,0.45),1)
	text_at(game.objective.text,Vector2(365,68),12,MUTED,510)
	ability(Vector2(24,653),"Q","Special","Ready" if p.special_cooldown<=0 else "%.1fs" % p.special_cooldown,p.special_cooldown<=0)
	ability(Vector2(90,653),"Shift","Dodge","Ready" if p.dodge_cooldown<=0 else "%.1fs" % p.dodge_cooldown,p.dodge_cooldown<=0)
	ability(Vector2(156,653),"F","Potion",str(game.potions),game.potions>0)

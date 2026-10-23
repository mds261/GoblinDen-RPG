extends Node2D
const ItemIcons = preload("res://scripts/item_icons.gd")
## Walk over dropped scrap/loot to collect it. Inactive rooms cannot grant loot.
## Supports both scrap rewards and story-driven human weapon drops (Section 6).

signal collected(amount: int)
signal loot_collected(loot_id: String, xp_amount: int)

var amount: int = 3
var xp_amount: int = 35
var loot_id: String = ""
var taken: bool = false
var time: float = 0.0

func _process(delta: float) -> void:
	time += delta
	if taken or not is_visible_in_tree():
		return
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player) and player.hp > 0 and global_position.distance_to(player.global_position) < 38:
		taken = true
		collected.emit(amount)
		if loot_id != "" or xp_amount > 0:
			loot_collected.emit(loot_id, xp_amount)
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 17, Color(0.8, 0.65, 0.3, 0.15))
	var icon := ItemIcons.get_icon(loot_id if loot_id != "" else "scrap")
	if icon != null:
		draw_texture_rect(icon, Rect2(-24, -24, 48, 48), false)
	if loot_id != "":
		var pulse := 0.55 + 0.25 * sin(time * 6.0)
		draw_arc(Vector2.ZERO, 22.0, 0, TAU, 24, Color(0.98, 0.82, 0.38, pulse), 2.0, true)

		draw_string(ThemeDB.fallback_font, Vector2(-34, -18), "RELIC + SCRAP", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("ffd97d"))
	draw_string(ThemeDB.fallback_font, Vector2(-23, 30), "+%d scrap" % amount, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("e3ce98"))

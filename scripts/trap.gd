extends Node2D
## Deployable Goblin Trap (Section 1 & 3 & 4: Traps, Chokepoints, Rogue Disarm).
## Hurts, bleeds, poisons, and snares invading human adventurers.

const HitSpark = preload("res://scripts/hit_spark.gd")
const FloatingText = preload("res://scripts/floating_text.gd")

var damage: int = 28
var bleed_dps: int = 8
var poison_dps: int = 8
var snare_time: float = 2.6
var trigger_radius: float = 44.0
var lifetime: float = 8.0
var remaining_lifetime: float = 8.0
var armed: bool = true
var expired: bool = false
var time: float = 0.0
var flash_time: float = 0.0

func _ready() -> void:
	add_to_group("goblin_traps")
	z_index = int(position.y) - 10
	remaining_lifetime = lifetime

func _physics_process(delta: float) -> void:
	time += delta
	if not is_visible_in_tree():
		return
	if not armed:
		flash_time -= delta
		if flash_time <= 0.0:
			queue_free()
		queue_redraw()
		return
	remaining_lifetime = maxf(0.0, remaining_lifetime - delta)
	if remaining_lifetime <= 0.0:
		armed = false
		expired = true
		flash_time = 0.55
		queue_redraw()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
			continue
		var dist: float = enemy.global_position.distance_to(global_position)
		# Human Rogues search for and disarm traps before stepping onto the jaws!
		if enemy.get("role") == "rogue" and dist < trigger_radius + 26.0 and dist > trigger_radius * 0.65:
			armed = false
			expired = false
			flash_time = 0.35
			if enemy.has_method("show_floating_text"):
				enemy.show_floating_text("TRAP DISARMED!")
			queue_redraw()
			return
		if dist <= trigger_radius:
			_trigger(enemy)
			return
	queue_redraw()

func _trigger(primary_enemy: Node2D) -> void:
	armed = false
	expired = false
	flash_time = 0.40
	# Polish: trap spring visual effect + floating damage
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		HitSpark.trap_spring(parent_node, global_position)
		FloatingText.spawn_status(parent_node, global_position + Vector2(0, -18), "SNARED!", Color("88d060"))
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
			continue
		if enemy.global_position.distance_to(global_position) <= trigger_radius + 28.0:
			enemy.take_damage(damage, Vector2.ZERO)
			if enemy.has_method("apply_status"):
				enemy.apply_status(bleed_dps, poison_dps, snare_time)
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(0.75)
			# Polish: floating damage from trap
			if is_instance_valid(parent_node):
				FloatingText.spawn_damage(parent_node, enemy.global_position + Vector2(0, -24), damage)
	queue_redraw()

func _draw() -> void:
	if not armed:
		var spent_color := Color(0.42, 0.45, 0.38, maxf(0.0, flash_time)) if expired else Color(0.45, 0.85, 0.35, maxf(0.0, flash_time))
		draw_circle(Vector2.ZERO, trigger_radius * 1.15, spent_color)
		draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 28, Color("757b6e") if expired else Color("9ce673"), 2.5, true)
		if expired:
			draw_string(ThemeDB.fallback_font, Vector2(-23, 4), "EXPIRED", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.76, 0.70, maxf(0.0, flash_time * 1.6)))
		return
	var pulse := 0.55 + 0.25 * sin(time * 5.0)
	var life_ratio := clampf(remaining_lifetime / maxf(lifetime, 0.01), 0.0, 1.0)
	draw_circle(Vector2.ZERO, 20.0, Color(0.12, 0.16, 0.09, 0.72))
	draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 28, Color(0.55, 0.82, 0.42, 0.28 * pulse), 1.5, true)
	draw_arc(Vector2.ZERO, trigger_radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * life_ratio, 32, Color(0.80, 1.0, 0.42, 0.90), 3.0, true)
	# Iron bear-trap jaws & venom droplets
	for idx in range(6):
		var angle := idx * TAU / 6.0 + time * 0.3
		var outer := Vector2.from_angle(angle) * 18.0
		var inner := Vector2.from_angle(angle + 0.25) * 8.0
		draw_line(outer, inner, Color("b8b2a6"), 2.2, true)
	draw_circle(Vector2.ZERO, 5.5, Color(0.45, 0.88, 0.36, 0.85))
	draw_string(ThemeDB.fallback_font, Vector2(-29, 32), "SNARE %.1fs" % remaining_lifetime, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("bde694"))

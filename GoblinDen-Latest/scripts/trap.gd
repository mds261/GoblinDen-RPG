extends Node2D
## Deployable Goblin Trap (Section 1 & 3 & 4: Traps, Chokepoints, Rogue Disarm).
## Hurts, bleeds, poisons, and snares invading human adventurers.

const SnareEffect = preload("res://scripts/snare_effect.gd")
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
			var cage := SnareEffect.new()
			cage.target = enemy
			cage.radius = trigger_radius
			cage.duration = snare_time
			parent_node.add_child(cage)
			cage.global_position = enemy.global_position
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
		# Release leaves an etched fading ring, not the former solid green disk.
		for index in range(12):
			var angle := index * TAU / 12.0
			var direction := Vector2.from_angle(angle)
			draw_line(direction * trigger_radius * 0.7, direction * trigger_radius, spent_color, 2, true)
		draw_arc(Vector2.ZERO, trigger_radius, 0, TAU, 28, Color("757b6e") if expired else Color("9ce673"), 2.5, true)
		if expired:
			draw_string(ThemeDB.fallback_font, Vector2(-23, 4), "EXPIRED", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color(0.75, 0.76, 0.70, maxf(0.0, flash_time * 1.6)))
		return
	var pulse := 0.65 + 0.25 * sin(time * 4.0)
	var life_ratio := clampf(remaining_lifetime / maxf(lifetime, 0.01), 0.0, 1.0)
	var reveal := minf(1.0, time / 0.3)
	# Etched ground seal blooms on placement; its edge matches the trigger radius.
	for ring in range(5):
		draw_circle(Vector2.ZERO, trigger_radius * (0.55 + ring * 0.13) * reveal, Color(0.18, 0.8, 0.26, pulse * 0.025))
	draw_arc(Vector2.ZERO, trigger_radius * reveal, 0, TAU, 64, Color(0.48, 0.9, 0.32, pulse * 0.6), 2, true)
	draw_arc(Vector2.ZERO, trigger_radius + 4, -PI * 0.5, -PI * 0.5 + TAU * life_ratio, 64, Color(0.9, 1, 0.5, 0.85), 2.5, true)
	for index in range(10):
		var angle := index * TAU / 10.0 + time * 0.12
		var radial := Vector2.from_angle(angle)
		var tangent := radial.rotated(PI * 0.5)
		var point := radial * trigger_radius * 0.8 * reveal
		draw_polyline(PackedVector2Array([point - tangent * 3, point - radial * 6, point + tangent * 3]), Color(0.73, 1, 0.48, pulse), 1.5, true)
	# Large, readable iron jaws with golden edges and venom pooling in the center.
	for side in [-1, 1]:
		var center := Vector2(0, side * 6.0)
		var start := 0.15 if side > 0 else PI + 0.15
		draw_arc(center, 23 * reveal, start, start + PI - 0.3, 24, Color("293e30"), 9, true)
		draw_arc(center, 23 * reveal, start, start + PI - 0.3, 24, Color("bfc3a4"), 4, true)
		for tooth in range(5):
			var angle := start + 0.18 + tooth * (PI - 0.66) / 4
			var radial := Vector2.from_angle(angle)
			var tangent := radial.rotated(PI * 0.5)
			var base := center + radial * 23 * reveal
			draw_colored_polygon(PackedVector2Array([base - tangent * 4, base - radial * 10, base + tangent * 4]), Color("e4d8a2"))
	draw_circle(Vector2.ZERO, 8, Color(0.3, 0.9, 0.25, pulse * 0.8))
	draw_circle(Vector2(-2, -2), 3, Color(0.85, 1, 0.5, pulse))
	for index in range(8):
		var phase := fmod(time * 0.45 + index * 0.125, 1.0)
		var point := Vector2.from_angle(index * 2.4 + time * 0.25) * (15 + phase * 20)
		point.y -= phase * 18
		draw_circle(point, 1.5, Color(0.7, 1, 0.35, sin(phase * PI) * 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-30, trigger_radius + 19), "SNARE %.1fs" % remaining_lifetime, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("d7edb0"))

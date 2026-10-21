extends "res://scripts/knight.gd"
## Locked telegraphs, punishable recoveries, and a single reinforcement phase.
var boss_state: String = "recover"
var state_time: float = 1.0
var attack_index: int = 0
var charge_direction := Vector2.LEFT
var charge_origin := Vector2.ZERO
var phase_two: bool = false
var charge_hit: bool = false

func _physics_process(delta: float) -> void:
	animation_time += delta
	z_index = int(position.y)
	flash = maxf(0.0, flash - delta)
	hit_time = maxf(0.0, hit_time - delta)
	status_text_time = maxf(0.0, status_text_time - delta)
	blessed_timer = maxf(0.0, blessed_timer - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		queue_redraw()
		return
	if dot_timer > 0.0:
		dot_timer = maxf(0.0, dot_timer - delta)
		dot_tick_accum += delta
		if dot_tick_accum >= 0.5:
			dot_tick_accum -= 0.5
			take_damage(maxi(1, (bleed_dps + poison_dps) / 2))
		if dot_timer <= 0.0:
			bleed_dps = 0
			poison_dps = 0
	if hp <= 0 or not is_instance_valid(target) or target.hp <= 0:
		queue_redraw()
		return
	if stun_timer > 0.0:
		stun_timer = maxf(0.0, stun_timer - delta)
		boss_state = "recover"
		state_time = 0.8
		windup = 0.0
		queue_redraw()
		return
	state_time -= delta
	match boss_state:
		"recover":
			if state_time <= 0.0:
				if not phase_two and hp <= max_hp / 2:
					phase_two = true
					_begin_attack("rally", 1.25)
				else:
					attack_index += 1
					_begin_attack("charge" if attack_index % 2 == 1 else "sweep", 0.95)
		"charge", "sweep", "rally":
			windup = maxf(0.0, state_time)
			if state_time <= 0.0:
				if boss_state == "charge":
					boss_state = "charging"
					state_time = 0.8
					charge_hit = false
				elif boss_state == "sweep":
					_sweep()
					_recover(1.15)
				else:
					_rally()
					_recover(0.8)
		"charging":
			velocity = charge_direction * 560.0
			move_and_slide()
			if not charge_hit and global_position.distance_to(target.global_position) < 44.0:
				target.take_damage(damage)
				charge_hit = true
			var hit_wall := false
			for index in range(get_slide_collision_count()):
				if get_slide_collision(index).get_collider() is StaticBody2D:
					hit_wall = true
			if hit_wall:
				apply_stun(1.65)
				show_floating_text("STAGGERED! STRIKE NOW")
				get_tree().call_group("combat_feedback", "impact", true)
				_recover(1.65)
			elif state_time <= 0.0:
				_recover(0.9)
	queue_redraw()

func _begin_attack(kind: String, duration: float) -> void:
	boss_state = kind
	state_time = duration
	windup = duration
	max_windup = duration
	charge_origin = global_position
	charge_direction = global_position.direction_to(target.global_position)
	strike_position = global_position
	strike_radius = 125.0
	show_floating_text({"charge": "CHARGE - DODGE SIDEWAYS", "sweep": "SWEEP - GET BEHIND", "rally": "RALLY - STUN TO INTERRUPT"}[kind])

func _recover(duration: float) -> void:
	boss_state = "recover"
	state_time = duration
	windup = 0.0
	velocity = Vector2.ZERO

func _sweep() -> void:
	var victims: Array = get_tree().get_nodes_in_group("allies")
	victims.append(target)
	for victim in victims:
		if not is_instance_valid(victim) or victim.hp <= 0:
			continue
		var offset: Vector2 = victim.global_position - global_position
		if offset.length() <= 125.0 and charge_direction.dot(offset.normalized()) >= -0.25:
			var ray := PhysicsRayQueryParameters2D.create(global_position, victim.global_position, 1)
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				victim.take_damage(damage)
	get_tree().call_group("combat_feedback", "play_cue", "swing")

func _rally() -> void:
	var game = get_parent().get_parent()
	for offset in [Vector2(-75, -65), Vector2(-75, 65)]:
		var point: Vector2 = global_position + offset
		point.x = clampf(point.x, 130, 1020)
		point.y = clampf(point.y, 150, 570)
		var cave = game.get_node("Cave")
		var cell: Vector2i = cave._nearest_open_cell(point)
		point = Vector2(cell) * 24.0 + Vector2(12, 12)
		game.spawn_enemy_ext(2, point, "CAPTAIN'S GUARD", 35, 110.0, 9, 1, "knight", 15, "")
	for ally in get_tree().get_nodes_in_group("enemies"):
		if ally.is_visible_in_tree() and ally.hp > 0:
			ally.blessed_timer = 5.0
	show_floating_text("HOLD THE LINE!")

func reset_encounter_motion() -> void:
	_recover(1.0)

func _draw() -> void:
	# Suppress the inherited circular marker: these attacks have different shapes.
	var saved_windup := windup
	windup = 0.0
	super._draw()
	windup = saved_windup
	if hp <= 0:
		return
	if boss_state == "charge":
		var end := charge_direction * 448.0
		draw_line(Vector2.ZERO, end, Color(1, 0.3, 0.12, 0.22), 70.0)
		draw_line(Vector2.ZERO, end, Color("ffb675"), 3.0, true)
	elif boss_state == "sweep":
		var angle := charge_direction.angle()
		var points := PackedVector2Array([Vector2.ZERO])
		for i in range(33):
			points.append(Vector2.from_angle(angle - 1.82 + i * 3.64 / 32.0) * 125.0)
		draw_colored_polygon(points, Color(1, 0.25, 0.1, 0.24))
		draw_arc(Vector2.ZERO, 125.0, angle - 1.82, angle + 1.82, 32, Color("ffb675"), 3.0, true)
	elif boss_state == "rally":
		draw_arc(Vector2.ZERO, 60.0 + sin(animation_time * 12.0) * 5.0, 0, TAU, 40, Color("ffd76c"), 4.0, true)
	elif boss_state == "recover":
		draw_arc(Vector2.ZERO, 31.0, 0, TAU, 24, Color(0.6, 1.0, 0.7, 0.65), 2.0, true)

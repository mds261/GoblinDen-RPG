extends CharacterBody2D
## Human Adventuring Party Member (Sections 2 & 3 of Concept Document).
## Roles: "knight" (frontline protector), "priest" (healer/buffer),
## "mage" (AoE spellcaster), "ranger" (backline kiter), "rogue" (trap disarmer/flanker),
## and "boss" (commander/champion).

const EnemyAnimation = preload("res://scripts/enemy_animation.gd")
const Projectile = preload("res://scripts/projectile.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")

signal defeated

@export var max_hp: int = 100
@export var speed: float = 105.0
@export var damage: int = 20
@export var display_name: String = "HUMAN KNIGHT"
@export var scrap_reward: int = 3
@export var xp_reward: int = 35
@export var loot_drop_id: String = ""
@export var role: String = "knight"

var appearance_animation = EnemyAnimation.new()
var animation_time: float = 0.0
var hp: int = 100
var target: Node2D
var dungeon_awareness: RefCounted
var cooldown: float = 0.8
var support_cooldown: float = 2.4
var windup: float = 0.0
var max_windup: float = 0.65
var strike_position := Vector2.ZERO
var strike_radius: float = 48.0
var flash: float = 0.0
var knockback := Vector2.ZERO
var hit_number: int = 0
var hit_time: float = 0.0
var status_text: String = ""
var status_text_time: float = 0.0

# Status effects inflicted by Goblin classes & traps
var bleed_dps: int = 0
var poison_dps: int = 0
var dot_timer: float = 0.0
var dot_tick_accum: float = 0.0
var slow_timer: float = 0.0
var stun_timer: float = 0.0
var blessed_timer: float = 0.0
var heal_beam_pos := Vector2.ZERO
var heal_beam_time: float = 0.0

func _ready() -> void:
	appearance_animation.configure(role)
	hp = max_hp
	target = get_tree().get_first_node_in_group("player")
	if role == "mage":
		strike_radius = 68.0
		max_windup = 0.85
	elif role == "rogue":
		max_windup = 0.45
	else:
		strike_radius = 48.0
		max_windup = 0.65

func _physics_process(delta: float) -> void:
	animation_time += delta
	z_index = int(position.y)
	flash = maxf(0.0, flash - delta)
	hit_time = maxf(0.0, hit_time - delta)
	status_text_time = maxf(0.0, status_text_time - delta)
	cooldown = maxf(0.0, cooldown - delta)
	support_cooldown = maxf(0.0, support_cooldown - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	blessed_timer = maxf(0.0, blessed_timer - delta)
	heal_beam_time = maxf(0.0, heal_beam_time - delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		queue_redraw()
		return
	# Process bleed & poison DoT ticks
	if dot_timer > 0.0:
		dot_timer = maxf(0.0, dot_timer - delta)
		dot_tick_accum += delta
		if dot_tick_accum >= 0.5:
			dot_tick_accum -= 0.5
			var dot_dmg := maxi(1, int((bleed_dps + poison_dps) * 0.5))
			take_damage(dot_dmg, Vector2.ZERO)
			if hp <= 0:
				return
		if dot_timer <= 0.0:
			bleed_dps = 0
			poison_dps = 0
	if stun_timer > 0.0:
		windup = 0.0
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 1100.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	var player_node = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(target) or target.get("hp") == null or target.hp <= 0:
		target = player_node
	if not is_instance_valid(target) or target.hp <= 0:
		queue_redraw()
		return
	# Stealth check: if player is hidden in shadow ambush alcove and far away, enemies hesitate
	if dungeon_awareness != null and not dungeon_awareness.step(self,delta):
		velocity += knockback
		knockback = knockback.move_toward(Vector2.ZERO,1100.0*delta)
		move_and_slide()
		queue_redraw()
		return
	var player_stealthed: bool = target == player_node and player_node.get("stealth_ambush") == true
	var effective_dmg := int(damage * (1.2 if blessed_timer > 0.0 else 1.0))
	var move_speed := speed * (0.55 if slow_timer > 0.0 else 1.0)
	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_execute_windup_attack(effective_dmg)
			cooldown = 1.15 if role in ["mage", "ranger", "priest"] else 1.0
	else:
		var offset := target.global_position - global_position
		var dist := offset.length()
		if player_stealthed and dist > 175.0:
			# Patrol slowly while player is hidden in cave shadows
			velocity = Vector2(cos(animation_time * 1.4), sin(animation_time * 1.1)) * (move_speed * 0.35)
		else:
			match role:
				"priest":
					_process_priest_ai(offset, dist, move_speed)
				"mage":
					_process_mage_ai(offset, dist, move_speed)
				"ranger":
					_process_ranger_ai(offset, dist, move_speed)
				"rogue":
					_process_rogue_ai(offset, dist, move_speed)
				_:
					# "knight" and "boss" frontline pursuit & strike
					if dist < 62.0 and cooldown <= 0.0:
						windup = max_windup
						strike_position = target.global_position
					elif dist > 44.0:
						velocity = _route_to(target.global_position) * move_speed
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1100.0 * delta)
	move_and_slide()
	queue_redraw()

func _process_priest_ai(offset: Vector2, dist: float, move_speed: float) -> void:
	# Priest prioritizes healing injured party members and buffing allies
	if support_cooldown <= 0.0:
		var wounded_ally := _find_wounded_party_member()
		if is_instance_valid(wounded_ally):
			wounded_ally.hp = mini(wounded_ally.max_hp, wounded_ally.hp + 24)
			wounded_ally.blessed_timer = 4.0
			wounded_ally.show_floating_text("+24 HEAL")
			heal_beam_pos = wounded_ally.global_position
			heal_beam_time = 0.45
			appearance_animation.release_attack(0.45)
			support_cooldown = 3.4
			return
	if dist < 150.0:
		velocity = -offset.normalized() * move_speed * 0.85
	elif dist > 260.0:
		velocity = _route_to(target.global_position) * move_speed
	elif cooldown <= 0.0:
		windup = 0.55
		max_windup = 0.55
		strike_position = target.global_position

func _process_mage_ai(offset: Vector2, dist: float, move_speed: float) -> void:
	if dist <= 320.0 and cooldown <= 0.0:
		windup = 0.85
		max_windup = 0.85
		strike_position = target.global_position
	elif dist < 165.0:
		velocity = -offset.normalized() * move_speed * 0.8
	elif dist > 280.0:
		velocity = _route_to(target.global_position) * move_speed

func _process_ranger_ai(offset: Vector2, dist: float, move_speed: float) -> void:
	if dist < 145.0:
		velocity = -offset.normalized() * move_speed * 0.95
	elif dist <= 360.0 and cooldown <= 0.0:
		windup = 0.55
		max_windup = 0.55
		strike_position = target.global_position
	elif dist > 310.0:
		velocity = _route_to(target.global_position) * move_speed

func _process_rogue_ai(offset: Vector2, dist: float, move_speed: float) -> void:
	# Rogue seeks nearby goblin traps to disarm them first
	for trap in get_tree().get_nodes_in_group("goblin_traps"):
		if is_instance_valid(trap) and trap.is_visible_in_tree() and trap.armed:
			var to_trap: Vector2 = trap.global_position - global_position
			if to_trap.length() < 220.0:
				velocity = _route_to(trap.global_position) * move_speed * 1.15
				return
	if dist < 68.0 and cooldown <= 0.0:
		windup = 0.45
		max_windup = 0.45
		strike_position = target.global_position
	elif dist > 42.0:
		# Subtle flank curve as rogue closes in
		var perp := Vector2(-offset.y, offset.x).normalized() * 0.28
		velocity = (_route_to(target.global_position) + perp).normalized() * move_speed

func _execute_windup_attack(effective_dmg: int) -> void:
	appearance_animation.release_attack()
	if not is_instance_valid(target) or target.hp <= 0:
		return
	get_tree().call_group("game_audio","play_sfx","bow" if role in ["ranger","priest"] else ("magic" if role=="mage" else "swing"))
	if role == "ranger" or role == "priest":
		var shot := Projectile.new()
		shot.global_position = global_position + Vector2(0, -14)
		var aim_dir := (strike_position - global_position).normalized()
		if aim_dir == Vector2.ZERO:
			aim_dir = Vector2.LEFT
		shot.velocity = aim_dir * (430.0 if role == "ranger" else 360.0)
		shot.damage = effective_dmg
		shot.from_player_team = false
		shot.style = "human_arrow" if role == "ranger" else "smite"
		get_parent().add_child(shot)
		return
	var hit_radius := strike_radius
	if target.global_position.distance_to(strike_position) < hit_radius:
		var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
		if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			target.take_damage(effective_dmg)
			# Guardian Goblin reflection if blocking
			if target.get("bulwark_timer") != null and target.bulwark_timer > 0.0 and target.get("evolution_id") == "guardian":
				take_damage(maxi(4, int(effective_dmg * 0.4)), Vector2.ZERO)
	# Mage AoE also hurts nearby Goblin Party allies clustered in the blast zone
	if role == "mage":
		for ally in get_tree().get_nodes_in_group("allies"):
			if is_instance_valid(ally) and ally.is_visible_in_tree() and ally.hp > 0:
				if ally.global_position.distance_to(strike_position) < hit_radius:
					ally.take_damage(effective_dmg)

func _find_wounded_party_member() -> Node2D:
	var best: Node2D = null
	var lowest_ratio: float = 0.92
	for ally in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(ally) or not ally.is_visible_in_tree() or ally.hp <= 0:
			continue
		if global_position.distance_to(ally.global_position)>360.0:
			continue
		var ratio := float(ally.hp) / float(maxi(1, ally.max_hp))
		if ratio < lowest_ratio:
			lowest_ratio = ratio
			best = ally
	return best

func _is_protected_by_knight() -> bool:
	if role in ["knight", "boss"]:
		return false
	for ally in get_tree().get_nodes_in_group("enemies"):
		if ally != self and is_instance_valid(ally) and ally.is_visible_in_tree() and ally.hp > 0:
			if ally.get("role") in ["knight", "boss"] and ally.global_position.distance_to(global_position) <= 145.0:
				return true
	return false

func apply_status(add_bleed: int, add_poison: int, add_slow: float) -> void:
	if hp <= 0:
		return
	if add_bleed > 0 or add_poison > 0:
		bleed_dps = maxi(bleed_dps, add_bleed)
		poison_dps = maxi(poison_dps, add_poison)
		dot_timer = maxf(dot_timer, 3.0)
	if add_slow > 0.0:
		slow_timer = maxf(slow_timer, add_slow)

func apply_stun(duration: float) -> void:
	if hp <= 0:
		return
	stun_timer = maxf(stun_timer, duration)
	windup = 0.0
	show_floating_text("STUNNED!")

func show_floating_text(words: String) -> void:
	status_text = words
	status_text_time = 0.85

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0:
		return
	if amount > 0 and dungeon_awareness != null:
		dungeon_awareness.alert(self)
	var final_amount := amount
	# Frontline Knight protects weaker backline party members within 145px (Section 3)
	if amount < 500 and _is_protected_by_knight():
		final_amount = maxi(1, int(round(amount * 0.75)))
	hp = maxi(0, hp - final_amount)
	if direction != Vector2.ZERO:
		get_tree().call_group("combat_feedback", "impact", false)
	flash = 0.13
	if direction != Vector2.ZERO:
		knockback = direction * 240.0
	# Polish: floating damage number on enemies
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		FloatingText.spawn_damage(parent_node, global_position + Vector2(0, -28), final_amount, final_amount >= 30)
		HitSpark.melee_hit(parent_node, global_position + Vector2(0, -5), final_amount >= 30)
	queue_redraw()
	if hp == 0:
		windup = 0.0
		collision_layer = 0
		collision_mask = 0
		# Polish: death burst effect
		if is_instance_valid(parent_node):
			if role == "boss":
				DeathEffect.burst_boss(parent_node, global_position)
			else:
				DeathEffect.burst_enemy(parent_node, global_position)
		defeated.emit()

func _draw() -> void:
	var captain := max_hp > 165 or role == "boss"
	var size := 124.0 if captain else 104.0
	if role in ["rogue", "ranger", "priest"]:
		size = 98.0
	# Draw Priest heal beam when active
	if heal_beam_time > 0.0:
		draw_line(Vector2.ZERO, to_local(heal_beam_pos), Color(1.0, 0.92, 0.45, heal_beam_time * 1.6), 4.0, true)
		draw_circle(to_local(heal_beam_pos), 28.0, Color(1.0, 0.92, 0.45, heal_beam_time * 0.5))
	# Draw attack / spell / ranged telegraph
	if windup > 0.0:
		var local_strike := to_local(strike_position)
		var progress := 1.0 - windup / maxf(0.1, max_windup)
		if role == "ranger" or role == "priest":
			var beam_col := Color(0.95, 0.78, 0.38, 0.55) if role == "ranger" else Color(1.0, 0.94, 0.55, 0.65)
			draw_line(Vector2(0, -14), local_strike, beam_col, 2.0, true)
			draw_arc(local_strike, 20.0, 0, TAU, 24, beam_col, 2.0, true)
		else:
			var fill_col := Color(0.75, 0.22, 0.85, 0.30) if role == "mage" else Color(0.8, 0.16, 0.06, 0.33)
			var ring_col := Color("e68af7") if role == "mage" else Color("f6a36d")
			draw_circle(local_strike, strike_radius, fill_col)
			draw_arc(local_strike, strike_radius, 0, TAU, 40, ring_col, 2.5, true)
			draw_arc(local_strike, strike_radius, -PI / 2, -PI / 2 + TAU * progress, 40, Color("ffe4ae"), 3, true)
	appearance_animation.configure(role)
	appearance_animation.draw_actor(self, size, flash > 0.0)
	if hp <= 0:
		return
	# Status indicators (bleed, poison, stun, knight shield aura)
	if bleed_dps > 0:
		draw_circle(Vector2(-18, -32), 4.0, Color("d93829"))
	if poison_dps > 0:
		draw_circle(Vector2(18, -32), 4.0, Color("5cd966"))
	if stun_timer > 0.0:
		draw_arc(Vector2(0, -size * 0.72), 16.0, animation_time * 4.0, animation_time * 4.0 + PI * 1.4, 14, Color("ffe875"), 2.5, true)
	var top := minf(-size * 0.84, appearance_animation.label_top(size))
	draw_rect(Rect2(-62, top - 16, 124, 19), Color(0.04, 0.035, 0.03, 0.8))
	draw_string(ThemeDB.fallback_font, Vector2(-56, top - 2), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("decbae"))
	draw_rect(Rect2(-28, top + 8, 56, 5), Color("342830"))
	draw_rect(Rect2(-28, top + 8, 56 * float(hp) / max_hp, 5), Color("c37e69"))
	if status_text_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-38, top - 22 - (0.85 - status_text_time) * 18), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffe596"))

func _route_to(destination: Vector2) -> Vector2:
	var cave = get_tree().current_scene.get_node_or_null("Cave") if get_tree().current_scene != null else get_parent().get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("route_direction"):
		return cave.route_direction(global_position, destination)
	return global_position.direction_to(destination)

func _process(delta: float) -> void:
	appearance_animation.configure(role)
	var aim := strike_position - global_position
	appearance_animation.update(delta, velocity, hp > 0, windup, max_windup, aim, stun_timer > 0.0)
	queue_redraw()

func reset_encounter_motion() -> void:
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	windup = 0.0
	cooldown = 0.8
	appearance_animation.reset()

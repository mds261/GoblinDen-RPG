extends CharacterBody2D
## Shared miniboss controller for the three creatures guarding the expanded route.

const EnemyAnimation = preload("res://scripts/enemy_animation.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")
const MonsterMinion = preload("res://scripts/monster_minion.gd")
const PoisonCloud = preload("res://scripts/poison_cloud.gd")
const SpecialEffect = preload("res://scripts/special_effect.gd")


signal defeated

var enemy_kind: String = "spider"
var display_name: String = "GIANT SPIDER"
var role: String = "large"
var max_hp: int = 300
var hp: int = 300
var speed: float = 120.0
var damage: int = 25
var scrap_reward: int = 10
var xp_reward: int = 140
var loot_drop_id: String = ""
var attack_radius: float = 72.0
var max_windup: float = 0.65
var windup_total: float = 0.65
var cooldown_length: float = 1.1
var art_size: float = 178.0

var target: Node2D
var appearance_animation = EnemyAnimation.new()
var animation_time: float = 0.0
var cooldown: float = 0.8
var windup: float = 0.0
var strike_position := Vector2.ZERO
var flash: float = 0.0
var knockback := Vector2.ZERO
var bleed_dps: int = 0
var poison_dps: int = 0
var dot_timer: float = 0.0
var dot_tick_accum: float = 0.0
var slow_timer: float = 0.0
var stun_timer: float = 0.0
var status_text: String = ""
var status_text_time: float = 0.0
var special_attack: bool = false
var special_cooldown: float = 4.5
var summon_cooldown: float = 2.2
var gas_cooldown: float = 3.8
var pack_cooldown: float = 0.4

func configure(kind: String) -> void:
	enemy_kind = kind
	match enemy_kind:
		"spider":
			display_name = "ROOTVEIN GIANT SPIDER"
			max_hp = 320
			speed = 148.0
			damage = 24
			scrap_reward = 10
			xp_reward = 150
			attack_radius = 82.0
			max_windup = 0.48
			cooldown_length = 0.9
			art_size = 184.0
		"ogre":
			display_name = "CAVE-MOUTH OGRE"
			max_hp = 480
			speed = 82.0
			damage = 38
			scrap_reward = 14
			xp_reward = 210
			attack_radius = 108.0
			max_windup = 1.12
			cooldown_length = 1.5
			art_size = 188.0
		"wolf_rider":
			display_name = "THORNWOOD WOLF RIDER"
			max_hp = 370
			speed = 182.0
			damage = 30
			scrap_reward = 12
			xp_reward = 180
			attack_radius = 88.0
			max_windup = 0.58
			cooldown_length = 0.82
			art_size = 196.0
	hp = max_hp
	windup_total = max_windup

func _ready() -> void:
	appearance_animation.configure(enemy_kind)
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("player")
	hp = max_hp
	if enemy_kind == "wolf_rider":
		call_deferred("_ensure_wolf_pack")

func reset_encounter_motion() -> void:
	appearance_animation.reset()
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	windup = 0.0
	cooldown = 0.65

func _physics_process(delta: float) -> void:
	animation_time += delta
	z_index = int(position.y)
	flash = maxf(0.0, flash - delta)
	cooldown = maxf(0.0, cooldown - delta)
	status_text_time = maxf(0.0, status_text_time - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	summon_cooldown = maxf(0.0, summon_cooldown - delta)
	gas_cooldown = maxf(0.0, gas_cooldown - delta)
	pack_cooldown = maxf(0.0, pack_cooldown - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	velocity = Vector2.ZERO
	if hp <= 0:
		queue_redraw()
		return
	_process_damage_over_time(delta)
	if hp <= 0:
		return
	if stun_timer > 0.0:
		windup = 0.0
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO, 950.0 * delta)
		move_and_slide()
		queue_redraw()
		return
	if not is_instance_valid(target) or target.hp <= 0:
		target = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(target) or target.hp <= 0:
		return
	_process_signature_abilities()
	if windup > 0.0:
		windup -= delta
		if windup <= 0.0:
			_execute_attack()
			cooldown = cooldown_length
	else:
		var offset: Vector2 = target.global_position - global_position
		var distance := offset.length()
		var engage_distance := 92.0 if enemy_kind != "ogre" else 108.0
		if distance <= engage_distance and cooldown <= 0.0:
			windup = max_windup
			windup_total = max_windup
			strike_position = target.global_position
		elif distance > engage_distance * 0.72:
			var move_speed := speed * (0.55 if slow_timer > 0.0 else 1.0)
			velocity = _route_to(target.global_position) * move_speed
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 950.0 * delta)
	move_and_slide()
	queue_redraw()

func _process_signature_abilities() -> void:
	if enemy_kind == "spider":
		if summon_cooldown <= 0.0:
			_summon_spiderlings()
			summon_cooldown = 7.2
		if gas_cooldown <= 0.0:
			_drop_poison_cloud()
			gas_cooldown = 6.4
	elif enemy_kind == "ogre":
		if special_cooldown <= 0.0 and windup <= 0.0 and cooldown <= 0.0:
			var distance := global_position.distance_to(target.global_position)
			if distance <= 260.0:
				special_attack = true
				windup = 1.75
				windup_total = 1.75
				strike_position = target.global_position
				status_text = "CHARGED CAVEBREAKER"
				status_text_time = 1.75
				special_cooldown = 7.8
	elif enemy_kind == "wolf_rider" and pack_cooldown <= 0.0:
		_ensure_wolf_pack()
		pack_cooldown = 6.0

func _summon_spiderlings() -> void:
	var existing := _count_minions("spiderling")
	var to_spawn := mini(2, 4 - existing)
	if to_spawn <= 0:
		return
	appearance_animation.release_attack(0.4)
	status_text = "BROOD AWAKENS"
	status_text_time = 1.0
	for index in range(to_spawn):
		var angle := animation_time * 1.7 + float(index) * PI
		_spawn_minion("spiderling", global_position + Vector2.from_angle(angle) * 62.0)

func _drop_poison_cloud() -> void:
	appearance_animation.release_attack(0.4)
	var cloud := PoisonCloud.new()
	get_parent().add_child(cloud)
	cloud.global_position = target.global_position
	status_text = "VENOM GAS"
	status_text_time = 0.9

func _ensure_wolf_pack() -> void:
	if not is_inside_tree() or hp <= 0:
		return
	var missing := maxi(0, 3 - _count_minions("wolf"))
	for index in range(missing):
		var angle := TAU * float(index) / maxf(1.0, float(missing)) + animation_time
		_spawn_minion("wolf", global_position + Vector2.from_angle(angle) * (78.0 + index * 9.0))
	if missing > 0:
		appearance_animation.release_attack(0.4)
		status_text = "PACK HUNT"
		status_text_time = 0.9

func _count_minions(kind: String) -> int:
	var count := 0
	for child in get_parent().get_children():
		if child.get("minion_kind") == kind and child.get("hp") != null and child.hp > 0:
			count += 1
	return count

func _spawn_minion(kind: String, point: Vector2) -> void:
	var minion = MonsterMinion.new()
	minion.configure(kind)
	minion.global_position = point
	minion.collision_layer = collision_layer
	minion.collision_mask = collision_mask
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 18.0 if kind == "wolf" else 12.0
	collision.shape = shape
	minion.add_child(collision)
	get_parent().add_child(minion)

func _process_damage_over_time(delta: float) -> void:
	if dot_timer <= 0.0:
		return
	dot_timer = maxf(0.0, dot_timer - delta)
	dot_tick_accum += delta
	if dot_tick_accum >= 0.5:
		dot_tick_accum -= 0.5
		take_damage(maxi(1, int((bleed_dps + poison_dps) * 0.5)))
	if dot_timer <= 0.0:
		bleed_dps = 0
		poison_dps = 0

func _execute_attack() -> void:
	appearance_animation.release_attack(0.38)
	var victims: Array[Node] = [target]
	if enemy_kind == "ogre":
		victims.append_array(get_tree().get_nodes_in_group("allies"))
	var effective_damage := int(round(damage * 1.75)) if special_attack else damage
	var effective_radius := 168.0 if special_attack else attack_radius
	if special_attack:
		var effect = SpecialEffect.new()
		effect.setup("ogre_smash", Vector2.RIGHT, effective_radius)
		get_parent().add_child(effect)
		effect.global_position = strike_position
	for victim in victims:
		if not is_instance_valid(victim) or victim.get("hp") == null or victim.hp <= 0:
			continue
		if victim.global_position.distance_to(strike_position) <= effective_radius:
			victim.take_damage(effective_damage)
			if victim == target and enemy_kind == "spider":
				status_text = "VENOM POUNCE"
				status_text_time = 0.8
			elif victim == target and enemy_kind == "wolf_rider":
				status_text = "SPEAR CHARGE"
				status_text_time = 0.8
	if special_attack:
		status_text = "CAVEBREAKER IMPACT"
		status_text_time = 0.9
		special_attack = false

func apply_status(add_bleed: int, add_poison: int, add_slow: float) -> void:
	bleed_dps = maxi(bleed_dps, add_bleed)
	poison_dps = maxi(poison_dps, add_poison)
	if add_bleed > 0 or add_poison > 0:
		dot_timer = maxf(dot_timer, 3.0)
	if add_slow > 0.0:
		slow_timer = maxf(slow_timer, add_slow * 0.65)

func apply_stun(duration: float) -> void:
	stun_timer = maxf(stun_timer, duration * 0.45)
	windup = 0.0
	status_text = "STAGGERED"
	status_text_time = 0.75

func show_floating_text(words: String) -> void:
	status_text = words
	status_text_time = 0.85

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.14
	if direction != Vector2.ZERO:
		knockback = direction * (105.0 if enemy_kind == "ogre" else 165.0)
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		FloatingText.spawn_damage(parent_node, global_position + Vector2(0, -55), amount, amount >= 30)
		HitSpark.melee_hit(parent_node, global_position + Vector2(0, -10), amount >= 30)
	queue_redraw()
	if hp == 0:
		windup = 0.0
		collision_layer = 0
		collision_mask = 0
		if is_instance_valid(parent_node):
			DeathEffect.burst_boss(parent_node, global_position)
		defeated.emit()

func _draw() -> void:
	if windup > 0.0:
		var local_strike := to_local(strike_position)
		var progress := 1.0 - windup / maxf(0.1, windup_total)
		var fill := Color(0.76, 0.12, 0.08, 0.23)
		if enemy_kind == "spider":
			fill = Color(0.65, 0.08, 0.12, 0.26)
		elif enemy_kind == "wolf_rider":
			fill = Color(0.92, 0.38, 0.08, 0.20)
		var telegraph_radius := 168.0 if special_attack else attack_radius
		if special_attack:
			fill = Color(0.95, 0.24, 0.04, 0.30)
		draw_circle(local_strike, telegraph_radius, fill)
		draw_arc(local_strike, telegraph_radius, 0, TAU, 42, Color("ff9c68"), 2.5 if not special_attack else 6.0, true)
		draw_arc(local_strike, telegraph_radius, -PI / 2, -PI / 2 + TAU * progress, 42, Color("ffe2a6"), 4.0, true)
	appearance_animation.configure(enemy_kind)
	appearance_animation.draw_actor(self, art_size, flash > 0.0)
	if hp <= 0:
		return
	var top := minf(-art_size * 0.73, appearance_animation.label_top(art_size))
	draw_rect(Rect2(-82, top - 19, 164, 21), Color(0.035, 0.02, 0.018, 0.88))
	draw_string(ThemeDB.fallback_font, Vector2(-76, top - 4), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color("f0c99d"))
	draw_rect(Rect2(-58, top + 8, 116, 7), Color("38242a"))
	draw_rect(Rect2(-58, top + 8, 116.0 * float(hp) / max_hp, 7), Color("bd4737"))
	if status_text_time > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-48, top - 29), status_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("ffd27d"))

func _route_to(destination: Vector2) -> Vector2:
	var cave = get_parent().get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("route_direction"):
		return cave.route_direction(global_position, destination)
	return global_position.direction_to(destination)

func _process(delta: float) -> void:
	appearance_animation.configure(enemy_kind)
	var aim := strike_position - global_position
	appearance_animation.update(delta, velocity, hp > 0, windup, windup_total, aim, stun_timer > 0.0)
	queue_redraw()

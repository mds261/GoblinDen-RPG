extends CharacterBody2D
## Spiderlings and dire wolves supporting the expanded-room minibosses.

const EnemyAnimation = preload("res://scripts/enemy_animation.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")


var minion_kind: String = "spiderling"
var role: String = "monster_minion"
var display_name: String = "SPIDERLING"
var max_hp: int = 55
var hp: int = 55
var speed: float = 155.0
var damage: int = 10
var scrap_reward: int = 0
var xp_reward: int = 0
var loot_drop_id: String = ""
var cooldown: float = 0.4
var windup: float = 0.0
var knockback := Vector2.ZERO
var flash: float = 0.0
var stun_timer: float = 0.0
var slow_timer: float = 0.0
var bleed_dps: int = 0
var poison_dps: int = 0
var dot_timer: float = 0.0
var dot_tick: float = 0.0
var appearance_animation = EnemyAnimation.new()
var animation_time: float = 0.0
var target: Node2D
var death_time: float = 0.0

func configure(kind: String) -> void:
	minion_kind = kind
	if kind == "wolf":
		display_name = "PACK WOLF"
		max_hp = 105
		speed = 170.0
		damage = 16
	else:
		display_name = "ROOTVEIN SPIDERLING"
		max_hp = 58
		speed = 162.0
		damage = 9
	hp = max_hp

func _ready() -> void:
	appearance_animation.configure(minion_kind)
	add_to_group("enemies")
	target = get_tree().get_first_node_in_group("player")
	hp = max_hp

func reset_encounter_motion() -> void:
	appearance_animation.reset()
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	windup = 0.0
	cooldown = 0.5

func _physics_process(delta: float) -> void:
	animation_time += delta
	z_index = int(position.y)
	flash = maxf(0.0, flash - delta)
	cooldown = maxf(0.0, cooldown - delta)
	stun_timer = maxf(0.0, stun_timer - delta)
	slow_timer = maxf(0.0, slow_timer - delta)
	if hp <= 0:
		death_time += delta
		queue_redraw()
		if death_time >= 0.45:
			queue_free()
		return
	_process_dot(delta)
	if hp <= 0:
		return
	if not is_instance_valid(target) or target.hp <= 0:
		target = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(target) or target.hp <= 0:
		return
	if stun_timer > 0.0:
		velocity = knockback
	else:
		var offset: Vector2 = target.global_position - global_position
		var distance := offset.length()
		if distance <= (52.0 if minion_kind == "wolf" else 44.0) and cooldown <= 0.0:
			appearance_animation.faces_left = offset.x < 0.0
			appearance_animation.release_attack(0.28)
			target.take_damage(damage)
			cooldown = 0.78 if minion_kind == "wolf" else 0.95
			windup = 0.18
			velocity = Vector2.ZERO
		elif distance > 34.0:
			var current_speed := speed * (0.58 if slow_timer > 0.0 else 1.0)
			velocity = _route_to(target.global_position) * current_speed
	windup = maxf(0.0, windup - delta)
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO, 1000.0 * delta)
	move_and_slide()
	queue_redraw()

func _process_dot(delta: float) -> void:
	if dot_timer <= 0.0:
		return
	dot_timer -= delta
	dot_tick += delta
	if dot_tick >= 0.5:
		dot_tick -= 0.5
		take_damage(maxi(1, int((bleed_dps + poison_dps) * 0.5)))

func apply_status(add_bleed: int, add_poison: int, add_slow: float) -> void:
	bleed_dps = maxi(bleed_dps, add_bleed)
	poison_dps = maxi(poison_dps, add_poison)
	if add_bleed > 0 or add_poison > 0:
		dot_timer = maxf(dot_timer, 3.0)
	slow_timer = maxf(slow_timer, add_slow)

func apply_stun(duration: float) -> void:
	stun_timer = maxf(stun_timer, duration)

func show_floating_text(_words: String) -> void:
	pass

func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.14
	if direction != Vector2.ZERO:
		knockback = direction * 190.0
	FloatingText.spawn_damage(get_parent(), global_position + Vector2(0, -24), amount, amount >= 25)
	if hp == 0:
		collision_layer = 0
		collision_mask = 0
		DeathEffect.burst_enemy(get_parent(), global_position)
		var game := get_parent().get_parent()
		if is_instance_valid(game) and game.has_method("refresh_objective"):
			game.call_deferred("refresh_objective")

func _draw() -> void:
	var draw_size := 78.0 if minion_kind == "wolf" else 57.0
	appearance_animation.configure(minion_kind)
	appearance_animation.draw_actor(self, draw_size, flash > 0.0)
	if hp <= 0:
		return
	var top := minf(-draw_size * 0.73, appearance_animation.label_top(draw_size))
	draw_rect(Rect2(-24, top, 48, 4), Color("2b2024"))
	draw_rect(Rect2(-24, top, 48.0 * float(hp) / max_hp, 4), Color("b84f3d"))

func _route_to(destination: Vector2) -> Vector2:
	var cave = get_parent().get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("route_direction"):
		return cave.route_direction(global_position, destination)
	return global_position.direction_to(destination)

func _process(delta: float) -> void:
	appearance_animation.configure(minion_kind)
	var aim := target.global_position - global_position if is_instance_valid(target) else Vector2.ZERO
	appearance_animation.update(delta, velocity, hp > 0, 0.0, 0.18, aim, stun_timer > 0.0)
	queue_redraw()

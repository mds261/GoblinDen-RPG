extends CharacterBody2D
## Recruitable Goblin Party Companion & Summon (Section 7: From Lone Goblin to Goblin Chief).
## Supports the four core class companions plus summoned Cave Wolves and Risen Skeletons.

const CLASS_ART := {
	"blade": preload("res://assets/goblin_class_blade.png"),
	"archer": preload("res://assets/goblin_class_archer.png"),
	"knight": preload("res://assets/goblin_class_knight.png"),
	"mage": preload("res://assets/goblin_class_mage.png")
}
const FALLBACK_ART = preload("res://assets/goblin_class_blade.png")
const SummonAnimation = preload("res://scripts/summon_animation.gd")
const DirectionalActor = preload("res://scripts/directional_actor.gd")
const ClassAnimation = preload("res://scripts/class_animation.gd")
const BladeAnimation = preload("res://scripts/blade_animation.gd")
const PaintedActor = preload("res://scripts/painted_actor.gd")
const Projectile = preload("res://scripts/projectile.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const FloatingText = preload("res://scripts/floating_text.gd")

var ally_id: String = "goblin_archer"
var display_name: String = "GOBLIN ARCHER"
var role: String = "archer" # Core class id, or "wolf" / "skeleton" for summons.
var max_hp: int = 80
var hp: int = 80
var speed: float = 200.0
var damage: int = 15
var attack_range: float = 280.0
var slot_index: int = 0
var appearance_animation = DirectionalActor.new()
var class_animation = ClassAnimation.new()
var blade_animation = BladeAnimation.new()
var summon_animation = SummonAnimation.new()
var animation_time: float = 0.0
var cooldown: float = 0.6
var support_cooldown: float = 2.5
var swing_time: float = 0.0
var flash: float = 0.0
var warcry_timer: float = 0.0
var faces_left: bool = false

func _ready() -> void:
	add_to_group("allies")
	collision_layer = 0
	collision_mask = 1
	hp = max_hp

func _physics_process(delta: float) -> void:
	animation_time += delta
	summon_animation.configure(role)
	class_animation.set_class(role)
	appearance_animation.configure(role)
	z_index = int(position.y)
	cooldown = maxf(0.0, cooldown - delta)
	support_cooldown = maxf(0.0, support_cooldown - delta)
	swing_time = maxf(0.0, swing_time - delta)
	flash = maxf(0.0, flash - delta)
	warcry_timer = maxf(0.0, warcry_timer - delta)
	if hp <= 0 or not is_visible_in_tree():
		if is_visible_in_tree():
			summon_animation.update(delta, Vector2.ZERO, hp > 0, warcry_timer)
		velocity = Vector2.ZERO
		queue_redraw()
		return
	var player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var target := _choose_enemy_target(player)
	var formation_offset := Vector2(-58 - (slot_index % 2) * 36, -48 + (slot_index * 34))
	var desired_pos: Vector2 = player.global_position + formation_offset
	if is_instance_valid(target):
		var to_enemy := target.global_position - global_position
		faces_left = to_enemy.x < 0.0
		var dist := to_enemy.length()
		var effective_dmg := int(damage * (1.35 if warcry_timer > 0.0 else 1.0))
		if role in ["archer", "mage"]:
			if dist <= attack_range and cooldown <= 0.0:
				_fire_projectile(target.global_position, effective_dmg)
				cooldown = 0.92 if role == "archer" else 1.12
				swing_time = 0.18
				summon_animation.start_attack(faces_left)
				appearance_animation.start_attack(0.34 if role == "blade" else 0.4)
				class_animation.start_attack()
			if dist < 135.0:
				velocity = -to_enemy.normalized() * speed * 0.85
			elif dist > attack_range * 0.88:
				velocity = _route_to(target.global_position) * speed
			else:
				velocity = Vector2.ZERO
		else:
			if dist <= attack_range and cooldown <= 0.0:
				target.take_damage(effective_dmg, to_enemy.normalized())
				if target.has_method("apply_status"):
					target.apply_status(5 if role in ["berserker", "rogue", "wolf"] else 0, 4 if role == "rogue" else 0, 0.0)
				cooldown = 0.68 if role == "blade" else (1.0 if role == "knight" else 0.82)
				swing_time = 0.18
				summon_animation.start_attack(faces_left)
				appearance_animation.start_attack(0.34 if role == "blade" else 0.4)
				if role == "blade":
					blade_animation.start_attack()
				elif role == "knight":
					class_animation.start_attack()
				velocity = Vector2.ZERO
			else:
				velocity = _route_to(target.global_position) * speed
	else:
		var to_slot := desired_pos - global_position
		if to_slot.length() > 26.0:
			velocity = _route_to(desired_pos) * speed * 0.9
			faces_left = velocity.x < -5.0
		else:
			velocity = Vector2.ZERO
	move_and_slide()
	summon_animation.update(delta, velocity, hp > 0, warcry_timer)
	appearance_animation.update(delta, velocity, hp > 0, velocity.length() / maxf(speed, 1.0))
	if role == "blade":
		blade_animation.update(delta, velocity.length() > 5.0, hp > 0, velocity.length() / maxf(speed, 1.0))
	elif ClassAnimation.SHEETS.has(role):
		class_animation.update(delta, velocity.length() > 5.0, hp > 0, velocity.length() / maxf(speed, 1.0))
	queue_redraw()

func _choose_enemy_target(player: Node2D) -> Node2D:
	var best: Node2D = null
	var best_score: float = 999999.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		# Goblin Rogues and Archers prioritize enemy Priests, Mages, and Rangers!
		if role in ["blade", "archer"] and enemy.get("role") in ["priest", "mage", "ranger"]:
			dist *= 0.55
		if dist < best_score:
			best_score = dist
			best = enemy
	return best

func _fire_projectile(target_pos: Vector2, dmg: int) -> void:
	var shot := Projectile.new()
	shot.global_position = global_position + Vector2(0, -14)
	shot.velocity = (target_pos - global_position).normalized() * 410.0
	shot.damage = dmg
	shot.from_player_team = true
	shot.style = "hex" if role == "mage" else "arrow"
	shot.poison_dps = 6 if role == "mage" else 4
	shot.splash_radius = 48.0 if role == "mage" else 0.0
	get_parent().add_child(shot)

func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.15
	# Polish: floating damage on allies
	var parent_node := get_parent()
	if is_instance_valid(parent_node):
		FloatingText.spawn_player_hit(parent_node, global_position + Vector2(0, -24), amount)
	queue_redraw()
	if hp == 0:
		appearance_animation.update(0.0, Vector2.ZERO, false)
		blade_animation.update(0.0, false, false)
		class_animation.update(0.0, false, false)
		# Polish: death effect for fallen ally
		if is_instance_valid(parent_node):
			DeathEffect.burst_ally(parent_node, global_position)

func revive_and_heal() -> void:
	hp = max_hp
	flash = 0.0
	summon_animation = SummonAnimation.new()
	summon_animation.configure(role)
	blade_animation = BladeAnimation.new()
	class_animation = ClassAnimation.new(role)
	appearance_animation = DirectionalActor.new()
	appearance_animation.configure(role)
	queue_redraw()

func _draw() -> void:
	var tint := Color.WHITE
	var draw_size := 74.0
	if role == "knight":
		draw_size = 80.0
	elif role == "wolf":
		draw_size = 90.0
	elif role == "skeleton":
		tint = Color.WHITE
		draw_size = 72.0
	var actor_texture: Texture2D = CLASS_ART.get(role, FALLBACK_ART)
	var role_overlay := "" if CLASS_ART.has(role) else role
	if SummonAnimation.SHEETS.has(role):
		summon_animation.configure(role)
		summon_animation.draw_actor(self, draw_size, flash > 0.0, hp <= 0)
	elif CLASS_ART.has(role) and appearance_animation.uses_sheet():
		appearance_animation.draw_actor(self, draw_size, faces_left, velocity.length() > 5.0, flash > 0.0, hp <= 0, tint)
	elif role == "blade":
		blade_animation.draw_actor(self, draw_size, faces_left, velocity.length() > 5.0, flash > 0.0, hp <= 0, tint)
	elif ClassAnimation.SHEETS.has(role):
		class_animation.set_class(role)
		class_animation.draw_actor(self, draw_size, faces_left, velocity.length() > 5.0, flash > 0.0, hp <= 0, tint)
	else:
		PaintedActor.draw_actor(self, actor_texture, draw_size, faces_left, animation_time,
			velocity.length() > 5.0, swing_time > 0.0, flash > 0.0, hp <= 0, tint, role_overlay)
	if hp <= 0:
		return
	if warcry_timer > 0.0:
		draw_arc(Vector2.ZERO, 24.0, 0, TAU, 20, Color(0.95, 0.72, 0.32, 0.55), 2.0, true)
	var top := -draw_size * 0.85
	draw_rect(Rect2(-42, top - 12, 84, 14), Color(0.03, 0.04, 0.03, 0.75))
	draw_string(ThemeDB.fallback_font, Vector2(-38, top - 1), display_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("b8e0a2"))
	draw_rect(Rect2(-24, top + 4, 48, 4), Color("233022"))
	draw_rect(Rect2(-24, top + 4, 48.0 * float(hp) / max_hp, 4), Color("79c96b"))

func _route_to(destination: Vector2) -> Vector2:
	var cave = get_tree().current_scene.get_node_or_null("Cave") if get_tree().current_scene != null else get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("route_direction"):
		return cave.route_direction(global_position, destination)
	return global_position.direction_to(destination)

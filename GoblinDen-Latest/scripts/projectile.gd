extends Node2D
## Ranged projectile for Archer Goblin arrows, Mage Goblin hex/fire bolts,
## Goblin Ally shots, and Human Ranger/Mage/Priest attacks.

const FloatingText = preload("res://scripts/floating_text.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")

var velocity := Vector2.RIGHT * 420.0
var damage: int = 20
var from_player_team: bool = true
var style: String = "arrow" # "arrow", "hex", "fire", "human_arrow", "smite"
var poison_dps: int = 0
var bleed_dps: int = 0
var slow_time: float = 0.0
var splash_radius: float = 0.0
var lifesteal_ratio: float = 0.0
var owner_actor: Node2D = null
var lifetime: float = 1.6
var hit_done: bool = false

func _physics_process(delta: float) -> void:
	if hit_done or not is_visible_in_tree():
		return
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	var next_pos := global_position + velocity * delta
	# Check wall collision on layer 1 (Cave)
	var ray := PhysicsRayQueryParameters2D.create(global_position, next_pos, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		_detonate()
		return
	global_position = next_pos
	z_index = int(position.y)
	if from_player_team:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
				continue
			if enemy.global_position.distance_to(global_position) <= 28.0:
				_apply_to_enemy(enemy)
				_detonate()
				return
	else:
		var targets: Array[Node] = []
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player) and player.hp > 0:
			targets.append(player)
		for ally in get_tree().get_nodes_in_group("allies"):
			if is_instance_valid(ally) and ally.is_visible_in_tree() and ally.hp > 0:
				targets.append(ally)
		for target in targets:
			if target.global_position.distance_to(global_position) <= 24.0:
				target.take_damage(damage)
				_detonate()
				return
	queue_redraw()

func _apply_to_enemy(primary_enemy: Node2D) -> void:
	var dir := velocity.normalized()
	if splash_radius > 0.0:
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
				continue
			if enemy.global_position.distance_to(global_position) <= splash_radius:
				var mult := 1.0 if enemy == primary_enemy else 0.65
				var dealt := maxi(1, int(damage * mult))
				enemy.take_damage(dealt, dir * 0.5)
				_show_damage(enemy, dealt)
				if enemy.has_method("apply_status"):
					enemy.apply_status(bleed_dps, poison_dps, slow_time)
	else:
		primary_enemy.take_damage(damage, dir * 0.6)
		_show_damage(primary_enemy, damage)
		if primary_enemy.has_method("apply_status"):
			primary_enemy.apply_status(bleed_dps, poison_dps, slow_time)
	if lifesteal_ratio > 0.0 and is_instance_valid(owner_actor) and owner_actor.get("hp") != null:
		owner_actor.hp = mini(owner_actor.max_hp, owner_actor.hp + maxi(1, int(damage * lifesteal_ratio)))
		if owner_actor.has_signal("health_changed"):
			owner_actor.health_changed.emit(owner_actor.hp, owner_actor.max_hp)

func _show_damage(enemy: Node2D, amount: int) -> void:
	if is_instance_valid(owner_actor) and owner_actor.is_in_group("player"):
		FloatingText.spawn_damage(enemy.get_parent(), enemy.global_position + Vector2(0, -20), amount, false)

func _detonate() -> void:
	hit_done = true
	# Polish: impact spark effect at projectile hit location
	if is_instance_valid(get_parent()):
		HitSpark.projectile_hit(get_parent(), global_position, style)
	queue_free()

func _draw() -> void:
	var angle := velocity.angle()
	draw_set_transform(Vector2.ZERO, angle, Vector2.ONE)
	if style == "cursed_coin":
		draw_circle(Vector2.ZERO, 8.0, Color("d49d3a"))
		draw_arc(Vector2.ZERO, 6.0, 0, TAU, 16, Color("fff0a5"), 2, true)
		draw_line(Vector2(-3,-3),Vector2(3,3),Color("8d5c29"),2,true)
	elif style == "arrow" or style == "human_arrow":
		var shaft_color := Color("a9d67c") if style == "arrow" else Color("e6c88a")
		var tip_color := Color("6bd968") if poison_dps > 0 else Color("dcd9ce")
		draw_line(Vector2(-14, 0), Vector2(10, 0), shaft_color, 2.5, true)
		draw_colored_polygon(PackedVector2Array([Vector2(14, 0), Vector2(6, -5), Vector2(6, 5)]), tip_color)
		draw_line(Vector2(-14, 0), Vector2(-19, -4), shaft_color, 1.5, true)
		draw_line(Vector2(-14, 0), Vector2(-19, 4), shaft_color, 1.5, true)
	elif style == "hex" or style == "fire":
		var core := Color("c66be8") if style == "hex" else Color("ff7b39")
		var outer := Color(core.r, core.g, core.b, 0.28)
		draw_circle(Vector2.ZERO, 12.0, outer)
		draw_circle(Vector2.ZERO, 6.5, core)
		draw_circle(Vector2(2, 0), 3.0, Color("fff0c4"))
	else:
		draw_circle(Vector2.ZERO, 9.0, Color(1.0, 0.9, 0.5, 0.35))
		draw_circle(Vector2.ZERO, 5.0, Color("ffe89e"))
	draw_set_transform(Vector2.ZERO)

extends Node2D
## Persistent poison field dropped by the Rootvein Giant Spider.

var radius: float = 92.0
var duration: float = 5.5
var elapsed: float = 0.0
var tick_timer: float = 0.35
var damage_per_tick: int = 7

func _ready() -> void:
	z_index = 12
	add_to_group("enemy_hazards")

func _process(delta: float) -> void:
	elapsed += delta
	tick_timer -= delta
	if tick_timer <= 0.0:
		tick_timer += 0.75
		_damage_inside()
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _damage_inside() -> void:
	var victims: Array[Node] = []
	var player := get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		victims.append(player)
	victims.append_array(get_tree().get_nodes_in_group("allies"))
	for victim in victims:
		if is_instance_valid(victim) and victim.get("hp") != null and victim.hp > 0:
			if victim.global_position.distance_to(global_position) <= radius:
				victim.take_damage(damage_per_tick)

func _draw() -> void:
	var fade := clampf(minf(elapsed / 0.5, (duration - elapsed) / 1.0), 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.18, 0.42, 0.10, 0.13 * fade))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 42, Color(0.48, 0.86, 0.20, 0.34 * fade), 2.0, true)
	for index in range(18):
		var angle := float(index) * 2.39 + elapsed * (0.32 + float(index % 3) * 0.13)
		var orbit := Vector2.from_angle(angle) * radius * (0.18 + float(index % 6) * 0.12)
		orbit.y += sin(elapsed * 1.7 + float(index)) * 12.0
		var bubble := 9.0 + float(index % 4) * 4.0
		draw_circle(orbit, bubble, Color(0.32, 0.62, 0.16, 0.07 * fade))
		draw_circle(orbit, 2.0 + float(index % 2), Color(0.66, 0.96, 0.28, 0.28 * fade))


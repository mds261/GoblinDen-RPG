extends Node2D
## Death burst particle effect. Spawns when an enemy or ally dies.
## Creates expanding ring + fading particles in the actor's tint color.

var particles: Array = []
var ring_radius: float = 0.0
var ring_max_radius: float = 48.0
var ring_alpha: float = 1.0
var ring_color: Color = Color("e0c090")
var lifetime: float = 0.0
var max_lifetime: float = 0.65

func _init() -> void:
	z_index = 150

func configure(count: int = 12, color: Color = Color("e0c090"), spread: float = 45.0) -> void:
	ring_color = color
	ring_max_radius = spread * 1.1
	particles.clear()
	for i in range(count):
		var angle := randf() * TAU
		var spd := randf_range(40.0, spread * 2.5)
		var size := randf_range(2.0, 5.0)
		particles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"size": size,
			"alpha": 1.0,
			"color_shift": randf_range(-0.1, 0.1)
		})

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	var t := lifetime / max_lifetime
	ring_radius = ring_max_radius * t
	ring_alpha = 1.0 - t
	# Update particles
	for p in particles:
		p["vel"] = p["vel"] * (1.0 - delta * 3.5)
		p["pos"] = p["pos"] + p["vel"] * delta
		p["alpha"] = maxf(0.0, 1.0 - t * 1.2)
	queue_redraw()

func _draw() -> void:
	# Expanding impact ring
	if ring_alpha > 0.0:
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 32, Color(ring_color.r, ring_color.g, ring_color.b, ring_alpha * 0.6), 2.0, true)
		draw_arc(Vector2.ZERO, ring_radius * 0.6, 0, TAU, 24, Color(ring_color.r, ring_color.g, ring_color.b, ring_alpha * 0.3), 1.0, true)
	# Scattered particles
	for p in particles:
		if p["alpha"] <= 0.0:
			continue
		var col := Color(
			clampf(ring_color.r + p["color_shift"], 0.0, 1.0),
			clampf(ring_color.g + p["color_shift"], 0.0, 1.0),
			clampf(ring_color.b + p["color_shift"], 0.0, 1.0),
			p["alpha"] * 0.85
		)
		draw_circle(p["pos"], p["size"] * p["alpha"], col)

# ---- Static factory helpers ----

static func burst_enemy(parent: Node, world_pos: Vector2) -> void:
	var fx := new()
	fx.global_position = world_pos
	fx.configure(14, Color("e0a888"), 42.0)
	parent.add_child(fx)

static func burst_boss(parent: Node, world_pos: Vector2) -> void:
	var fx := new()
	fx.global_position = world_pos
	fx.configure(22, Color("ffd070"), 65.0)
	fx.max_lifetime = 0.9
	fx.ring_max_radius = 75.0
	parent.add_child(fx)

static func burst_ally(parent: Node, world_pos: Vector2) -> void:
	var fx := new()
	fx.global_position = world_pos
	fx.configure(10, Color("7ce69a"), 36.0)
	fx.max_lifetime = 0.55
	parent.add_child(fx)

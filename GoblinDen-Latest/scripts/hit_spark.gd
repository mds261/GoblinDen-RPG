extends Node2D
## Brief impact spark/burst when a melee or projectile attack connects.
## Flashes bright then rapidly contracts.

var lifetime: float = 0.0
var max_lifetime: float = 0.18
var spark_color: Color = Color("ffe8a0")
var spark_count: int = 6
var sparks: Array = []
var base_size: float = 18.0

func _init() -> void:
	z_index = 180

func configure(color: Color = Color("ffe8a0"), size: float = 18.0, count: int = 6) -> void:
	spark_color = color
	base_size = size
	spark_count = count
	sparks.clear()
	for i in range(count):
		var angle := randf() * TAU
		var len := randf_range(size * 0.4, size * 1.2)
		sparks.append({
			"angle": angle,
			"length": len,
			"width": randf_range(1.5, 3.0)
		})

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := lifetime / max_lifetime
	var alpha := 1.0 - t
	var scale_factor := 1.0 + t * 0.5
	# Central flash
	draw_circle(Vector2.ZERO, base_size * (1.0 - t * 0.8) * 0.6, Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.7))
	# Radiating spark lines
	for s in sparks:
		var dir := Vector2.from_angle(float(s["angle"]))
		var start: Vector2 = dir * base_size * 0.2 * scale_factor
		var end: Vector2 = dir * float(s["length"]) * alpha * scale_factor
		var col := Color(spark_color.r, spark_color.g, spark_color.b, alpha * 0.9)
		draw_line(start, end, col, float(s["width"]) * alpha, true)

# ---- Static factory ----

static func melee_hit(parent: Node, world_pos: Vector2, is_crit: bool = false) -> void:
	var fx := new()
	fx.global_position = world_pos
	if is_crit:
		fx.configure(Color("ffaa44"), 28.0, 10)
		fx.max_lifetime = 0.25
	else:
		fx.configure(Color("ffe8a0"), 16.0, 6)
	parent.add_child(fx)

static func projectile_hit(parent: Node, world_pos: Vector2, style: String = "arrow") -> void:
	var fx := new()
	fx.global_position = world_pos
	match style:
		"hex":
			fx.configure(Color("d080f0"), 22.0, 8)
		"fire":
			fx.configure(Color("ff7030"), 24.0, 9)
			fx.max_lifetime = 0.22
		"human_arrow":
			fx.configure(Color("e6d090"), 14.0, 5)
		"smite":
			fx.configure(Color("fff0a0"), 20.0, 8)
		_:
			fx.configure(Color("a0e870"), 14.0, 5)
	parent.add_child(fx)

static func trap_spring(parent: Node, world_pos: Vector2) -> void:
	var fx := new()
	fx.global_position = world_pos
	fx.configure(Color("88d060"), 32.0, 10)
	fx.max_lifetime = 0.3
	parent.add_child(fx)

extends Node2D
## Floating damage/heal/status number that drifts upward and fades out.
## Color-coded by type: yellow=normal, orange=crit, red=player-hit,
## green=heal, purple=poison, crimson=bleed, cyan=stun.

var text_value: String = "0"
var text_color: Color = Color("f0dfa0")
var text_size: int = 18
var lifetime: float = 0.0
var max_lifetime: float = 0.9
var drift_velocity := Vector2(0, -65)
var drift_decel: float = 40.0
var scale_start: float = 1.2
var outline: bool = true

func _ready() -> void:
	z_index = 200
	# Slight random horizontal jitter so stacked numbers don't overlap
	drift_velocity.x += randf_range(-18, 18)

func _process(delta: float) -> void:
	lifetime += delta
	if lifetime >= max_lifetime:
		queue_free()
		return
	# Decelerating upward drift
	drift_velocity.y += drift_decel * delta * sign(drift_velocity.y) * -0.3
	position += drift_velocity * delta
	# Pop-in scale then settle
	var t := lifetime / max_lifetime
	var scale_factor := scale_start * (1.0 - t * 0.3) if t < 0.15 else 1.0 - t * 0.2
	queue_redraw()

func _draw() -> void:
	var t := lifetime / max_lifetime
	var alpha := 1.0 - smoothstep(0.5, 1.0, t)
	var col := Color(text_color.r, text_color.g, text_color.b, alpha)
	var font := ThemeDB.fallback_font
	var text_size_scaled := int(text_size * (scale_start if t < 0.08 else 1.0 - t * 0.15))
	var text_width := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size_scaled).x
	if outline:
		var shadow := Color(0.02, 0.015, 0.01, alpha * 0.85)
		draw_string(font, Vector2(-text_width * 0.5 + 1, 1), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size_scaled, shadow)
	draw_string(font, Vector2(-text_width * 0.5, 0), text_value, HORIZONTAL_ALIGNMENT_LEFT, -1, text_size_scaled, col)

# ---- Static helpers to spawn floating text at a world position ----

static func spawn_damage(parent: Node, world_pos: Vector2, amount: int, is_crit: bool = false) -> void:
	var ft := new()
	ft.global_position = world_pos + Vector2(randf_range(-8, 8), -12)
	ft.text_value = str(amount)
	ft.text_color = Color("ffb84d") if not is_crit else Color("ff6b3d")
	ft.text_size = 22 if is_crit else 16
	ft.max_lifetime = 1.0 if is_crit else 0.75
	ft.scale_start = 1.5 if is_crit else 1.15
	parent.add_child(ft)

static func spawn_player_hit(parent: Node, world_pos: Vector2, amount: int) -> void:
	var ft := new()
	ft.global_position = world_pos + Vector2(randf_range(-12, 12), -18)
	ft.text_value = str(amount)
	ft.text_color = Color("ff5555")
	ft.text_size = 20
	ft.max_lifetime = 0.85
	ft.scale_start = 1.4
	parent.add_child(ft)

static func spawn_heal(parent: Node, world_pos: Vector2, amount: int) -> void:
	var ft := new()
	ft.global_position = world_pos + Vector2(0, -20)
	ft.text_value = "+%d" % amount
	ft.text_color = Color("6ce68a")
	ft.text_size = 17
	ft.max_lifetime = 0.8
	parent.add_child(ft)

static func spawn_status(parent: Node, world_pos: Vector2, label: String, color: Color) -> void:
	var ft := new()
	ft.global_position = world_pos + Vector2(0, -26)
	ft.text_value = label
	ft.text_color = color
	ft.text_size = 14
	ft.max_lifetime = 1.0
	ft.drift_velocity = Vector2(0, -35)
	parent.add_child(ft)

static func spawn_loot(parent: Node, world_pos: Vector2, label: String) -> void:
	var ft := new()
	ft.global_position = world_pos + Vector2(0, -24)
	ft.text_value = label
	ft.text_color = Color("ffd966")
	ft.text_size = 16
	ft.max_lifetime = 1.2
	ft.drift_velocity = Vector2(0, -40)
	ft.scale_start = 1.35
	parent.add_child(ft)

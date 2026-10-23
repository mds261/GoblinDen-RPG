extends RefCounted
## Original sheets are sampled directly; alpha and artwork stay untouched.
const WALK = preload("res://assets/blade_walk_sheet.png")
const ATTACK = preload("res://assets/blade_attack_sheet.png")
const WALK_FRAMES := 24 # Last cell repeats the opening pose.
const WALK_FPS := 28.0
const ATTACK_FIRST := 5 # Skip the opening and closing repeated ready poses.
const ATTACK_FRAMES := 15

var walk_time: float = 0.0
var attack_elapsed: float = 0.0
var attack_duration: float = 0.34
var attacking: bool = false

func start_attack(duration: float = 0.34) -> void:
	attack_elapsed = 0.0
	attack_duration = maxf(0.08, duration)
	attacking = true

func update(delta: float, moving: bool, alive: bool, movement_rate: float = 1.0) -> void:
	if not alive:
		attacking = false
		return
	if attacking:
		attack_elapsed += delta
		if attack_elapsed >= attack_duration:
			attacking = false
	if moving and not attacking:
		walk_time += delta * clampf(movement_rate, 0.4, 2.8)
	elif not moving:
		walk_time = 0.0

func frame_index(moving: bool) -> int:
	if attacking:
		return ATTACK_FIRST + mini(ATTACK_FRAMES - 1, int(attack_elapsed / attack_duration * ATTACK_FRAMES))
	return int(walk_time * WALK_FPS) % WALK_FRAMES if moving else 0

func draw_actor(canvas: Node2D, size: float, faces_left: bool, moving: bool,
		hurt: bool, dead: bool, tint: Color = Color.WHITE, role_tag: String = "") -> void:
	var texture: Texture2D = ATTACK if attacking else WALK
	var cell: float = 512.0 if attacking else 256.0
	var frame := frame_index(moving)
	var source := Rect2(float(frame % 5) * cell, floorf(float(frame) / 5.0) * cell, cell, cell)
	# Match visible body height rather than the sheets' very different padding.
	var factor := size * 0.83 / (192.0 if attacking else 207.0)
	var anchor := Vector2(256, 482) if attacking else Vector2(128, 238)
	var direction := -1.0 if faces_left else 1.0
	canvas.draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.36))
	canvas.draw_circle(Vector2.ZERO, size * 0.25, Color(0.01, 0.015, 0.01, 0.45))
	var color := tint
	if hurt:
		color = color.lerp(Color(1.6, 1.3, 1.1, color.a), 0.5)
	if dead:
		color = Color(0.45, 0.43, 0.4, 0.75)
	canvas.draw_set_transform(Vector2(0, 10 if not dead else 16), -1.35 if dead else 0.0, Vector2(direction, 1.0))
	canvas.draw_texture_rect_region(texture, Rect2(-anchor * factor, Vector2.ONE * cell * factor), source, color)
	if not dead and role_tag == "assassin":
		canvas.draw_line(Vector2(-size * 0.18, -size * 0.24), Vector2(-size * 0.02, -size * 0.19), Color("88d97c"), 2.5, true)
	elif not dead and role_tag == "berserker":
		canvas.draw_circle(Vector2(0, -size * 0.42), 5.0, Color(0.9, 0.25, 0.18, 0.65))
	canvas.draw_set_transform(Vector2.ZERO)

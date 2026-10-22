extends RefCounted
## Real pose clips for companion quadrupeds and undead. Rendering never moves colliders.
const Frames = preload("res://scripts/summon_frames.gd")
const ATTACK_SHEET = preload("res://assets/summons/attacks.png")
const SHEETS := {
	"wolf": preload("res://assets/summons/wolf.png"),
	"skeleton": preload("res://assets/summons/skeleton.png")
}
var kind := "wolf"
var direction := "down"
var faces_left := false
var walk_time := 0.0
var age := 0.0
var attack_elapsed := 10.0
var death_elapsed := 0.0
var buff_elapsed := 10.0
var last_buff := 0.0
var moving := false
var attack_duration := 0.38

func configure(role: String) -> void:
	if SHEETS.has(role):
		kind = role

func start_attack(left: bool) -> void:
	attack_elapsed = 0.0
	faces_left = left

func update(delta: float, movement: Vector2, alive: bool, buff: float = 0.0) -> void:
	age += delta
	if not alive:
		death_elapsed += delta
		moving = false
		return
	attack_elapsed += delta
	if buff > last_buff + 0.1:
		buff_elapsed = 0.0
	buff_elapsed += delta
	last_buff = buff
	moving = movement.length() > 5.0
	if moving and attack_elapsed >= attack_duration:
		if absf(movement.y) > absf(movement.x) * 1.15:
			direction = "up" if movement.y < 0.0 else "down"
		elif absf(movement.x) > absf(movement.y) * 1.15:
			direction = "side"
		if absf(movement.x) > 5.0:
			faces_left = movement.x < 0.0
		walk_time += delta
	elif not moving:
		walk_time = 0.0

func frame_index(dead: bool = false) -> int:
	if dead:
		return 16 + mini(3, int(death_elapsed / 0.65 * 4.0))
	if attack_elapsed < attack_duration:
		return 12 + mini(3, int(attack_elapsed / attack_duration * 4.0))
	var first := 4 if direction == "up" else (8 if direction == "side" else 0)
	return first + (int(walk_time * (8.0 if kind == "wolf" else 6.0)) % 4 if moving else 0)

func draw_actor(canvas: Node2D, size: float, hurt: bool, dead: bool) -> void:
	var data: Dictionary = Frames.DATA[kind]
	var index := frame_index(dead)
	var region: Rect2 = data["regions"][index]
	var anchor: Vector2 = data["anchors"][index]
	var factor := size / float(data["body_size"])
	var is_attack := index >= 12 and index < 16
	if is_attack:
		factor *= float(data["attack_scale"])
	var side := dead or attack_elapsed < attack_duration or direction == "side"
	var flip := -1.0 if side and faces_left else 1.0
	var arrival := clampf(age / 0.55, 0.0, 1.0)
	var breath := sin(age * 3.2) * 0.6 if not moving and not dead else 0.0
	canvas.draw_set_transform(Vector2(0, 8), 0.0, Vector2(1, 0.32))
	canvas.draw_circle(Vector2.ZERO, size * (0.36 if kind == "wolf" else 0.23), Color(0, 0.01, 0.01, 0.4))
	canvas.draw_set_transform(Vector2.ZERO)
	if arrival < 1.0 or buff_elapsed < 0.75:
		var p := arrival if arrival < 1.0 else buff_elapsed / 0.75
		var col := Color("7fffd8") if kind == "skeleton" else Color("ffb958")
		canvas.draw_set_transform(Vector2(0, 6), 0.0, Vector2(1, 0.4))
		canvas.draw_arc(Vector2.ZERO, size * (0.18 + p * 0.35), 0, TAU, 40, Color(col, (1.0 - p) * 0.85), 3.0, true)
		canvas.draw_set_transform(Vector2.ZERO)
		for i in range(7):
			var a := float(i) * TAU / 7.0 + p * 2.0
			var point := Vector2(cos(a) * size * 0.3, -p * 45.0 + sin(a) * 8.0)
			canvas.draw_circle(point, 2.0, Color(col, 1.0 - p))
	var tint := Color(1.7, 1.35, 1.1, 1) if hurt else Color.WHITE
	if dead:
		tint = Color(0.64, 0.68, 0.65, 0.85)
	else:
		tint.a = arrival
	var rise := (1.0 - arrival) * 18.0 if kind == "skeleton" else 0.0
	canvas.draw_set_transform(Vector2(0, 8 + rise + breath), 0.0, Vector2(flip, 1))
	canvas.draw_texture_rect_region(ATTACK_SHEET if is_attack else SHEETS[kind], Rect2(-anchor * factor, region.size * factor), region, tint)
	canvas.draw_set_transform(Vector2.ZERO)

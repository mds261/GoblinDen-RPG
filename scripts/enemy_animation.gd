extends RefCounted
## Pose playback reads combat state; visual clips never apply damage or move bodies.
const Frames = preload("res://scripts/enemy_animation_frames.gd")
const SHEETS := {
	"knight": preload("res://assets/enemies/knight.png"),
	"captain": preload("res://assets/enemies/captain.png"),
	"ranger": preload("res://assets/enemies/ranger.png"),
	"mage": preload("res://assets/enemies/mage.png"),
	"priest": preload("res://assets/enemies/priest.png"),
	"rogue": preload("res://assets/enemies/rogue.png"),
	"ogre": preload("res://assets/enemies/ogre.png"),
	"wolf_rider": preload("res://assets/enemies/wolf_rider.png"),
	"wolf": preload("res://assets/enemies/wolf.png"),
	"spider": preload("res://assets/enemies/spider.png")
}
const WALK_FPS := {"ogre": 5.0, "wolf": 8.5, "spider": 9.0, "wolf_rider": 7.0}
var kind := "knight"
var variant := "knight"
var direction := "down"
var faces_left := false
var state := "idle"
var walk_time := 0.0
var age := 0.0
var attack_phase := 0.0
var release_elapsed := 9.0
var release_duration := 0.28
var death_elapsed := 0.0
const DEATH_DURATION := 0.40

func configure(id: String) -> void:
	var selected := "captain" if id == "boss" else ("spider" if id == "spiderling" else id)
	if not SHEETS.has(selected):
		selected = "knight"
	variant = id
	if selected != kind:
		kind = selected
		reset()

func reset() -> void:
	state = "idle"
	attack_phase = 0.0
	release_elapsed = 9.0
	death_elapsed = 0.0
	walk_time = 0.0

func release_attack(duration: float = 0.28) -> void:
	release_duration = maxf(duration, 0.08)
	release_elapsed = 0.0
	attack_phase = 0.5
	state = "release"

func select_direction(movement: Vector2) -> void:
	if movement.length() <= 5.0:
		return
	if absf(movement.y) > absf(movement.x) * 1.15:
		direction = "up" if movement.y < 0.0 else "down"
	elif absf(movement.x) > absf(movement.y) * 1.15:
		direction = "side"
	if absf(movement.x) > 5.0:
		faces_left = movement.x < 0.0

func update(delta: float, movement: Vector2, alive: bool, windup: float = 0.0,
		windup_total: float = 0.65, aim: Vector2 = Vector2.ZERO, stunned: bool = false) -> void:
	age += delta
	if not alive:
		state = "death"
		death_elapsed += delta
		release_elapsed = 9.0
		return
	if stunned:
		state = "stunned"
		release_elapsed = 9.0
		return
	if windup > 0.0:
		state = "windup"
		attack_phase = clampf(1.0 - windup / maxf(windup_total, 0.01), 0.0, 0.999) * 0.5
		release_elapsed = 9.0
		if absf(aim.x) > 0.01:
			faces_left = aim.x < 0.0
		return
	if release_elapsed < release_duration:
		release_elapsed += delta
		if release_elapsed < release_duration:
			state = "release"
			attack_phase = 0.5 + release_elapsed / release_duration * 0.5
			return
	select_direction(movement)
	state = "walk" if movement.length() > 5.0 else "idle"
	if state == "walk":
		walk_time += delta * (1.2 if variant == "spiderling" else 1.0)
	else:
		walk_time = 0.0

func frame_index() -> int:
	if state == "death":
		return 16 + mini(3, int(death_elapsed / DEATH_DURATION * 4.0))
	if state == "stunned":
		return 16
	if state in ["windup", "release"]:
		return 12 + mini(3, int(attack_phase * 4.0))
	var first := 4 if direction == "up" else (8 if direction == "side" else 0)
	return first + (int(walk_time * float(WALK_FPS.get(kind, 6.0))) % 4 if state == "walk" else 0)

func label_top(size: float) -> float:
	# Keep names/health above the tallest living pose, including raised weapons.
	var data: Dictionary = Frames.DATA[kind]
	var highest := 0.0
	for i in range(16):
		highest = maxf(highest, data["anchors"][i].y)
	return 9.0 - highest * size * 0.85 / float(data["body_size"]) - 14.0

func draw_actor(canvas: Node2D, size: float, hurt: bool = false) -> void:
	var data: Dictionary = Frames.DATA[kind]
	var index := frame_index()
	var region: Rect2 = data["regions"][index]
	var anchor: Vector2 = data["anchors"][index]
	var factor := size * 0.85 / float(data["body_size"])
	var horizontal := direction == "side" or state in ["windup", "release", "death", "stunned"]
	var flip := -1.0 if horizontal and faces_left else 1.0
	var color := Color(0.82, 1.0, 0.76) if variant == "spiderling" else Color.WHITE
	if hurt:
		color = color.lerp(Color(1.7, 1.35, 1.2), 0.65)
	if state == "death":
		color = Color(0.6, 0.58, 0.56, 0.8)
	canvas.draw_set_transform(Vector2(0, 9), 0.0, Vector2(1, 0.32))
	canvas.draw_circle(Vector2.ZERO, size * (0.35 if kind in ["wolf", "spider", "wolf_rider"] else 0.23), Color(0.01, 0.01, 0.01, 0.4))
	var breath := sin(age * 2.8) * 0.65 if state == "idle" else 0.0
	canvas.draw_set_transform(Vector2(0, 9 + breath), 0.0, Vector2(flip, 1))
	preload("res://scripts/atlas_clip.gd").draw_frame(canvas, SHEETS[kind], region, anchor, factor, color, data["clips"][index])
	canvas.draw_set_transform(Vector2.ZERO)

extends RefCounted
## Four-direction walking and distinct evolution atlases. Combat remains in actor scripts.
const Frames = preload("res://scripts/directional_frames.gd")
const SHEETS := {
	"blade": preload("res://assets/directional/blade.png"),
	"archer": preload("res://assets/directional/archer.png"),
	"knight": preload("res://assets/directional/knight.png"),
	"mage": preload("res://assets/directional/mage.png"),
	"assassin": preload("res://assets/directional/assassin.png"),
	"berserker": preload("res://assets/directional/berserker.png"),
	"hunter": preload("res://assets/directional/hunter.png"),
	"beastmaster": preload("res://assets/directional/beastmaster.png"),
	"warlord": preload("res://assets/directional/warlord.png"),
	"guardian": preload("res://assets/directional/guardian.png"),
	"shaman": preload("res://assets/directional/shaman.png"),
	"warlock": preload("res://assets/directional/warlock.png"),
	"necromancer": preload("res://assets/directional/necromancer.png")
}
const WALK_FPS := {"blade": 6.0, "archer": 5.5, "knight": 4.5, "mage": 5.0}
var class_id: String = "blade"
var visual_id: String = "blade"
var direction: String = "side"
var walk_time: float = 0.0
var attacking: bool = false
var attack_elapsed: float = 0.0
var attack_duration: float = 0.4
var faces_left: bool = false

func configure(base_class: String, evolution: String = "") -> void:
	if not WALK_FPS.has(base_class):
		return
	var selected := base_class
	if Frames.DATA.has(evolution) and Frames.DATA[evolution]["base"] == base_class:
		selected = evolution
	if class_id != base_class or visual_id != selected:
		class_id = base_class
		visual_id = selected
		walk_time = 0.0
		attacking = false
		attack_elapsed = 0.0

func select_direction(movement: Vector2) -> void:
	if movement.length() <= 5.0:
		return
	# A 15% dead band preserves the last axis around diagonals.
	if absf(movement.y) > absf(movement.x) * 1.15:
		direction = "up" if movement.y < 0.0 else "down"
	elif absf(movement.x) > absf(movement.y) * 1.15:
		direction = "side"
	elif direction != "side":
		direction = "up" if movement.y < 0.0 else "down"
	if absf(movement.x) > 5.0:
		faces_left = movement.x < 0.0

func update(delta: float, movement: Vector2, alive: bool, movement_rate: float = 1.0) -> void:
	if not alive:
		attacking = false
		return
	var moving := movement.length() > 5.0
	if not attacking:
		select_direction(movement)
	if attacking:
		attack_elapsed += delta
		if attack_elapsed >= attack_duration:
			attacking = false
	if moving and not attacking:
		walk_time += delta * clampf(movement_rate, 0.4, 2.8)
	elif not moving:
		walk_time = 0.0

func start_attack(duration: float = 0.4) -> void:
	attacking = true
	attack_elapsed = 0.0
	attack_duration = maxf(duration, 0.08)

func uses_sheet() -> bool:
	# Blade now has one coherent atlas for every movement view and attack.
	return visual_id == "blade" or visual_id != class_id or (direction != "side" and not attacking)

func frame_index(moving: bool) -> int:
	if attacking and (visual_id != class_id or visual_id == "blade"):
		return 12 + mini(3, int(attack_elapsed / attack_duration * 4.0))
	var first := 4 if direction == "up" else (8 if direction == "side" else 0)
	if visual_id == class_id and visual_id != "blade" and first == 8:
		first = 0 # Base side clips are drawn by their existing controller.
	return first + (int(walk_time * float(WALK_FPS[class_id])) % 4 if moving else 0)

func draw_actor(canvas: Node2D, size: float, attack_faces_left: bool, moving: bool,
		hurt: bool, dead: bool, tint: Color = Color.WHITE) -> void:
	var data: Dictionary = Frames.DATA[visual_id]
	var frame := frame_index(moving)
	var region: Rect2 = data["regions"][frame]
	var anchor: Vector2 = data["anchors"][frame]
	var factor := size * 0.83 / float(data["body_height"])
	var mirror := attack_faces_left if attacking else faces_left
	var horizontal := attacking or direction == "side"
	var flip := -1.0 if horizontal and mirror else 1.0
	canvas.draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.36))
	canvas.draw_circle(Vector2.ZERO, size * 0.25, Color(0.01, 0.015, 0.01, 0.45))
	var color := tint
	if hurt:
		color = color.lerp(Color(1.6, 1.3, 1.1, color.a), 0.5)
	if dead:
		color = Color(0.45, 0.43, 0.4, 0.75)
	canvas.draw_set_transform(Vector2(0, 10 if not dead else 16), -1.35 if dead else 0.0, Vector2(flip, 1.0))
	if data.has("clips"):
		preload("res://scripts/atlas_clip.gd").draw_frame(canvas, SHEETS[visual_id], region, anchor, factor, color, data["clips"][frame])
	else:
		canvas.draw_texture_rect_region(SHEETS[visual_id], Rect2(-anchor * factor, region.size * factor), region, color)
	canvas.draw_set_transform(Vector2.ZERO)

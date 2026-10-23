extends RefCounted
## Walk and attack playback for Archer, Knight and Mage; never moves physics bodies.
const Frames = preload("res://scripts/class_animation_frames.gd")
const SHEETS := {
	"archer": preload("res://assets/archer_animation_sheet.png"),
	"knight": preload("res://assets/knight_animation_sheet.png"),
	"mage": preload("res://assets/mage_animation_sheet.png")
}
const WALK_FPS := {"archer": 10.0, "knight": 8.0, "mage": 9.0}
var class_id: String = "archer"
var walk_time: float = 0.0
var idle_time: float = 0.0
var attack_elapsed: float = 0.0
var attack_duration: float = 0.4
var attacking: bool = false

func _init(new_class: String = "archer") -> void:
	set_class(new_class)

func set_class(new_class: String) -> void:
	if new_class == class_id or not SHEETS.has(new_class):
		return
	class_id = new_class
	walk_time = 0.0
	attacking = false
	attack_elapsed = 0.0

func start_attack(duration: float = 0.4) -> void:
	attack_elapsed = 0.0
	attack_duration = maxf(0.08, duration)
	attacking = true

func update(delta: float, moving: bool, alive: bool, movement_rate: float = 1.0) -> void:
	idle_time += delta
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
		return 8 + mini(7, int(attack_elapsed / attack_duration * 8.0))
	return int(walk_time * float(WALK_FPS[class_id])) % 8 if moving else 0

func draw_actor(canvas: Node2D, size: float, faces_left: bool, moving: bool,
		hurt: bool, dead: bool, tint: Color = Color.WHITE, role_tag: String = "") -> void:
	var frame := frame_index(moving)
	var data: Dictionary = Frames.DATA[class_id]
	var region: Rect2 = data["regions"][frame]
	var anchor: Vector2 = data["anchors"][frame]
	var scale_factor := size * 0.83 / float(data["body_height"])
	var direction := -1.0 if faces_left else 1.0
	canvas.draw_set_transform(Vector2(0, 10), 0.0, Vector2(1.0, 0.36))
	canvas.draw_circle(Vector2.ZERO, size * 0.25, Color(0.01, 0.015, 0.01, 0.45))
	var color := tint
	if hurt:
		color = color.lerp(Color(1.6, 1.3, 1.1, color.a), 0.5)
	if dead:
		color = Color(0.45, 0.43, 0.4, 0.75)
	canvas.draw_set_transform(Vector2(0, (10.0 + (sin(idle_time * 2.6) * 0.65 if not moving and not attacking else 0.0)) if not dead else 16.0), -1.35 if dead else 0.0, Vector2(direction, 1.0))
	canvas.draw_texture_rect_region(SHEETS[class_id], Rect2(-anchor * scale_factor, region.size * scale_factor), region, color)
	# Equipment is already painted into the frames. Keep evolution effects subtle.
	if not dead and role_tag == "shaman":
		canvas.draw_circle(Vector2(0, -size * 0.38), 3.0, Color(0.37, 0.88, 0.55, 0.55))
	elif not dead and role_tag == "necromancer":
		canvas.draw_circle(Vector2(0, -size * 0.38), 3.0, Color(0.48, 0.91, 0.83, 0.55))
	canvas.draw_set_transform(Vector2.ZERO)

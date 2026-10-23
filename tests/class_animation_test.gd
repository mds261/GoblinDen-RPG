extends SceneTree
const ClassAnim = preload("res://scripts/class_animation.gd")
const Frames = preload("res://scripts/class_animation_frames.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	for role in ["archer", "knight", "mage"]:
		var anim = ClassAnim.new(role)
		anim.update(0.25, true, true)
		check(anim.frame_index(true) > 0, role + " walk advances")
		anim.update(0.1, false, true)
		check(anim.frame_index(false) == 0, role + " idle resets")
		anim.start_attack()
		check(anim.frame_index(true) == 8, role + " attack begins at correct row")
		anim.update(0.2, true, true)
		check(anim.frame_index(true) == 12, role + " attack overrides walk")
		anim.update(0.21, true, true)
		check(not anim.attacking, role + " attack returns to locomotion")
		anim.start_attack()
		anim.update(0.01, true, false)
		check(not anim.attacking, role + " death cancels animation")
		var image_size: Vector2 = ClassAnim.SHEETS[role].get_size()
		var rects: Array = Frames.DATA[role]["regions"]
		check(rects.size() == 16, role + " has 16 poses")
		for i in range(16):
			var region: Rect2 = rects[i]
			check(Rect2(Vector2.ZERO, image_size).encloses(region), role + " frame is inside texture")
			for j in range(i):
				check(not region.intersects(rects[j]), role + " frames never overlap")
	var arena := Node2D.new()
	root.add_child(arena)
	var player = load("res://scenes/player.tscn").instantiate()
	arena.add_child(player)
	player.set_physics_process(false)
	for role in ["archer", "knight", "mage"]:
		player.apply_class_and_gear(role)
		player.attack_cooldown = 0.0
		player.attack()
		check(player.class_animation.class_id == role and player.class_animation.attacking, role + " primary attack wired")
		player.class_animation.update(1.0, false, true)
		player.special_cooldown = 0.0
		player.use_special()
		check(player.class_animation.attacking, role + " special wired")
	# Real companions must select the correct controller and trigger attacks.
	current_scene = arena
	var enemy = DummyEnemy.new()
	enemy.position = Vector2(60, 0)
	arena.add_child(enemy)
	enemy.add_to_group("enemies")
	for role in ["archer", "knight", "mage"]:
		var ally = load("res://scripts/goblin_ally.gd").new()
		ally.role = role
		ally.cooldown = 0.0
		ally.attack_range = 300.0
		arena.add_child(ally)
		ally.set_physics_process(false)
		ally._physics_process(0.01)
		check(ally.class_animation.class_id == role and ally.class_animation.attacking, role + " companion attack wired")
		ally.queue_free()
		await process_frame
	arena.queue_free()
	await process_frame
	print("Class animation checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(failures)

class DummyEnemy extends Node2D:
	var hp := 1000
	var role := "knight"
	func take_damage(amount: int, _direction: Vector2) -> void:
		hp -= amount
	func apply_status(_bleed: int, _poison: int, _slow: float) -> void:
		pass

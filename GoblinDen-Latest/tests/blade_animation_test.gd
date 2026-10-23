extends SceneTree
const BladeAnim = preload("res://scripts/blade_animation.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	var animation = BladeAnim.new()
	animation.update(0.1, true, true)
	check(animation.frame_index(true) > 0, "Movement advances walk poses")
	animation.update(24.0 / 28.0, true, true)
	check(animation.frame_index(true) == 2, "Walk wraps to the same phase")
	animation.update(0.1, false, true)
	check(animation.frame_index(false) == 0, "Stopping restores idle")
	animation.start_attack()
	check(animation.frame_index(true) == 5, "Attack starts at first unique pose")
	animation.update(0.17, true, true)
	check(animation.frame_index(true) == 12, "Attack takes priority over walking")
	animation.update(0.18, true, true)
	check(not animation.attacking, "Attack completes without looping")
	animation.start_attack()
	animation.update(0.01, false, false)
	check(not animation.attacking, "Death cancels playback")
	var player = load("res://scenes/player.tscn").instantiate()
	var arena := Node2D.new()
	root.add_child(arena)
	arena.add_child(player)
	player.set_physics_process(false)
	player.attack()
	check(player.blade_animation.attacking, "Primary attack triggers sprite sequence")
	var elapsed: float = player.blade_animation.attack_elapsed
	player.attack()
	check(player.blade_animation.attack_elapsed == elapsed, "Cooldown blocks restart")
	player.blade_animation.update(0.4, false, true)
	player.use_special()
	check(player.blade_animation.attacking, "Blade special triggers sprite sequence")
	player.apply_class_and_gear("mage")
	check(not player.blade_animation.attacking, "Class switch clears attack state")
	arena.queue_free()
	await process_frame
	print("Blade animation checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(failures)

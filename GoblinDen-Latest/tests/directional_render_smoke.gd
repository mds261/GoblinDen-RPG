extends SceneTree
var failures := 0

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.mouse_aim = false
	for base in game.player.GoblinData.CLASSES:
		var forms: Array = [""]
		forms.append_array(game.player.GoblinData.CLASSES[base]["evolutions"])
		for evolution in forms:
			game.player.apply_class_and_gear(base, evolution)
			game.player.dodge_time = 0.0
			for action in ["move_up", "move_down", "move_left", "move_right"]:
				Input.action_press(action)
				await physics_frame
				await physics_frame
				Input.action_release(action)
				game.player.queue_redraw()
				await process_frame
				var expected: String = "up" if action == "move_up" else ("down" if action == "move_down" else "side")
				if game.player.appearance_animation.direction != expected:
					failures += 1
					push_error(base + "/" + evolution + ": " + action + " selected wrong view")
	game.player.apply_class_and_gear("mage", "necromancer")
	Input.action_press("move_up")
	await physics_frame
	await physics_frame
	Input.action_release("move_up")
	await process_frame
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var args := OS.get_cmdline_user_args()
		if not args.is_empty():
			root.get_texture().get_image().save_png(args[0])
	print("Full-game directional rendering smoke: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	game.queue_free()
	await process_frame
	await process_frame
	quit(failures)

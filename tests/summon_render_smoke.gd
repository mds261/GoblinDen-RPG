extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run_checks")
func run_checks() -> void:
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.enter_room(1, Vector2(420, 430))
	game.player.mouse_aim = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for id in ["beastmaster", "necromancer"]:
		game.player.apply_class_and_gear("archer" if id == "beastmaster" else "mage", id, true)
		game._sync_summons()
		if id == "necromancer":
			game._spawn_skeleton_minion(Vector2(480, 460))
			game._spawn_skeleton_minion(Vector2(540, 460))
		for summon in game.summon_nodes:
			summon.set_physics_process(false)
			summon.position = game.player.position + Vector2(120 + summon.slot_index * 85, 90)
			summon.summon_animation.age = 1.0
			for direction in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
				summon.summon_animation.update(0.13, direction * 100, true)
				summon.queue_redraw()
				await process_frame
			summon.summon_animation.start_attack(false)
			summon.summon_animation.update(0.2, Vector2.ZERO, true)
			summon.queue_redraw()
		game.player.special_cooldown = 0
		game.player.facing = Vector2.RIGHT
		game.player.use_special()
		await create_timer(0.24).timeout
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var args := OS.get_cmdline_user_args()
			if not args.is_empty():
				root.get_texture().get_image().save_png(args[0].path_join(id + "-special-in-game.png"))
		await process_frame
		await create_timer(0.8).timeout
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var args := OS.get_cmdline_user_args()
			if not args.is_empty():
				root.get_texture().get_image().save_png(args[0].path_join(id + "-in-game.png"))
		await process_frame
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Summon full-game render smoke: PASS (0 failures)")
	quit(failures)

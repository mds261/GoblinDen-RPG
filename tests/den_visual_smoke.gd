extends SceneTree
func _initialize() -> void:
	call_deferred("capture")
func capture() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.player.mouse_aim = false
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var args := OS.get_cmdline_user_args()
	for room in [0, 7, 8, 9]:
		game.enter_room(room, Vector2(575, 470))
		game.notice_time = 0.0
		await create_timer(0.2).timeout
		if DisplayServer.get_name() != "headless" and not args.is_empty():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(args[0].path_join("Den-Room-%d.png" % room))
		await process_frame
	game.queue_free()
	await process_frame
	var cave = load("res://scripts/cave.gd").new()
	cave.scale = Vector2.ONE * 0.5
	root.add_child(cave)
	cave.configure_room(6)
	cave.debug_collision_overlay = true
	await process_frame
	if DisplayServer.get_name() != "headless" and not args.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(args[0].path_join("Outdoor-Collision-Overlay.png"))
	await process_frame
	cave.queue_free()
	load("res://scripts/save_data.gd").delete_save()
	print("Den rooms and collision overlay rendered successfully")
	quit()

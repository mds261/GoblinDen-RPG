extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for room in [0, 10, 11, 12, 6]:
		game.enter_room(room, Vector2(575, 420))
		await create_timer(0.1).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/goblin-room-%d.png" % room)
	game.rpg.open_storage("")
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/goblin-equipment.png")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	quit()

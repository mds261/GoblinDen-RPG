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
	for entry in [["chest",0,Vector2(350,480)],["npc",0,Vector2(550,335)],["door",0,Vector2(575,510)],["resource",6,Vector2(800,500)]]:
		game.enter_room(entry[1], entry[2])
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("user://movement-"+entry[0]+".png")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	quit()

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
	game.player.invulnerability = 999
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for floor_id in range(13,16):
		game.enter_room(floor_id,Vector2(1300,1000) if floor_id!=14 else Vector2(1580,1000))
		await create_timer(.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/dungeon-floor-%d.png"%floor_id)
	var boss = game.rpg.dungeon.boss
	boss.set_physics_process(false)
	game.enter_room(15,Vector2(2180,1260))
	boss.awaken()
	for state in ["reveal","hunt","bite","coins","slam","recover"]:
		boss.boss_state = state
		boss.state_total = 1.2
		boss.state_time = .65
		boss.strike_position = Vector2(2210,1230)
		boss.locked_direction = Vector2.LEFT
		boss.velocity = Vector2(70,0) if state=="hunt" else Vector2.ZERO
		await create_timer(.12).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/dungeon-boss-%s.png"%state)
	boss.flash = .2
	boss.hit_reaction = .2
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/dungeon-boss-hurt.png")
	boss.take_damage(99999)
	await create_timer(.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/dungeon-boss-defeat.png")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("Dungeon floors and boss animation states rendered")
	quit()

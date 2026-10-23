extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.enter_room(0, Vector2(520, 430))
	game.player.apply_class_and_gear("archer")
	game.spawn_enemy_ext(0, Vector2(660, 420), "SNARE PREVIEW", 1000, 0, 0, 0, "knight", 0, "")
	var enemy = game.rooms[0].get_child(game.rooms[0].get_child_count()-1)
	enemy.set_physics_process(false)
	var trap = load("res://scripts/trap.gd").new()
	trap.position = Vector2(640, 420)
	game.rooms[0].add_child(trap)
	trap.set_physics_process(false)
	trap.time = 0.6
	trap.queue_redraw()
	await create_timer(0.1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/snare-armed.png")
	var hp: int = enemy.hp
	trap._trigger(enemy)
	assert(enemy.hp == hp - trap.damage, "Trigger preserves existing damage")
	assert(enemy.slow_timer == trap.snare_time, "Trigger preserves snare duration")
	await create_timer(0.22).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("/tmp/snare-caught.png")
	var applied_hp: int = enemy.hp
	await create_timer(0.5).timeout
	assert(enemy.hp == applied_hp, "Visual cage does not apply additional damage")
	await create_timer(2.5).timeout
	for child in game.rooms[0].get_children():
		assert(child.get_script() != load("res://scripts/snare_effect.gd"), "Effect cleans itself up")
	print("Snare visuals rendered; damage, slow and cleanup checks passed")
	game.queue_free()
	await process_frame
	quit()

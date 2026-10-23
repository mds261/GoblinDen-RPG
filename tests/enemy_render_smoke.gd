extends SceneTree
var game: Node2D
var directory := ""
func _initialize() -> void:
	call_deferred("run_checks")
func photograph(name: String) -> void:
	game.notice_time = 0.0
	await create_timer(0.08).timeout
	if DisplayServer.get_name() != "headless" and not directory.is_empty():
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join(name + ".png"))
	await process_frame
func freeze_enemies() -> void:
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
func run_checks() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		directory = args[0]
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.invulnerability = 999
	game.player.set_physics_process(false)
	freeze_enemies()
	game.enter_room(1, Vector2(350, 510))
	for child in game.rooms[1].get_children():
		child.queue_free()
	await process_frame
	var roles := ["knight", "ranger", "mage", "priest", "rogue"]
	for i in range(roles.size()):
		game.spawn_enemy_ext(1, Vector2(180 + i * 195, 340), roles[i].to_upper(), 100, 100, 1, 0, roles[i], 0, "")
	freeze_enemies()
	for actor in game.rooms[1].get_children():
		actor.windup = 0.1
		actor.strike_position = game.player.global_position
		actor._process(0.01)
	await photograph("Human-Roles-In-Game")
	game.enter_room(2, Vector2(350, 510))
	var captain = game.rooms[2].get_child(0)
	captain._begin_attack("sweep", 0.95)
	captain._process(0.01)
	await photograph("Blue-Captain-In-Game")
	for room_id in [3, 4, 5]:
		game.enter_room(room_id, Vector2(340, 475))
		var boss: Node2D
		for actor in game.rooms[room_id].get_children():
			if actor.get("enemy_kind") != null:
				boss = actor
		boss.position = Vector2(730, 400)
		if room_id == 3:
			boss._summon_spiderlings()
			boss._drop_poison_cloud()
		elif room_id == 4:
			boss.special_attack = true
			boss.windup = 0.6
			boss.windup_total = 1.75
			boss.strike_position = game.player.global_position
		else:
			boss._ensure_wolf_pack()
		await process_frame
		freeze_enemies()
		boss._process(0.01)
		await photograph(["", "", "", "Spiders-In-Game", "Ogre-In-Game", "Wolf-Rider-and-Pack-In-Game"][room_id])
	load("res://scripts/save_data.gd").delete_save()
	print("Full-game enemy rendering smoke: PASS (humans, captain, spider brood, ogre, rider and wolves)")
	call_deferred("quit", 0)

extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.enter_room(10,Vector2(1000,600))
	await physics_frame
	var residents: Array = []
	for actor in get_nodes_in_group("friendly_npcs"):
		if int(actor.definition.room)==10:
			residents.append(actor)
			actor.rng.seed = 200+residents.size()
			actor.wait_time = 0
	for frame in range(150):
		await physics_frame
		for actor in residents:
			check(actor.position.distance_to(actor.home)<=actor.ROAM_RADIUS+1,"Resident stays near its home service")
			var query := PhysicsPointQueryParameters2D.new()
			query.position = actor.position
			query.collision_mask = 1
			check(game.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Walking resident remains outside scenery")
	var moved := 0
	for actor in residents:
		if actor.position.distance_to(actor.home)>8:
			moved += 1
	check(moved>=3,"Residents periodically leave their idle pose and walk")
	var keeper = game.rpg.npc_nodes.depot_keeper
	keeper.position = keeper.home+Vector2(86,0)
	game.player.position = keeper.position+Vector2(56,0)
	var follows := false
	for candidate in game.rpg.interaction_candidates():
		if str(candidate.label).contains("Nib"):
			follows = candidate.point==keeper.position
	check(follows,"Talk prompt follows the live actor instead of its original spot")
	game.rpg._talk(keeper.definition)
	var stopped: Vector2 = keeper.position
	await create_timer(0.15,true).timeout
	check(keeper.position==stopped,"Talking stops the NPC")
	game.rpg._npc_service(keeper.definition)
	check(game.rpg.panel.visible and game.rpg.current_storage()==game.rpg.depot,"Wandering depot keeper still supplies nearby storage")
	game.rpg.panel.hide()
	game.player.position = keeper.position+Vector2(60,0)
	keeper.wait_time = 0
	for frame in range(12):
		await physics_frame
	check(keeper.position==stopped,"Resident stops when the player approaches")
	var positions: Array = []
	for actor in residents:
		positions.append(actor.position)
	game.enter_room(0,Vector2(575,400))
	for frame in range(15):
		await physics_frame
	for i in range(residents.size()):
		check(residents[i].position==positions[i],"NPCs cannot wander while their scene is inactive")
	game.enter_room(6,Vector2(600,350))
	var traveler := {"room":6,"point":Vector2(600,350),"kind":"Wandering merchant","remaining":100.0}
	game.rpg.travelers.append(traveler)
	game.rpg._sync_traveler_actors()
	var actor = game.rpg.npc_nodes[traveler.id]
	actor.position += Vector2(80,0)
	game.player.position = actor.position+Vector2(40,0)
	game.scrap = 10
	var herbs: int = game.rpg.backpack.count_item("herb")
	game.rpg._talk_traveler(traveler)
	game.rpg._resolve_traveler(traveler)
	check(game.scrap==7 and game.rpg.backpack.count_item("herb")==herbs+2,"Wandering traveler trades at its live position")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("NPC walking, bounds, pause and live-service checks; failures: %d" % failures)
	quit(1 if failures else 0)

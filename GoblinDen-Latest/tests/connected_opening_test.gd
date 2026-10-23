extends SceneTree
const Layout = preload("res://scripts/starting_caves.gd")
var failures := 0
var game: Node2D
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool,text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func run() -> void:
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await physics_frame
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	var cave = game.get_node("Cave")
	check(game.current_room==0 and game.player.position.distance_to(Layout.START)<1,"New run begins in Hearth Hall")
	check(cave.world_size_for_room()==Layout.SIZE,"Opening is one large world")
	check(game.player.get_node("Camera2D").limit_right==4608,"Camera follows the connected cave network")
	for id in Layout.IDS:
		check(game.rooms[id].visible and game.rooms[id].process_mode!=Node.PROCESS_MODE_DISABLED,"All connected chambers stay active")
		var goal: Vector2 = Layout.CHAMBERS[id].get_center()
		var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(Layout.START),cave._nearest_open_cell(goal))
		check(path.size()>0,"Continuous floor route reaches chamber %d"%id)
		for point in path:
			var query := PhysicsPointQueryParameters2D.new()
			query.position = point
			query.collision_mask = 1
			check(game.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Navigation stays clear of real rock and facility colliders")
	check(game.is_den_room(),"Hearth hall is safe")
	var hp: int = game.player.hp
	await create_timer(0.7).timeout
	check(game.player.hp==hp,"A new player is not attacked across the map")
	for id in [1,2,3]:
		for enemy in game.rooms[id].get_children():
			if enemy is CharacterBody2D and enemy.is_in_group("enemies"):
				check(enemy.dungeon_awareness!=null and enemy.dungeon_awareness.state=="idle","Opening enemy starts with local awareness")
	var home: Vector2 = game.player.position
	# Physically move a player body along the main route, without room changes or E.
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.player.collision_mask = 1 # Verify fixed world geometry separately from movable combatants.
	var goal := Layout.EXIT-Vector2(80,0)
	var route: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(home),cave._nearest_open_cell(goal))
	for point in route:
		var before: Vector2 = game.player.position
		game.player.move_and_collide(point-before)
		check(game.player.position.distance_to(point)<2,"Main route is physically traversable")
	check(game.current_room==0 and game.player.position.distance_to(goal)<40,"Walk reaches daylight without teleporting or clearing arenas")
	check(not game.is_den_room(),"Outer cave is not a safe class-changing area")
	game.player.position = Layout.EXIT
	check(game.interaction_feedback.activate(),"Surface exit has a real usable prompt")
	check(game.current_room==5,"Daylight exit reaches Thornwood Hollow")
	game.player.position = game.LEFT_GATE
	game._interact_legacy()
	check(game.current_room==0 and game.player.position.distance_to(Layout.EXIT)<110,"Forest returns to the physical cave mouth")
	for station in game.DenLayout.STATIONS:
		game.player.position = station.pos+Vector2(0,65)
		var focus: Dictionary = game.interaction_feedback.choose(game.interaction_feedback.candidates())
		check(not focus.is_empty(),"Every den facility remains reachable and interactable")
	game.player.position = game.REST+Vector2(0,65)
	game.player.hp = 40
	game._interact_legacy()
	check(game.player.hp==game.player.max_hp,"Rest fire works at its new world position")
	var captain: Node2D
	for child in game.rooms[2].get_children():
		if child is CharacterBody2D and child.display_name=="IRON CAPTAIN":
			captain = child
	if captain!=null:
		var before_count: int = game.rooms[2].get_child_count()
		captain._rally()
		check(game.rooms[2].get_child_count()==before_count+2,"Captain can call reinforcements in the connected camp")
		for i in range(before_count,game.rooms[2].get_child_count()):
			var guard = game.rooms[2].get_child(i)
			guard.set_physics_process(false)
			check(guard.position.distance_to(captain.position)<150 and Layout.walkable(guard.position),"Reinforcements use nearby world positions rather than old room coordinates")
	# Persistence migrates old room-local corpse coordinates exactly once.
	var rpg = game.rpg
	rpg.restore({"corpses":[{"room":8,"position":Vector2(350,350),"items":[{"id":"herb","count":2}],"remaining":1200.0,"kind":"Dropped loot"}]})
	check(rpg.corpses[0].room==0 and rpg.corpses[0].position.distance_to(Layout.point(8,Vector2(350,350)))<0.1,"Old recovery loot migrates into the connected map")
	var state: Dictionary = rpg.snapshot().duplicate(true)
	var migrated: Vector2 = rpg.corpses[0].position
	rpg.restore(state)
	check(rpg.corpses[0].position==migrated,"New saves do not migrate coordinates a second time")
	# Kill a real camp defender and claim from its body in the combined map.
	var defender: Node2D
	for child in game.rooms[1].get_children():
		if child is CharacterBody2D and child.is_in_group("enemies"):
			defender = child
			break
	check(defender!=null,"Watch tunnels contain an incursion encounter")
	if defender!=null:
		game.player.position = defender.position-Vector2(50,0)
		var before: Array = rpg.backpack.slots.duplicate(true)
		defender.take_damage(99999)
		check(rpg.backpack.slots==before and rpg.monster_corpses[-1].room==0,"Camp defeat keeps loot unclaimed in the combined world")
		check(rpg.loot_window.open(rpg.monster_corpses[-1]),"Connected cave enemy loot can be inspected")
		rpg.loot_window.close()
		var key: String = defender.get_meta("opening_key")
		check(game.opening_cleared.has(key),"Cleared opening encounter is recorded")
		save.save(game)
		game.queue_free()
		await process_frame
		game = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		current_scene = game
		await process_frame
		var respawned := false
		for child in game.rooms[1].get_children():
			if str(child.get_meta("opening_key",""))==key:
				respawned = true
		check(not respawned,"Cleared opening defender stays cleared after reloading")
	# Commander progress must not depend on killing every summoned guard first.
	for actor in game.rooms[2].get_children():
		if actor is CharacterBody2D and actor.get("role")=="boss":
			game.spawn_enemy_ext(2,actor.position+Vector2(75,0),"test guard",30,80,3,1,"knight",5,"","",true)
			actor.take_damage(99999)
			check(game.captain_defeated,"Commander defeat completes the incursion even with surviving reinforcements")
			break
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	print("Connected opening navigation, physics, awareness, facilities, loot and save checks; failures: %d"%failures)
	quit(1 if failures else 0)

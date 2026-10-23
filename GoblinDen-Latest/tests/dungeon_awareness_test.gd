extends SceneTree
const Awareness = preload("res://scripts/dungeon_awareness.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
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
	game.player.invulnerability = 9999
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.rpg.dungeon.boss.set_physics_process(false)
	for room_id in range(13,16):
		game.enter_room(room_id,Layout.entry(room_id)+Vector2(80,0))
		await physics_frame
		for guard in game.rooms[room_id].get_children():
			if guard.get("dungeon_awareness") == null:
				continue
			var original: Vector2 = guard.position
			guard._physics_process(0.1)
			check(guard.dungeon_awareness.state=="idle" and guard.position==original and guard.windup==0,"Distant guard waits on floor entry")
	game.enter_room(13,Vector2(950,320))
	await physics_frame
	var guards: Array = []
	for actor in game.rooms[13].get_children():
		if actor.get("dungeon_awareness") != null:
			guards.append(actor)
	var home: Vector2 = guards[0].position
	game.player.position = home-Vector2(330,0)
	await physics_frame
	guards[0]._physics_process(0.016)
	check(guards[0].dungeon_awareness.state=="engaged","Guard detects the player beyond the previous 280-pixel radius")
	guards[0].position = home
	guards[0].dungeon_awareness.configure(guards[0])
	game.player.position = Vector2(950,320)
	var ally = load("res://scripts/goblin_ally.gd").new()
	game.add_child(ally)
	ally.set_physics_process(false)
	ally.position = game.player.position
	check(ally._choose_enemy_target(game.player)==null,"Companions do not run ahead to pull idle dungeon guards")
	for guard in guards:
		guard._physics_process(0.016)
	var engaged := 0
	for guard in guards:
		if guard.dungeon_awareness.state=="engaged":
			engaged += 1
	check(engaged==1,"Entering a nearby guard's view engages it without alarming the entire floor")
	check(ally._choose_enemy_target(game.player)==guards[0],"Companions help against the nearby engaged guard")
	var guard = guards[0]
	# Both endpoints are open floor; the wall between adjacent chambers blocks sight.
	guard.position = Vector2(1000,500)
	guard.dungeon_awareness.configure(guard)
	game.player.position = Vector2(750,500)
	await physics_frame
	check(Layout.walkable(guard.position,13) and Layout.walkable(game.player.position,13),"Wall-occlusion fixture uses valid floor on both sides")
	check(not guard.dungeon_awareness.sees(guard,game.player.position),"Actual dungeon wall blocks perception")
	guard._physics_process(0.016)
	check(guard.dungeon_awareness.state=="idle" and guard.windup==0,"Nearby guard cannot detect the player through a wall")
	guard.take_damage(1)
	check(guard.dungeon_awareness.state=="engaged","Attacking a guard alerts that guard")
	guard._physics_process(Awareness.LOST_SIGHT_SECONDS+0.1)
	check(guard.dungeon_awareness.state!="engaged" and guard.windup==0,"Losing sight disengages and cancels pending attacks")
	guard.position = Vector2(1130,320)
	guard.dungeon_awareness.configure(guard)
	game.player.position = Vector2(950,320)
	guard._physics_process(0.016)
	guard.position = guard.dungeon_awareness.home+Vector2(220,0)
	guard.windup = 0.8
	game.player.position = Layout.entry(13)
	var health: int = guard.hp
	guard._physics_process(0.016)
	check(guard.dungeon_awareness.state=="returning" and guard.windup==0,"Long retreat breaks pursuit and cancels queued attacks")
	guard.set_physics_process(true)
	for frame in range(280):
		await physics_frame
	guard.set_physics_process(false)
	check(guard.position.distance_to(guard.dungeon_awareness.home)<=12.0 and guard.dungeon_awareness.state=="idle","Disengaged guard physically returns to its home area")
	check(guard.hp==health,"Disengaging does not heal the guard")
	game.player.position = guard.position+Vector2(-100,0)
	guard._physics_process(0.016)
	check(guard.dungeon_awareness.state=="engaged","Returning to the aggro area can engage a guard again")
	for actor in game.rooms[1].get_children():
		if actor.get("hp") != null:
			check(actor.get("dungeon_awareness")!=null,"Connected opening guards also use local awareness")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("Dungeon local aggro, sight, retreat and companion checks; failures: %d" % failures)
	await create_timer(0.25).timeout
	quit(1 if failures else 0)

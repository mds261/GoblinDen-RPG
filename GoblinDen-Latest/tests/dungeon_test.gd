extends SceneTree
const Layout = preload("res://scripts/dungeon_layout.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func run() -> void:
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var dungeon = game.rpg.dungeon
	var cave = game.get_node("Cave")
	check(game.rooms.size()==16,"Three floors appended without renumbering old rooms")
	game.enter_room(12,Vector2(1000,365))
	check(dungeon.try_interact() and game.current_room==13,"Dungeon entrance follows last area")
	for floor_id in range(13,16):
		game.enter_room(floor_id,Layout.entry(floor_id)+Vector2(80,0))
		await physics_frame
		var camera = game.player.get_node("Camera2D")
		check(camera.limit_right==2880 and camera.limit_bottom==1920,"Camera uses expansive floor bounds")
		var points: Array = [Layout.entry(floor_id),Layout.stairs(floor_id)]
		if floor_id<15:
			points.append_array(Layout.seals(floor_id))
		else:
			points.append(Vector2(2330,1260))
		for point in points:
			var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(Layout.entry(floor_id)),cave._nearest_open_cell(point))
			check(not path.is_empty(),"Every ward/stair/boss chamber has a walkable route")
			var query := PhysicsPointQueryParameters2D.new()
			query.position = point
			query.collision_mask = 1
			check(game.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Quest marker lies outside walls")
		if floor_id<15:
			game.player.position = Layout.stairs(floor_id)
			dungeon.try_interact()
			check(game.current_room==floor_id,"Ward lock prevents premature descent")
			for point in Layout.seals(floor_id):
				game.player.position = point
				dungeon.try_interact()
			check(dungeon.seal_count(floor_id)==2,"Both seals persist independently")
			game.player.position = Layout.stairs(floor_id)
			dungeon.try_interact()
			check(game.current_room==floor_id+1,"Unlocked stairs descend exactly one floor")
			game.player.position = Layout.entry(floor_id+1)
			dungeon.try_interact()
			check(game.current_room==floor_id,"Upper route returns to preceding floor")
	# Exercise physical movement through the same corridors, not only AStar connectivity.
	game.enter_room(13,Layout.stairs(13))
	game.player.invulnerability = 999
	game.spawn_enemy_ext(13,Layout.entry(13),"CORRIDOR ROUTE TEST",100,450,0,0,"knight",0,"")
	var pursuer = game.rooms[13].get_child(game.rooms[13].get_child_count()-1)
	for frame in range(660):
		await physics_frame
		if pursuer.position.distance_to(game.player.position)<100:
			break
	print("Physical route: ",pursuer.position," -> ",game.player.position," velocity ",pursuer.velocity)
	check(pursuer.position.distance_to(game.player.position)<100,"Actor physically traverses chambers and corridors to staircase")
	pursuer.queue_free()
	await process_frame
	var boss = dungeon.boss
	game.enter_room(15,Vector2(2200,1260))
	boss.set_physics_process(false)
	check(boss.boss_state=="dormant" and not boss.is_in_group("enemies"),"Boss identity stays dormant before reveal")
	boss.awaken()
	check(boss.is_in_group("enemies"),"Reveal activates boss combat")
	boss._begin("slam",1.2)
	var locked: Vector2 = boss.strike_position
	game.player.position = locked+Vector2(250,0)
	var hp: int = game.player.hp
	boss._release()
	check(game.player.hp==hp,"Leaving locked slam telegraph avoids damage")
	boss.position = Vector2(2330,1260)
	game.player.position = Vector2(2250,1260)
	boss._begin("bite",.9)
	var direction: Vector2 = boss.locked_direction
	game.player.position = Vector2(2410,1260)
	check(boss.locked_direction==direction,"Bite direction does not track after telegraph")
	boss._begin("coins",.9)
	boss._release()
	check(get_nodes_in_group("dungeon_boss_projectiles").size()==12,"Coin attack creates bounded projectile pattern")
	boss.phase_two = false
	boss.hp = 300
	boss.boss_state = "recover"
	boss.state_time = 0
	boss._physics_process(.01)
	check(boss.phase_two and boss.boss_state=="enrage","Low health starts second-phase animation")
	boss.take_damage(9999)
	check(dungeon.boss_defeated,"Boss defeat updates quest once")
	boss.take_damage(9999)
	check(dungeon.cleared.count("vault_boss")==1,"Repeated death cannot duplicate boss completion")
	game.player.position = Vector2(2440,1660)
	dungeon.try_interact()
	var reward_count: int = game.rpg.backpack.count_item("hero_dawnbreaker")
	dungeon.try_interact()
	check(reward_count==1 and game.rpg.backpack.count_item("hero_dawnbreaker")==1,"Final vault grants unique reward once")
	check(dungeon.claim_reward() and not dungeon.claim_reward(),"Return quest reward pays once")
	var saved: Dictionary = dungeon.snapshot().duplicate(true)
	save.save(game)
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(game.rpg.dungeon.snapshot()==saved,"Seals, cleared enemies and quest rewards survive restart")
	check(game.rpg.dungeon.boss==null,"Defeated boss does not respawn after reload")
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Three-floor dungeon and boss checks; failures: ",failures)
	await create_timer(0.25).timeout
	quit(1 if failures else 0)


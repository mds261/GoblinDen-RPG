extends SceneTree
const Layout = preload("res://scripts/den_layout.gd")
const Geometry = preload("res://scripts/expanse_geometry.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func source_point(x: float, y: float) -> Vector2:
	return Vector2(x, y) * Geometry.WORLD_SIZE / Geometry.SOURCE_SIZE
func point_blocked(game: Node2D, point: Vector2) -> bool:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = point
	query.collision_mask = 1
	return not game.get_world_2d().direct_space_state.intersect_point(query).is_empty()
func run_checks() -> void:
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.player.set_physics_process(false)
	var cave = game.get_node("Cave")
	check(game.rooms.size() == 10, "Seven existing rooms plus three den rooms")
	var station_count := 0
	for room in game.rooms:
		for child in room.get_children():
			if child.has_method("set_collision_active"):
				station_count += 1
	check(station_count == 8, "All eight stations exist exactly once")
	for room_id in Layout.PORTALS:
		for portal in Layout.PORTALS[room_id]:
			check(Layout.PORTALS[portal["to"]].any(func(back): return back["to"] == room_id), "Every passage has a return connection")
			game.enter_room(room_id, portal["pos"])
			game.interact()
			check(game.current_room == portal["to"], "Passage reaches the correct room")
			check(game.player.position == portal["spawn"], "Passage uses the matching arrival point")
			await physics_frame
			check(not point_blocked(game, game.player.position), "Arrival point is outside station collisions")
			var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(game.player.position), cave._nearest_open_cell(Vector2(575, 365)))
			check(not path.is_empty(), "Each entry connects to its room floor")
	for station in Layout.STATIONS:
		game.enter_room(station["room"], station["pos"] + Vector2(0, 58))
		await physics_frame
		check(point_blocked(game, station["pos"]), "Active station has a physical footprint")
		check(not point_blocked(game, game.player.position), "Station interaction approach stays walkable")
		check(game.contextual_hint().begins_with("E "), "Every station exposes an interaction")
		for room in game.rooms:
			for prop in room.get_children():
				if prop.has_method("set_collision_active"):
					check((prop.obstacle.collision_layer == 1) == (room == game.rooms[game.current_room]), "Hidden room station colliders are disabled")
	game.enter_room(0, game.FORGE + Vector2(0, 58))
	game.scrap = 100
	var level: int = game.blade_level
	game.interact()
	check(game.blade_level == level, "Forge cannot be used in another room")
	game.enter_room(Layout.ARMORY, game.FORGE + Vector2(0, 58))
	game.interact()
	check(game.blade_level == level + 1, "Forge still upgrades in the armory")
	game.enter_room(Layout.STRATEGY, game.RECRUITMENT_HUT + Vector2(0, 58))
	game.interact()
	check(game.recruited_ids.size() == 1, "Recruitment still works in the strategy room")
	game.enter_room(Layout.STRATEGY, game.WAR_ROOM + Vector2(0, 58))
	var tier: int = game.campaign_index
	game.interact()
	check(game.campaign_index != tier, "War table launches a raid from the strategy room")
	game.enter_room(Layout.TREASURY, game.TREASURE_ROOM + Vector2(0, 58))
	game.select_goblin_class("mage")
	check(game.player.class_id == "mage", "Class switching works throughout the safe den")
	var saved_scrap: int = game.scrap
	var saved_blade: int = game.blade_level
	save.save(game)
	game.scrap = 0
	game.blade_level = 1
	check(save.load_data(game) and game.scrap == saved_scrap and game.blade_level == saved_blade, "Existing progression save format survives the den expansion")
	game.enter_room(0, game.RIGHT_GATE)
	game.interact()
	check(game.current_room == 1, "Main hall still leads to the raid")
	game.enter_room(6, game.RIGHT_GATE)
	game.interact()
	check(game.current_room == 6, "Expanse cannot advance into a safe-room ID")
	await physics_frame
	for point in [source_point(820,310), source_point(570,510), source_point(1100,470), source_point(920,720), source_point(1450,610)]:
		check(point_blocked(game, point), "Tree, plinth, water and ravine are physical obstacles: " + str(point))
	var probe := CharacterBody2D.new()
	probe.collision_layer = 2
	probe.collision_mask = 1
	var collider := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 15.0
	collider.shape = circle
	probe.add_child(collider)
	root.add_child(probe)
	var probes := [
		[source_point(850,440), source_point(850,250), "tree roots"],
		[source_point(570,620), source_point(570,450), "statue steps"],
		[source_point(980,440), source_point(1110,470), "upper water"],
		[source_point(760,710), source_point(930,720), "lower water"],
		[source_point(1300,540), source_point(1530,600), "cliff top"]
	]
	for spec in probes:
		probe.position = spec[0]
		await physics_frame
		check(not point_blocked(game, probe.position), "Dry starting point for " + spec[2])
		var hit := probe.move_and_collide(spec[1] - spec[0])
		check(hit != null, "Swept movement/dodge cannot cross " + spec[2])
	probe.position = source_point(960,550)
	await physics_frame
	check(probe.move_and_collide(source_point(1150,590) - probe.position) == null, "The bridge deck remains physically crossable")
	var start: Vector2i = cave._nearest_open_cell(game.EXPANSE_SPAWN)
	for interaction in game.EXPANSE_INTERACTIONS:
		check(not point_blocked(game, interaction["pos"]), "Interaction target remains on land: " + interaction["id"])
		var route: PackedVector2Array = cave.navigation.get_point_path(start, cave._nearest_open_cell(interaction["pos"]))
		check(not route.is_empty(), "Companions can route to " + interaction["id"])
		for step in route:
			check(not point_blocked(game, step), "Pathfinding shares physical obstacle boundaries")
		for i in range(route.size() - 1):
			check(not probe.test_move(Transform2D(0.0, route[i]), route[i + 1] - route[i]), "A 15px companion body can traverse each path segment")
	probe.queue_free()
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Den network and collision checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(failures)

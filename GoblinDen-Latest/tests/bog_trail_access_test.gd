extends SceneTree

var failures := 0

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var cave = load("res://scripts/cave.gd").new()
	root.add_child(cave)
	cave.configure_room(6)
	await physics_frame
	await physics_frame
	var destination: Vector2 = load("res://scripts/rpg_systems.gd").BOG_TRAIL_POINT
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 15.0
	query.shape = shape
	query.collision_mask = 1
	query.transform = Transform2D(0, Vector2(1900, 1000))
	var space := root.get_world_2d().direct_space_state
	check(not space.intersect_shape(query).is_empty(), "Old entrance reproduces the cliff collision")
	query.transform = Transform2D(0, destination)
	check(space.intersect_shape(query).is_empty(), "New entrance clears the full player body")
	for start in [Vector2(400, 350), Vector2(600, 350), Vector2(365, 285)]:
		var path: PackedVector2Array = cave.navigation.get_point_path(cave._nearest_open_cell(start), cave._nearest_open_cell(destination))
		check(path.size() > 1, "Entrance has a continuous path from forest arrival %s" % start)
		if path.size() < 2:
			continue
		check(path[-1].distance_to(destination) < 30.0, "Path reaches the entrance itself")
		for i in range(path.size() - 1):
			query.transform = Transform2D(0, path[i])
			query.motion = path[i + 1] - path[i]
			var result := space.cast_motion(query)
			check(result[0] >= 0.999, "Full player body can traverse path segment %d" % i)
	print("Bog Trail accessibility checks; failures: %d" % failures)
	quit(1 if failures else 0)

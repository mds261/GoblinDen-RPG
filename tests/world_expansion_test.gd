extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	check(game.rooms.size() == 10, "World should contain seven original rooms and three connected den rooms.")
	check(game.ROOM_NAMES[3] == "ROOTVEIN GROTTO", "Rootvein Grotto room is missing.")
	check(game.ROOM_NAMES[4] == "THE CAVE MOUTH", "Cave Mouth room is missing.")
	check(game.ROOM_NAMES[5] == "THORNWOOD HOLLOW", "Thornwood Hollow room is missing.")
	for room_index in [3, 4, 5]:
		game.enter_room(room_index, Vector2(215, 365))
		await process_frame
		check(game.current_room == room_index, "Could not enter room %d." % room_index)
		check(game.get_node("Cave").room_index == room_index, "Backdrop did not follow room %d." % room_index)
		check(game.rooms[room_index].visible, "Room %d was not made visible." % room_index)
	check(game.current_room == 5 and game.contextual_hint().contains("Thornwood Hollow"),
		"Exterior exploration hint is missing.")
	print("Expanded-world checks; failures: %d" % failures)
	game.queue_free()
	await process_frame
	quit(failures)


extends SceneTree

var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func find_large_enemy(room: Node) -> Node:
	for child in room.get_children():
		if child.get("enemy_kind") != null:
			return child
	return null

func run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var expected := {
		3: {"kind": "spider", "name": "ROOTVEIN GIANT SPIDER"},
		4: {"kind": "ogre", "name": "CAVE-MOUTH OGRE"},
		5: {"kind": "wolf_rider", "name": "THORNWOOD WOLF RIDER"}
	}
	for room_index in [3, 4, 5]:
		var enemy = find_large_enemy(game.rooms[room_index])
		check(is_instance_valid(enemy), "Room %d is missing its large enemy." % room_index)
		if is_instance_valid(enemy):
			check(enemy.enemy_kind == expected[room_index]["kind"], "Room %d has the wrong creature." % room_index)
			check(enemy.display_name == expected[room_index]["name"], "Room %d has the wrong encounter name." % room_index)
			check(enemy.hp == enemy.max_hp and enemy.max_hp >= 300, "Large enemy stats were not configured.")
	game.enter_room(3, Vector2(935, 365))
	await process_frame
	check(game.living_enemies() == 1, "The Giant Spider should guard Rootvein Grotto.")
	game.player.position = game.RIGHT_GATE
	game.interact()
	check(game.current_room == 3, "The Giant Spider should block travel to the Cave Mouth.")
	for room_index in [3, 4, 5]:
		if game.current_room != room_index:
			game.enter_room(room_index, Vector2(215, 365))
		for enemy in game.rooms[room_index].get_children():
			if enemy is CharacterBody2D and enemy.is_in_group("enemies") and enemy.hp > 0:
				enemy.take_damage(9999, Vector2.RIGHT)
		await process_frame
		check(game.living_enemies() == 0, "Defeating the room %d miniboss should clear the route." % room_index)
	print("Large-enemy checks; failures: %d" % failures)
	game.queue_free()
	await process_frame
	quit(failures)


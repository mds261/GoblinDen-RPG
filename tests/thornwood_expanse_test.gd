extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await physics_frame
	game.enter_room(5, Vector2(900, 365))
	await physics_frame
	for actor in game.rooms[5].get_children():
		if actor is CharacterBody2D and actor.is_in_group("enemies"):
			actor.take_damage(99999)
	await process_frame
	await process_frame
	check(game.living_enemies() == 0, "Entrance guardian is cleared")
	game.player.position = game.RIGHT_GATE
	game.interact()
	check(game.current_room == game.EXPANSE_ROOM_INDEX, "Wolf-gated trail enters Thornwood Expanse")
	check(game.player.position == game.EXPANSE_SPAWN, "Player enters at the exterior cave landmark")
	var camera: Camera2D = game.player.get_node("Camera2D")
	check(camera.limit_right == 2304 and camera.limit_bottom == 1440, "Camera follows within the expanded world bounds")
	check(camera.enabled and camera.is_current(), "Player camera is explicitly active")
	game.player.position = Vector2(1500, 1000)
	for frame in range(30):
		await physics_frame
	check(camera.get_screen_center_position().x > 1000.0 and camera.get_screen_center_position().y > 700.0, "Camera scrolls after the player leaves the first screen")
	check(game.get_node("Cave").room_index == game.EXPANSE_ROOM_INDEX, "Expanded background is active")
	check(game.get_node("Cave").expanse_foreground_layers.size() >= 8, "Painted foreground is split into depth-sorted occlusion layers")
	check(game.get_node("Cave").navigation.region.size == Vector2i(96, 60), "Navigation grid scales to the exterior")
	check(game.living_enemies() == 3, "Existing 2D combat patrols populate the exterior")
	game.player.position = Vector2(770, 455)
	Input.action_press("move_right")
	for frame in range(45):
		await physics_frame
	Input.action_release("move_right")
	check(game.player.position.x < 840.0, "Tree and cliff geometry blocks walking through painted scenery")
	game.player.position = game.EXPANSE_LANDMARKS[0]["pos"]
	game._update_expanse_discovery()
	check(game.discovered_expanse_landmarks.has("fallen_arch"), "Landmark exploration is recorded")
	var scrap_before: int = game.scrap
	game.player.position = game.EXPANSE_INTERACTIONS[2]["pos"]
	game.interact()
	check(game.scrap == scrap_before + 8 and game.used_expanse_interactions.has("camp_cache"), "Exterior camp is physically interactable")
	game.player.position = game.EXPANSE_RETURN_GATE
	game.interact()
	check(game.current_room == 5, "Cave entrance returns to Thornwood Hollow")
	check(camera.limit_right == 1152 and camera.limit_bottom == 720, "Room camera bounds are restored")
	game.queue_free()
	await process_frame
	print("Thornwood Expanse checks; failures: ", failures)
	quit(failures)

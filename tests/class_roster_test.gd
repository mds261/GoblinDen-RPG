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
	check(game.player.CLASS_ART.size() == 4, "All four playable class paintings should be loaded.")
	var expected := ["blade", "archer", "knight", "mage"]
	for class_id in expected:
		game.select_goblin_class(class_id)
		check(game.player.class_id == class_id, "Could not try playable class: %s" % class_id)
	check(game.player.class_id == "mage", "Direct class selection should finish on Mage.")
	game.cycle_base_class()
	check(game.player.class_id == "blade", "Training Pit class cycle should wrap Mage to Blade.")
	game.scrap = 100
	for unused in range(3):
		game.recruit_goblin_follower()
	check(game.recruited_ids.size() == 3, "Blade player should recruit the other three core classes.")
	check(game.active_companion_count() == 3, "A full squad should field three companions plus the player.")
	game.select_goblin_class("archer")
	check(game.active_companion_count() == 2, "The recruited Archer duplicate should wait while Archer is controlled.")
	game.recruit_goblin_follower()
	check(game.recruited_ids.has("goblin_blade"), "Switching to Archer should make Blade recruitable.")
	check(game.active_companion_count() == 3, "The roster should still field one of each class after swapping leaders.")
	print("Class-roster checks; failures: %d" % failures)
	game.queue_free()
	await process_frame
	quit(failures)


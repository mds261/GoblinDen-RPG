extends SceneTree
var failures := 0
const Catalog = preload("res://scripts/design_catalog.gd")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	check(game.rpg.items.iron_sword.name == "QA Goblin Blade" and game.rpg.items.iron_sword.attack == 19, "Edited item name and damage load into live inventory definitions")
	check(game.player.get_class_title() == "QA Blade Class" and game.player.speed == 230.0, "Edited player class name and speed load")
	check(game.ROOM_NAMES[0] == "QA Safe Den", "Edited location name loads")
	check(game.rpg.ACTIONS.heal.name == "QA Mend" and game.rpg.ACTIONS.heal.heal == 45, "Edited spell name and healing load")
	var captain = game.rooms[2].get_child(0)
	check(captain.display_name == "QA Captain" and captain.max_hp == 195, "Edited campaign enemy name and stats load")
	check(captain.get_script() == load("res://scripts/iron_captain.gd"), "Renaming a boss preserves its special behavior")
	check(game.rpg.NpcData.RESIDENTS[0].name == "QA Den Keeper", "Edited NPC name loads into dialogue definitions")
	game.rpg.backpack.add("iron_sword")
	for i in range(game.rpg.backpack.slots.size()):
		if game.rpg.backpack.slots[i].id == "iron_sword":
			game.player.level = 2
			game.rpg.equip(i)
			break
	load("res://scripts/save_data.gd").save(game)
	game.rpg.equipped.clear()
	check(load("res://scripts/save_data.gd").load_data(game), "Save reload succeeds after renaming records")
	check(game.rpg.equipped.get("weapon") == "iron_sword" and game.rpg.items.iron_sword.name == "QA Goblin Blade", "Saved equipment follows stable ID after name changes")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("Catalog runtime rename/stat/save checks; failures: ", failures)
	quit(failures)

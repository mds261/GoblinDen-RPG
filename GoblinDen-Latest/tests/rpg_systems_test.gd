extends SceneTree
const Model = preload("res://scripts/item_container.gd")
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var definitions := {"wood": {"stack": 10}, "sword": {"stack": 1}}
	var source = Model.new(3, definitions)
	var destination = Model.new(1, definitions)
	source.add("wood", 15)
	destination.add("wood", 9)
	check(not source.transfer(0, destination, 2), "Partial stack overflow must reject atomically")
	check(source.count_item("wood") == 15 and destination.count_item("wood") == 9, "Failed transfer conserves inventory")
	check(source.transfer(0, destination, 1), "Split transfer fills compatible stack")
	check(source.count_item("wood") == 14 and destination.count_item("wood") == 10, "Split conserves total")
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var rpg = game.rpg
	var cave = game.get_node("Cave")
	game.player.set_physics_process(false)
	var opening = load("res://scripts/starting_caves.gd")
	for route in [[0,opening.EXIT,5],[5,Vector2(1010,365),6],[6,Vector2(500,350),10],[10,Vector2(145,365),6],[6,Vector2(1850,850),11],[11,Vector2(1000,365),12],[12,Vector2(145,365),11],[11,Vector2(145,365),6],[6,Vector2(310,245),5],[5,Vector2(140,365),0]]:
		game.enter_room(route[0],route[1],true)
		await physics_frame
		game.interaction_feedback.activation_cooldown = 0
		check(game.interaction_feedback.activate() and game.current_room==route[2],"Exploration route reaches intended area")
		await physics_frame
		var query := PhysicsPointQueryParameters2D.new()
		query.position = game.player.position
		query.collision_mask = 1
		check(game.get_world_2d().direct_space_state.intersect_point(query).is_empty(),"Travel arrival is outside walls and props")

	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	rpg.backpack.add("bow")
	rpg.backpack.add("shield")
	check(rpg.equip(find_item(rpg, "shield")), "Shield equip")
	check(rpg.equip(find_item(rpg, "bow")), "Two-handed equip")
	check(not rpg.equipped.has("shield") and rpg.backpack.count_item("shield") == 1, "Two-handed swap returns shield")
	check(not rpg.equip(find_item(rpg, "shield")), "Cannot pair shield and bow")
	# A full bag plus a two-handed item swap requires two return slots.
	rpg.unequip("weapon")
	check(rpg.equip(find_item(rpg, "rust_sword")), "Equip single-handed starter")
	check(rpg.equip(find_item(rpg, "shield")), "Equip shield beside starter")
	while rpg.backpack.slots.size() < rpg.backpack.capacity:
		rpg.backpack.add("helmet")
	var inventory_before: Array = rpg.backpack.slots.duplicate(true)
	var equipment_before: Dictionary = rpg.equipped.duplicate(true)
	check(not rpg.equip(find_item(rpg, "bow")), "Full bag rejects swap needing two displaced slots")
	check(rpg.backpack.slots == inventory_before and rpg.equipped == equipment_before, "Failed swap restores both containers")
	while rpg.backpack.slots.size() > 5:
		rpg.backpack.slots.pop_back()

	game.enter_room(6, Vector2(400, 350))
	rpg.storage_kind = "depot"
	check(rpg.current_storage() == null, "No remote depot in wilderness")
	game.enter_room(10, Vector2(350, 300))
	check(rpg.current_storage() == rpg.depot, "Depot available at discovered settlement")
	rpg.chest.add("ore", 8)
	rpg.depot.add("ring")
	game.enter_room(6, Vector2(400, 350))
	rpg.die()
	check(game.current_room == 0 and game.player.hp > 0, "Death respawns at den")
	check(rpg.corpses.size() == 1 and rpg.backpack.slots.is_empty() and rpg.equipped.is_empty(), "Death transfers belongings to corpse")
	check(rpg.chest.count_item("ore") == 8 and rpg.depot.count_item("ring") == 1, "Death protects storage")
	rpg.corpses[0].remaining = 777.0
	rpg.train("Magic", 25)
	rpg.bindings[0] = "heal"
	rpg.keycodes[0] = KEY_F3
	save.save(game)
	var cfg := ConfigFile.new()
	cfg.load(save.SAVE_PATH)
	var state: Dictionary = cfg.get_value("rpg", "state")
	check(float(state.corpses[0].remaining) == 777.0, "Saved corpse retains active-gameplay lifetime")
	rpg.corpses.clear()
	rpg.restore(state)
	check(rpg.corpses.size() == 1 and float(rpg.corpses[0].remaining) == 777.0, "Reload restores corpse timer")
	check(rpg.keycodes[0] == KEY_F3, "Custom binding persists")
	game.enter_room(6, Vector2(400, 350))
	check(rpg.try_interact(), "Corpse can be recovered")
	check(rpg.backpack.count_item("bow") == 1 and rpg.corpses.is_empty(), "Recovered equipment becomes carried inventory")
	game.enter_room(0, Vector2(575, 400))
	rpg.die()
	rpg.die()
	check(rpg.corpses.size() == 2, "Repeated deaths keep independent corpses")
	rpg.corpses[0].remaining = 0.01
	rpg._process(0.02)
	check(rpg.corpses.size() == 1, "Only expired corpse removed")
	game.enter_room(10, Vector2(750, 300))
	game.scrap = 100
	rpg._learn("fireball")
	check(rpg.learned.has("fireball"), "Trainer permanently unlocks action")
	game.enter_room(11, Vector2(500, 350))
	rpg.auto_target = true
	var before: float = rpg.mana
	rpg.cast("fireball")
	check(rpg.mana == before, "No target consumes no mana")
	rpg.panel.show()
	rpg._refresh_panel()
	check(rpg.input_blocked(), "Open inventory suppresses combat input")
	rpg.panel.hide()
	rpg.chat_entry.grab_focus()
	check(rpg.input_blocked(), "Typing suppresses gameplay input")
	rpg.chat_entry.release_focus()
	game.queue_free()
	await process_frame
	save.delete_save()
	await create_timer(0.3).timeout
	print("RPG integration checks complete; failures: ", failures)
	quit(1 if failures else 0)
func find_item(rpg, id: String) -> int:
	for i in range(rpg.backpack.slots.size()):
		if rpg.backpack.slots[i].id == id:
			return i
	return -1


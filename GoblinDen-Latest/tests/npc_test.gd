extends SceneTree
const NpcData = preload("res://scripts/npc_data.gd")
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
	var rpg = game.rpg
	check(get_nodes_in_group("friendly_npcs").size() == 7, "Seven distinct residents spawn")
	for npc in get_nodes_in_group("friendly_npcs"):
		check(not npc.is_in_group("enemies") and not npc.is_in_group("allies"), "Friendly residents are separate from combat actors")
	game.enter_room(10, Vector2(350, 345))
	check(rpg.try_interact() and rpg.dialogue.visible, "Approaching depot keeper opens dialogue")
	check(paused and rpg.input_blocked(), "Dialogue pauses danger and blocks gameplay")
	var before: float = rpg.mana
	rpg.corpses.append({"room": 6, "position": Vector2(500, 350), "items": [], "remaining": 500.0, "kind": "Test"})
	rpg._process(10.0)
	check(float(rpg.corpses[0].remaining) == 500.0 and rpg.mana == before, "Dialogue pauses active-gameplay timers")
	rpg._npc_service(NpcData.RESIDENTS[1])
	check(not paused and rpg.panel.visible and rpg.current_storage() == rpg.depot, "Depot dialogue opens actual local storage")
	rpg.panel.hide()
	game.enter_room(10, Vector2(550, 345))
	rpg._talk(NpcData.RESIDENTS[2])
	rpg._npc_service(NpcData.RESIDENTS[2])
	check(rpg.storage_kind == "merchant" and rpg.panel.visible, "Smith opens gear and crafting")
	rpg.panel.hide()
	game.enter_room(10, Vector2(550, 515))
	rpg.kills = 5
	var scrap_before: int = game.scrap
	rpg._npc_service(NpcData.RESIDENTS[5])
	check(game.scrap == scrap_before + 40 and rpg.quest_claimed, "Scout captain pays contract")
	rpg._npc_service(NpcData.RESIDENTS[5])
	check(game.scrap == scrap_before + 40, "Contract cannot pay twice")
	game.enter_room(6, Vector2(600, 400))
	var traveler := {"room": 6, "point": Vector2(600, 400), "kind": "Wandering merchant", "remaining": 100.0}
	rpg.travelers.append(traveler)
	rpg._sync_traveler_actors()
	var count: int = get_nodes_in_group("friendly_npcs").size()
	rpg._sync_traveler_actors()
	check(get_nodes_in_group("friendly_npcs").size() == count, "Traveler sprite is created once")
	game.scrap = 20
	rpg._talk_traveler(traveler)
	check(game.scrap == 20, "Talking does not spend currency")
	rpg._resolve_traveler(traveler)
	check(game.scrap == 17 and rpg.backpack.count_item("herb") == 2, "Explicit trade transfers cost and goods once")
	rpg._resolve_traveler(traveler)
	check(game.scrap == 17, "Departed traveler cannot trade twice")
	rpg._sync_traveler_actors()
	await process_frame
	check(get_nodes_in_group("friendly_npcs").size() == 7, "Resolved traveler actor cleans up")
	save.save(game)
	var talked: Array = rpg.talked_npcs.duplicate()
	rpg.talked_npcs.clear()
	save.load_data(game)
	check(rpg.talked_npcs == talked, "NPC conversation flags survive save/reload")
	if DisplayServer.get_name() != "headless":
		game.enter_room(10, Vector2(470, 400))
		await create_timer(0.15).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/npc-market.png")
		game.enter_room(10, Vector2(750, 345))
		rpg._talk(NpcData.RESIDENTS[3])
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/npc-dialogue.png")
		rpg.dialogue.hide()
	game.queue_free()
	await process_frame
	save.delete_save()
	print("NPC dialogue/service/persistence checks; failures: ", failures)
	quit(1 if failures else 0)

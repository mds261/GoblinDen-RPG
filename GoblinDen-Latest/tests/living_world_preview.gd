extends SceneTree
var game: Node2D
var failures := 0
var output_dir := "user://living-world-previews/"
func _initialize() -> void:
	call_deferred("run")
func capture(name: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir+name+".png")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1152,720)
	load("res://scripts/save_data.gd").delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.player.invulnerability = 9999
	game.player.get_node("Camera2D").position_smoothing_enabled = false
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	game.rpg.dungeon.boss.set_physics_process(false)
	game.enter_room(10,Vector2(1000,600))
	for actor in get_nodes_in_group("friendly_npcs"):
		if int(actor.definition.room)==10:
			actor.wait_time = 0
	await create_timer(2.0).timeout
	game.notice_time = 0
	await capture("01-wandering-market-residents")
	game.enter_room(6,Vector2(1100,650))
	await process_frame
	game.spawn_enemy_ext(6,Vector2(1190,660),"THORNWOOD SCOUT",10,0,0,14,"rogue",20,"")
	var enemy = game.rooms[6].get_child(game.rooms[6].get_child_count()-1)
	enemy.set_physics_process(false)
	enemy.take_damage(99999)
	await create_timer(1.1).timeout
	var corpse: Dictionary = game.rpg.monster_corpses[-1]
	corpse.items = [{"id":"wood","count":3},{"id":"herb","count":2},{"id":"boots","count":1}]
	game.player.position = corpse.position-Vector2(55,0)
	game.notice_time = 0
	await capture("02-defeated-monster")
	check(game.rpg.loot_window.open(corpse),"Open corpse from nearby")
	await capture("03-choose-monster-loot")
	var before: int = game.rpg.backpack.count_item("wood")
	var claimed := false
	for button in game.rpg.loot_window.body.find_children("*","Button",true,false):
		if button.text=="Take":
			button.pressed.emit()
			claimed = true
			break
	check(claimed and game.rpg.backpack.count_item("wood")==before+3,"The actual Take button claims only its stack")
	check(corpse.items.size()==2 and int(corpse.scrap)==14,"Unchosen stacks and scrap remain after click")
	await capture("04-partially-claimed-loot")
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.physical_keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(not paused and not game.rpg.loot_window.panel.visible,"Escape closes loot without opening the pause menu")
	check(not game.game_menu.overlay.visible,"Closing loot does not leak the key into other menus")
	print("Rendered loot choice and live button checks; failures: %d" % failures)
	quit(1 if failures else 0)

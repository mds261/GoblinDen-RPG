extends SceneTree
const OUT := "user://overhaul-previews/"
var game: Node2D
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func capture(file: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(OUT+file+".png") == OK,"Save preview " + file)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(OUT)
	root.size = Vector2i(1152,720)
	load("res://scripts/save_data.gd").delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.player.invulnerability = 9999
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.rpg.dungeon.boss.set_physics_process(false)
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	game.enter_room(6,Vector2(1100,650))
	game.notice_time = 0
	await create_timer(0.4).timeout
	game.notice_time = 0
	await capture("01-forest-hud")
	check(game.rpg.hotbar.get_child(0).visible,"Assigned heal remains accessible")
	check(not game.rpg.hotbar.get_child(1).visible,"Empty spell slots are hidden")
	check(not game.rpg.chat_panel.visible,"Journal is closed during play")
	game.enter_room(13,Vector2(480,365))
	game.notice_time = 0
	await capture("02-dungeon-entrance")
	game.enter_room(13,Vector2(1390,1630))
	game.notice_time = 0
	await capture("03-sealed-stairs")
	game.rpg.dungeon.seals.append_array(["13_0","13_1"])
	await capture("04-open-stairs")
	game.enter_room(13,Vector2(2250,420))
	game.notice_time = 0
	await capture("05-ward-shrine")
	var boss = game.rpg.dungeon.boss
	game.enter_room(15,Vector2(2180,1260))
	boss.awaken()
	game.notice_time = 0
	boss.boss_state = "hunt"
	await capture("06-vault-guardian")
	boss._begin("bite",1.0)
	boss.state_time = 0.5
	game.notice_time = 0
	await capture("07-boss-bite")
	for state in ["coins","slam","recover"]:
		boss.boss_state = state
		boss.state_time = 0.6
		boss.state_total = 1.2
		boss.strike_position = Vector2(2180,1260)
		game.notice_time = 0
		await capture("boss-"+state)
	boss.take_damage(99999)
	game.notice_time = 0
	await capture("boss-defeated")
	game.game_menu.open()
	check(paused and game.rpg.input_blocked(),"Pause menu blocks combat input")
	var old_playtime: float = game.playtime
	await create_timer(0.1,true).timeout
	check(is_equal_approx(old_playtime,game.playtime),"Pause freezes gameplay clock")
	await capture("08-pause-menu")
	game.game_menu.controls_visible = true
	game.game_menu._rebuild()
	await capture("09-controls-guide")
	game.game_menu.close()
	check(not paused,"Resume restores simulation")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_ESCAPE
	key.keycode = KEY_ESCAPE
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	check(game.game_menu.overlay.visible,"Escape opens menu during play")
	Input.parse_input_event(key)
	await process_frame
	check(not game.game_menu.overlay.visible and not paused,"Escape closes menu")
	game.rpg.pack_page = "Inventory"
	game.rpg.panel.show()
	game.rpg._refresh_panel()
	await capture("10-backpack-inventory")
	for page in ["Character","Journal","Crafting","Actions"]:
		var found := false
		for button in game.rpg.body.find_children("*","Button",true,false):
			if button.text == page:
				button.pressed.emit()
				found = true
				break
		check(found and game.rpg.pack_page==page,"Backpack tab opens " + page)
		await capture("pack-"+page.to_lower())
	game.rpg.panel.hide()
	var bindings: Array = game.rpg.bindings.duplicate()
	game.rpg.bindings.fill("heal")
	game.rpg.refresh_timer = 0
	game.rpg._process(0.01)
	await process_frame
	check(game.rpg.hotbar.position.x>214 and game.rpg.hotbar.position.x+game.rpg.hotbar.size.x<918,"All twelve assigned actions fit without crowding other HUD elements")
	game.rpg.bindings = bindings
	print("Overhaul preview and menu checks; failures: %d" % failures)
	quit(1 if failures else 0)

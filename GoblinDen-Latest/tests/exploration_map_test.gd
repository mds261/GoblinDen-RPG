extends SceneTree
const Layout = preload("res://scripts/dungeon_layout.gd")
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
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var map = game.rpg.exploration_map
	game.enter_room(13,Layout.entry(13))
	await physics_frame
	map.explored.clear()
	map.known_markers.clear()
	map.reveal_near_player()
	check(map.is_explored(13,game.player.position),"Current location reveals")
	check(map.is_explored(13,game.player.position+Vector2(48,0)),"Nearby visible floor reveals")
	check(not map.is_explored(13,Vector2(2350,400)),"Distant chamber remains hidden")
	check(not map.known_markers.get(13,{}).has("seal_0"),"Undiscovered ward marker stays hidden")
	check(not map.known_markers.get(13,{}).has("stairs_down"),"Unvisited stairs are not pre-revealed")
	check(not map.explored.has(14),"Unvisited floor has independent unexplored fog")
	game.player.position = Vector2(720,450)
	await physics_frame
	map.reveal_near_player()
	check(not map.is_explored(13,Vector2(900,450)),"Walls block map discovery behind them")
	game.player.position = Layout.seals(13)[0]
	await physics_frame
	map.reveal_near_player()
	check(map.known_markers[13].has("seal_0"),"Ward marker appears after actual discovery")
	game.enter_room(14,Layout.entry(14))
	await physics_frame
	map.reveal_near_player()
	check(map.is_explored(14,Layout.entry(14)),"Second floor reveals its own location")
	check(map.is_explored(13,Layout.seals(13)[0]),"Leaving an area preserves prior exploration")
	map.shown = false
	map.canvas.hide()
	game.enter_room(0,Vector2(575,400))
	await physics_frame
	map.reveal_near_player()
	check(map.is_explored(0,game.player.position),"Exploration works outside dungeon and while map collapsed")
	var saved: Dictionary = map.snapshot().duplicate(true)
	save.save(game)
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	map = game.rpg.exploration_map
	check(map.explored==saved.explored and map.known_markers==saved.known_markers,"Explored cells and discovered markers survive full reload")
	check(not map.shown,"Map visibility preference persists")
	if DisplayServer.get_name()!="headless":
		map._toggle()
		game.enter_room(13,Layout.entry(13))
		await create_timer(.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/exploration-map-partial.png")
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Exploration fog, visibility and persistence checks; failures: ",failures)
	quit(1 if failures else 0)

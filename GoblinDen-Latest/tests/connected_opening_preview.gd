extends SceneTree
const Layout = preload("res://scripts/starting_caves.gd")
var game: Node2D
var output_dir := "user://connected-opening-previews/"
func _initialize() -> void:
	call_deferred("run")
func capture(name: String, point: Vector2) -> void:
	game.player.position = point
	game.player.get_node("Camera2D").reset_smoothing()
	game.player.get_node("Camera2D").force_update_scroll()
	game.notice_time = 0
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir+name+".png")
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1152,720)
	load("res://scripts/save_data.gd").delete_save()
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.player.invulnerability = 99999
	game.player.get_node("Camera2D").position_smoothing_enabled = false
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	await capture("01-hearth-hall",Layout.START)
	await capture("02-linked-tunnels",Vector2(1230,1344))
	await capture("03-armory",Vector2(570,2310))
	await capture("04-incursion-camp",Vector2(2850,1408))
	await capture("05-rootvein-branch",Vector2(2900,510))
	await capture("06-daylight-exit",Vector2(4180,1376))
	# A real render of the entire connected floor, with chamber names for orientation.
	for layer in game.find_children("*","CanvasLayer",true,false):
		layer.visible = false
	game.player.hide()
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2(0.25,0.25)
	for id in Layout.IDS:
		game.add_label(game,Layout.NAMES[id],Layout.CHAMBERS[id].get_center()+Vector2(-240,-100),54,Color("eee0b8"))
	await capture("07-layout-overview",Layout.SIZE*0.5)
	game.queue_free()
	await process_frame
	await create_timer(0.3).timeout
	quit()

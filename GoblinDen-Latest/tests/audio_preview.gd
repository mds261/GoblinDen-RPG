extends SceneTree
var failures := 0
var output_dir := "user://audio-previews/"
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	root.size = Vector2i(1152,720)
	var capture := AudioEffectCapture.new()
	capture.buffer_length = 1.0
	AudioServer.add_bus_effect(0,capture)
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	await create_timer(1.1).timeout
	capture.clear_buffer()
	game.audio_system.play_cue("swing")
	await create_timer(0.4).timeout
	var samples := capture.get_buffer(capture.get_frames_available())
	var peak := 0.0
	for sample in samples:
		peak = maxf(peak,maxf(absf(sample.x),absf(sample.y)))

	check(samples.size()>0 and peak>0.001,"Live music and effects reach the actual audio mixer")
	game.game_menu.open()
	for button in game.game_menu.content.find_children("*","Button",true,false):
		if button.text=="Audio":
			button.pressed.emit()
			break
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output_dir+"audio-settings.png")
	check(game.game_menu.audio_visible,"Audio menu is rendered")
	for button in game.game_menu.content.find_children("*","Button",true,false):
		if button.text=="Test sound effects":
			button.pressed.emit()
			break
	check(game.audio_system.cooldowns.has("interact"),"The audio preview button plays its cue while paused")
	game.game_menu.close()
	game.queue_free()
	await process_frame
	AudioServer.remove_bus_effect(0,AudioServer.get_bus_effect_count(0)-1)
	await create_timer(0.25).timeout
	print("Audio menu and live mixer checks; peak %.4f; failures: %d" % [peak,failures])
	quit(1 if failures else 0)


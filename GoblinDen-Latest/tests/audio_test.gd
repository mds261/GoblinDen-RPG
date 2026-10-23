extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run() -> void:
	load("res://scripts/save_data.gd").delete_save()
	if FileAccess.file_exists("user://audio_settings.cfg"):
		DirAccess.remove_absolute("user://audio_settings.cfg")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	var audio = game.audio_system
	check(audio.music_players.size()==2 and audio.voices.size()==8,"Music crossfade and effect voice counts are bounded")
	check(audio.current_mood=="haven","Den starts the haven theme")
	for mood in audio.loops:
		var stream: AudioStreamWAV = audio.loops[mood]
		check(stream.get_length()>60 and stream.stereo,"Music track is a complete stereo composition")
		check(stream.loop_mode==AudioStreamWAV.LOOP_FORWARD and stream.loop_end>1000000,"Music has a valid seamless forward loop")
	for cue in audio.EFFECTS:
		for voice in audio.voices:
			voice.stop()
		audio.cooldowns.clear()
		check(audio.EFFECTS[cue].get_length()>0.05 and audio.EFFECTS[cue].data.size()>1000,"Effect contains real sample data: " + cue)
		check(audio.play_sfx(cue),"Effect starts: " + cue)
		check(audio.voices[0].bus=="SFX" and audio.voices[0].playing,"Effect is routed to SFX")
	audio._process(2.0)
	game.enter_room(6,Vector2(1100,650))
	audio._process(0.1)
	check(audio.current_mood=="woodland","Outdoor travel selects woodland music")
	check(audio.music_players[0].playing and audio.music_players[1].playing,"Area transition crossfades both music voices")
	audio._process(3.0)
	var playing := 0
	for player in audio.music_players:
		if player.playing:
			playing += 1
	check(playing==1,"Old soundtrack stops after the fade")
	game.enter_room(13,Vector2(336,288))
	audio._process(0.1)
	check(audio.current_mood=="descent","Dungeon selects its darker soundtrack")
	for voice in audio.voices:
		voice.stop()
	audio.cooldowns.clear()
	audio.last_room = game.current_room
	audio.last_position = game.player.position
	audio.step_distance = 0
	game.player.position += Vector2(70,0)
	audio._update_footsteps()
	check(audio.voices[0].playing and audio.voices[0].stream==audio.EFFECTS.step_stone,"Actual movement triggers material-specific footsteps")
	game.game_menu.open()
	for voice in audio.voices:
		voice.stop()
	game.player.position += Vector2(70,0)
	audio._update_footsteps()
	check(not audio.voices[0].playing,"Paused menu does not generate footsteps")
	var old_duck: float = audio.duck_db
	audio._process(0.25)
	check(audio.duck_db<old_duck,"Pause gently lowers the soundtrack")
	var found := false
	for button in game.game_menu.content.find_children("*","Button",true,false):
		if button.text=="Audio":
			button.pressed.emit()
			found = true
			break
	check(found and game.game_menu.audio_visible,"Audio settings open from the real menu button")
	var sliders: Array = game.game_menu.content.find_children("*","HSlider",true,false)
	check(sliders.size()==2,"Separate music and effects sliders are available")
	sliders[0].value = 22
	sliders[1].value = 83
	check(is_equal_approx(audio.music_level,0.22) and is_equal_approx(audio.effects_level,0.83),"Real sliders update independent audio levels")
	audio.set_music_volume(0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("SFX")),"Music can be muted independently")
	audio.set_music_volume(0.22)
	game.game_menu.close()
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	check(is_equal_approx(game.audio_system.music_level,0.22) and is_equal_approx(game.audio_system.effects_level,0.83),"Volume settings persist across a game restart")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	await create_timer(0.25).timeout
	print("Soundtrack, effects, footstep, volume and persistence checks; failures: %d" % failures)
	quit(1 if failures else 0)


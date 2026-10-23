extends SceneTree
var game: Node2D
var failures := 0
var output_dir := "user://recovery-previews/"
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func capture(name: String) -> void:
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
	game.player.invulnerability = 9999
	game.player.get_node("Camera2D").position_smoothing_enabled = false
	for actor in get_nodes_in_group("enemies"):
		actor.set_physics_process(false)
	game.rpg.dungeon.boss.set_physics_process(false)
	game.enter_room(6,Vector2(1100,650))
	var rpg = game.rpg
	rpg.encounter_timer = 9999
	rpg.weather = "Clear"
	rpg.weather_timer = 9999
	var own := {"room":6,"position":Vector2(1160,650),"items":[{"id":"herb","count":2}],"kind":"Goblin corpse","remaining":1400.0}
	rpg.corpses.append(own)
	rpg._sync_recovery_visuals()
	await create_timer(0.2).timeout
	game.notice_time = 0
	check(rpg.recovery_visuals.size()==1 and rpg.recovery_visuals[0].visible,"Gear recovery creates visible world art")
	check(rpg.recovery_visuals[0].z_index==650,"Recovery art shares world depth sorting")
	await capture("01-recoverable-gear")
	game.enter_room(0,Vector2(575,400))
	await process_frame
	await process_frame
	check(not rpg.recovery_visuals[0].visible,"Recovery sprite hidden in other scenes")
	game.enter_room(6,Vector2(1100,650))
	var count: int = rpg.backpack.count_item("herb")
	rpg._recover_corpse(own)
	await process_frame
	await process_frame
	check(rpg.corpses.is_empty() and rpg.recovery_visuals.is_empty(),"Claimed gear removes world art")
	check(rpg.backpack.count_item("herb")==count+2,"New art preserves gear recovery")
	game.spawn_enemy_ext(6,Vector2(1180,650),"THORNWOOD SCOUT",10,0,0,14,"rogue",20,"")
	var enemy = game.rooms[6].get_child(game.rooms[6].get_child_count()-1)
	enemy.set_physics_process(false)
	enemy.take_damage(99999)
	await create_timer(0.6).timeout
	var monster: Dictionary = rpg.monster_corpses[-1]
	monster.items = [{"id":"wood","count":3},{"id":"herb","count":2}]
	game.notice_time = 0
	await capture("02-monster-loot-bundle")
	check(rpg.recovery_visuals[-1].monster,"Enemy loot uses smaller bundle")
	check(rpg.loot_window.open(monster),"New sprite still opens selective loot")
	await capture("03-claim-loot")
	rpg.loot_window.close()
	var audio = game.audio_system
	for voice in audio.voices:
		voice.stop()
	audio.cooldowns.clear()
	check(audio.play_sfx("magic"),"Soft spell cue plays")
	check(audio.voices[0].volume_db<=-15.0,"Spell mix remains restrained")
	check(not audio.play_sfx("swing"),"Crowded combat effects cannot stack instantly")
	audio._process(0.08)
	check(audio.play_sfx("hit"),"Combat feedback resumes after the short shared gap")
	check(not audio.play_sfx("magic"),"Repeated spells are throttled")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("Recovery rendering, interaction and gentler effect checks; failures: %d" % failures)
	quit(1 if failures else 0)

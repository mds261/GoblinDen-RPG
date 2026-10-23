extends SceneTree
const Anim = preload("res://scripts/enemy_animation.gd")
const Directional = preload("res://scripts/directional_actor.gd")
var failures := 0
var checks := 0
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func inspect_clips(data: Dictionary, size: Vector2, label: String) -> void:
	for i in range(data["regions"].size()):
		var region: Rect2 = data["regions"][i]
		check(Rect2(Vector2.ZERO, size).encloses(region), label + " frame inside original PNG")
		check(not data["clips"][i].is_empty(), label + " isolated frame clip exists")
		for clip in data["clips"][i]:
			var polygon := PackedVector2Array(clip)
			check(not Geometry2D.triangulate_polygon(polygon).is_empty(), label + " clip triangulates")
			for point in polygon:
				check(point.x >= 0 and point.y >= 0 and point.x <= region.size.x and point.y <= region.size.y, label + " clip inside source region")
func run_checks() -> void:
	check(Anim.SHEETS.size() == 10, "Ten distinct enemy atlas identities")
	for key in Anim.SHEETS:
		var anim := Anim.new()
		anim.configure(key)
		var data: Dictionary = Anim.Frames.DATA[key]
		check(data["regions"].size() == 20, key + " has twenty poses")
		inspect_clips(data, Anim.SHEETS[key].get_size(), key)
		for movement in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
			anim.update(0.2, movement * 100, true)
			check(anim.frame_index() in range(4,8) if movement == Vector2.UP else (anim.frame_index() in range(0,4) if movement == Vector2.DOWN else anim.frame_index() in range(8,12)), key + " correct movement view")
			var view := anim.direction
			anim.update(0.1, Vector2.ZERO, true)
			check(anim.direction == view and anim.state == "idle", key + " idle retains view")
		anim.update(0.01, Vector2.ZERO, true, 0.65, 0.65, Vector2.LEFT)
		check(anim.frame_index() == 12 and anim.faces_left, key + " windup faces target")
		anim.update(0.01, Vector2.ZERO, true, 0.01, 0.65, Vector2.LEFT)
		check(anim.frame_index() == 13, key + " anticipation holds until damage event")
		anim.release_attack()
		check(anim.frame_index() == 14, key + " damage event selects contact pose")
		anim.update(0.18, Vector2.ZERO, true)
		check(anim.frame_index() == 15, key + " recovery pose")
		anim.update(0.2, Vector2.ZERO, true)
		check(anim.frame_index() < 12 and anim.state == "idle", key + " attacks stop instead of looping")
		anim.release_attack()
		anim.update(0.01, Vector2.ZERO, true, 0.4, 0.65, Vector2.RIGHT, true)
		check(anim.state == "stunned", key + " stun interrupts attack playback")
		anim.update(0.35, Vector2.ZERO, false)
		check(anim.frame_index() == 19, key + " final collapse before minion despawn")
		anim.update(2.0, Vector2.ZERO, false)
		check(anim.frame_index() == 19, key + " corpse holds final pose")
	var blade := Directional.new()
	blade.configure("blade")
	check(Directional.Frames.DATA["blade"]["regions"].size() == 16, "Blade has one complete movement/attack atlas")
	inspect_clips(Directional.Frames.DATA["blade"], Directional.SHEETS["blade"].get_size(), "blade")
	for movement in [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT]:
		blade.update(0.2, movement * 100, true)
		check(blade.uses_sheet(), "Blade never falls back to the mismatched old side sheet")
	blade.start_attack()
	check(blade.uses_sheet() and blade.frame_index(false) == 12, "Blade attack uses the same atlas as walking")
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.enter_room(1, Vector2(360, 440))
	game.player.invulnerability = 999.0
	game.player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	for role in ["knight", "priest", "mage", "ranger", "rogue", "boss"]:
		var enemy = load("res://scenes/knight.tscn").instantiate()
		enemy.role = role
		enemy.position = Vector2(600, 440)
		game.rooms[1].add_child(enemy)
		enemy.set_physics_process(false)
		enemy.windup = 0.3
		enemy._process(0.01)
		check(enemy.appearance_animation.kind == ("captain" if role == "boss" else role), role + " actual actor selects its own art")
		check(enemy.appearance_animation.state == "windup", role + " actual windup is wired")
		enemy.strike_position = game.player.global_position
		enemy._execute_windup_attack(1)
		check(enemy.appearance_animation.frame_index() == 14, role + " actual strike triggers contact")
		enemy.queue_free()
	for kind in ["spider", "ogre", "wolf_rider"]:
		var enemy = load("res://scripts/large_enemy.gd").new()
		enemy.configure(kind)
		enemy.position = Vector2(700, 440)
		game.rooms[1].add_child(enemy)
		enemy.set_physics_process(false)
		enemy.windup = 0.2
		enemy._process(0.01)
		check(enemy.appearance_animation.kind == kind and enemy.appearance_animation.state == "windup", kind + " boss animation wired")
		enemy._execute_attack()
		check(enemy.appearance_animation.frame_index() == 14, kind + " actual strike selects contact")
		if kind == "spider":
			enemy._summon_spiderlings()
			enemy._drop_poison_cloud()
			check(enemy.appearance_animation.state == "release", "Spider signature abilities animate")
		enemy.queue_free()
	for kind in ["spiderling", "wolf"]:
		var enemy = load("res://scripts/monster_minion.gd").new()
		enemy.configure(kind)
		enemy.position = game.player.position + Vector2(30, 0)
		game.rooms[1].add_child(enemy)
		enemy.set_physics_process(false)
		enemy.cooldown = 0.0
		enemy._physics_process(0.01)
		check(enemy.appearance_animation.state == "release", kind + " instant bite and contact stay synchronized")
		check(enemy.appearance_animation.faces_left, kind + " bite faces target")
		enemy.hp = 0
		enemy._process(0.35)
		check(enemy.appearance_animation.frame_index() == 19, kind + " real minion collapse completes")
		enemy.queue_free()
	var captain = game.rooms[2].get_child(0)
	captain._begin_attack("charge", 0.01)
	captain._physics_process(0.02)
	check(captain.appearance_animation.state == "release", "Iron Captain charge animates on launch")
	captain._sweep()
	check(captain.appearance_animation.frame_index() == 14, "Iron Captain sweep animates on damage")
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Enemy and unified Blade animations: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures; ", checks, " checks)")
	quit(failures)

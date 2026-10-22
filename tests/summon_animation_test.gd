extends SceneTree
const Anim = preload("res://scripts/summon_animation.gd")
const Ally = preload("res://scripts/goblin_ally.gd")
const Effect = preload("res://scripts/special_effect.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run_checks")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run_checks() -> void:
	for kind in Anim.SHEETS:
		var anim := Anim.new()
		anim.configure(kind)
		var data: Dictionary = Anim.Frames.DATA[kind]
		check(data.regions.size() == 20, kind + ": twenty poses")
		for i in range(20):
			var sheet: Texture2D = Anim.ATTACK_SHEET if i >= 12 and i < 16 else Anim.SHEETS[kind]
			check(Rect2(Vector2.ZERO, sheet.get_size()).encloses(data.regions[i]), kind + ": frame bounds")
			for j in range(i + 1, 20):
				var same_sheet: bool = (i >= 12 and i < 16) == (j >= 12 and j < 16)
				if same_sheet:
					check(not data.regions[i].intersects(data.regions[j]), kind + ": isolated frame regions")
		for dir in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			anim.update(0.2, dir * 100.0, true)
			var expected: String = "up" if dir == Vector2.UP else ("down" if dir == Vector2.DOWN else "side")
			check(anim.direction == expected, kind + ": correct direction")
			var old_direction := anim.direction
			anim.update(0.1, Vector2.ZERO, true)
			check(anim.direction == old_direction, kind + ": idle keeps direction")
		anim.start_attack(true)
		check(anim.frame_index() == 12 and anim.faces_left, kind + ": left attack begins")
		anim.update(0.2, Vector2.ZERO, true)
		check(anim.frame_index() == 14, kind + ": bite/slash contact pose")
		anim.update(0.3, Vector2.ZERO, true)
		check(anim.frame_index() < 12, kind + ": recovery returns to idle")
		anim.update(0.1, Vector2.ZERO, true, 8.0)
		check(anim.buff_elapsed < 0.2, kind + ": buff starts once")
		anim.update(0.3, Vector2.ZERO, true, 7.7)
		check(anim.buff_elapsed > 0.3, kind + ": buff does not restart each tick")
		anim.update(0.2, Vector2.ZERO, false)
		check(anim.frame_index(true) == 17, kind + ": collapse advances")
		anim.update(1.0, Vector2.ZERO, false)
		check(anim.frame_index(true) == 19, kind + ": corpse holds final pose")
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.apply_class_and_gear("archer", "beastmaster", true)
	game._sync_summons()
	check(game.summon_nodes.size() == 1 and game.summon_nodes[0].role == "wolf", "Beastmaster gets wolf")
	game.player.apply_class_and_gear("mage", "necromancer", true)
	game._sync_summons()
	game.current_room = 1
	game._on_player_special_used("test")
	await process_frame
	check(game.summon_nodes.size() == 2, "Necromancer raises two skeletons")
	for summon in game.summon_nodes:
		check(summon.role == "skeleton", "Undead use skeleton role")
	game.summon_nodes[0].hp = 0
	game._spawn_skeleton_minion(Vector2(200, 200))
	check(game.summon_nodes.size() == 2, "Dead skeleton no longer blocks replacement")
	game._spawn_skeleton_minion(Vector2(210, 200))
	check(game.summon_nodes.size() == 2, "Living summon cap remains two")
	for kind in preload("res://scripts/summon_gallery.gd").KINDS:
		var effect := Effect.new()
		effect.setup(kind, Vector2.LEFT, 100.0)
		root.add_child(effect)
		check(effect.z_index == 0 and not effect.z_as_relative, kind + ": ground layer")
		check(effect.get_child_count() == 1 and effect.get_child(0).z_index == 2000, kind + ": airborne layer")
		effect._process(effect.duration + 0.1)
		check(effect.is_queued_for_deletion(), kind + ": effects clean up")
	await create_timer(0.8).timeout
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Summons and signature effects: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(failures)

extends SceneTree
const Directional = preload("res://scripts/directional_actor.gd")
const GoblinData = preload("res://scripts/goblin_data.gd")
var failures := 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _initialize() -> void:
	call_deferred("run_checks")

func run_checks() -> void:
	# The normal game creates these in main._ready; this isolated fixture does not load main.
	for action in ["move_up", "move_down", "move_left", "move_right", "dodge", "attack", "special_skill"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for key in Directional.Frames.DATA:
		var data: Dictionary = Directional.Frames.DATA[key]
		var base: String = data["base"]
		var actor = Directional.new()
		actor.configure(base, key if key != base else "")
		check(actor.visual_id == key, key + " selects its own atlas")
		actor.update(0.25, Vector2(0, -100), true)
		check(actor.direction == "up" and actor.frame_index(true) in range(4, 8), key + " walking up uses rear poses")
		actor.update(0.1, Vector2.ZERO, true)
		check(actor.direction == "up" and actor.frame_index(false) == 4, key + " idle retains rear view")
		actor.update(0.1, Vector2(100, -100), true)
		check(actor.direction == "up", key + " diagonal dead band retains vertical axis")
		actor.update(0.1, Vector2(0, 100), true)
		check(actor.direction == "down" and actor.frame_index(true) in range(0, 4), key + " walking down uses front poses")
		actor.update(0.1, Vector2(-100, 0), true)
		check(actor.direction == "side" and actor.faces_left, key + " horizontal movement mirrors side art")
		actor.start_attack()
		check(actor.uses_sheet() == (key != base or key == "blade"), key + " base attacks retained and evolution attacks distinct")
		if key != base or key == "blade":
			check(actor.frame_index(false) == 12, key + " own attack starts at row four")
		actor.update(0.5, Vector2.ZERO, true)
		check(not actor.attacking, key + " attack completes")
		actor.start_attack()
		actor.update(0.01, Vector2.ZERO, false)
		check(not actor.attacking, key + " death stops attack")
		var texture_size: Vector2 = Directional.SHEETS[key].get_size()
		var regions: Array = data["regions"]
		check(regions.size() == (8 if key == base and key != "blade" else 16), key + " required frame count")
		for i in range(regions.size()):
			check(Rect2(Vector2.ZERO, texture_size).encloses(regions[i]), key + " source in atlas bounds")
			for j in range(i):
				if not data.has("clips"):
					check(not regions[i].intersects(regions[j]), key + " sources do not overlap")
	var arena := Node2D.new()
	root.add_child(arena)
	var player = load("res://scenes/player.tscn").instantiate()
	arena.add_child(player)
	player.set_physics_process(false)
	for base in GoblinData.CLASSES:
		player.apply_class_and_gear(base)
		Input.action_press("move_up")
		player._physics_process(0.05)
		Input.action_release("move_up")
		check(player.appearance_animation.direction == "up", base + " player movement selects rear view")
		player._physics_process(0.05)
		check(player.appearance_animation.direction == "up", base + " player idle retains rear view")
		for evolution in GoblinData.CLASSES[base]["evolutions"]:
			player.apply_class_and_gear(base, evolution)
			check(player.appearance_animation.visual_id == evolution, evolution + " class switch equips new art")
			player.attack_cooldown = 0.0
			player.dodge_time = 0.0
			player.attack()
			check(player.appearance_animation.attacking, evolution + " normal attack wired")
			player.appearance_animation.update(0.5, Vector2.ZERO, true)
			player.special_cooldown = 0.0
			player.use_special()
			check(player.appearance_animation.attacking, evolution + " special wired")
			# Render actual player/evolution once as well as inspecting controller state.
			player.queue_redraw()
			await process_frame
		player.dodge_time = 0.0
		player.attack_cooldown = 0.0
		player.apply_class_and_gear(base)
		check(player.appearance_animation.visual_id == base, base + " switching back restores base art")
	for base in GoblinData.CLASSES:
		var ally = load("res://scripts/goblin_ally.gd").new()
		ally.role = base
		ally.position = Vector2(400, 500)
		arena.add_child(ally)
		ally.set_physics_process(false)
		ally._physics_process(0.01)
		check(ally.appearance_animation.class_id == base, base + " companion configured")
		check(ally.appearance_animation.direction == "up", base + " companion follows upward with rear art")
		ally.queue_free()
	arena.queue_free()
	await process_frame
	print("Directional/evolution checks: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(failures)

extends SceneTree

const SaveData = preload("res://scripts/save_data.gd")
const GoblinData = preload("res://scripts/goblin_data.gd")
const Trap = preload("res://scripts/trap.gd")
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run() -> void:
	SaveData.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	var seen_names := {}
	for evolution_id in GoblinData.EVOLUTIONS:
		var evo: Dictionary = GoblinData.EVOLUTIONS[evolution_id]
		game.player.apply_class_and_gear(evo["base_class"], evolution_id, true)
		game.player.special_cooldown = 0.0
		var special_name: String = game.player.get_special_name()
		check(special_name == evo["special_name"], "%s should expose its own special name." % evolution_id)
		check(not seen_names.has(special_name), "%s should have a unique evolved special." % evolution_id)
		seen_names[special_name] = true
		var room: Node = game.rooms[game.current_room]
		var before := room.get_child_count()
		game.player.use_special()
		await process_frame
		check(room.get_child_count() > before or evolution_id in ["warlord", "guardian"], "%s should create visible special art." % evolution_id)
	var timed_trap := Trap.new()
	timed_trap.lifetime = 0.05
	game.rooms[0].add_child(timed_trap)
	timed_trap._physics_process(0.06)
	check(not timed_trap.armed and timed_trap.expired, "An untriggered snare should expire when its timer reaches zero.")
	check(is_equal_approx(timed_trap.remaining_lifetime, 0.0), "Expired snare timer should stop at zero.")
	print("Evolved special checks; failures: %d" % failures)
	game.queue_free()
	await process_frame
	SaveData.delete_save()
	quit(failures)

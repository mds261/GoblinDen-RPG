extends SceneTree
const SaveData = preload("res://scripts/save_data.gd")
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_checks")

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		push_error(description)

func run_checks() -> void:
	# The game auto-loads user://goblin_den_save.cfg on startup, so wipe any
	# leftover save first to keep these checks deterministic.
	SaveData.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	game.enter_room(2, Vector2(380, 260))
	var cave = game.get_node("Cave")
	var boss = game.rooms[2].get_child(0)
	boss.set_physics_process(false)
	check(cave.chokepoints_active, "Captain arena has collision pillars")
	# A real actor must cross the obstructed route, not merely produce a path.
	game.spawn_enemy_ext(2, Vector2(610, 260), "PATH TEST", 100, 150.0, 1, 0, "knight", 0, "")
	var pursuer = game.rooms[2].get_child(1)
	game.player.set_physics_process(false)
	game.player.invulnerability = 99.0
	for frame in range(230):
		await physics_frame
	check(pursuer.position.distance_to(game.player.position) < 85.0, "Enemy navigates around pillar and reaches player")
	pursuer.queue_free()
	await process_frame
	# Locked charge: moving the target after the tell cannot retarget the charge.
	boss.position = Vector2(650, 250)
	game.player.position = Vector2(350, 250)
	boss._begin_attack("charge", 0.95)
	var locked: Vector2 = boss.charge_direction
	game.player.position = Vector2(350, 400)
	boss._physics_process(0.96)
	check(boss.charge_direction == locked, "Charge commits to telegraphed direction")
	for frame in range(35):
		boss._physics_process(1.0 / 60.0)
		await physics_frame
	check(boss.stun_timer > 0.0, "Charging into pillar staggers Captain")
	# Sweep has a safe rear arc and damages the front once.
	boss.position = Vector2(800, 350)
	boss.charge_direction = Vector2.LEFT
	game.player.position = Vector2(870, 350)
	game.player.invulnerability = 0.0
	var hp_before: int = game.player.hp
	boss._sweep()
	check(game.player.hp == hp_before, "Behind Captain is safe during sweep")
	game.player.position = Vector2(730, 350)
	boss._sweep()
	check(game.player.hp < hp_before, "Sweep hits exposed front arc")
	# One rally opportunity per encounter; stun cancels it.
	boss.hp = 80
	boss.stun_timer = 0.0
	boss._recover(0.0)
	boss._physics_process(0.02)
	check(boss.boss_state == "rally", "Half health starts rally telegraph")
	boss.apply_stun(1.0)
	boss._physics_process(0.02)
	check(game.rooms[2].get_child_count() == 1, "Interrupt prevents reinforcements")
	boss.stun_timer = 0.0
	boss._recover(0.0)
	boss._physics_process(0.02)
	check(boss.boss_state != "rally", "Interrupted rally does not repeat")
	boss._rally()
	check(game.rooms[2].get_child_count() == 3, "Completed rally calls two guards")
	# Dodge follows movement while aim stays independent.
	game.player.dodge_cooldown = 0.0
	game.player.facing = Vector2.RIGHT
	Input.action_press("move_up")
	game.player.start_dodge()
	Input.action_release("move_up")
	check(game.player.dodge_direction == Vector2.UP, "Dodge follows movement rather than mouse aim")
	game.enter_room(0, Vector2(450, 350))
	check(boss.boss_state == "recover", "Room transitions cancel pending boss attacks")
	game.queue_free()
	await process_frame
	check(Engine.time_scale == 1.0, "Feedback restores time scale on restart")
	print("Combat update checks; failures: ", failures)
	quit(failures)

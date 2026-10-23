extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	load("res://scripts/save_data.gd").delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await physics_frame
	var player = game.player
	var feedback = game.interaction_feedback
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	game.enter_room(0, Vector2(575,420))
	Input.action_press("move_right")
	player._physics_process(1.0/60.0)
	check(player.velocity.x > 0 and player.velocity.x < player.speed, "Movement accelerates quickly without instantly snapping to full speed")
	for i in range(10):
		player._physics_process(1.0/60.0)
	check(is_equal_approx(player.velocity.x, player.speed), "Walking reaches class speed")
	Input.action_release("move_right")
	for i in range(5):
		player._physics_process(1.0/60.0)
	check(player.velocity == Vector2.ZERO, "Release brakes to rest within five frames")
	player.dodge_time = 0.005
	player.velocity = Vector2.RIGHT * player.speed * 2.8
	player._physics_process(0.016)
	check(player.velocity == Vector2.ZERO, "Dodge exit has no residual glide")
	# Real wall fixture isolates actual displacement from intended velocity.
	game.enter_room(0,Vector2(580,420))
	var wall := StaticBody2D.new()
	wall.position = Vector2(620,420)
	wall.collision_layer = 1
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(20,160)
	collision.shape = shape
	wall.add_child(collision)
	game.add_child(wall)
	await physics_frame
	Input.action_press("move_right")
	for i in range(25):
		player._physics_process(0.016)
	Input.action_release("move_right")
	check(player.animation_velocity.length() < 5, "Walking animation stops against a physical wall")
	wall.queue_free()
	await physics_frame
	player.facing = Vector2.LEFT
	player.attack_cooldown = 0.0
	player.attack()
	player.facing = Vector2.RIGHT
	check(player.attack_facing == Vector2.LEFT, "Attack keeps its initial visual direction")
	player.attack_buffer = 0.1
	game.enter_room(0, Vector2(350,500))
	check(player.animation_velocity == Vector2.ZERO and player.attack_buffer == 0 and not player.appearance_animation.attacking, "Travel clears old movement and attack animation")
	await physics_frame
	var target: Dictionary = feedback.choose(feedback.candidates())
	check(str(target.get("label", "")) == "Open den chest", "Chest prompt identifies the actual nearby object")
	feedback.activation_cooldown = 0.0
	check(feedback.activate() and game.rpg.panel.visible and game.rpg.storage_kind == "chest", "Focused chest activation opens that chest")
	check(not feedback.activate(), "Open inventory blocks world interaction")
	game.rpg.panel.hide()
	game.enter_room(0, Vector2(550,300))
	await physics_frame
	feedback.activation_cooldown = 0.0
	target = feedback.choose(feedback.candidates())
	check(str(target.get("label", "")).contains("Moss"), "NPC prompt names the selected resident")
	feedback.activate()
	check(game.rpg.dialogue.visible, "Focused NPC activation opens dialogue")
	game.rpg.dialogue.hide()
	game.enter_room(0, Vector2(500,430))
	await physics_frame
	var options := [{"point":Vector2(520,430),"radius":80.0,"label":"near"},{"point":Vector2(540,430),"radius":80.0,"label":"far"}]
	check(feedback.choose(options).get("label") == "near", "Overlapping interaction ranges choose the closest object")
	var barrier := StaticBody2D.new()
	barrier.position = Vector2(530,430)
	barrier.collision_layer = 1
	var block := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10,100)
	block.shape = rect
	barrier.add_child(block)
	game.add_child(barrier)
	await physics_frame
	check(feedback.choose([{"point":Vector2(575,430),"radius":90.0}]).is_empty(), "Interaction focus rejects a target through a wall")
	barrier.queue_free()
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("Movement and interaction checks; failures: ", failures)
	quit(failures)

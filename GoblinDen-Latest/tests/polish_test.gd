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
	await process_frame
	var player = game.player
	var rpg = game.rpg
	player.set_physics_process(false)
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.dodge_cooldown = 0.08
	Input.action_press("dodge")
	player._physics_process(0.016)
	Input.action_release("dodge")
	await process_frame
	player._physics_process(0.08)
	check(player.dodge_time > 0.0, "Released early dodge executes when cooldown ends")
	player.dodge_time = 0.0
	player.special_cooldown = 0.08
	Input.action_press("special_skill")
	player._physics_process(0.016)
	Input.action_release("special_skill")
	await process_frame
	player._physics_process(0.08)
	check(player.special_cooldown > 1.0, "Released early special executes when cooldown ends")
	player.dodge_time = 0.0
	player.dodge_cooldown = 0.0
	rpg.stamina = 0.0
	Input.action_press("dodge")
	player._physics_process(0.016)
	Input.action_release("dodge")
	await process_frame
	player._physics_process(0.2)
	rpg.stamina = 100.0
	player._physics_process(0.016)
	check(player.dodge_time == 0.0, "Expired dodge does not fire later when stamina recovers")
	player.attack_buffer = 0.1
	player.dodge_buffer = 0.1
	player.special_buffer = 0.1
	rpg.panel.show()
	player._physics_process(0.016)
	check(player.attack_buffer == 0.0 and player.dodge_buffer == 0.0 and player.special_buffer == 0.0, "Opening inventory cancels queued combat")
	check(rpg._tooltip("fish").contains("Restores 15"), "Consumable tooltip describes healing")
	check(rpg._tooltip("wood").contains("Crafting material"), "Material tooltip avoids misleading weapon stats")
	rpg.backpack.add("bow")
	rpg.selected_index = rpg.backpack.slots.size() - 1
	rpg._refresh_panel()
	var text := ""
	for child in rpg.body.get_children():
		if child is Label:
			text += child.text + "\n"
	check(text.contains("Compared with") and text.contains("Attack +8"), "Selected equipment displays a stat comparison")
	# Exercise range hit feedback using a real player-owned projectile.
	rpg.panel.hide()
	game.enter_room(2, Vector2(380, 260))
	var enemy = game.rooms[2].get_child(0)
	var shot = load("res://scripts/projectile.gd").new()
	shot.owner_actor = player
	shot.damage = 5
	game.add_child(shot)
	var before: int = enemy.hp
	shot._apply_to_enemy(enemy)
	check(enemy.hp < before, "Player ranged impact damages a real enemy and spawns feedback without errors")
	shot.queue_free()
	rpg.equipped.helmet = "helmet"
	rpg.backpack.capacity = rpg.backpack.slots.size()
	rpg.unequip("helmet")
	check(rpg.equipped.get("helmet") == "helmet", "Full backpack preserves equipped gear")
	check(str(rpg.logs.back()).contains("Backpack full"), "Full backpack provides a reason for failed unequip")
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	print("Polish checks; failures: ", failures)
	quit(failures)

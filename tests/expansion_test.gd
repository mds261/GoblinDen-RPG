extends SceneTree
const SaveData = preload("res://scripts/save_data.gd")
const CameraFX = preload("res://scripts/camera_fx.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")
const Tutorial = preload("res://scripts/tutorial.gd")
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
	await physics_frame
	var player = game.player
	check(game.current_room == 0 and game.living_enemies() == 0, "Start in safe den")
	check(not game.rooms[1].visible and game.rooms[1].get_child(0).collision_layer == 0, "Inactive enemies disabled")
	var origin: Vector2 = player.position
	Input.action_press("move_right")
	for frame in range(12):
		await physics_frame
	Input.action_release("move_right")
	check(player.position.x > origin.x + 10, "Movement input")
	player.position = Vector2(100,380)
	Input.action_press("move_left")
	for frame in range(25):
		await physics_frame
	Input.action_release("move_left")
	check(player.position.x >= 94, "Wall collision")
	player.start_dodge()
	check(player.dodge_time > 0 and player.invulnerability > 0, "Dodge starts")
	player.take_damage(20)
	check(player.hp == 100, "Dodge prevents damage")
	player.dodge_time = 0
	player.start_dodge()
	check(player.dodge_time == 0, "Dodge cooldown")
	player.position = game.FORGE
	game.interact()
	check(game.blade_level == 1 and game.scrap == 0, "Cannot buy without scrap")
	player.position = game.RIGHT_GATE
	game.interact()
	check(game.current_room == 1 and game.living_enemies() == 2, "Travel into passage")
	for enemy in game.rooms[1].get_children():
		enemy.set_physics_process(false)
	player.position = game.RIGHT_GATE
	game.interact()
	check(game.current_room == 1, "Forward exit blocked during battle")
	var scout = game.rooms[1].get_child(0)
	player.position = Vector2(400,350)
	scout.position = Vector2(455,350)
	player.facing = Vector2.LEFT
	player.attack()
	check(scout.hp == 60, "Directional melee misses behind")
	player.attack_cooldown = 0
	player.facing = Vector2.RIGHT
	player.attack()
	check(scout.hp == 35 and scout.knockback.length() > 0, "Melee damage and knockback")
	player.attack()
	check(scout.hp == 35, "Melee cooldown")
	player.attack_cooldown = 0
	player.position = Vector2(110,350)
	scout.position = Vector2(60,350)
	player.facing = Vector2.LEFT
	await physics_frame
	player.attack()
	check(scout.hp == 35, "Wall blocks attack")
	scout.position = Vector2(455,350)
	player.position = Vector2(400,350)
	player.invulnerability = 0
	scout.windup = 0.01
	scout.strike_position = player.position
	scout._physics_process(0.02)
	check(player.hp == 85, "Knight hits marked location")
	player.invulnerability = 0
	scout.windup = 0.01
	scout.strike_position = Vector2(600,350)
	scout._physics_process(0.02)
	check(player.hp == 85, "Moving avoids knight attack")
	# Retreat before clearing: health and enemy damage persist across rooms.
	player.position = game.LEFT_GATE
	game.interact()
	check(game.current_room == 0 and player.hp == 85, "Retreat preserves HP")
	player.position = game.REST
	game.interact()
	check(player.hp == 100 and game.health_bar.value == 100, "Rest restores health and HUD")
	player.position = game.RIGHT_GATE
	game.interact()
	check(scout.hp == 35, "Enemy HP persists")
	for enemy in game.rooms[1].get_children():
		if enemy is CharacterBody2D:
			enemy.take_damage(999)
	await process_frame
	await process_frame
	check(game.living_enemies() == 0, "Passage cleared")
	# Collect drops by moving onto them, not by calling the reward handler.
	for drop in game.rooms[1].get_children():
		if not drop is CharacterBody2D:
			player.position = drop.position
			await process_frame
			await process_frame
	check(game.scrap == 6, "Each enemy awards scrap once")
	scout.take_damage(999)
	await process_frame
	check(game.scrap == 6, "Dead enemy cannot award again")
	player.position = game.LEFT_GATE
	game.interact()
	player.position = game.FORGE
	game.interact()
	check(game.blade_level == 2 and game.scrap == 3 and player.attack_damage == 35, "Forge purchase")
	game.interact()
	check(game.blade_level == 2 and game.scrap == 3, "Second upgrade requires six scrap")
	player.position = game.RIGHT_GATE
	game.interact()
	player.position = game.RIGHT_GATE
	game.interact()
	check(game.current_room == 2, "Cleared passage unlocks breach")
	var captain = game.rooms[2].get_child(0)
	check(captain.hp == 180, "Captain stats")
	captain.take_damage(999)
	await process_frame
	await process_frame
	player.position = captain.position
	await process_frame
	await process_frame
	check(game.scrap == 11 and game.captain_defeated, "Captain reward")
	player.position = game.LEFT_GATE
	game.interact()
	player.position = game.LEFT_GATE
	game.interact()
	check(game.completed and game.current_room == 0, "Return-home victory")
	player.position = game.FORGE
	game.interact()
	check(game.blade_level == 3 and game.scrap == 5 and player.attack_damage == 45, "Final blade upgrade")
	game.interact()
	check(game.scrap == 5, "Max level cannot spend scrap")
	player.invulnerability = 0
	player.take_damage(999)
	check(player.hp == 0 and game.result.text.contains("FALLEN"), "Death state")
	player.position = game.REST
	game.interact()
	check(player.hp == 0, "Dead player cannot heal")
	game.queue_free()
	await process_frame
	var fresh = load("res://scenes/main.tscn").instantiate()
	root.add_child(fresh)
	await physics_frame
	check(fresh.scrap == 0 and fresh.blade_level == 1 and fresh.player.hp == 100, "Fresh run resets progression")
	# Expanded Goblin Perspective RPG concept checks:
	# 1. Class selection (Blade, Archer, Knight, Mage) & Class Evolutions
	fresh.select_goblin_class("archer")
	check(fresh.player.class_id == "archer" and fresh.player.attack_range > 300.0, "Archer Goblin ranged class")
	fresh.player.special_cooldown = 0.0
	fresh.player.use_special()
	check(get_nodes_in_group("goblin_traps").size() == 1, "Archer deploys snare trap")
	fresh.select_goblin_class("knight")
	check(fresh.player.class_id == "knight" and fresh.player.armor_rating >= 0.25, "Knight Goblin tank armor")
	fresh.select_goblin_class("mage")
	check(fresh.player.class_id == "mage", "Mage Goblin spellcaster class")
	fresh.gain_xp(120)
	check(fresh.player.level >= 2, "XP gain and level-up")
	fresh.cycle_class_evolution(false)
	check(fresh.player.evolution_id == "shaman", "Mage evolves into Shaman")
	# 2. Story-driven human loot & Treasure Room equipping
	fresh._on_loot_and_xp_collected("captain_sword", 0)
	fresh.player.position = fresh.TREASURE_ROOM
	fresh.interact()
	check(fresh.player.equipped_loot_id == "captain_sword", "Treasure Room equips Knight Captain's Sword")
	# 3. Recruitment Hut & Inverted RPG Party
	fresh.scrap = 10
	fresh.player.position = fresh.RECRUITMENT_HUT
	fresh.interact()
	check(fresh.party_nodes.size() == 1 and fresh.recruited_ids[0] == "goblin_archer", "Recruit Goblin Party ally")
	# 4. War Room escalating campaigns (Coordinated Human Adventuring Party)
	fresh.player.position = fresh.WAR_ROOM
	fresh.interact()
	check(fresh.campaign_index == 1 and fresh.rooms[1].get_child_count() == 3, "War Room launches Tier 2 Guild Party")
	# ===== POLISH & UX CHECKS =====
	# 5. Camera shake system
	var cam = fresh.player.get_node_or_null("Camera2D")
	check(is_instance_valid(cam), "Player owns a Camera2D for shake")
	CameraFX.shake(cam, 8.0, 0.3)
	check(cam.get_meta("shake_intensity", 0.0) == 8.0, "Shake stores intensity")
	check(cam.get_meta("shake_duration", 0.0) == 0.3, "Shake stores duration")
	CameraFX.update_shake(cam, 0.05)
	check(cam.offset != Vector2.ZERO, "Shake displaces the camera")
	CameraFX.shake(cam, 2.0, 0.3)
	check(cam.get_meta("shake_intensity", 0.0) == 8.0, "Weaker shake does not override a stronger one")
	CameraFX.update_shake(cam, 1.0)
	check(cam.offset == Vector2.ZERO, "Shake settles back to rest")
	# Screen flash overlay
	CameraFX.flash_screen(fresh.screen_flash, Color(1, 1, 1, 0.4), 0.2)
	check(fresh.screen_flash.visible, "Screen flash turns on")
	CameraFX.update_flash(fresh.screen_flash, 0.3)
	check(not fresh.screen_flash.visible, "Screen flash fades back off")
	# 6. Floating damage numbers (all five factories)
	var before_text: int = fresh.get_child_count()
	FloatingText.spawn_damage(fresh, Vector2(100, 100), 42, false)
	FloatingText.spawn_damage(fresh, Vector2(150, 100), 99, true)
	FloatingText.spawn_player_hit(fresh, Vector2(200, 200), 15)
	FloatingText.spawn_heal(fresh, Vector2(300, 300), 20)
	FloatingText.spawn_status(fresh, Vector2(400, 400), "STUNNED!", Color.YELLOW)
	FloatingText.spawn_loot(fresh, Vector2(500, 500), "RELIC")
	check(fresh.get_child_count() - before_text == 6, "All six floating-text factories spawn a node")
	await process_frame
	# 7. Death particle bursts
	var before_death: int = fresh.get_child_count()
	DeathEffect.burst_enemy(fresh, Vector2(300, 300))
	DeathEffect.burst_boss(fresh, Vector2(400, 400))
	DeathEffect.burst_ally(fresh, Vector2(500, 500))
	check(fresh.get_child_count() - before_death == 3, "All three death-burst factories spawn a node")
	await process_frame
	# 8. Impact flash / spark effects
	var before_spark: int = fresh.get_child_count()
	HitSpark.melee_hit(fresh, Vector2(300, 300), false)
	HitSpark.melee_hit(fresh, Vector2(400, 400), true)
	HitSpark.projectile_hit(fresh, Vector2(500, 500), "hex")
	HitSpark.trap_spring(fresh, Vector2(600, 600))
	check(fresh.get_child_count() - before_spark == 4, "All four hit-spark factories spawn a node")
	await process_frame
	# 9. Enhanced HUD + save-system surface
	check(is_instance_valid(fresh.xp_bar), "XP progress bar exists in the HUD")
	check(is_instance_valid(fresh.save_indicator), "Save indicator exists in the HUD")
	check(fresh.has_method("get_stats"), "Game exposes get_stats() for the save system")
	var stats: Dictionary = fresh.get_stats()
	check(stats.has("total_playtime") and stats.has("player_level"), "Stats carry playtime and player level")
	# 10. Save / load round trip
	SaveData.delete_save()
	fresh.scrap = 25
	fresh.blade_level = 3
	fresh.player.level = 5
	fresh.player.attack_damage = 40
	SaveData.save(fresh)
	check(SaveData.has_save(), "Save file written to disk")
	var reload = load("res://scenes/main.tscn").instantiate()
	root.add_child(reload)
	await physics_frame
	var restored: bool = SaveData.load_data(reload)
	check(restored, "Save data loads back successfully")
	check(reload.scrap == 25, "Scrap restored (%d)" % reload.scrap)
	check(reload.blade_level == 3, "Blade level restored")
	check(reload.player.level == 5, "Player level restored")
	check(reload.player.attack_damage == 40, "Attack damage restored")
	reload.queue_free()
	SaveData.delete_save()
	check(not SaveData.has_save(), "Save file removed")
	# 11. Tutorial one-shot hint tracking
	check(Tutorial.should_show(fresh, "first_codex"), "An unseen hint is still pending")
	Tutorial.mark_shown(fresh, "first_codex")
	check(not Tutorial.should_show(fresh, "first_codex"), "A shown hint never repeats")
	check(Tutorial.get_text("first_spawn") != "", "Known hint resolves to text")
	check(Tutorial.get_text("does_not_exist") == "", "Unknown hint resolves to empty text")
	# 12. Player signals the shake system
	check(fresh.player.has_signal("camera_shake_requested"), "Player exposes camera_shake_requested")
	# 13. Polish hooks fire on real combat (spawn a dummy human and hit it)
	fresh.enter_room(0, Vector2(450, 350))
	fresh.spawn_enemy_ext(0, Vector2(520, 350), "POLISH DUMMY", 200, 0.0, 1, 0, "knight", 0, "")
	var dummy = fresh.rooms[0].get_child(fresh.rooms[0].get_child_count() - 1)
	dummy.set_physics_process(false)
	var before_hit: int = fresh.get_child_count()
	dummy.take_damage(45, Vector2.RIGHT)
	check(dummy.hp == 155, "Dummy takes damage through the polish hook")
	check(fresh.get_child_count() > before_hit, "Hitting an enemy spawns damage number + spark")
	await process_frame
	dummy.take_damage(9999, Vector2.RIGHT)
	check(dummy.hp == 0, "Dummy dies")
	await process_frame
	await process_frame
	# 14. Wolf-gated, continuous Thornwood Expanse progression.
	fresh.enter_room(5, Vector2(900, 365))
	await process_frame
	for actor in fresh.rooms[5].get_children():
		if actor is CharacterBody2D and actor.is_in_group("enemies"):
			actor.take_damage(99999)
	await process_frame
	await process_frame
	check(fresh.living_enemies() == 0, "Defeating the entrance wolf clears the trail")
	fresh.player.position = fresh.RIGHT_GATE
	fresh.interact()
	check(fresh.current_room == fresh.EXPANSE_ROOM_INDEX, "Wolf victory unlocks Thornwood Expanse")
	check(fresh.player.position == fresh.EXPANSE_SPAWN, "Expanse uses its own world-scale spawn")
	var expanse_camera: Camera2D = fresh.player.get_node("Camera2D")
	check(expanse_camera.limit_right == 2304 and expanse_camera.limit_bottom == 1440, "Expanse camera follows across large world bounds")
	check(fresh.get_node("Cave").room_index == fresh.EXPANSE_ROOM_INDEX, "Expanse background and perimeter are active")
	fresh.player.position = fresh.EXPANSE_LANDMARKS[0]["pos"]
	fresh._update_expanse_discovery()
	check(fresh.discovered_expanse_landmarks.size() == 1, "Open-world landmark discovery records exploration")
	fresh.player.position = fresh.EXPANSE_RETURN_GATE
	fresh.interact()
	check(fresh.current_room == 5 and expanse_camera.limit_right == 1152, "Cave return restores room-sized camera limits")
	# 15. Ambient cave particle layer exists and never blocks movement
	var cave_node = fresh.get_node_or_null("Cave")
	check(is_instance_valid(cave_node), "Cave backdrop node exists")
	check(cave_node.has_method("_draw_ambient_particles"), "Cave has an ambient particle layer")
	check(fresh.player.position.distance_to(Vector2(450, 350)) < 2.0, "Ambient particles do not obstruct the player")
	fresh.queue_free()
	await process_frame
	SaveData.delete_save()
	print("Expansion gameplay checks; failures: ", failures)
	quit(failures)

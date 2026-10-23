extends Node2D
## Owns the run: Goblin Den progression hub (8 facilities), 4 Goblin classes & 9 evolutions,
## XP/leveling, story-driven human loot, recruited Goblin Party allies, and 5 Raid Campaigns.

const KNIGHT = preload("res://scenes/knight.tscn")
const SCRAP = preload("res://scripts/scrap.gd")
const PROP = preload("res://scripts/painted_prop.gd")
const GoblinData = preload("res://scripts/goblin_data.gd")
const GoblinAlly = preload("res://scripts/goblin_ally.gd")
const CameraFX = preload("res://scripts/camera_fx.gd")
const SaveData = preload("res://scripts/save_data.gd")
const Tutorial = preload("res://scripts/tutorial.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const LargeEnemy = preload("res://scripts/large_enemy.gd")

const DenLayout = preload("res://scripts/den_layout.gd")

const ROOM_NAMES = [
	"THE GOBLIN DEN",
	"ASHEN PASSAGE",
	"THE BREACH",
	"ROOTVEIN GROTTO",
	"THE CAVE MOUTH",
	"THORNWOOD HOLLOW",
	"THORNWOOD EXPANSE",
	"THE TREASURE ROOM",
	"THE ARMORY",
	"THE STRATEGY ROOM"
]
const CLASS_ORDER: Array[String] = ["blade", "archer", "knight", "mage"]
const FORGE := Vector2(350, 350)
const REST := Vector2(410, 350)
const TRAINING_PIT := Vector2(350, 350)
const ARCHERY_TRAP_SHOP := Vector2(760, 350)
const SHAMAN_HUT := Vector2(750, 350)
const RECRUITMENT_HUT := Vector2(800, 350)
const TREASURE_ROOM := Vector2(575, 350)
const WAR_ROOM := Vector2(575, 430)
const LEFT_GATE := Vector2(140, 365)
const RIGHT_GATE := Vector2(1010, 365)
const EXPANSE_RETURN_GATE := Vector2(310, 245)
const EXPANSE_SPAWN := Vector2(365, 285)
const EXPANSE_WORLD_SIZE := Vector2(2304, 1440)
const EXPANSE_ROOM_INDEX := 6
const EXPANSE_LANDMARKS := [
	{"id": "fallen_arch", "name": "Fallen-Root Arch", "pos": Vector2(410, 925)},
	{"id": "watch_shrine", "name": "Old Watch Shrine", "pos": Vector2(950, 795)},
	{"id": "hunter_camp", "name": "Abandoned Hunter Camp", "pos": Vector2(1535, 510)},
	{"id": "stream_ford", "name": "Whispering Stream Ford", "pos": Vector2(1715, 850)},
	{"id": "high_overlook", "name": "Thornwood High Overlook", "pos": Vector2(2035, 510)}
]
const EXPANSE_INTERACTIONS := [
	{"id": "root_herbs", "name": "E  FORAGE HERBS", "pos": Vector2(430, 970), "kind": "herbs"},
	{"id": "shrine_blessing", "name": "E  USE SHRINE", "pos": Vector2(960, 820), "kind": "shrine"},
	{"id": "camp_cache", "name": "E  SEARCH CAMP", "pos": Vector2(1535, 520), "kind": "cache"},
	{"id": "ford_cache", "name": "E  SEARCH FORD", "pos": Vector2(1715, 855), "kind": "ford"},
	{"id": "overlook_totem", "name": "E  TRAIL TOTEM", "pos": Vector2(2035, 520), "kind": "totem"}
]

@onready var player = $BladeGoblin

var rooms: Array[Node2D] = []
var current_room: int = 0
var scrap: int = 0
var blade_level: int = 1
var trap_level: int = 1
var shaman_level: int = 1
var potions: int = 1
var max_potions: int = 2
var captain_defeated: bool = false
var completed: bool = false
var campaign_index: int = 0
var unlocked_loot: Array[String] = []
var equipped_loot_index: int = -1
var recruited_ids: Array[String] = []
var party_nodes: Array[Node2D] = []
var summon_nodes: Array[Node2D] = []
var discovered_expanse_landmarks: Array[String] = []
var used_expanse_interactions: Array[String] = []
var thornwood_unlocked: bool = false

var health_label: Label
var health_bar: ProgressBar
var xp_bar: ProgressBar
var objective: Label
var room_label: Label
var status: Label
var sub_status: Label
var hint: Label
var result: Label
var codex_panel: Panel
var codex_label: Label
var screen_flash: ColorRect
var save_indicator: Label
var save_indicator_time: float = 0.0
var playtime: float = 0.0
var auto_save_timer: float = 0.0
var notice: String = ""
var notice_time: float = 0.0

func _ready() -> void:
	var feedback = preload("res://scripts/combat_feedback.gd").new()
	add_child(feedback)
	configure_input()
	create_hud()
	player.health_changed.connect(update_health)
	player.died.connect(on_player_died)
	if player.has_signal("special_used"):
		player.special_used.connect(_on_player_special_used)
	if player.has_signal("camera_shake_requested"):
		player.camera_shake_requested.connect(_on_camera_shake_requested)
	for index in range(ROOM_NAMES.size()):
		var room := Node2D.new()
		room.name = "Room%d" % index
		add_child(room)
		rooms.append(room)
	_spawn_den_facilities()
	# Polish: restore a previous run BEFORE the world is populated, so the
	# saved campaign tier is the one that actually gets spawned.
	var restored_save := false
	if SaveData.has_save():
		restored_save = SaveData.load_data(self)
	if restored_save:
		_spawn_large_enemies()
		_populate_campaign_enemies(campaign_index)
		_spawn_exterior_encounters()
		_restore_recruited_party()
	else:
		_spawn_large_enemies()
		_populate_campaign_enemies(0)
		_spawn_exterior_encounters()
	enter_room(0, Vector2(575, 400))
	update_health(player.hp, player.max_hp)
	if restored_save:
		show_notice("Save loaded — welcome back, Goblin Chief!")
		Tutorial.show_if_new(self, "save_loaded")
	else:
		show_notice("Explore the den passages [E], or head right to repel the humans.")
		Tutorial.show_if_new(self, "first_spawn")

## Re-spawns the recruited Goblin Party recorded in the save file.
func _restore_recruited_party() -> void:
	for rid in recruited_ids:
		var entry: Dictionary = {}
		for candidate in GoblinData.PARTY_ROSTER:
			if candidate["id"] == rid:
				entry = candidate
				break
		if entry.is_empty():
			continue
		var ally := GoblinAlly.new()
		ally.ally_id = entry["id"]
		ally.display_name = entry["name"]
		ally.role = entry["role"]
		ally.max_hp = int(entry["max_hp"])
		ally.hp = ally.max_hp
		ally.speed = float(entry["speed"])
		ally.damage = int(entry["damage"])
		ally.attack_range = float(entry["range"])
		ally.slot_index = party_nodes.size()
		ally.position = player.position + Vector2(-48, 24)
		add_child(ally)
		party_nodes.append(ally)
	_sync_party_for_active_class()

func _spawn_den_facilities() -> void:
	for st in DenLayout.STATIONS:
		var prop = PROP.new()
		prop.cell = st["cell"]
		prop.position = st["pos"]
		rooms[st["room"]].add_child(prop)

func is_den_room() -> bool:
	return DenLayout.is_safe(current_room)

func _try_den_portal() -> bool:
	for portal in DenLayout.PORTALS.get(current_room, []):
		if player.position.distance_to(portal["pos"]) < 75.0:
			enter_room(portal["to"], portal["spawn"])
			show_notice("Entered " + ROOM_NAMES[current_room] + ".")
			_auto_save()
			return true
	return false

func _spawn_large_enemies() -> void:
	var encounters := [
		{"room": 3, "kind": "spider", "pos": Vector2(760, 350), "radius": 34.0},
		{"room": 4, "kind": "ogre", "pos": Vector2(755, 370), "radius": 38.0},
		{"room": 5, "kind": "wolf_rider", "pos": Vector2(760, 350), "radius": 36.0}
	]
	for encounter in encounters:
		if encounter["room"] == 5 and thornwood_unlocked:
			continue
		var enemy = LargeEnemy.new()
		enemy.configure(encounter["kind"])
		enemy.position = encounter["pos"]
		enemy.collision_layer = 0
		enemy.collision_mask = 0
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = encounter["radius"]
		collision.shape = shape
		enemy.add_child(collision)
		var room_index: int = encounter["room"]
		rooms[room_index].add_child(enemy)
		enemy.defeated.connect(on_enemy_defeated.bind(enemy, room_index))

func _spawn_exterior_encounters() -> void:
	# The exterior keeps the existing 2D combat model. These patrols are spaced
	# across the continuous map so exploration, attacks, projectiles, specials,
	# companions, drops, and knockback all work without a separate combat port.
	spawn_enemy_ext(6, Vector2(1080, 790), "THORNWOOD SCOUT", 92, 118.0, 12, 5, "rogue", 48, "")
	spawn_enemy_ext(6, Vector2(1460, 690), "POACHER ARCHER", 78, 108.0, 11, 6, "archer", 52, "")
	spawn_enemy_ext(6, Vector2(1940, 470), "OVERLOOK SENTINEL", 125, 92.0, 16, 8, "knight", 70, "")

func configure_input() -> void:
	var bindings := {
		"move_up": KEY_W, "move_down": KEY_S,
		"move_left": KEY_A, "move_right": KEY_D, "attack": KEY_SPACE,
		"restart": KEY_R, "interact": KEY_E, "dodge": KEY_SHIFT,
		"special_skill": KEY_Q, "class_1": KEY_1, "class_2": KEY_2,
		"class_3": KEY_3, "class_4": KEY_4, "evolve_class": KEY_C,
		"cycle_loot": KEY_I, "use_potion": KEY_F, "toggle_codex": KEY_TAB
	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			var event := InputEventKey.new()
			event.physical_keycode = bindings[action]
			InputMap.action_add_event(action, event)
	var mouse_left := InputEventMouseButton.new()
	mouse_left.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("attack", mouse_left):
		InputMap.action_add_event("attack", mouse_left)
	var mouse_right := InputEventMouseButton.new()
	mouse_right.button_index = MOUSE_BUTTON_RIGHT
	if not InputMap.action_has_event("special_skill", mouse_right):
		InputMap.action_add_event("special_skill", mouse_right)

func _populate_campaign_enemies(camp_idx: int) -> void:
	campaign_index = clampi(camp_idx, 0, GoblinData.CAMPAIGNS.size() - 1)
	for r_idx in [1, 2]:
		for child in rooms[r_idx].get_children():
			rooms[r_idx].remove_child(child)
			child.queue_free()
	var camp: Dictionary = GoblinData.CAMPAIGNS[campaign_index]
	for edata in camp["room_1"]:
		spawn_enemy_ext(1, edata["pos"], edata["name"], edata["hp"], edata["speed"], edata["damage"], edata["scrap"], edata["role"], edata["xp"], edata["loot"])
	for edata in camp["room_2"]:
		spawn_enemy_ext(2, edata["pos"], edata["name"], edata["hp"], edata["speed"], edata["damage"], edata["scrap"], edata["role"], edata["xp"], edata["loot"])
	if is_instance_valid($Cave) and $Cave.has_method("update_chokepoints"):
		$Cave.update_chokepoints(bool(camp["chokepoints"]) and current_room > 0)

func spawn_enemy(room_index: int, point: Vector2, title: String, health: int, movement: float, damage: int, reward: int) -> void:
	spawn_enemy_ext(room_index, point, title, health, movement, damage, reward, "knight", 35, "")

func spawn_enemy_ext(room_index: int, point: Vector2, title: String, health: int, movement: float, damage: int, reward: int, role_name: String, xp_val: int, loot_id: String) -> void:
	var enemy = KNIGHT.instantiate()
	if title == "IRON CAPTAIN":
		enemy.set_script(preload("res://scripts/iron_captain.gd"))
	enemy.position = point
	enemy.max_hp = health
	enemy.hp = health
	enemy.speed = movement
	enemy.damage = damage
	enemy.display_name = title
	enemy.scrap_reward = reward
	enemy.role = role_name
	enemy.xp_reward = xp_val
	enemy.loot_drop_id = loot_id
	var active := room_index == current_room
	enemy.collision_layer = 2 if active else 0
	enemy.collision_mask = 3 if active else 0
	rooms[room_index].add_child(enemy)
	enemy.defeated.connect(on_enemy_defeated.bind(enemy, room_index))

func enter_room(index: int, spawn_point: Vector2) -> void:
	current_room = index
	for room_index in range(rooms.size()):
		var active := room_index == current_room
		rooms[room_index].visible = active
		rooms[room_index].process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		for actor in rooms[room_index].get_children():
			if actor.has_method("set_collision_active"):
				actor.set_collision_active(active)
			if actor is CharacterBody2D and actor.is_in_group("enemies"):
				actor.collision_layer = 2 if active and actor.hp > 0 else 0
				actor.collision_mask = 3 if active and actor.hp > 0 else 0
				actor.windup = 0.0
				actor.cooldown = 0.8
				actor.knockback = Vector2.ZERO
				if actor.has_method("reset_encounter_motion"):
					actor.reset_encounter_motion()
	player.position = spawn_point
	player.velocity = Vector2.ZERO
	player.dodge_time = 0.0
	player.invulnerability = 0.6
	for idx in range(party_nodes.size()):
		var ally := party_nodes[idx]
		if is_instance_valid(ally):
			ally.position = spawn_point + Vector2(-42 - (idx % 2) * 28, -32 + idx * 24)
			ally.velocity = Vector2.ZERO
	for idx in range(summon_nodes.size()):
		var sum_node := summon_nodes[idx]
		if is_instance_valid(sum_node):
			sum_node.position = spawn_point + Vector2(36, -28 + idx * 28)
			sum_node.velocity = Vector2.ZERO
	if $Cave.has_method("configure_room"):
		$Cave.configure_room(index)
	else:
		$Cave.room_index = index
	if $Cave.has_method("update_chokepoints"):
		var camp: Dictionary = GoblinData.CAMPAIGNS[campaign_index]
		$Cave.update_chokepoints((bool(camp["chokepoints"]) or index == 2) and index > 0)
	$Cave.queue_redraw()
	_configure_camera_for_room(index)
	var camp_tag := "  •  TIER %d" % (campaign_index + 1) if index > 0 and index <= 2 else ""
	room_label.text = ROOM_NAMES[index] + camp_tag
	refresh_objective()
	queue_redraw()

func _configure_camera_for_room(index: int) -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if not is_instance_valid(camera):
		return
	camera.enabled = true
	camera.position = Vector2.ZERO
	if index == EXPANSE_ROOM_INDEX:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = int(EXPANSE_WORLD_SIZE.x)
		camera.limit_bottom = int(EXPANSE_WORLD_SIZE.y)
	else:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = 1152
		camera.limit_bottom = 720
	camera.reset_smoothing()
	camera.force_update_scroll()

# Safety net: in the open Expanse the camera must follow across the whole
# 2304x1440 world. If anything left the room-sized limits (1152x720) in place,
# the camera is pinned to the first screen, so re-apply the world bounds and
# make sure the player's camera is the active one.
func _sync_expanse_camera() -> void:
	var camera: Camera2D = player.get_node_or_null("Camera2D")
	if not is_instance_valid(camera):
		return
	var want_right := int(EXPANSE_WORLD_SIZE.x)
	var want_bottom := int(EXPANSE_WORLD_SIZE.y)
	if camera.limit_right != want_right or camera.limit_bottom != want_bottom or camera.limit_left != 0 or camera.limit_top != 0:
		camera.limit_left = 0
		camera.limit_top = 0
		camera.limit_right = want_right
		camera.limit_bottom = want_bottom
	if not camera.enabled:
		camera.enabled = true
	if not camera.is_current():
		camera.make_current()

func _left_gate_position() -> Vector2:
	return EXPANSE_RETURN_GATE if current_room == EXPANSE_ROOM_INDEX else LEFT_GATE

func _right_gate_position() -> Vector2:
	return RIGHT_GATE

func living_enemies() -> int:
	var count := 0
	for actor in rooms[current_room].get_children():
		if actor is CharacterBody2D and actor.is_in_group("enemies") and actor.hp > 0:
			count += 1
	return count

func on_enemy_defeated(enemy: Node2D, room_index: int) -> void:
	var drop = SCRAP.new()
	drop.position = enemy.position
	drop.amount = enemy.scrap_reward
	drop.xp_amount = enemy.get("xp_reward") if enemy.get("xp_reward") != null else 35
	drop.loot_id = enemy.get("loot_drop_id") if enemy.get("loot_drop_id") != null else ""
	drop.collected.connect(collect_scrap)
	drop.loot_collected.connect(_on_loot_and_xp_collected)
	rooms[room_index].call_deferred("add_child", drop)
	# Necromancer raises fallen humans as skeletal allies!
	if player.evolution_id == "necromancer":
		call_deferred("_spawn_skeleton_minion", enemy.position)
	if room_index == 2 and _remaining_enemies_in_room(2, enemy) == 0:
		captain_defeated = true
		show_notice("The human commander falls! The sealed route beyond the Breach is now open.")
		# Polish: big boss-down moment
		_shake_camera(11.0, 0.4)
		CameraFX.flash_screen(screen_flash, Color(1.0, 0.85, 0.45, 0.3), 0.3)
		DeathEffect.burst_boss(self, enemy.global_position)
		_auto_save()
	elif room_index == 1 and _remaining_enemies_in_room(1, enemy) == 0:
		show_notice("Passage cleared. Collect the scrap & gear; your den awaits.")
		_shake_camera(5.0, 0.2)
	elif room_index == 3 and _remaining_enemies_in_room(3, enemy) == 0:
		show_notice("The Rootvein Giant Spider falls. The path to the cave mouth is clear.")
		_shake_camera(9.0, 0.3)
	elif room_index == 4 and _remaining_enemies_in_room(4, enemy) == 0:
		show_notice("The Cave-Mouth Ogre crashes down. Daylight lies ahead.")
		_shake_camera(11.0, 0.38)
	elif room_index == 5 and _remaining_enemies_in_room(5, enemy) == 0:
		thornwood_unlocked = true
		show_notice("The Thornwood Wolf Rider is defeated. The trail into the open expanse is clear.")
		_shake_camera(10.0, 0.34)
		_auto_save()
	refresh_objective()

func _remaining_enemies_in_room(room_idx: int, defeated_enemy: Node2D) -> int:
	var count := 0
	for actor in rooms[room_idx].get_children():
		if actor != defeated_enemy and actor is CharacterBody2D and actor.is_in_group("enemies") and actor.hp > 0:
			count += 1
	return count

func collect_scrap(amount: int) -> void:
	scrap += amount
	show_notice("Collected %d scrap. Return to the den to upgrade or recruit." % amount)
	# Polish: scrap pickup juice + tutorial
	FloatingText.spawn_loot(self, player.global_position + Vector2(0, -30), "+%d SCRAP" % amount)
	Tutorial.show_if_new(self, "first_scrap")

func _on_loot_and_xp_collected(loot_id: String, xp_amount: int) -> void:
	gain_xp(xp_amount)
	if loot_id != "" and GoblinData.LOOT_ITEMS.has(loot_id):
		var first_time := not unlocked_loot.has(loot_id)
		if first_time:
			unlocked_loot.append(loot_id)
		var item: Dictionary = GoblinData.LOOT_ITEMS[loot_id]
		show_notice("Stole %s! (%s) — Equip at Treasure Room or press [I]." % [item["name"], item["tradeoff"]])
		# Polish: loot pickup juice
		FloatingText.spawn_loot(self, player.global_position + Vector2(0, -40), str(item["name"]).to_upper())
		_shake_camera(4.0, 0.18)
		Tutorial.show_if_new(self, "first_loot")
		if first_time:
			_auto_save()

func gain_xp(amount: int) -> void:
	if amount <= 0:
		return
	player.xp += amount
	var leveled := false
	while player.xp >= player.xp_to_next:
		player.xp -= player.xp_to_next
		player.level += 1
		player.xp_to_next = int(round(player.xp_to_next * 1.35))
		leveled = true
	if leveled:
		player.apply_class_and_gear(player.class_id, player.evolution_id, true)
		player.heal(25)
		show_notice("LEVEL UP! Now Lv %d %s — Press [C] or visit Training Pit to evolve!" % [player.level, player.get_class_title()])
		# Polish: level-up juice + tutorial + autosave
		_shake_camera(7.0, 0.28)
		CameraFX.flash_screen(screen_flash, Color(1.0, 0.92, 0.6, 0.22), 0.2)
		FloatingText.spawn_status(self, player.global_position + Vector2(0, -46), "LEVEL UP!", Color("ffd966"))
		Tutorial.show_if_new(self, "first_level_up")
		_auto_save()

func select_goblin_class(new_class_id: String) -> void:
	if player.hp <= 0:
		return
	if not is_den_room():
		show_notice("Return to the Goblin Den to switch base class.")
		return
	if not GoblinData.CLASSES.has(new_class_id):
		return
	player.apply_class_and_gear(new_class_id, "", false)
	_sync_summons()
	_sync_party_for_active_class()
	var cdata: Dictionary = GoblinData.CLASSES[new_class_id]
	show_notice("Switched to %s (%s) — Special [Q]: %s" % [cdata["name"], cdata["role"], cdata["special_name"]])
	# Polish: class-switch juice + tutorial
	FloatingText.spawn_status(self, player.global_position + Vector2(0, -44), str(cdata["name"]).to_upper(), Color("a8d6c5"))
	_shake_camera(4.5, 0.2)
	Tutorial.show_if_new(self, "first_class_switch")
	_auto_save()

func cycle_base_class() -> void:
	var current_index := CLASS_ORDER.find(player.class_id)
	var next_class := CLASS_ORDER[(current_index + 1) % CLASS_ORDER.size()]
	select_goblin_class(next_class)

func cycle_class_evolution(at_station: bool = false) -> void:
	if player.hp <= 0:
		return
	var cdata: Dictionary = GoblinData.CLASSES[player.class_id]
	var evos: Array = cdata["evolutions"]
	if player.level < 2 and player.evolution_id == "":
		if at_station and scrap >= 4:
			scrap -= 4
			player.level = 2
		else:
			show_notice("Reach Level 2 (or spend 4 scrap at Training Pit) to unlock Class Evolutions!")
			return
	var next_idx := 0
	if player.evolution_id != "":
		var cur_idx := evos.find(player.evolution_id)
		next_idx = (cur_idx + 1) % evos.size()
	var new_evo: String = evos[next_idx]
	player.apply_class_and_gear(player.class_id, new_evo, true)
	_sync_summons()
	var edata: Dictionary = GoblinData.EVOLUTIONS[new_evo]
	show_notice("EVOLVED into %s! [Q] %s" % [edata["name"], edata.get("special_name", "EVOLVED SPECIAL")])
	# Polish: evolution juice + tutorial + autosave
	var aura: Color = edata.get("aura_color", Color("d4a0e8"))
	FloatingText.spawn_status(self, player.global_position + Vector2(0, -48), str(edata["name"]).to_upper(), aura)
	_shake_camera(9.0, 0.32)
	CameraFX.flash_screen(screen_flash, Color(aura.r, aura.g, aura.b, 0.26), 0.24)
	DeathEffect.burst_ally(self, player.global_position)
	Tutorial.show_if_new(self, "first_evolution")
	_auto_save()

func _sync_summons() -> void:
	for s in summon_nodes:
		if is_instance_valid(s):
			s.queue_free()
	summon_nodes.clear()
	if player.evolution_id == "beastmaster":
		var wolf := GoblinAlly.new()
		wolf.ally_id = "cave_wolf"
		wolf.display_name = "CAVE FANG WOLF"
		wolf.role = "wolf"
		wolf.max_hp = 95
		wolf.hp = 95
		wolf.speed = 245.0
		wolf.damage = 18
		wolf.attack_range = 64.0
		wolf.slot_index = 2
		wolf.position = player.position + Vector2(36, 24)
		add_child(wolf)
		summon_nodes.append(wolf)

func _spawn_skeleton_minion(pos: Vector2) -> void:
	var living := 0
	for summon in summon_nodes.duplicate():
		if not is_instance_valid(summon):
			summon_nodes.erase(summon)
		elif summon.hp <= 0:
			summon_nodes.erase(summon)
			get_tree().create_timer(0.75).timeout.connect(summon.queue_free)
		else:
			living += 1
	if living >= 2:
		return
	var skel := GoblinAlly.new()
	skel.ally_id = "risen_skeleton"
	skel.display_name = "RISEN SKELETON"
	skel.role = "skeleton"
	skel.max_hp = 65
	skel.hp = 65
	skel.speed = 205.0
	skel.damage = 15
	skel.attack_range = 64.0
	skel.slot_index = summon_nodes.size()
	skel.position = pos
	add_child(skel)
	summon_nodes.append(skel)

func _on_player_special_used(skill_name: String) -> void:
	if player.evolution_id == "necromancer" and not is_den_room():
		var side: Vector2 = player.facing.rotated(PI * 0.5) * 25.0
		_spawn_skeleton_minion(player.position + player.facing * 42.0 + side)
		_spawn_skeleton_minion(player.position + player.facing * 42.0 - side)
	show_notice("Unleashed %s!" % skill_name)
	var flash_colors := {
		"blade": Color(0.35, 0.92, 0.80, 0.22),
		"archer": Color(0.48, 1.0, 0.32, 0.20),
		"knight": Color(0.62, 0.84, 1.0, 0.24),
		"mage": Color(0.72, 0.38, 1.0, 0.26)
	}
	CameraFX.flash_screen(screen_flash, flash_colors.get(player.class_id, Color(1, 1, 1, 0.18)), 0.18)
	Tutorial.show_if_new(self, "first_special")

func upgrade_blade() -> void:
	var max_tier := 3 + campaign_index
	if blade_level >= max_tier:
		show_notice("Your blade is fully reforged.")
		return
	var cost := blade_level * 3
	if scrap < cost:
		show_notice("You need %d scrap for the next upgrade." % cost)
		return
	scrap -= cost
	blade_level += 1
	player.attack_damage = 25 + (blade_level - 1) * 10
	show_notice("Blade upgraded! Your slash now deals %d damage." % player.attack_damage)

func upgrade_archery_and_traps() -> void:
	if trap_level >= 4:
		show_notice("Archery Range & Traps are at peak lethality.")
		return
	var cost := trap_level * 3
	if scrap < cost:
		show_notice("Need %d scrap to upgrade traps & ranged precision." % cost)
		return
	scrap -= cost
	trap_level += 1
	player.trap_bonus_damage += 12
	player.ranged_bonus_damage += 6
	show_notice("Archery & Trap Workshop Lv %d! +12 Trap dmg & +6 Ranged dmg." % trap_level)

func use_shaman_hut() -> void:
	if potions < max_potions and scrap >= 2:
		scrap -= 2
		potions = max_potions
		player.magic_bonus_damage += 4
		shaman_level += 1
		show_notice("Shaman Hut: Refilled Bloodmoss Potions (%d/%d) & +4 Hex Power!" % [potions, max_potions])
	elif scrap >= 3 and shaman_level < 4:
		scrap -= 3
		shaman_level += 1
		max_potions += 1
		potions = max_potions
		player.magic_bonus_damage += 6
		show_notice("Shaman Ritual Lv %d! Max potions %d & +6 Magic damage." % [shaman_level, max_potions])
	else:
		show_notice("Need 2-3 scrap for Shaman potions and hex rituals.")

func recruit_goblin_follower() -> void:
	var next_entry := _next_recruit_entry()
	if next_entry.is_empty():
		for ally in party_nodes:
			if is_instance_valid(ally):
				ally.revive_and_heal()
		show_notice("Every other core class is in your squad. All companions healed.")
		return
	var cost: int = int(next_entry["cost"])
	if scrap < cost:
		show_notice("Need %d scrap to recruit %s (%s)." % [cost, next_entry["name"], next_entry["summary"]])
		return
	scrap -= cost
	recruited_ids.append(next_entry["id"])
	var ally := GoblinAlly.new()
	ally.ally_id = next_entry["id"]
	ally.display_name = next_entry["name"]
	ally.role = next_entry["role"]
	ally.max_hp = int(next_entry["max_hp"])
	ally.hp = ally.max_hp
	ally.speed = float(next_entry["speed"])
	ally.damage = int(next_entry["damage"])
	ally.attack_range = float(next_entry["range"])
	ally.slot_index = party_nodes.size()
	ally.position = player.position + Vector2(-48, 24)
	add_child(ally)
	party_nodes.append(ally)
	_sync_party_for_active_class()
	show_notice("Recruited %s into your Goblin Party! (%s)" % [next_entry["name"], next_entry["summary"]])
	# Polish: recruit juice + tutorial + autosave
	FloatingText.spawn_status(self, ally.global_position + Vector2(0, -40), str(next_entry["name"]).to_upper(), Color("8ce8b5"))
	_shake_camera(5.0, 0.2)
	Tutorial.show_if_new(self, "first_party")
	_auto_save()

func _next_recruit_entry() -> Dictionary:
	for entry in GoblinData.PARTY_ROSTER:
		if entry["role"] == player.class_id:
			continue
		if not recruited_ids.has(entry["id"]):
			return entry
	return {}

func _sync_party_for_active_class() -> void:
	# A recruited version of the class currently controlled by the player waits
	# at the den. Switching classes automatically brings the previous specialist back.
	for ally in party_nodes:
		if not is_instance_valid(ally):
			continue
		var active: bool = str(ally.role) != str(player.class_id)
		ally.visible = active
		ally.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED

func active_companion_count() -> int:
	var count := 0
	for ally in party_nodes:
		if is_instance_valid(ally) and ally.visible and ally.hp > 0:
			count += 1
	return count

func cycle_equipped_loot() -> void:
	if unlocked_loot.is_empty():
		show_notice("No stolen human weapons yet. Defeat human leaders to claim their gear!")
		return
	equipped_loot_index = (equipped_loot_index + 1) % unlocked_loot.size()
	var item_id: String = unlocked_loot[equipped_loot_index]
	player.equipped_loot_id = item_id
	player.apply_class_and_gear(player.class_id, player.evolution_id, true)
	var item: Dictionary = GoblinData.LOOT_ITEMS[item_id]
	show_notice("Equipped %s (+%d Dmg | %s) %s" % [item["name"], item["damage"], item["tradeoff"], item["lore"]])

func advance_war_room_campaign() -> void:
	var next_camp := (campaign_index + 1) % GoblinData.CAMPAIGNS.size()
	captain_defeated = false
	_populate_campaign_enemies(next_camp)
	var camp: Dictionary = GoblinData.CAMPAIGNS[campaign_index]
	refresh_objective()
	show_notice("WAR ROOM: Launched %s! Head right [E] to raid." % camp["title"])
	# Polish: campaign launch juice + autosave
	_shake_camera(6.0, 0.24)
	CameraFX.flash_screen(screen_flash, Color(0.85, 0.45, 0.25, 0.18), 0.2)
	_auto_save()

func use_potion() -> void:
	if player.hp <= 0:
		return
	if potions <= 0:
		show_notice("Out of Bloodmoss Potions! Rest at the fire or visit the Shaman Hut.")
		return
	potions -= 1
	player.heal(35)
	player.venom_coating_timer = 8.0
	show_notice("Drank Bloodmoss & Venom Vial! +35 HP and Poison Weapons for 8s.")
	# Polish: potion juice + tutorial
	FloatingText.spawn_heal(self, player.global_position + Vector2(0, -34), 35)
	FloatingText.spawn_status(self, player.global_position + Vector2(0, -54), "VENOM COATED", Color("5ce66a"))
	Tutorial.show_if_new(self, "first_potion")

func interact() -> void:
	if player.hp <= 0:
		return
	if current_room == EXPANSE_ROOM_INDEX and _try_expanse_interaction():
		return
	if is_den_room():
		if current_room == DenLayout.station_room(0) and player.position.distance_to(FORGE) < 85:
			Tutorial.show_if_new(self, "near_forge")
			upgrade_blade()
			_auto_save()
			return
		if current_room == DenLayout.station_room(1) and player.position.distance_to(REST) < 85:
			Tutorial.show_if_new(self, "near_rest")
			player.hp = player.max_hp
			potions = max_potions
			for ally in party_nodes:
				if is_instance_valid(ally):
					ally.revive_and_heal()
			update_health(player.hp, player.max_hp)
			show_notice("Rested by the den fire. HP, party, and potions restored.")
			_auto_save()
			return
		if current_room == DenLayout.station_room(2) and player.position.distance_to(TRAINING_PIT) < 80:
			Tutorial.show_if_new(self, "near_training")
			cycle_base_class()
			return
		if current_room == DenLayout.station_room(3) and player.position.distance_to(ARCHERY_TRAP_SHOP) < 80:
			Tutorial.show_if_new(self, "near_archery")
			upgrade_archery_and_traps()
			_auto_save()
			return
		if current_room == DenLayout.station_room(4) and player.position.distance_to(SHAMAN_HUT) < 80:
			Tutorial.show_if_new(self, "near_shaman")
			use_shaman_hut()
			_auto_save()
			return
		if current_room == DenLayout.station_room(5) and player.position.distance_to(RECRUITMENT_HUT) < 80:
			Tutorial.show_if_new(self, "near_recruit")
			recruit_goblin_follower()
			return
		if current_room == DenLayout.station_room(6) and player.position.distance_to(TREASURE_ROOM) < 80:
			Tutorial.show_if_new(self, "near_treasure")
			cycle_equipped_loot()
			return
		if current_room == DenLayout.station_room(7) and player.position.distance_to(WAR_ROOM) < 85:
			Tutorial.show_if_new(self, "near_war_room")
			advance_war_room_campaign()
			return
	if _try_den_portal():
		return
	if current_room > 0 and current_room <= EXPANSE_ROOM_INDEX and player.position.distance_to(_left_gate_position()) < 75:
		enter_room(current_room - 1, Vector2(935, 365))
		if current_room == 0 and captain_defeated:
			completed = true
			show_notice("DEN SAVED! Visit the WAR ROOM to launch higher-tier raids or press R.")
			_auto_save()
		return
	if current_room < EXPANSE_ROOM_INDEX and player.position.distance_to(_right_gate_position()) < 75:
		if living_enemies() > 0:
			show_notice("Defeat the guardian here to open the way forward." if current_room >= 3 else "Defeat the humans here to open the way forward.")
		else:
			var next_room := current_room + 1
			var next_spawn := EXPANSE_SPAWN if next_room == EXPANSE_ROOM_INDEX else Vector2(215, 365)
			enter_room(next_room, next_spawn)
			if current_room > 0:
				Tutorial.show_if_new(self, "first_combat_room")
			if current_room == 3:
				show_notice("ROOTVEIN GROTTO — old roots and glowcaps mark a forgotten way out.")
			elif current_room == 4:
				show_notice("THE CAVE MOUTH — daylight spills across the goblin wards.")
			elif current_room == 5:
				show_notice("THORNWOOD HOLLOW — the hidden world beyond the den.")
			elif current_room == EXPANSE_ROOM_INDEX:
				show_notice("THORNWOOD EXPANSE — roam freely; the camera follows across the open wilds.")
				_auto_save()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		# A fresh run means a genuinely lone Goblin again; normal progress is
		# already protected by autosaves in the den and after major actions.
		SaveData.delete_save()
		get_tree().reload_current_scene()
	elif event.is_action_pressed("interact"):
		interact()
	elif event.is_action_pressed("class_1"):
		select_goblin_class("blade")
	elif event.is_action_pressed("class_2"):
		select_goblin_class("archer")
	elif event.is_action_pressed("class_3"):
		select_goblin_class("knight")
	elif event.is_action_pressed("class_4"):
		select_goblin_class("mage")
	elif event.is_action_pressed("evolve_class"):
		cycle_class_evolution(false)
	elif event.is_action_pressed("cycle_loot"):
		cycle_equipped_loot()
	elif event.is_action_pressed("use_potion"):
		use_potion()
	elif event.is_action_pressed("toggle_codex"):
		codex_panel.visible = not codex_panel.visible
		if codex_panel.visible:
			Tutorial.show_if_new(self, "first_codex")

func _process(delta: float) -> void:
	notice_time = maxf(0.0, notice_time - delta)
	# Polish: playtime tracking, auto-save, flash + save-indicator updates
	playtime += delta
	CameraFX.update_flash(screen_flash, delta)
	if save_indicator_time > 0.0:
		save_indicator_time = maxf(0.0, save_indicator_time - delta)
		save_indicator.modulate.a = clampf(save_indicator_time / 0.9, 0.0, 1.0)
	if is_den_room() and player.hp > 0:
		auto_save_timer += delta
		if auto_save_timer >= 30.0:
			auto_save_timer = 0.0
			_auto_save()
	if current_room == EXPANSE_ROOM_INDEX:
		_sync_expanse_camera()
	if current_room == EXPANSE_ROOM_INDEX and player.hp > 0:
		_update_expanse_discovery()
	# Polish: keep XP bar in sync
	xp_bar.max_value = maxi(1, player.xp_to_next)
	xp_bar.value = player.xp
	if player.dodge_time > 0.0:
		Tutorial.show_if_new(self, "first_dodge")
	var dodge_text := "READY" if player.dodge_cooldown <= 0.0 else "%.1fs" % player.dodge_cooldown
	var spec_text := "READY" if player.special_cooldown <= 0.0 else "%.1fs" % player.special_cooldown
	status.text = "SCRAP %d   /   BLADE %d   /   DODGE %s" % [scrap, blade_level, dodge_text]
	var gear_name := "NONE"
	if player.equipped_loot_id != "" and GoblinData.LOOT_ITEMS.has(player.equipped_loot_id):
		gear_name = GoblinData.LOOT_ITEMS[player.equipped_loot_id]["name"]
	sub_status.text = "LV %d (%d/%d XP)  •  [Q] %s  •  [F] POTION %d  •  SQUAD %d/4  •  GEAR: %s" % [
		player.level, player.xp, player.xp_to_next, spec_text, potions, 1 + active_companion_count(), gear_name
	]
	if codex_panel.visible:
		_refresh_codex_text()
	hint.text = contextual_hint()
	if notice_time > 0.0:
		hint.text = notice

func contextual_hint() -> String:
	if player.hp <= 0:
		return "Press R to begin a fresh run."
	if is_den_room():
		if current_room == DenLayout.station_room(0) and player.position.distance_to(FORGE) < 85:
			var max_tier := 3 + campaign_index
			return "E  Reforge blade — %d scrap (+10 damage)" % (blade_level * 3) if blade_level < max_tier else "Blade fully upgraded"
		if current_room == DenLayout.station_room(1) and player.position.distance_to(REST) < 85:
			return "E  Rest at the fire — restore all HP, party & potions"
		if current_room == DenLayout.station_room(2) and player.position.distance_to(TRAINING_PIT) < 80:
			var next_class := CLASS_ORDER[(CLASS_ORDER.find(player.class_id) + 1) % CLASS_ORDER.size()]
			return "E  Try next class: %s  •  [1-4] pick directly  •  [C] evolve" % GoblinData.CLASSES[next_class]["name"]
		if current_room == DenLayout.station_room(3) and player.position.distance_to(ARCHERY_TRAP_SHOP) < 80:
			return "E  Archery & Trap Workshop — %d scrap (+12 trap & +6 ranged dmg)" % (trap_level * 3)
		if current_room == DenLayout.station_room(4) and player.position.distance_to(SHAMAN_HUT) < 80:
			return "E  Shaman Hut — Brew Bloodmoss Potions & Hex upgrades (2-3 scrap)"
		if current_room == DenLayout.station_room(5) and player.position.distance_to(RECRUITMENT_HUT) < 80:
			var next_ally := _next_recruit_entry()
			if not next_ally.is_empty():
				return "E  Recruit %s — %d scrap (%s)" % [next_ally["name"], next_ally["cost"], next_ally["summary"]]
			return "E  Recruitment Hut — Heal your full four-class squad"
		if current_room == DenLayout.station_room(6) and player.position.distance_to(TREASURE_ROOM) < 80:
			return "E  Treasure Room — Equip stolen human weapons (%d unlocked)" % unlocked_loot.size()
		if current_room == DenLayout.station_room(7) and player.position.distance_to(WAR_ROOM) < 85:
			var next_c: Dictionary = GoblinData.CAMPAIGNS[(campaign_index + 1) % GoblinData.CAMPAIGNS.size()]
			return "E  War Room — Launch next raid: %s" % next_c["title"]
	if current_room == EXPANSE_ROOM_INDEX:
		for interaction in EXPANSE_INTERACTIONS:
			if not used_expanse_interactions.has(interaction["id"]) and player.position.distance_to(interaction["pos"]) < 92.0:
				return interaction["name"]
	for portal in DenLayout.PORTALS.get(current_room, []):
		if player.position.distance_to(portal["pos"]) < 75.0:
			return "E  Enter " + portal["title"]
	if is_den_room() and current_room != 0:
		return "Explore the room's stations, or use [E] at a passage to continue through the den."
	if current_room > 0 and current_room <= EXPANSE_ROOM_INDEX and player.position.distance_to(_left_gate_position()) < 75:
		return "E  Return to " + ROOM_NAMES[current_room - 1]
	if current_room < EXPANSE_ROOM_INDEX and player.position.distance_to(_right_gate_position()) < 75:
		if living_enemies() > 0:
			return "Defeat the guardian to proceed" if current_room >= 3 else "Defeat the humans to proceed"
		return "E  Enter " + ROOM_NAMES[current_room + 1]
	if current_room == EXPANSE_ROOM_INDEX:
		return "Explore freely — %d/%d landmarks discovered. The cave entrance remains your route home." % [discovered_expanse_landmarks.size(), EXPANSE_LANDMARKS.size()]
	if current_room == 5:
		return "The den lies safely hidden beneath Thornwood Hollow. Explore, or return through the cave mouth."
	return "Return home to rest and reforge, or visit War Room for new raids." if completed else "Keys [1-4] Class  •  [Q/RClick] Special  •  [C] Evolve  •  [I] Gear  •  [TAB] Codex"

func show_notice(words: String) -> void:
	notice = words
	notice_time = 4.0

func _update_expanse_discovery() -> void:
	for landmark in EXPANSE_LANDMARKS:
		var landmark_id: String = landmark["id"]
		if discovered_expanse_landmarks.has(landmark_id):
			continue
		if player.position.distance_to(landmark["pos"]) <= 105.0:
			discovered_expanse_landmarks.append(landmark_id)
			show_notice("LANDMARK DISCOVERED — %s (%d/%d)" % [landmark["name"], discovered_expanse_landmarks.size(), EXPANSE_LANDMARKS.size()])
			refresh_objective()
			_auto_save()
			break

func _try_expanse_interaction() -> bool:
	for interaction in EXPANSE_INTERACTIONS:
		var interaction_id: String = interaction["id"]
		if used_expanse_interactions.has(interaction_id) or player.position.distance_to(interaction["pos"]) >= 92.0:
			continue
		used_expanse_interactions.append(interaction_id)
		match String(interaction["kind"]):
			"herbs":
				potions = mini(max_potions, potions + 1)
				show_notice("You gather bloodmoss and refill one potion.")
			"shrine":
				player.heal(30)
				show_notice("The old goblin shrine restores 30 HP.")
			"cache":
				scrap += 8
				show_notice("The abandoned camp yields 8 scrap.")
			"ford":
				scrap += 5
				show_notice("You recover 5 river-polished scrap from the ford.")
			"totem":
				gain_xp(45)
				show_notice("The old trail marks teach you the forest paths. +45 XP.")
		_auto_save()
		queue_redraw()
		return true
	return false

func refresh_objective() -> void:
	if is_den_room():
		objective.text = {0: "Rest, heal and explore your den", 7: "Inspect and equip stolen treasures", 8: "Reforge weapons and upgrade traps", 9: "Train, recruit and plan your next raid"}[current_room]
		return

	if current_room >= 3 and current_room <= 5 and living_enemies() > 0:
		var hunt_names := ["", "", "", "Rootvein Giant Spider", "Cave-Mouth Ogre", "Thornwood Wolf Rider"]
		objective.text = "Defeat the " + hunt_names[current_room]
		return
	objective.text = "Return to your den" if captain_defeated else "Drive out the human incursion"
	if captain_defeated and current_room < 4:
		objective.text = "Explore the forgotten route to the cave mouth"
	elif current_room == 4:
		objective.text = "Step beyond the cave mouth"
	elif current_room == 5:
		objective.text = "Defeat the Wolf Rider and open the forest trail" if living_enemies() > 0 else "Enter the open Thornwood Expanse"
	elif current_room == EXPANSE_ROOM_INDEX:
		objective.text = "Explore the open expanse — %d/%d landmarks" % [discovered_expanse_landmarks.size(), EXPANSE_LANDMARKS.size()]

func add_label(parent: Node, words: String, point: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = words
	label.position = point
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.015, 0.01, 0.9))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label

func create_hud() -> void:
	var hud := CanvasLayer.new()
	add_child(hud)
	var panel := Panel.new()
	panel.position = Vector2(24, 12)
	panel.size = Vector2(1104, 88)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.06, 0.05, 0.04, 0.94)
	frame.border_color = Color("756044")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", frame)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(panel)
	var footer := Panel.new()
	footer.position = Vector2(24, 637)
	footer.size = Vector2(1104, 77)
	footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	footer.add_theme_stylebox_override("panel", frame)
	hud.add_child(footer)
	room_label = add_label(hud, "", Vector2(42, 18), 20, Color("ded6bb"))
	health_label = add_label(hud, "", Vector2(42, 48), 15, Color("a5bb8e"))
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(315, 52)
	health_bar.size = Vector2(150, 12)
	health_bar.show_percentage = false
	var bar_back := StyleBoxFlat.new()
	bar_back.bg_color = Color("30251e")
	bar_back.set_corner_radius_all(2)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("a64e3d")
	bar_fill.set_corner_radius_all(2)
	health_bar.add_theme_stylebox_override("background", bar_back)
	health_bar.add_theme_stylebox_override("fill", bar_fill)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(health_bar)
	# Polish: slim XP progress bar directly beneath the health bar
	xp_bar = ProgressBar.new()
	xp_bar.position = Vector2(315, 67)
	xp_bar.size = Vector2(150, 5)
	xp_bar.show_percentage = false
	xp_bar.max_value = 100
	xp_bar.value = 0
	var xp_back := StyleBoxFlat.new()
	xp_back.bg_color = Color("241d2e")
	xp_back.set_corner_radius_all(2)
	var xp_fill := StyleBoxFlat.new()
	xp_fill.bg_color = Color("6f8fd6")
	xp_fill.set_corner_radius_all(2)
	xp_bar.add_theme_stylebox_override("background", xp_back)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	xp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(xp_bar)
	add_label(hud, "XP", Vector2(288, 58), 11, Color("8fa6d8"))
	objective = add_label(hud, "", Vector2(540, 18), 17, Color("c1b69f"))
	status = add_label(hud, "", Vector2(540, 46), 15, Color("c5d3ba"))
	sub_status = add_label(hud, "", Vector2(42, 73), 13, Color("d4c49e"))
	add_label(hud, "WASD Move  /  Mouse Aim + Click / SPACE Attack  /  Q Special  /  SHIFT Dodge  /  1-4 Class  /  C Evolve  /  F Potion  /  I Gear  /  E Use  /  TAB Codex", Vector2(52, 650), 14, Color("c7c4b1"))
	hint = add_label(hud, "", Vector2(60, 682), 16, Color("c9bb94"))
	hint.size.x = 1032
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result = add_label(hud, "", Vector2(310, 285), 30, Color("e6d4a3"))
	result.size = Vector2(532, 120)
	result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_theme_color_override("font_shadow_color", Color.BLACK)
	result.add_theme_constant_override("shadow_offset_x", 2)
	result.add_theme_constant_override("shadow_offset_y", 2)
	# Tactical Warlord Codex overlay (toggle with TAB)
	codex_panel = Panel.new()
	codex_panel.position = Vector2(156, 120)
	codex_panel.size = Vector2(840, 480)
	codex_panel.visible = false
	codex_panel.add_theme_stylebox_override("panel", frame)
	codex_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(codex_panel)
	codex_label = add_label(codex_panel, "", Vector2(28, 22), 15, Color("e6dec8"))
	# Polish: full-screen flash overlay (driven by CameraFX.flash_screen)
	screen_flash = ColorRect.new()
	screen_flash.color = Color(1, 1, 1, 0)
	screen_flash.visible = false
	screen_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	screen_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.add_child(screen_flash)
	# Polish: brief "SAVED" indicator
	save_indicator = add_label(hud, "", Vector2(1042, 104), 13, Color("9fd6a5"))
	save_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	save_indicator.modulate.a = 0.0

func _refresh_codex_text() -> void:
	var cdata: Dictionary = GoblinData.CLASSES[player.class_id]
	var evo_text := "None (Reach Lv 2 & press C or use Training Pit)"
	if player.evolution_id != "" and GoblinData.EVOLUTIONS.has(player.evolution_id):
		var ed: Dictionary = GoblinData.EVOLUTIONS[player.evolution_id]
		evo_text = "%s — %s" % [ed["name"], ed["summary"]]
	var loot_text := "None equipped (Defeat human leaders & press I or visit Treasure Room)"
	if player.equipped_loot_id != "" and GoblinData.LOOT_ITEMS.has(player.equipped_loot_id):
		var ld: Dictionary = GoblinData.LOOT_ITEMS[player.equipped_loot_id]
		loot_text = "%s (+%d Dmg | %s)\n    Lore: %s" % [ld["name"], ld["damage"], ld["tradeoff"], ld["lore"]]
	var camp: Dictionary = GoblinData.CAMPAIGNS[campaign_index]
	codex_label.text = (
		"GOBLIN PERSPECTIVE RPG — TRIBE & WARLORD CODEX (Press TAB to close)\n\n" +
		"• Class & Combat Identity: %s (%s) — %s\n" % [cdata["name"], cdata["role"], cdata["summary"]] +
		"• Active Evolution: %s\n" % evo_text +
		"• Stats: Level %d (%d/%d XP)  |  Effective Attack: %d  |  Armor: %d%%  |  Crit: %d%%\n" % [
			player.level, player.xp, player.xp_to_next, player.get_effective_damage(),
			int(round(player.armor_rating * 100.0)), int(round(player.crit_chance * 100.0))
		] +
		"• Stolen Human Relic: %s\n\n" % loot_text +
		"• Goblin Den Facilities:\n" +
		"    Forge Lv %d  |  Archery & Traps Lv %d  |  Shaman Hut Lv %d  |  Potions %d/%d\n" % [blade_level, trap_level, shaman_level, potions, max_potions] +
		"• Four-Class Squad (%d active including you): %s\n    Switch with [1-4]; a companion matching your active class waits at the den.\n\n" % [1 + active_companion_count(), ", ".join(recruited_ids) if not recruited_ids.is_empty() else "No companions yet (Visit Recruitment Hut)"] +
		"• Active War Room Campaign: %s\n    %s" % [camp["title"], camp["subtitle"]]
	)

# ---- Polish & UX helpers ----

func _shake_camera(intensity: float, duration: float) -> void:
	var cam := player.get_node_or_null("Camera2D")
	if is_instance_valid(cam):
		CameraFX.shake(cam, intensity, duration)
	# Big impacts also get a screen flash
	if intensity >= 6.0:
		CameraFX.flash_screen(screen_flash, Color(1, 1, 1, 0.16), 0.1)

func _on_camera_shake_requested(intensity: float, duration: float) -> void:
	_shake_camera(intensity, duration)

func _show_save_indicator() -> void:
	save_indicator.text = "SAVED"
	save_indicator_time = 0.9
	save_indicator.modulate.a = 1.0

func _auto_save() -> void:
	if player.hp <= 0:
		return
	SaveData.save(self)
	_show_save_indicator()

func get_stats() -> Dictionary:
	return {
		"total_playtime": playtime,
		"campaign_index": campaign_index,
		"captain_defeated": captain_defeated,
		"completed": completed,
		"blade_level": blade_level,
		"trap_level": trap_level,
		"shaman_level": shaman_level,
		"party_size": recruited_ids.size(),
		"loot_count": unlocked_loot.size(),
		"player_level": player.level,
		"player_class": player.class_id,
		"player_evolution": player.evolution_id,
	}

func update_health(current: int, maximum: int) -> void:
	health_label.text = "%s   •   HP %d / %d" % [player.get_class_title(), current, maximum]
	health_bar.max_value = maximum
	health_bar.value = current

func on_player_died() -> void:
	objective.text = "THE DEN HAS FALLEN"
	result.text = "YOU HAVE FALLEN\nPress R for a fresh run"
	# Polish: heavy death shake + red flash
	_shake_camera(12.0, 0.45)
	CameraFX.flash_screen(screen_flash, Color(0.75, 0.1, 0.08, 0.35), 0.35)

func marker(point: Vector2, title: String, color: Color) -> void:
	draw_arc(point, 32, 0, TAU, 32, Color(color, 0.45), 1, true)
	draw_rect(Rect2(point + Vector2(-54, 42), Vector2(112, 22)), Color(0.04, 0.03, 0.02, 0.78))
	draw_string(ThemeDB.fallback_font, point + Vector2(-49, 57), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color)

func _draw() -> void:
	# Parent draws behind actors. All stations use distance-based interaction.
	if is_den_room():
		for station in DenLayout.STATIONS:
			if station["room"] == current_room:
				marker(station["pos"], station["title"], Color("dfc28e"))
		for portal in DenLayout.PORTALS.get(current_room, []):
			_den_door(portal["pos"], portal["title"])

	if current_room > 0 and current_room <= EXPANSE_ROOM_INDEX:
		var left_title := "E  HOME" if current_room == 1 else "E  BACK"
		var left_gate := _left_gate_position()
		left_title = "E  CAVE ENTRANCE" if current_room == EXPANSE_ROOM_INDEX else left_title
		marker(left_gate, left_title, Color("8fb9a5"))
		draw_line(left_gate + Vector2(12, 0), left_gate - Vector2(12, 0), Color("8fb9a5"), 4)
		draw_line(left_gate - Vector2(12, 0), left_gate + Vector2(-3, -9), Color("8fb9a5"), 3)
		draw_line(left_gate - Vector2(12, 0), left_gate + Vector2(-3, 9), Color("8fb9a5"), 3)
	if current_room < EXPANSE_ROOM_INDEX:
		var right_title := "E  RAID" if current_room == 0 else ("E  OUTSIDE" if current_room == 4 else ("E  EXPLORE" if current_room == 5 else "E  DEEPER"))
		marker(RIGHT_GATE, right_title, Color("d0b892"))
		draw_line(RIGHT_GATE - Vector2(12, 0), RIGHT_GATE + Vector2(12, 0), Color("d0b892"), 4)
		draw_line(RIGHT_GATE + Vector2(12, 0), RIGHT_GATE + Vector2(3, -9), Color("d0b892"), 3)
		draw_line(RIGHT_GATE + Vector2(12, 0), RIGHT_GATE + Vector2(3, 9), Color("d0b892"), 3)
	if current_room == EXPANSE_ROOM_INDEX:
		for interaction in EXPANSE_INTERACTIONS:
			if not used_expanse_interactions.has(interaction["id"]):
				marker(interaction["pos"], interaction["name"], Color("a9ca83"))

func _den_door(point: Vector2, title: String) -> void:
	draw_arc(point, 31.0, 0, TAU, 32, Color(0.67, 0.85, 0.72, 0.55), 2.0, true)
	var label := "E  " + title
	var width := maxf(126.0, ThemeDB.fallback_font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x + 24.0)
	draw_rect(Rect2(point + Vector2(-width * 0.5, 36), Vector2(width, 25)), Color(0.03, 0.035, 0.025, 0.87))
	draw_string(ThemeDB.fallback_font, point + Vector2(-width * 0.5 + 12, 53), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("b8dbba"))
	draw_circle(point, 4.0, Color("b8dbba"))
	var direction := Vector2.UP if point.y < 200 else (Vector2.DOWN if point.y > 500 else (Vector2.LEFT if point.x < 200 else Vector2.RIGHT))
	draw_line(point - direction * 12, point + direction * 12, Color("b8dbba"), 3.0, true)
	draw_line(point + direction * 12, point + direction * 4 + direction.orthogonal() * 7, Color("b8dbba"), 2.0, true)
	draw_line(point + direction * 12, point + direction * 4 - direction.orthogonal() * 7, Color("b8dbba"), 2.0, true)

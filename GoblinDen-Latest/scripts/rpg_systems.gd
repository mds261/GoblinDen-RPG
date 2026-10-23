extends Node2D
const Starting = preload("res://scripts/starting_caves.gd")
const Catalog = preload("res://scripts/design_catalog.gd")
## October 22 plan: an offline vertical slice integrated with the painted game.
const ItemContainer = preload("res://scripts/item_container.gd")
const ExplorationMap = preload("res://scripts/exploration_map.gd")
const DungeonSystem = preload("res://scripts/dungeon_system.gd")
const NpcData = preload("res://scripts/npc_data.gd")
const FriendlyNpc = preload("res://scripts/friendly_npc.gd")
const ItemIcons = preload("res://scripts/item_icons.gd")
const Data = preload("res://scripts/goblin_data.gd")
const SLOTS := ["necklace", "helmet", "weapon", "shield", "armor", "legs", "boots", "ring"]
static var SKILLS: Array = Catalog.table("skills").keys()

static var ACTIONS: Dictionary = Catalog.actions()

# Keep the drawn marker and interaction on the open trail east of the bridge.
const BOG_TRAIL_POINT := Vector2(1850, 850)
const HUB := 10
const SWAMP := 11
const DEEP_CAVE := 12
var exploration_map: Node2D
var dungeon: Node2D
var game: Node2D
var items: Dictionary = {}
var backpack: RefCounted
var chest: RefCounted
var depot: RefCounted
var equipped: Dictionary = {}
var proficiencies: Dictionary = {}
var attributes: Dictionary = Catalog.attribute_defaults()
var points := 0
var learned: Array = ["heal"]
var bindings: Array = ["heal", "", "", "", "", "", "", "", "", "", "", "potion"]
var keycodes: Array = [KEY_F1, KEY_F2, KEY_F3, KEY_F4, KEY_F5, KEY_F6, KEY_F7, KEY_F8, KEY_F9, KEY_F10, KEY_F11, KEY_F12]
var cooldowns: Dictionary = {}
var corpses: Array = []
var discovered: Array = []
var quest_claimed := false
var kills := 0
var mana := 60.0
var stamina := 100.0
var world_hour := 8.0
var weather := "Clear"
var weather_timer := 0.0
var encounter_timer := 0.0
var logs: Array = []
var filter_channel := "General"
var auto_target := true
var target: Node2D
var panel: PanelContainer
var body: VBoxContainer
var chat_panel: PanelContainer
var chat_output: RichTextLabel
var chat_entry: LineEdit
var resource_label: Label
var pack_page := "Inventory"
var hotbar: HBoxContainer
var storage_kind := ""
var search_text := ""
var selected_index := -1
var selected_storage := false
var rebind_slot := -1
var refresh_timer := 0.0
var last_room := -1
var effects: Array = []
var travelers: Array = []
var npc_nodes: Dictionary = {}
var talked_npcs: Array = []
var dialogue: PanelContainer
var dialogue_body: VBoxContainer
var active_npc: Dictionary = {}
var wanderer_counter := 0
var loot_feedback: VBoxContainer
var monster_corpses: Array = []
var loot_serial := 0
var recovery_visuals: Array[Node2D] = []
var loot_window: CanvasLayer

func _ready() -> void:
	game = get_parent()
	process_mode = Node.PROCESS_MODE_ALWAYS
	z_index = 3900
	_define_items()
	backpack = ItemContainer.new(24, items)
	chest = ItemContainer.new(100, items)
	depot = ItemContainer.new(160, items)
	for skill in SKILLS:
		proficiencies[skill] = 0.0
	backpack.add("rust_sword")
	backpack.add("cloth_armor")
	backpack.add("wood", 4)
	backpack.add("ore", 4)
	for id in game.unlocked_loot:
		backpack.add(id)
	if game.player.equipped_loot_id != "":
		equipped.weapon = game.player.equipped_loot_id
		backpack.remove(game.player.equipped_loot_id, 1)
	_build_ui()
	loot_window = preload("res://scripts/monster_loot_window.gd").new()
	loot_window.game = game
	loot_window.rpg = self
	add_child(loot_window)
	_spawn_residents()
	dungeon = DungeonSystem.new()
	dungeon.game = game
	dungeon.rpg = self
	add_child(dungeon)
	exploration_map = ExplorationMap.new()
	exploration_map.game = game
	exploration_map.rpg = self
	add_child(exploration_map)
	log_event("System", "The den is quiet. Your journey begins.")

func _define_items() -> void:
	items = Catalog.table("items").duplicate(true)

func input_blocked() -> bool:
	return get_tree().paused or chat_entry != null and chat_entry.has_focus() or panel != null and panel.visible or dialogue != null and dialogue.visible

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if dialogue != null and dialogue.visible:
		if event.keycode in [KEY_ESCAPE, KEY_E]:
			dialogue.hide()
		get_viewport().set_input_as_handled()
		return
	if get_tree().paused:
		return
	if rebind_slot >= 0:
		var existing := keycodes.find(event.physical_keycode)
		if existing >= 0:
			keycodes[existing] = keycodes[rebind_slot]
		keycodes[rebind_slot] = event.physical_keycode
		game._auto_save()
		rebind_slot = -1
		get_viewport().set_input_as_handled()
		_refresh_panel()
		return
	if chat_entry.has_focus():
		if event.keycode == KEY_ESCAPE:
			chat_entry.release_focus()
		get_viewport().set_input_as_handled()
		return
	if event.keycode == KEY_ENTER:
		chat_panel.show()
		chat_entry.grab_focus()
	elif event.physical_keycode == KEY_I:
		panel.visible = not panel.visible
		if panel.visible:
			_refresh_panel()
	elif event.physical_keycode == KEY_ESCAPE and panel.visible:
		panel.hide()
	elif panel.visible:
		return
	else:
		for i in range(keycodes.size()):
			if event.physical_keycode == int(keycodes[i]):
				cast(str(bindings[i]))
				get_viewport().set_input_as_handled()
				return
		return
	get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if not is_instance_valid(game) or get_tree().paused:
		return
	# Pausing the SceneTree also pauses this node, so corpse time is gameplay time.
	for corpse in corpses.duplicate():
		corpse.remaining = float(corpse.remaining) - delta
		if corpse.remaining <= 0:
			corpses.erase(corpse)
			log_event("System", "A corpse expired with its unrecovered contents.")
		elif float(corpse.remaining) <= 300 and not bool(corpse.get("warned", false)):
			corpse.warned = true
			log_event("System", "Corpse recovery warning: less than five minutes remain.")
	for record in monster_corpses.duplicate():
		record.remaining = float(record.get("remaining",1800.0)) - delta
		if record.remaining <= 0:
			monster_corpses.erase(record)
	_sync_recovery_visuals()
	_sync_traveler_actors()
	if dialogue != null and dialogue.visible and int(active_npc.get("room", -1)) != game.current_room:
		dialogue.hide()
	for traveler in travelers.duplicate():
		traveler.remaining -= delta
		if traveler.remaining <= 0:
			travelers.erase(traveler)
	for action in cooldowns.keys():
		cooldowns[action] = maxf(0.0, float(cooldowns[action]) - delta)
	mana = minf(max_mana(), mana + delta * (1.5 + float(attributes.Willpower) * 0.1))
	stamina = minf(100.0, stamina + delta * 18.0)
	weather_timer -= delta
	if weather_timer <= 0:
		weather_timer = 90.0
		weather = ["Clear", "Rain", "Mist"].pick_random() if game.current_room in [5, 6, SWAMP] else "Clear"
	if game.current_room == DEEP_CAVE:
		weather = "Snow at cave mouth"
	if last_room != game.current_room:
		last_room = game.current_room
		weather_timer = 0.0
		weather = "Snow at cave mouth" if last_room == DEEP_CAVE else "Clear"
		world_hour = fmod(world_hour + 0.5, 24.0)
		if not discovered.has(last_room):
			discovered.append(last_room)
			game.gain_xp(25 if last_room != HUB else 60)
			log_event("System", "Discovered " + str(game.ROOM_NAMES[last_room]))
	encounter_timer -= delta
	if encounter_timer <= 0 and game.current_room in [6, SWAMP, DEEP_CAVE]:
		encounter_timer = 65.0
		_spawn_encounter()
	refresh_timer -= delta
	if refresh_timer <= 0:
		refresh_timer = 0.25
		resource_label.text = "Mana %d/%d   Stamina %d   %02d:00   %s" % [mana, max_mana(), stamina, int(world_hour), weather]
		for i in range(hotbar.get_child_count()):
			var action: String = str(bindings[i])
			var left: float = float(cooldowns.get(action, 0.0))
			var button: Button = hotbar.get_child(i)
			button.visible = action != "" and action != "potion"
			var title := Catalog.display("spells",action,action.replace("_"," "))
			button.tooltip_text = title + (" — %.1fs" % left if left > 0 else "")
			button.text = "%s\n%s" % [OS.get_keycode_string(int(keycodes[i])), "%.1fs" % left if left > 0 else title.left(6)]
		var used := 0
		for button in hotbar.get_children():
			if button.visible:
				used += 1
		hotbar.position.x = (1152.0 - float(used*56-6)) * 0.5
	for effect in effects.duplicate():
		effect.time -= delta
		if effect.time <= 0:
			effects.erase(effect)
	queue_redraw()

func _sync_recovery_visuals() -> void:
	var records: Array = corpses + monster_corpses
	while recovery_visuals.size()>records.size():
		recovery_visuals.pop_back().queue_free()
	while recovery_visuals.size()<records.size():
		var visual := preload("res://scripts/recovery_visual.gd").new()
		visual.rpg = self
		game.add_child(visual)
		recovery_visuals.append(visual)
	for index in range(records.size()):
		recovery_visuals[index].record = records[index]
		recovery_visuals[index].monster = index>=corpses.size()

func max_mana() -> float:
	return 60.0 + float(attributes.Willpower) * 5.0

func _spawn_encounter() -> void:
	if game.living_enemies() >= 6:
		return
	var tier := 1 if game.current_room == 6 else (2 if game.current_room == SWAMP else 3)
	var point: Vector2 = game.player.position + Vector2(340, 100).rotated(randf() * TAU)
	var bounds := Vector2(2200, 1340) if game.current_room == 6 else Vector2(1050, 620)
	point = point.clamp(Vector2(100, 120), bounds)
	if point.distance_to(game.player.position) < 220:
		return
	var ray := PhysicsRayQueryParameters2D.create(game.player.position, point, 1)
	if not game.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	# Biome and weather affect ordinary encounters; bosses are never rolled.
	if randf() < 0.30:
		travelers.append({"room": game.current_room, "point": point, "kind": ["Wandering merchant", "Injured traveler", "Treasure hunter"].pick_random(), "remaining": 100.0})
		log_event("System", "You spot a traveler nearby.")
		return
	var monster_id: String = [["forest_scout_wanderer", "thornwood_poacher_wanderer"], ["bog_marauder_wanderer", "mire_stalker_wanderer"], ["deep_cave_sentinel_wanderer", "frostroot_delver_wanderer"]][tier - 1].pick_random()
	var title: String = Catalog.display("monsters", monster_id)
	var role := "archer" if randf() < (0.45 if weather == "Rain" else 0.25) else "knight"
	role = "ranger" if role == "archer" else role
	game.spawn_enemy_ext(game.current_room, point, title, 45 + tier * 25, 60 + tier * 10, 4 + tier * 4, tier * 5, role, tier * 25, "", monster_id)
	log_event("System", "Movement nearby: " + title)

func train(skill: String, amount: float) -> void:
	var favored: bool = skill == "Magic" and game.player.class_id == "mage" or skill == "Distance Fighting" and game.player.class_id == "archer" or skill in ["Sword Fighting", "Axe Fighting", "Club Fighting", "Shielding"] and game.player.class_id == "knight"
	proficiencies[skill] = float(proficiencies.get(skill, 0.0)) + amount * (1.5 if favored else 1.0)

func proficiency_level(skill: String) -> int:
	return int(sqrt(float(proficiencies.get(skill, 0.0)) / 20.0))

func combat_skill() -> String:
	var weapon: Dictionary = items.get(str(equipped.get("weapon", "")), {})
	return str(weapon.get("skill", "Magic" if game.player.class_id == "mage" else ("Distance Fighting" if game.player.class_id == "archer" else "Sword Fighting")))

func gear_stat(stat: String) -> float:
	var value := 0.0
	for id in equipped.values():
		value += float(items.get(str(id), {}).get(stat, 0.0))
	return value

func equip(index: int, destination: String = "") -> bool:
	if index < 0 or index >= backpack.slots.size():
		return false
	var id: String = str(backpack.slots[index].id)
	var item: Dictionary = items[id]
	var slot: String = str(item.get("slot", ""))
	if slot == "" or destination != "" and destination != slot:
		return false
	if game.player.level < int(item.get("level", 1)):
		log_event("System", "Requires level %d." % item.level)
		return false
	if slot == "shield" and bool(items.get(str(equipped.get("weapon", "")), {}).get("two_handed", false)):
		log_event("System", "Unequip your two-handed weapon first.")
		return false
	var before: Array = backpack.slots.duplicate(true)
	backpack.remove(id, 1)
	var displaced: Array = []
	if equipped.has(slot):
		displaced.append(slot)
	if bool(item.get("two_handed", false)) and equipped.has("shield"):
		displaced.append("shield")
	for key in displaced:
		if not backpack.add(str(equipped[key])):
			backpack.slots = before
			log_event("System", "Make room in your backpack first.")
			return false
	for key in displaced:
		equipped.erase(key)
	equipped[slot] = id
	log_event("System", "Equipped " + str(item.name) + ".")
	_recalculate()
	return true

func unequip(slot: String) -> void:
	if not equipped.has(slot):
		return
	var id := str(equipped[slot])
	if not backpack.add(id):
		log_event("System", "Backpack full. Make room before removing equipment.")
		return
	equipped.erase(slot)
	log_event("System", "Removed " + str(items[id].name) + ".")
	_recalculate()

func _recalculate() -> void:
	# Keep legacy unique-item modifiers, with one equipment source of truth.
	game.player.equipped_loot_id = str(equipped.get("weapon", "")) if Data.LOOT_ITEMS.has(str(equipped.get("weapon", ""))) else ""
	game.player.apply_class_and_gear(game.player.class_id, game.player.evolution_id, true)
	game._auto_save()
	_refresh_panel()

func loot(id: String, count: int = 1) -> void:
	if backpack.add(id, count):
		log_event("Loot", "+%d %s" % [count, items[id].name])
		_show_loot_icon(id, count)
	else:
		# Never silently discard a full-backpack pickup.
		corpses.append({"room": game.current_room, "position": game.player.position, "items": [{"id": id, "count": count}], "remaining": 1800.0, "kind": "Dropped loot"})
		log_event("Loot", "Backpack full. Item left in a recoverable ground bag.")

func enemy_reward(enemy: Node2D, room_id: int = -1) -> void:
	dungeon.enemy_down(enemy)
	kills += 1
	train(combat_skill(),clampf(float(enemy.max_hp)/maxf(1.0,float(game.player.get_effective_damage())),0.5,6.0))
	var contents = ItemContainer.new(50,items)
	contents.add(["wood","ore","herb"].pick_random(),1)
	if randf() < 0.10:
		contents.add(["ring","helmet","legs","boots","necklace"].pick_random(),1)
	var unique: String = str(enemy.get("loot_drop_id")) if enemy.get("loot_drop_id") != null else ""
	if unique != "":
		contents.add(unique,1)
	loot_serial += 1
	monster_corpses.append({"id":"monster_%d" % loot_serial,"name":str(enemy.display_name),"room":0 if Starting.connected(room_id) else (game.current_room if room_id < 0 else room_id),"position":enemy.position,"items":contents.slots.duplicate(true),"scrap":maxi(0,int(enemy.scrap_reward)),"remaining":1800.0})
	log_event("Combat","Defeated " + str(enemy.display_name) + ". Inspect the body to claim its loot.")

func can_loot_monster(record: Dictionary) -> bool:
	return not record.is_empty() and monster_corpses.has(record) and int(record.room)==game.current_room and game.player.hp>0 and game.player.position.distance_to(record.position)<100.0

func claim_monster_item(record: Dictionary, index: int) -> bool:
	if not can_loot_monster(record) or index < 0 or index >= record.items.size():
		return false
	var entry: Dictionary = record.items[index]
	var id: String = str(entry.id)
	var count: int = int(entry.count)
	if not backpack.add(id,count):
		return false
	record.items.remove_at(index)
	game.audio_system.play_sfx("loot")
	if Data.LOOT_ITEMS.has(id) and not game.unlocked_loot.has(id):
		game.unlocked_loot.append(id)
	_show_loot_icon(id,count)
	log_event("Loot","Claimed %d %s." % [count,items[id].name])
	_finish_monster_loot(record)
	game._auto_save()
	return true

func claim_monster_scrap(record: Dictionary) -> bool:
	if not can_loot_monster(record) or int(record.get("scrap",0)) <= 0:
		return false
	var amount: int = int(record.scrap)
	record.scrap = 0
	game.collect_scrap(amount)
	_finish_monster_loot(record)
	game._auto_save()
	return true

func claim_all_monster_loot(record: Dictionary) -> void:
	if not can_loot_monster(record):
		return
	for index in range(record.items.size()-1,-1,-1):
		claim_monster_item(record,index)
	claim_monster_scrap(record)

func _finish_monster_loot(record: Dictionary) -> void:
	if record.items.is_empty() and int(record.get("scrap",0))==0:
		monster_corpses.erase(record)

func npc_position(definition: Dictionary) -> Vector2:
	var actor = npc_nodes.get(str(definition.get("id","")))
	if is_instance_valid(actor):
		return actor.position
	return definition.get("point",Vector2.ZERO)

func die() -> void:
	var dropped: Array = backpack.slots.duplicate(true)
	for id in equipped.values():
		dropped.append({"id": id, "count": 1})
	corpses.append({"room": game.current_room, "position": game.player.position, "items": dropped, "remaining": 1800.0, "kind": "Goblin corpse"})
	backpack.slots.clear()
	equipped.clear()
	game.player.equipped_loot_id = ""
	game.player.apply_class_and_gear(game.player.class_id, game.player.evolution_id, false)
	game.player.invulnerability = 3.0
	game.enter_room(0, Vector2(575, 400))
	game.result.text = ""
	game._auto_save()
	log_event("System", "Respawned at den. Backpack and equipment remain on your corpse for 30 minutes of gameplay. Stored items are safe.")

func interaction_candidates() -> Array:
	var options: Array = []
	var room: int = game.current_room
	for corpse in corpses:
		if int(corpse.room) == room:
			options.append({"point": corpse.position, "radius": 85.0, "label": "Recover gear" if str(corpse.kind)=="Goblin corpse" else "Recover dropped loot", "action": _recover_corpse.bind(corpse)})
	for record in monster_corpses:
		if int(record.room) == room:
			options.append({"point":record.position,"radius":85.0,"label":"Loot " + str(record.name),"action":loot_window.open.bind(record)})
	for npc in NpcData.RESIDENTS:
		if int(npc.room) == room:
			options.append({"point": npc_position(npc), "radius": 78.0, "label": "Talk to " + str(npc.name), "action": _talk.bind(npc)})
	for traveler in travelers:
		if int(traveler.room) == room:
			options.append({"point": npc_position(traveler), "radius": 80.0, "label": "Talk to " + str(traveler.kind), "action": _talk_traveler.bind(traveler)})
	# Trail definitions are also used by the focus prompt and activation.
	var routes: Array = []
	match room:
		0:
			routes = []
			options.append({"point": Starting.CHEST, "radius": 85.0, "label": preload("res://scripts/design_catalog.gd").display("labels", "open_den_chest"), "action": open_storage.bind("chest")})
		6:
			routes = [[Vector2(500, 350), 80.0, preload("res://scripts/design_catalog.gd").display("labels", "enter_bramble_market"), HUB, Vector2(210, 365)], [Vector2(700, 350), 80.0, "Follow the hollow trail", 5, Vector2(900,365)], [BOG_TRAIL_POINT, 90.0, preload("res://scripts/design_catalog.gd").display("labels", "enter_mirewood_bog"), SWAMP, Vector2(210, 365)]]
		SWAMP:
			routes = [[Vector2(1000, 365), 90.0, preload("res://scripts/design_catalog.gd").display("labels", "enter_frostroot_cave"), DEEP_CAVE, Vector2(210, 365)], [Vector2(145, 365), 90.0, preload("res://scripts/design_catalog.gd").display("labels", "return_to_the_forest"), 6, Vector2(600, 350)]]
		DEEP_CAVE:
			routes = [[Vector2(145, 365), 90.0, preload("res://scripts/design_catalog.gd").display("labels", "return_to_mirewood_bog"), SWAMP, Vector2(900, 365)]]
		HUB:
			routes = [[Vector2(145, 365), 90.0, preload("res://scripts/design_catalog.gd").display("labels", "return_to_the_forest"), 6, Vector2(600, 350)]]
			# Resident NPCs own market services, avoiding overlapping invisible service targets.
	for route in routes:
		options.append({"point": route[0], "radius": route[1], "label": route[2], "action": game.enter_room.bind(route[3], route[4])})
	if room in [6, SWAMP, DEEP_CAVE]:
		var remaining := float(cooldowns.get("resource_%d" % room, 0.0))
		options.append({"point": Vector2(800, 500), "radius": 80.0, "label": (preload("res://scripts/design_catalog.gd").display("labels", "gather_wood") if room == 6 else "Mine ore") if remaining <= 0.0 else "Resource regrowing — %ds" % ceili(remaining), "action": _gather_resource.bind(room), "ready": remaining <= 0.0})
	if room == 6:
		var remaining := float(cooldowns.get("fishing", 0.0))
		options.append({"point": Vector2(1000, 450), "radius": 80.0, "label": preload("res://scripts/design_catalog.gd").display("labels", "fish_at_riverbank") if remaining <= 0.0 else "Fish returning — %ds" % ceili(remaining), "action": _fish, "ready": remaining <= 0.0})
	options.append_array(dungeon.interaction_candidates())
	return options

func try_interact() -> bool:
	# Retained entry point for other game systems; same resolver as the visible prompt.
	var target: Dictionary = get_parent().interaction_feedback.choose(interaction_candidates())
	if target.is_empty():
		return false
	target.action.call()
	return true

func _recover_corpse(corpse: Dictionary) -> void:
	var ground = ItemContainer.new(500, items)
	ground.restore(corpse.items)
	for i in range(ground.slots.size() - 1, -1, -1):
		ground.transfer(i, backpack)
	corpse.items = ground.slots.duplicate(true)
	if ground.slots.is_empty():
		corpses.erase(corpse)
	log_event("Loot", "Recovered what fits. %d stacks remain." % ground.slots.size())
	game._auto_save()

func _gather_resource(room: int) -> void:
	var key := "resource_%d" % room
	if float(cooldowns.get(key, 0.0)) > 0:
		log_event("System", "This resource needs time to regrow.")
		return
	cooldowns[key] = 60.0
	loot("wood" if room == 6 else "ore", 2)
	train("Woodcutting" if room == 6 else "Mining", 5.0)
	game._auto_save()

func _fish() -> void:
	if float(cooldowns.get("fishing", 0.0)) > 0:
		log_event("System", "Give the fish time to return.")
		return
	cooldowns.fishing = 60.0
	loot("fish", 2)
	train("Fishing", 5.0)
	log_event("System", "Caught two River Fish. Select them in your backpack to eat.")
	game._auto_save()

func _resolve_traveler(traveler: Dictionary) -> void:
	if not travelers.has(traveler) or game.current_room != int(traveler.room) or game.player.position.distance_to(npc_position(traveler)) >= 100:
		return
	match str(traveler.kind):
		"Injured traveler":
			if backpack.remove("herb", 1):
				game.gain_xp(40)
				game.scrap += 12
				travelers.erase(traveler)
				log_event("General", "Traveler: Thank you for the Glowleaf. Take these supplies.")
			else:
				log_event("General", "Traveler: Can you spare one Glowleaf?")
		"Wandering merchant":
			if game.scrap >= 3 and backpack.add("herb", 2):
				game.scrap -= 3
				travelers.erase(traveler)
				log_event("General", "Merchant: Two Glowleaf for three scrap. Safe travels!")
			else:
				log_event("General", "Merchant: Three scrap for two Glowleaf. You'll need space.")
		_:
			log_event("General", "Treasure hunter: The bog lies southeast. Take spare gear; the cave beyond is dangerous.")
	game._auto_save()
	dialogue.hide()

func open_storage(kind: String) -> void:
	pack_page = "Inventory"
	storage_kind = kind
	panel.show()
	_refresh_panel()

func current_storage() -> RefCounted:
	if storage_kind == "chest" and game.current_room == 0 and game.player.position.distance_to(Starting.CHEST) < 100:
		return chest
	if storage_kind == "depot" and game.current_room == HUB and game.player.position.distance_to(npc_position({"id":"depot_keeper","point":Vector2(350,345)})) < 140:
		return depot
	return null

func cast(action: String) -> void:
	if action == "" or game.player.hp <= 0 or not ACTIONS.has(action):
		return
	if action != "potion" and not learned.has(action):
		log_event("System", "Learn this action from the settlement trainer first.")
		return
	if float(cooldowns.get(action, 0.0)) > 0 or mana < int(ACTIONS[action].cost):
		log_event("System", "Action needs more mana or is cooling down.")
		return
	if action == "shield_bash" and not equipped.has("shield"):
		log_event("System", "Shield Bash requires an equipped shield.")
		return
	if action == "potion":
		game.use_potion()
		return
	var spec: Dictionary = ACTIONS[action]
	var hits: Array = []
	if spec.has("damage"):
		var aim: Vector2 = game.get_global_mouse_position()
		if auto_target:
			var closest: float = float(spec.range)
			target = null
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if enemy.is_visible_in_tree() and enemy.hp > 0 and enemy.position.distance_to(game.player.position) < closest:
					closest = enemy.position.distance_to(game.player.position)
					target = enemy
			if not is_instance_valid(target):
				log_event("System", "No target in range.")
				return
			aim = target.position
		if aim.distance_to(game.player.position) > float(spec.range):
			log_event("System", "Target is out of range.")
			return
		var ray := PhysicsRayQueryParameters2D.create(game.player.position, aim, 1)
		if not game.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			log_event("System", "The path is blocked.")
			return
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy.is_visible_in_tree() and enemy.hp > 0 and enemy.position.distance_to(aim) <= float(spec.radius):
				var sight := PhysicsRayQueryParameters2D.create(aim, enemy.position, 1)
				if game.get_world_2d().direct_space_state.intersect_ray(sight).is_empty():
					hits.append(enemy)
		effects.append({"point": aim, "radius": spec.radius, "time": 0.4})
		for enemy in hits:
			enemy.take_damage(int(spec.damage) + proficiency_level("Magic") + int(attributes.Intelligence) * 2, game.player.position.direction_to(enemy.position))
			if action == "shield_bash" and enemy.has_method("apply_status"):
				enemy.apply_status(0, 0, 0.7)
				if enemy.get("stun_timer") != null:
					enemy.stun_timer = 0.7
		if not hits.is_empty():
			train("Magic" if action == "fireball" else combat_skill(), 2.0)
	elif spec.has("heal"):
		if game.player.hp >= game.player.max_hp:
			return
		game.player.heal(int(spec.heal) + int(attributes.Intelligence) * 2)
		train("Magic", 1.0)
	mana -= int(spec.cost)
	cooldowns[action] = float(spec.cooldown)
	log_event("Combat", "Used " + Catalog.display("spells", action, action.replace("_", " ")))

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 8
	add_child(layer)
	resource_label = Label.new()
	resource_label.hide()
	resource_label.position = Vector2(28, 106)
	resource_label.add_theme_font_size_override("font_size", 14)
	layer.add_child(resource_label)
	hotbar = HBoxContainer.new()
	hotbar.position = Vector2(520, 653)
	hotbar.add_theme_constant_override("separation",6)
	layer.add_child(hotbar)
	for i in range(12):
		var button := Button.new()
		button.custom_minimum_size = Vector2(50, 43)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		if bindings[i] == "potion":
			_item_button(button, "potion", 28)
		button.add_theme_font_size_override("font_size", 11)
		var action_style := StyleBoxFlat.new()
		action_style.bg_color = Color("111c17")
		action_style.border_color = Color("89714a")
		action_style.set_border_width_all(1)
		action_style.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal",action_style)
		button.pressed.connect(func(): cast(str(bindings[i])))
		hotbar.add_child(button)
	var menu := Button.new()
	menu.text = "Pack"
	menu.tooltip_text = "Backpack & equipment [I]"
	menu.position = Vector2(1002, 18)
	menu.add_theme_font_size_override("font_size", 12)
	menu.custom_minimum_size = Vector2(58, 28)
	menu.pressed.connect(func(): panel.visible = not panel.visible; _refresh_panel())
	layer.add_child(menu)
	var pause_button := Button.new()
	pause_button.text = "Menu"
	pause_button.tooltip_text = "Pause, controls & training [Esc]"
	pause_button.position = Vector2(1066,18)
	pause_button.custom_minimum_size = Vector2(66,28)
	pause_button.pressed.connect(func(): game.game_menu.open())
	layer.add_child(pause_button)
	loot_feedback = VBoxContainer.new()
	loot_feedback.position = Vector2(870, 265)
	loot_feedback.custom_minimum_size.x = 255
	layer.add_child(loot_feedback)
	panel = PanelContainer.new()
	panel.position = Vector2(80, 120)
	panel.size = Vector2(990, 500)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.055, 0.07, 0.065, 0.98)
	style.border_color = Color("a99162")
	style.set_border_width_all(2)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(950, 470)
	panel.add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body)
	panel.hide()
	chat_panel = PanelContainer.new()
	chat_panel.position = Vector2(28, 365)
	chat_panel.size = Vector2(440, 195)
	chat_panel.add_theme_stylebox_override("panel", style)
	layer.add_child(chat_panel)
	var chat_box := VBoxContainer.new()
	chat_panel.add_child(chat_box)
	var channels := HBoxContainer.new()
	chat_box.add_child(channels)
	for channel in ["General", "Combat", "Loot", "System"]:
		_button(channels, channel, func(): filter_channel = channel; _refresh_chat())
	_button(channels, "Hide", func(): chat_panel.hide(); chat_entry.release_focus())
	chat_output = RichTextLabel.new()
	chat_output.custom_minimum_size = Vector2(410, 110)
	chat_output.scroll_following = true
	chat_output.add_theme_font_size_override("normal_font_size", 13)
	chat_box.add_child(chat_output)
	chat_entry = LineEdit.new()
	chat_entry.placeholder_text = "/cast heal | /cast fireball | Enter to chat"
	chat_entry.text_submitted.connect(_chat_submit)
	chat_box.add_child(chat_entry)
	chat_panel.hide()
	dialogue = PanelContainer.new()
	dialogue.position = Vector2(220, 350)
	dialogue.custom_minimum_size = Vector2(710, 200)
	dialogue.add_theme_stylebox_override("panel", style)
	layer.add_child(dialogue)
	dialogue_body = VBoxContainer.new()
	dialogue.add_child(dialogue_body)
	dialogue.hide()
	dialogue.visibility_changed.connect(func(): get_tree().paused = dialogue.visible)

func _exit_tree() -> void:
	if dialogue != null and dialogue.visible:
		get_tree().paused = false

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _label(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.custom_minimum_size.y = 24
	parent.add_child(label)
	return label

func _refresh_panel() -> void:
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	var header := HBoxContainer.new()
	body.add_child(header)
	_label(header, "GOBLIN PACK  •  %d/%d slots  •  %d scrap" % [backpack.slots.size(), backpack.capacity, game.scrap])
	_button(header, "Close", func(): panel.hide())
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation",8)
	body.add_child(pages)
	for page in ["Inventory","Character","Journal","Crafting","Actions"]:
		var tab := _button(pages,page,func(): pack_page = page; _refresh_panel())
		tab.disabled = page == pack_page
	match pack_page:
		"Character":
			_render_character_tab()
			return
		"Journal":
			_label(body,dungeon.journal())
			return
		"Crafting":
			_render_crafting_tab()
			return
		"Actions":
			_render_actions_tab()
			return
	var tabs := HBoxContainer.new()
	body.add_child(tabs)
	_button(tabs, "Sort", func(): backpack.slots.sort_custom(func(a, b): return str(items[a.id].name) < str(items[b.id].name)); _refresh_panel())
	_button(tabs, "Deposit all", func(): _transfer_all(backpack, current_storage())).visible = current_storage() != null
	_button(tabs, "Take all", func(): _transfer_all(current_storage(), backpack)).visible = current_storage() != null
	_item_button(_button(tabs, "Upgrade bag (30 scrap)", _upgrade_bag), "backpack", 24)
	var search := LineEdit.new()
	search.placeholder_text = "Search items (Enter)"
	search.custom_minimum_size.x = 200
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search.text = search_text
	search.text_submitted.connect(func(value): search_text = value; _refresh_panel())
	tabs.add_child(search)
	_label(body, "Select an item to inspect it. Double-click to equip, or drag onto an equipment slot.")
	if current_storage() == chest:
		_button(body, "Expand chest (+50 slots): 40 scrap", func():
			if game.scrap >= 40 and chest.capacity < 300:
				game.scrap -= 40
				chest.capacity += 50
				game._auto_save()
				_refresh_panel())
	var workspace := HBoxContainer.new()
	body.add_child(workspace)
	var equipment := GridContainer.new()
	equipment.columns = 3
	equipment.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	workspace.add_child(equipment)
	var arrangement := ["necklace", "helmet", "ring", "weapon", "preview", "shield", "legs", "armor", "boots"]
	for slot in arrangement:
		if slot == "preview":
			var preview := TextureRect.new()
			preview.texture = load("res://assets/goblin_class_%s.png" % game.player.class_id)
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			preview.custom_minimum_size = Vector2(110, 72)
			equipment.add_child(preview)
			continue
		var id: String = str(equipped.get(slot, ""))
		var button = _button(equipment, Catalog.display("equipment_slots", slot) + "\n" + str(items.get(id, {}).get("name", "Empty")), func(): unequip(slot))
		button.icon = ItemIcons.get_icon(id) if id != "" else load("res://assets/ui/%s.svg" % slot)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 40 if id != "" else 26)
		button.custom_minimum_size = Vector2(110, 54)
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 12)
		button.tooltip_text = "Click/tap to unequip. " + _tooltip(id) if id != "" else "Empty " + slot + " slot. Drag matching gear here."
		button.set_drag_forwarding(Callable(), func(_at, data): return data is Dictionary and data.get("source") == "pack" and str(items[data.id].get("slot", "")) == slot, func(_at, data): equip(int(data.index), slot))
	var lists := VBoxContainer.new()
	lists.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workspace.add_child(lists)
	_render_container(lists, backpack, preload("res://scripts/design_catalog.gd").display("labels", "backpack"), false)
	var store = current_storage()
	if store != null:
		_render_container(lists, store, storage_kind.capitalize(), true)
	_render_selected_details()
	var operations := HBoxContainer.new()
	body.add_child(operations)
	var selected := _selected_item()
	var equip_action := _button(operations, "Equip selected", func(): equip(selected_index))
	equip_action.disabled = selected_storage or str(selected.get("slot", "")) == "" or game.player.level < int(selected.get("level", 1))
	var use_action := _button(operations, "Use selected", _use_selected)
	use_action.disabled = selected_storage or not selected.has("heal") or game.player.hp >= game.player.max_hp
	_button(operations, "Transfer selected", func(): _transfer_selected(false))
	_button(operations, "Transfer half", func(): _transfer_selected(true))
	if storage_kind in ["merchant", "trainer"] and game.current_room == HUB:
		_label(body, "SETTLEMENT SERVICES")
		if storage_kind == "trainer":
			for action in ["fireball", "heal", "shield_bash", "piercing_shot"]:
				_button(body, "Learn %s — 15 scrap%s" % [Catalog.display("spells", action), " (known)" if learned.has(action) else ""], func(): _learn(action))
		else:
			for id in ["shield", "helmet", "bow", "staff", "axe", "club"]:
				_item_button(_button(body, "Buy %s — 12 scrap" % items[id].name, func(): _buy(id)), id)
			_item_button(_button(body, "Supplies: refill potions — 8 scrap", _buy_potions), "potion")

func _render_crafting_tab() -> void:
	_label(body,"CRAFT AT YOUR DEN OR THE MARKET")
	var craft := HBoxContainer.new()
	body.add_child(craft)
	if game.is_den_room() or game.current_room == HUB:
		_item_button(_button(craft, "Forge sword: 6 ore + 3 wood", func(): _craft("iron_sword", {"ore": 6, "wood": 3})), "iron_sword", 32)
		_item_button(_button(craft, "Weave armor: 4 wood + 2 herb", func(): _craft("cloth_armor", {"wood": 4, "herb": 2})), "cloth_armor", 32)
	if not game.is_den_room() and game.current_room != HUB:
		_label(body,"Return to the den or Bramble Market to craft equipment.")

func _render_character_tab() -> void:
	_label(body, "LEVEL %d  •  Attribute points %d" % [game.player.level, points])
	var attrs := HBoxContainer.new()
	body.add_child(attrs)
	for attribute in attributes:
		var button := _button(attrs, "%s %d +" % [Catalog.display("attributes", attribute), attributes[attribute]], func(): _allocate(attribute); _refresh_panel())
		button.disabled = points <= 0
	_label(body,"PROFICIENCIES")
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",32)
	body.add_child(grid)
	for skill in SKILLS:
		var label := _label(grid,"%s  ·  Lv %d  ·  %.0f XP" % [Catalog.display("skills",skill),proficiency_level(skill),proficiencies[skill]])
		label.custom_minimum_size = Vector2(420,28)

func _render_actions_tab() -> void:
	_label(body,"Choose spells and rebind their keys. Only assigned spells appear in the action belt.")
	_button(body, "Targeting: " + ("Automatic nearest enemy" if auto_target else "Manual mouse aim"), func(): auto_target = not auto_target; _refresh_panel())
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation",24)
	body.add_child(grid)
	for i in range(12):
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(440,32)
		grid.add_child(row)
		_button(row, "Rebind " + OS.get_keycode_string(int(keycodes[i])), func(): rebind_slot = i; log_event("System", "Press a key for this action slot."))
		var picker := OptionButton.new()
		picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		picker.add_item("Empty")
		var options: Array = [""] + learned + ["potion"]
		for action in options.slice(1):
			picker.add_item(Catalog.display("spells", str(action)))
		picker.select(maxi(0, options.find(bindings[i])))
		picker.item_selected.connect(func(index): bindings[i] = options[index]; game._auto_save())
		row.add_child(picker)

func _render_container(parent: Node, container: RefCounted, title: String, is_storage: bool) -> void:
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 460
	parent.add_child(column)
	_label(column, title)
	for i in range(container.slots.size()):
		var entry: Dictionary = container.slots[i]
		if search_text != "" and not str(items[entry.id].name).to_lower().contains(search_text.to_lower()):
			continue
		var button := _button(column, "%s ×%d" % [items[entry.id].name, entry.count], func(): selected_index = i; selected_storage = is_storage; _refresh_panel())
		_item_button(button, str(entry.id))
		button.modulate = Color("f5dc8e") if selected_index == i and selected_storage == is_storage else Color.WHITE
		button.tooltip_text = _tooltip(str(entry.id))
		button.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.double_click:
				if is_storage:
					container.transfer(i, backpack)
					game._auto_save()
					_refresh_panel()
				else:
					equip(i))
		if not is_storage:
			button.set_drag_forwarding(func(_at):
				var preview := HBoxContainer.new()
				var picture := TextureRect.new()
				picture.texture = ItemIcons.get_icon(str(entry.id))
				picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				picture.custom_minimum_size = Vector2(44, 44)
				preview.add_child(picture)
				_label(preview, str(items[entry.id].name))
				button.set_drag_preview(preview)
				return {"source": "pack", "index": i, "id": entry.id}, Callable(), Callable())

func _selected_item() -> Dictionary:
	var source = current_storage() if selected_storage else backpack
	if source == null or selected_index < 0 or selected_index >= source.slots.size():
		return {}
	return items.get(str(source.slots[selected_index].id), {})

func _render_selected_details() -> void:
	var item := _selected_item()
	if item.is_empty():
		_label(body, "Select an item to inspect its stats and compare equipment.")
		return
	var source = current_storage() if selected_storage else backpack
	var id := str(source.slots[selected_index].id)
	var detail := _label(body, _tooltip(id))
	detail.add_theme_color_override("font_color", Color("eddaa9"))
	var slot := str(item.get("slot", ""))
	if slot == "":
		return
	var current: Dictionary = items.get(str(equipped.get(slot, "")), {})
	var attack_delta := int(item.get("attack", item.get("damage", 0))) - int(current.get("attack", current.get("damage", 0)))
	var armor_delta := int(round((float(item.get("defense", 0)) - float(current.get("defense", 0))) * 100))
	var health_delta := int(item.get("health", item.get("max_hp", 0))) - int(current.get("health", current.get("max_hp", 0)))
	_label(body, "Compared with %s: Attack %+d | Armor %+d%% | Health %+d" % [current.get("name", "empty " + slot + " slot"), attack_delta, armor_delta, health_delta])
	if bool(item.get("two_handed", false)) and equipped.has("shield"):
		_label(body, "Two-handed: your shield will return to the backpack.")
	if slot == "shield" and bool(items.get(str(equipped.get("weapon", "")), {}).get("two_handed", false)):
		_label(body, "Remove your two-handed weapon before equipping this shield.")
	if game.player.level < int(item.get("level", 1)):
		_label(body, "Requires level %d (you are level %d)." % [item.level, game.player.level])

func _tooltip(id: String) -> String:
	if not items.has(id):
		return ""
	var item: Dictionary = items[id]
	var text := "%s | %s" % [item.name, item.get("rarity", "Common")]
	if item.has("slot"):
		text += " | " + str(item.slot).capitalize()
		text += "\nAttack +%d | Armor +%d%% | Health +%d | Level %d" % [item.get("attack", item.get("damage", 0)), int(round(float(item.get("defense", 0)) * 100)), item.get("health", item.get("max_hp", 0)), item.get("level", 1)]
		if item.has("skill"):
			text += "\n" + Catalog.display("skills", str(item.skill))
		if bool(item.get("two_handed", false)):
			text += " | Two-handed"
	elif item.has("heal"):
		text += "\nRestores %d health." % item.heal
	else:
		text += "\nCrafting material | Stack limit %d" % item.get("stack", 1)
	if str(item.get("tradeoff", "")) != "":
		text += "\n" + str(item.tradeoff)
	return text

func _use_selected() -> void:
	if selected_storage or selected_index < 0 or selected_index >= backpack.slots.size():
		return
	var id: String = str(backpack.slots[selected_index].id)
	if items[id].has("heal") and game.player.hp < game.player.max_hp:
		backpack.remove(id, 1)
		game.player.heal(int(items[id].heal))
		game._auto_save()
		_refresh_panel()

func _transfer_selected(half: bool) -> void:
	var store = current_storage()
	if store == null:
		return
	var source = store if selected_storage else backpack
	var destination = backpack if selected_storage else store
	if selected_index >= 0 and selected_index < source.slots.size():
		source.transfer(selected_index, destination, maxi(1, int(source.slots[selected_index].count) / 2) if half else -1)
		game._auto_save()
		_refresh_panel()

func _transfer_all(source, destination) -> void:
	if source == null or destination == null:
		return
	for i in range(source.slots.size() - 1, -1, -1):
		source.transfer(i, destination)
	game._auto_save()
	_refresh_panel()

func _upgrade_bag() -> void:
	if game.scrap >= 30 and backpack.capacity < 64:
		game.scrap -= 30
		backpack.capacity = mini(64, backpack.capacity + 8)
		game._auto_save()
		_refresh_panel()

func _buy(id: String) -> void:
	if game.current_room == HUB and game.scrap >= 12 and backpack.add(id):
		game.scrap -= 12
		game._auto_save()
		_refresh_panel()

func _buy_potions() -> void:
	if game.current_room == HUB and game.scrap >= 8 and game.potions < game.max_potions:
		game.scrap -= 8
		game.potions = game.max_potions
		game._auto_save()
		_refresh_panel()

func _learn(action: String) -> void:
	if game.current_room == HUB and game.scrap >= 15 and not learned.has(action):
		game.scrap -= 15
		learned.append(action)
		var empty := bindings.find("")
		if empty >= 0:
			bindings[empty] = action
		game._auto_save()
		_refresh_panel()

func _craft(id: String, recipe: Dictionary) -> void:
	if not game.is_den_room() and game.current_room != HUB:
		return
	# Linked den chest is usable for home crafting, depot stays separate.
	var linked = chest if game.is_den_room() else ItemContainer.new(0, items)
	for material in recipe:
		if backpack.count_item(material) + linked.count_item(material) < int(recipe[material]):
			log_event("System", "Not enough materials.")
			return
	var before: Array = backpack.slots.duplicate(true)
	var stored_before: Array = linked.slots.duplicate(true)
	for material in recipe:
		var carried := mini(int(recipe[material]), backpack.count_item(material))
		backpack.remove(material, carried)
		linked.remove(material, int(recipe[material]) - carried)
	if not backpack.add(id):
		backpack.slots = before
		linked.slots = stored_before
		return
	train("Crafting", 8.0)
	game._auto_save()
	_refresh_panel()

func _allocate(attribute: String) -> void:
	if points > 0:
		points -= 1
		attributes[attribute] += 1
		_recalculate()

func log_event(channel: String, message: String) -> void:
	logs.append({"channel": channel, "text": message})
	if logs.size() > 150:
		logs.pop_front()
	if chat_output != null:
		_refresh_chat()
	if game != null:
		game.show_notice(message)

func _refresh_chat() -> void:
	chat_output.text = ""
	for entry in logs:
		if filter_channel == "General" or entry.channel == filter_channel:
			chat_output.append_text("[%s] %s\n" % [entry.channel, entry.text])

func _chat_submit(text: String) -> void:
	chat_entry.clear()
	chat_entry.release_focus()
	if text.begins_with("/cast "):
		cast(text.substr(6).strip_edges().to_lower().replace(" ", "_"))
	elif text != "":
		log_event("General", "You: " + text)

func snapshot() -> Dictionary:
	return {"opening_layout":2,"opening_cleared":game.opening_cleared,"monster_corpses":monster_corpses,"loot_serial":loot_serial,"pack": backpack.slots, "capacity": backpack.capacity, "chest": chest.slots, "chest_capacity": chest.capacity, "depot": depot.slots, "equipped": equipped, "proficiencies": proficiencies, "attributes": attributes, "points": points, "learned": learned, "bindings": bindings, "keycodes": keycodes, "corpses": corpses, "discovered": discovered, "quest": quest_claimed, "kills": kills, "mana": mana, "world_hour": world_hour, "cooldowns": cooldowns, "weather": weather, "travelers": travelers, "talked_npcs": talked_npcs, "wanderer_counter": wanderer_counter, "dungeon": dungeon.snapshot(), "exploration_map": exploration_map.snapshot()}

func restore(state: Dictionary) -> void:
	if state.is_empty():
		return
	if loot_window != null:
		loot_window.close()
	monster_corpses = state.get("monster_corpses",[]).duplicate(true)
	loot_serial = int(state.get("loot_serial",0))
	backpack.capacity = clampi(int(state.get("capacity", 24)), 24, 64)
	backpack.restore(state.get("pack", []))
	chest.capacity = clampi(int(state.get("chest_capacity", 100)), 100, 300)
	chest.restore(state.get("chest", []))
	depot.restore(state.get("depot", []))
	equipped = state.get("equipped", {}).duplicate(true)
	proficiencies.merge(state.get("proficiencies", {}), true)
	attributes.merge(state.get("attributes", {}), true)
	points = int(state.get("points", 0))
	learned = state.get("learned", ["heal"])
	bindings = state.get("bindings", bindings)
	keycodes = state.get("keycodes", keycodes)
	corpses = state.get("corpses", []).duplicate(true)
	game.opening_cleared = state.get("opening_cleared",[]).duplicate()
	# Old saves carry room-local corpse coordinates. Migrate once without losing loot.
	if int(state.get("opening_layout",0))<2:
		for record in corpses+monster_corpses:
			if Starting.connected(int(record.room)):
				record.position = Starting.point(int(record.room),record.position)
				record.room = 0
	discovered = state.get("discovered", [])
	quest_claimed = bool(state.get("quest", false))
	kills = int(state.get("kills", 0))
	mana = float(state.get("mana", 60.0))
	world_hour = float(state.get("world_hour", 8.0))
	cooldowns = state.get("cooldowns", {}).duplicate(true)
	weather = str(state.get("weather", "Clear"))
	travelers = state.get("travelers", []).duplicate(true)
	if int(state.get("opening_layout",0))<2:
		for traveler in travelers:
			if Starting.connected(int(traveler.room)):
				traveler.point = Starting.point(int(traveler.room),traveler.point)
				traveler.room = 0
	talked_npcs = state.get("talked_npcs", []).duplicate()
	wanderer_counter = int(state.get("wanderer_counter", 0))
	dungeon.restore(state.get("dungeon", {}))
	exploration_map.restore(state.get("exploration_map", {}))
	if int(state.get("opening_layout",0))<2:
		for old_room in Starting.IDS:
			exploration_map.explored.erase(old_room)
			exploration_map.known_markers.erase(old_room)
	game.player.equipped_loot_id = str(equipped.get("weapon", "")) if Data.LOOT_ITEMS.has(str(equipped.get("weapon", ""))) else ""
	game.player.apply_class_and_gear(game.player.class_id, game.player.evolution_id, false)

func _draw() -> void:
	if game == null:
		return
	var markers: Array = []
	match game.current_room:
		0: markers = [[Starting.CHEST,"Den chest"],[Starting.EXIT,"Thornwood Hollow"]]
		6: markers = [[Vector2(500, 350), preload("res://scripts/design_catalog.gd").display("labels", "trading_settlement")], [Vector2(700, 350), preload("res://scripts/design_catalog.gd").display("labels", "home_trail")], [BOG_TRAIL_POINT, preload("res://scripts/design_catalog.gd").display("labels", "bog_trail_tier_2")], [Vector2(800, 500), preload("res://scripts/design_catalog.gd").display("labels", "gather_wood")], [Vector2(1000, 450), preload("res://scripts/design_catalog.gd").display("labels", "riverbank")]]
		HUB: markers = [[Vector2(145, 365), preload("res://scripts/design_catalog.gd").display("labels", "forest_trail")], [Vector2(350, 300), preload("res://scripts/design_catalog.gd").display("labels", "personal_depot")], [Vector2(550, 300), preload("res://scripts/design_catalog.gd").display("labels", "merchant_smith")], [Vector2(750, 300), preload("res://scripts/design_catalog.gd").display("labels", "spell_trainer")], [Vector2(550, 480), preload("res://scripts/design_catalog.gd").display("labels", "quest_board")]]
		SWAMP: markers = [[Vector2(145, 365), preload("res://scripts/design_catalog.gd").display("labels", "forest_trail")], [Vector2(1000, 365), preload("res://scripts/design_catalog.gd").display("labels", "deep_cave_tier_3")], [Vector2(800, 500), preload("res://scripts/design_catalog.gd").display("labels", "mine_bog_iron")]]
		DEEP_CAVE: markers = [[Vector2(145, 365), preload("res://scripts/design_catalog.gd").display("labels", "bog_trail")], [Vector2(800, 500), preload("res://scripts/design_catalog.gd").display("labels", "mine_cave_ore")]]
	var font := ThemeDB.fallback_font
	for marker in markers:
		if game.player.position.distance_to(marker[0]) > 220.0:
			continue
		draw_circle(marker[0],4.0,Color(0.65,0.77,0.48,0.65))
		draw_arc(marker[0],15.0,0,TAU,24,Color(0.65,0.77,0.48,0.35),1.0,true)
	for effect in effects:
		draw_arc(effect.point, effect.radius * (1.0 - effect.time), 0, TAU, 28, Color(1, 0.5, 0.15, effect.time * 2), 5)
	if game.current_room in [6, SWAMP, DEEP_CAVE] and weather != "Clear":
		var origin: Vector2 = game.player.position - Vector2(600, 380)
		for i in range(70):
			var point := origin + Vector2(fmod(i * 137.0 + game.playtime * 30, 1200), fmod(i * 73.0 + game.playtime * 280, 760))
			if game.current_room == DEEP_CAVE:
				draw_circle(point, 2, Color(0.9, 0.95, 1, 0.5))
			else:
				draw_line(point, point + Vector2(-4, 14), Color(0.6, 0.75, 0.9, 0.35), 1)

func _spawn_residents() -> void:
	var props := Node2D.new()
	props.draw.connect(func(): _draw_hub_props(props))
	game.rooms[HUB].add_child(props)
	for definition in NpcData.RESIDENTS:
		_spawn_npc(definition)

func _spawn_npc(definition: Dictionary) -> void:
	var npc := FriendlyNpc.new()
	npc.definition = definition
	npc.game = game
	npc.position = definition.point
	game.rooms[int(definition.room)].add_child(npc)
	npc_nodes[str(definition.id)] = npc

func _sync_traveler_actors() -> void:
	var active_ids: Array = []
	for traveler in travelers:
		if not traveler.has("id"):
			wanderer_counter += 1
			traveler.id = "wanderer_%d" % wanderer_counter
		active_ids.append(str(traveler.id))
		if not npc_nodes.has(str(traveler.id)):
			var data: Dictionary = traveler.duplicate()
			data.name = Catalog.display("travelers", str(traveler.kind), "Traveler")
			data["class"] = "mage" if traveler.kind == "Wandering merchant" else "archer"
			_spawn_npc(data)
	for id in npc_nodes.keys():
		if str(id).begins_with("wanderer_") and not active_ids.has(id):
			if is_instance_valid(npc_nodes[id]):
				npc_nodes[id].queue_free()
			npc_nodes.erase(id)

func _clear_dialogue() -> void:
	for child in dialogue_body.get_children():
		dialogue_body.remove_child(child)
		child.queue_free()

func _talk(npc: Dictionary) -> void:
	active_npc = npc
	if not talked_npcs.has(npc.id):
		talked_npcs.append(npc.id)
		game._auto_save()
	_clear_dialogue()
	_label(dialogue_body, str(npc.name))
	_label(dialogue_body, str(npc.greeting))
	var advice := _label(dialogue_body, "")
	advice.hide()
	var options := HBoxContainer.new()
	dialogue_body.add_child(options)
	var service: String = str(npc.service)
	var title: String = {"rest": "Rest at the den", "depot": "Open my depot", "merchant": "Browse gear / Craft", "trainer": "Learn spells", "supplies": "Refill potions — 8 scrap", "quest": "Check contract", "guide": "Tell me about the trails"}[service]
	_button(options, title, func(): _npc_service(npc))
	_button(options, "Any advice?", func():
		advice.text = str(npc.rumor)
		advice.show()
		log_event("General", str(npc.name) + ": " + str(npc.rumor)))
	_button(options, "Goodbye", func(): dialogue.hide())
	dialogue.show()
	log_event("General", str(npc.name) + ": " + str(npc.greeting))

func _npc_service(npc: Dictionary) -> void:
	if game.current_room != int(npc.room) or game.player.position.distance_to(npc_position(npc)) > 100:
		dialogue.hide()
		return
	dialogue.hide()
	match str(npc.service):
		"depot", "merchant", "trainer": open_storage(str(npc.service))
		"rest":
			game.player.heal(game.player.max_hp)
			for ally in game.party_nodes:
				if is_instance_valid(ally):
					ally.revive_and_heal()
			game.potions = game.max_potions
			mana = max_mana()
			world_hour = fmod(world_hour + 8, 24)
			log_event("General", str(npc.name) + ": Catch your breath. The road can wait.")
		"supplies":
			_buy_potions()
			log_event("General", str(npc.name) + (": Supplies ready." if game.potions == game.max_potions else ": You'll need eight scrap for a refill."))
		"quest": _claim_contract()
		"guide":
			log_event("General", str(npc.name) + ": " + str(npc.rumor))
	game._auto_save()

func _claim_contract() -> void:
	if dungeon.claim_reward():
		return
	var contract: Dictionary = Catalog.record("quests", "bounty")
	if kills >= int(contract.kill_target) and not quest_claimed:
		quest_claimed = true
		game.scrap += int(contract.reward_scrap)
		game.gain_xp(int(contract.reward_xp))
		loot("ring")
		log_event("General", "%s: Good work. +%d scrap, +%d XP, and %s." % [Catalog.display("npcs", "scout_captain"), contract.reward_scrap, contract.reward_xp, items.ring.name])
	elif quest_claimed:
		log_event("General", "Rusk: You've earned your pay. Come back for more contracts in a later update.")
	else:
		log_event("General", "%s: Defeat %d enemies. Progress: %d/%d." % [Catalog.display("npcs", "scout_captain"), contract.kill_target, mini(kills, int(contract.kill_target)), contract.kill_target])

func _talk_traveler(traveler: Dictionary) -> void:
	active_npc = traveler
	_clear_dialogue()
	_label(dialogue_body, str(traveler.kind))
	var words: String = {"Wandering merchant": "Two Glowleaf for three scrap. Interested?", "Injured traveler": "I can't make it to the settlement like this. Can you spare a Glowleaf?", "Treasure hunter": "The bog is southeast, with a dangerous cave beyond. Keep backup gear at home."}.get(str(traveler.kind), "Safe travels.")
	_label(dialogue_body, words)
	var choices := HBoxContainer.new()
	dialogue_body.add_child(choices)
	if traveler.kind != "Treasure hunter":
		_button(choices, "Trade — 3 scrap" if traveler.kind == "Wandering merchant" else "Give one Glowleaf", func(): _resolve_traveler(traveler))
	_button(choices, "Goodbye", func(): dialogue.hide())
	dialogue.show()
	log_event("General", str(traveler.kind) + ": " + words)

func _draw_hub_props(canvas: Node2D) -> void:
	var station_art: Texture2D = load("res://assets/den_stations_v2.png")
	for service in [[Vector2(350, 300), 4], [Vector2(550, 300), 1], [Vector2(750, 300), 2], [Vector2(550, 480), 5]]:
		var cell: int = int(service[1])
		var region := Rect2(Vector2(cell % 3, cell / 3) * 512.0, Vector2(512, 512))
		canvas.draw_texture_rect_region(station_art, Rect2(service[0] - Vector2(65, 120), Vector2(130, 130)), region)

func _item_button(button: Button, id: String, icon_size: int = 40) -> void:
	button.icon = ItemIcons.get_icon(id)
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", icon_size)
	button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, icon_size + 8)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _show_loot_icon(id: String, count: int) -> void:
	if loot_feedback == null:
		return
	var toast := Button.new()
	toast.text = "+%d %s" % [count, items[id].name]
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_button(toast, id, 32)
	loot_feedback.add_child(toast)
	if loot_feedback.get_child_count() > 4:
		var oldest := loot_feedback.get_child(0)
		loot_feedback.remove_child(oldest)
		oldest.queue_free()
	get_tree().create_timer(3.5).timeout.connect(func():
		if is_instance_valid(toast):
			toast.queue_free())



extends Node2D
const Layout = preload("res://scripts/dungeon_layout.gd")
const Floor = preload("res://scripts/dungeon_floor.gd")
const Boss = preload("res://scripts/dungeon_boss.gd")
const Icons = preload("res://scripts/item_icons.gd")
var game: Node2D
var rpg: Node2D
var seals: Array = []
var cleared: Array = []
var caches: Array = []
var discovered: Array = []
var started := false
var boss_defeated := false
var vault_opened := false
var reward_claimed := false
var boss: CharacterBody2D
func _ready() -> void:
	z_as_relative = false
	z_index = 3800
	for id in range(Layout.FIRST,Layout.LAST+1):
		var floor_node := Floor.new()
		floor_node.room_id = id
		game.rooms[id].add_child(floor_node)
		# Wall dressing sits inside the existing solid edge; it adds no new blockers.
		for room in Layout.ROOMS:
			var bounds: Rect2 = Layout.rect(room,id)
			for point in [Vector2(bounds.position.x+80,bounds.position.y+6),Vector2(bounds.end.x-80,bounds.position.y+6)]:
				_add_dressing(id,point,0)
			_add_dressing(id,Vector2(bounds.position.x-22,bounds.position.y+56),2)
			_add_dressing(id,Vector2(bounds.position.x+38,bounds.end.y-30),3 if int(bounds.position.y)%3==0 else 4)
		_add_prop(id,Layout.entry(id),"stairs_up")
		_add_prop(id,Layout.point(Vector2(480,400),id),"cache")
		if id < 15:
			_add_prop(id,Layout.stairs(id),"stairs_down")
			var points: Array = Layout.seals(id)
			for i in range(points.size()):
				_add_prop(id,points[i],"seal",i)
		else:
			_add_prop(id,Vector2(2440,1660),"reliquary")
	_add_prop(12,Vector2(1000,365),"entrance")
func _add_prop(room_id: int, point: Vector2, kind: String, index: int = 0) -> void:
	var prop := preload("res://scripts/descent_prop.gd").new()
	prop.dungeon = self
	prop.floor_id = room_id
	prop.kind = kind
	prop.seal_index = index
	prop.position = point
	game.rooms[room_id].add_child(prop)

func _add_dressing(room_id: int, point: Vector2, kind: int) -> void:
	var item := preload("res://scripts/descent_dressing.gd").new()
	item.kind = kind
	item.position = point
	game.rooms[room_id].add_child(item)

func populate() -> void:
	for id in range(Layout.FIRST,Layout.LAST+1):
		var points := [Vector2(1130,320),Vector2(1460,400),Vector2(2110,360),Vector2(2500,520),Vector2(360,980),Vector2(610,1130),Vector2(1120,1010),Vector2(1450,1160),Vector2(2110,1050),Vector2(2450,1160),Vector2(2210,1660)]
		for i in range(points.size()):
			if id == 15 and i >= 8:
				continue
			var key := "floor_%d_guard_%d" % [id,i]
			if cleared.has(key):
				continue
			var tier := id-12
			var role: String = ["knight","ranger","mage"][i%3]
			var monster_id := "dungeon_guard_%d" % tier
			var title: String = preload("res://scripts/design_catalog.gd").display("monsters", monster_id)
			game.spawn_enemy_ext(id,Layout.point(points[i],id),title,65+tier*20,70+tier*5,5+tier*3,4+tier,role,25+tier*10,"",monster_id)
			var guard = game.rooms[id].get_child(game.rooms[id].get_child_count()-1)
			guard.set_meta("dungeon_id",key)
			guard.dungeon_awareness = preload("res://scripts/dungeon_awareness.gd").new()
			guard.dungeon_awareness.configure(guard)
	if not boss_defeated:
		boss = Boss.new()
		boss.position = Vector2(2330,1260)
		var collision := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 48
		collision.shape = shape
		boss.add_child(collision)
		boss.set_meta("dungeon_id","vault_boss")
		game.rooms[15].add_child(boss)
		boss.defeated.connect(game.on_enemy_defeated.bind(boss,15))
func enemy_down(enemy: Node2D) -> void:
	if not enemy.has_meta("dungeon_id"):
		return
	var id: String = str(enemy.get_meta("dungeon_id"))
	if not cleared.has(id):
		cleared.append(id)
	if id == "vault_boss":
		boss_defeated = true
		rpg.log_event("System","The guardian falls. Open the final reliquary, then report to Rusk at Bramble Market.")
	game._auto_save()
func on_enter(room_id: int) -> void:
	# Abandoned projectiles cannot linger at a staircase or carry across floors.
	for projectile in get_tree().get_nodes_in_group("dungeon_boss_projectiles"):
		projectile.queue_free()
	if not Layout.is_dungeon(room_id):
		return
	started = true
	if not discovered.has(room_id):
		discovered.append(room_id)
		rpg.log_event("System","Sealed Descent: floor %d of 3. Find the ward seals and investigate the depths." % (room_id-12))
	game._auto_save()
func interaction_candidates() -> Array:
	var room: int = game.current_room
	var options: Array = []
	if room == 12:
		return [{"point": Vector2(1000,365), "radius": 85.0, "label": "Enter the Sealed Descent", "action": try_interact}]
	if not Layout.is_dungeon(room):
		return options
	options.append({"point": Layout.entry(room), "radius": 80.0, "label": "Climb to the previous floor", "action": try_interact})
	if room < 15:
		var positions: Array = Layout.seals(room)
		for index in range(positions.size()):
			var active := seals.has("%d_%d" % [room,index])
			options.append({"point": positions[index], "radius": 85.0, "label": "Ward seal active" if active else "Activate ward seal", "ready": not active, "action": try_interact})
		options.append({"point": Layout.stairs(room), "radius": 85.0, "label": "Descend to the next floor" if seal_count(room) >= 2 else "Descent sealed — activate both wards", "ready": seal_count(room) >= 2, "action": try_interact})
	options.append({"point": Layout.point(Vector2(480,400),room), "radius": 80.0, "label": "Side vault empty" if caches.has("cache_%d" % room) else "Open side vault", "ready": not caches.has("cache_%d" % room), "action": try_interact})
	if room == 15:
		options.append({"point": Vector2(2440,1660), "radius": 85.0, "label": "Reliquary recovered" if vault_opened else ("Open final reliquary" if boss_defeated else "Reliquary bound to guardian"), "ready": boss_defeated and not vault_opened, "action": try_interact})
	return options

func try_interact() -> bool:
	var room_id: int = game.current_room
	var p: Vector2 = game.player.position
	if room_id == 12 and p.distance_to(Vector2(1000,365)) < 85:
		game.enter_room(13,Layout.entry(13))
		return true
	if not Layout.is_dungeon(room_id):
		return false
	if p.distance_to(Layout.entry(room_id)) < 80:
		game.enter_room(room_id-1,Vector2(900,365) if room_id==13 else Layout.stairs(room_id-1)-Vector2(70,0))
		return true
	if room_id<15:
		var positions: Array = Layout.seals(room_id)
		for index in range(positions.size()):
			if p.distance_to(positions[index]) < 85:
				var key := "%d_%d" % [room_id,index]
				if not seals.has(key):
					seals.append(key)
					game.gain_xp(30)
					rpg.log_event("System","Ward seal lit: %d/2 on this floor." % seal_count(room_id))
				else:
					rpg.log_event("System","This ward seal is already active.")
				game._auto_save()
				return true
		if p.distance_to(Layout.stairs(room_id)) < 85:
			if seal_count(room_id)<2:
				rpg.log_event("System","The descent is sealed. Activate both ward seals on this floor.")
			else:
				game.enter_room(room_id+1,Layout.entry(room_id+1)+Vector2(80,0))
			return true
	var cache := Layout.point(Vector2(480,400),room_id)
	if p.distance_to(cache)<80:
		var key := "cache_%d" % room_id
		if not caches.has(key):
			caches.append(key)
			rpg.loot("ore",4)
			rpg.loot("herb",2)
			game.scrap += 12
			rpg.log_event("Loot","Side vault opened: ore, herbs and 12 scrap.")
		else:
			rpg.log_event("System","This side vault is empty.")
		game._auto_save()
		return true
	if room_id == 15 and p.distance_to(Vector2(2440,1660))<85:
		if not boss_defeated:
			rpg.log_event("System","The final reliquary remains bound to its guardian.")
		elif not vault_opened:
			vault_opened = true
			rpg.loot("hero_dawnbreaker")
			rpg.loot("ore",8)
			game.scrap += 30
			rpg.log_event("System","Reliquary recovered. Return to Rusk for your quest reward.")
		else:
			rpg.log_event("System","The final reliquary has been recovered.")
		game._auto_save()
		return true
	return false
func seal_count(room_id: int) -> int:
	return int(seals.has("%d_0"%room_id))+int(seals.has("%d_1"%room_id))
func claim_reward() -> bool:
	if not vault_opened or reward_claimed:
		return false
	reward_claimed = true
	game.scrap += int(preload("res://scripts/design_catalog.gd").record("quests", "sealed_descent").reward_scrap)
	game.gain_xp(int(preload("res://scripts/design_catalog.gd").record("quests", "sealed_descent").reward_xp))
	rpg.log_event("General","%s: You made it through all three floors. +%d scrap and +%d XP." % [preload("res://scripts/design_catalog.gd").display("npcs", "scout_captain"), preload("res://scripts/design_catalog.gd").record("quests", "sealed_descent").reward_scrap, preload("res://scripts/design_catalog.gd").record("quests", "sealed_descent").reward_xp])
	game._auto_save()
	return true
func objective(room_id: int) -> String:
	if room_id<15:
		return "Ward seals %d/2 — find the stairs down" % seal_count(room_id)
	return "Recover the final reliquary" if boss_defeated else "Investigate the final vault"
func journal() -> String:
	if reward_claimed:
		return preload("res://scripts/design_catalog.gd").display("quests", "sealed_descent").to_upper() + " — Complete. Three floors explored; Rusk's reward claimed."
	if vault_opened:
		return preload("res://scripts/design_catalog.gd").display("quests", "sealed_descent").to_upper() + " — Return to Rusk in Bramble Market."
	if boss_defeated:
		return preload("res://scripts/design_catalog.gd").display("quests", "sealed_descent").to_upper() + " — Open the reliquary on floor 3."
	if started:
		return preload("res://scripts/design_catalog.gd").display("quests", "sealed_descent").to_upper() + " — Find two ward seals on each of floors 1 and 2, descend, and investigate the final vault."
	return preload("res://scripts/design_catalog.gd").display("quests", "sealed_descent").to_upper() + " — Find the passage beyond Frostroot Cavern."
func snapshot() -> Dictionary:
	return {"seals":seals,"cleared":cleared,"caches":caches,"discovered":discovered,"started":started,"boss_defeated":boss_defeated,"vault_opened":vault_opened,"reward_claimed":reward_claimed}
func restore(state: Dictionary) -> void:
	seals = state.get("seals",[]).duplicate()
	cleared = state.get("cleared",[]).duplicate()
	caches = state.get("caches",[]).duplicate()
	discovered = state.get("discovered",[]).duplicate()
	started = bool(state.get("started",false))
	boss_defeated = bool(state.get("boss_defeated",false))
	vault_opened = bool(state.get("vault_opened",false))
	reward_claimed = bool(state.get("reward_claimed",false))
func _process(_delta: float) -> void:
	queue_redraw()
func _draw() -> void:
	pass

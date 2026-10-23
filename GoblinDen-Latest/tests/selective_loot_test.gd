extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	if not ok:
		failures += 1
		push_error(text)
func run() -> void:
	var save = load("res://scripts/save_data.gd")
	save.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	game.player.invulnerability = 9999
	for enemy in get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	var rpg = game.rpg
	game.enter_room(1,Vector2(440,430))
	await process_frame
	var unique: String = load("res://scripts/goblin_data.gd").LOOT_ITEMS.keys()[0]
	game.spawn_enemy_ext(1,Vector2(450,430),"Loot test enemy",10,0,0,17,"knight",21,unique)
	var enemy = game.rooms[1].get_child(game.rooms[1].get_child_count()-1)
	enemy.set_physics_process(false)
	var before: Array = rpg.backpack.slots.duplicate(true)
	var scrap: int = game.scrap
	var xp: int = game.player.xp
	enemy.take_damage(99999)
	await process_frame
	check(rpg.backpack.slots==before and game.scrap==scrap,"Defeat adds no items or scrap to the player")
	check(game.player.xp==xp+21,"XP is granted at defeat")
	check(rpg.monster_corpses.size()==1,"Defeat creates one inspectable corpse")
	game.on_enemy_defeated(enemy,1)
	check(rpg.monster_corpses.size()==1 and game.player.xp==xp+21,"Duplicate defeat cannot duplicate loot or XP")
	var corpse: Dictionary = rpg.monster_corpses[0]
	for child in game.rooms[1].get_children():
		check(child.get_script()!=load("res://scripts/scrap.gd"),"No walk-over pickup is spawned")
	game.player.position = corpse.position
	await create_timer(0.25).timeout
	check(rpg.backpack.slots==before and game.scrap==scrap,"Walking across the defeated enemy does not collect anything")
	check(rpg.loot_window.open(corpse) and paused,"Body inspection opens a paused choice window")
	check(rpg.backpack.slots==before,"Opening loot does not claim it")
	rpg.loot_window.close()
	check(not paused and rpg.monster_corpses.has(corpse),"Closing leaves loot on the corpse")
	var index := -1
	for i in range(corpse.items.size()):
		if corpse.items[i].id==unique:
			index=i
	check(index>=0,"Named monster equipment is retained in corpse contents")
	var total: int = corpse.items.size()
	check(rpg.claim_monster_item(corpse,index),"Chosen item transfers successfully")
	check(corpse.items.size()==total-1 and int(corpse.scrap)==17,"Taking one item leaves the others and currency behind")
	check(game.unlocked_loot.has(unique),"Named equipment unlocks only when claimed")
	rpg.backpack.capacity = rpg.backpack.slots.size()
	var blocked: Dictionary = {"id":"full_pack","name":"Full pack test","room":0,"position":game.player.position,"items":[{"id":"helmet","count":1},{"id":"wood","count":1}],"scrap":8,"remaining":1500.0}
	rpg.monster_corpses.append(blocked)
	var left: Array = blocked.items.duplicate(true)
	check(not rpg.claim_monster_item(blocked,0) and blocked.items==left,"Full backpack preserves a rejected stack")
	check(rpg.claim_monster_scrap(blocked) and game.scrap==scrap+8,"Currency can be claimed even with a full backpack")
	check(not rpg.claim_monster_scrap(blocked),"Currency cannot be claimed twice")
	rpg.claim_all_monster_loot(blocked)
	check(blocked.items.size()==1 and blocked.items[0].id=="helmet","Take-all collects fitting stacks while leaving blocked equipment")
	game.player.position += Vector2(300,0)
	check(not rpg.claim_monster_item(blocked,0),"Loot cannot be claimed remotely")
	game.player.position = blocked.position
	var snapshot: Dictionary = rpg.snapshot().duplicate(true)
	save.save(game)
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	rpg = game.rpg
	check(rpg.monster_corpses.size()==snapshot.monster_corpses.size(),"All unclaimed corpse records survive scene reload")
	for i in range(rpg.monster_corpses.size()):
		var restored_record: Dictionary = rpg.monster_corpses[i]
		var saved_record: Dictionary = snapshot.monster_corpses[i]
		for key in ["id","name","room","position","items","scrap"]:
			check(restored_record[key]==saved_record[key],"Saved corpse field survives reload: " + key)
		check(absf(float(restored_record.remaining)-float(saved_record.remaining))<1.0,"Corpse timer resumes from its saved gameplay lifetime")
	var restored: Dictionary = rpg.monster_corpses[-1]
	game.enter_room(0,restored.position,true)
	rpg.backpack.capacity = 100
	rpg.claim_all_monster_loot(restored)
	check(not rpg.monster_corpses.has(restored),"Explicit take-all removes the corpse only when empty")
	game.queue_free()
	await process_frame
	save.delete_save()
	print("Selective loot, capacity, duplicate reward and persistence checks; failures: %d" % failures)
	await create_timer(0.25).timeout
	quit(1 if failures else 0)


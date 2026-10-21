extends SceneTree

const SaveData = preload("res://scripts/save_data.gd")
var failures: int = 0

func _init() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func count_kind(room: Node, property_name: String, value: String) -> int:
	var count := 0
	for child in room.get_children():
		if child.get(property_name) == value and child.get("hp") != null and child.hp > 0:
			count += 1
	return count

func find_kind(room: Node, property_name: String, value: String) -> Node:
	for child in room.get_children():
		if child.get(property_name) == value:
			return child
	return null

func run() -> void:
	SaveData.delete_save()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.recruited_ids.is_empty(), "A fresh game should start with no recruited goblins.")
	check(game.party_nodes.is_empty(), "A fresh game should put only the player Goblin on the field.")
	# Each class special must create a dedicated animated effect.
	for class_id in ["blade", "archer", "knight", "mage"]:
		game.select_goblin_class(class_id)
		game.player.special_cooldown = 0.0
		var room: Node = game.rooms[0]
		var before: int = room.get_child_count()
		game.player.use_special()
		await process_frame
		check(room.get_child_count() > before, "%s special should create visible combat art." % class_id)
	# Spider summons brood and creates poison terrain.
	game.enter_room(3, Vector2(420, 350))
	var spider = find_kind(game.rooms[3], "enemy_kind", "spider")
	spider.summon_cooldown = 0.0
	spider.gas_cooldown = 0.0
	spider._process_signature_abilities()
	await process_frame
	check(count_kind(game.rooms[3], "minion_kind", "spiderling") == 2, "Giant Spider should summon two spiderlings.")
	check(root.get_tree().get_nodes_in_group("enemy_hazards").size() >= 1, "Giant Spider should drop a poison gas field.")
	# Ogre begins a long, readable charged smash and produces an impact effect.
	game.enter_room(4, Vector2(620, 370))
	var ogre = find_kind(game.rooms[4], "enemy_kind", "ogre")
	ogre.target = game.player
	ogre.cooldown = 0.0
	ogre.special_cooldown = 0.0
	ogre.windup = 0.0
	ogre._process_signature_abilities()
	check(ogre.special_attack and ogre.windup >= 1.7, "Ogre charged smash needs a long telegraph.")
	ogre._execute_attack()
	check(not ogre.special_attack, "Ogre charged smash should resolve after impact.")
	# Wolf Rider is never alone: three living wolves accompany it.
	check(count_kind(game.rooms[5], "minion_kind", "wolf") == 3, "Wolf Rider should begin with a three-wolf pack.")
	print("Specials and monster-pack checks; failures: %d" % failures)
	game.queue_free()
	await process_frame
	SaveData.delete_save()
	quit(failures)


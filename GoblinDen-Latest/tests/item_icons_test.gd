extends SceneTree
const Icons = preload("res://scripts/item_icons.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.player.set_physics_process(false)
	var rpg = game.rpg
	var regions: Array = []
	for id in rpg.items:
		var icon = Icons.get_icon(id)
		check(icon != null, "Item has icon: " + str(id))
		if icon != null:
			check(not regions.has(icon.region), "Distinct items have distinct atlas cells: " + str(id))
			check(Rect2(Vector2.ZERO, Icons.ATLAS.get_size()).encloses(icon.region), "Icon stays inside atlas")
			regions.append(icon.region)
	check(rpg.items.size() == 25, "All 25 current inventory and unique-loot items covered")
	check(Icons.get_icon("missing_item") == null, "Unknown IDs cannot show a wrong icon")
	for id in ["potion", "scrap", "backpack", "chest", "scroll"]:
		check(Icons.get_icon(id) != null, "Support icon exists: " + id)
	var before: Dictionary = rpg.snapshot().duplicate(true)
	rpg._refresh_panel()
	check(rpg.snapshot() == before, "Rendering item art does not mutate inventory or progression")
	rpg.backpack.add("helmet")
	rpg.backpack.add("ring")
	rpg.backpack.add("necklace")
	rpg.backpack.add("shield")
	rpg.backpack.add("potion") # not an inventory item; should remain a separate legacy resource
	for id in ["helmet", "ring", "necklace", "shield"]:
		for i in range(rpg.backpack.slots.size()):
			if rpg.backpack.slots[i].id == id:
				rpg.equip(i)
				break
	rpg.open_storage("")
	check(Icons.get_icon("helmet") == Icons.get_icon("helmet"), "UI surfaces share cached canonical textures")
	if DisplayServer.get_name() != "headless":
		await create_timer(.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/item-icons-inventory.png")
		rpg.panel.hide()
		rpg.loot("ring")
		game.enter_room(10, Vector2(550, 345))
		rpg.open_storage("merchant")
		await create_timer(.1).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("/tmp/item-icons-shop.png")
	print("Item icon coverage and UI checks; failures: ", failures)
	game.queue_free()
	await process_frame
	load("res://scripts/save_data.gd").delete_save()
	quit(1 if failures else 0)

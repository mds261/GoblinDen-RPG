extends SceneTree
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	root.size = Vector2i(1440,900)
	var panel = load("res://addons/goblinden_data/data_panel.gd").new()
	root.add_child(panel)
	await process_frame
	panel.selected_id = "iron_sword"
	panel._rebuild_table()
	panel._build_form()
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://data-editor-items.png")
	panel.category = "monsters"
	panel.categories.select(1)
	panel.selected_id = "vault_hunger"
	panel._rebuild_table()
	panel._build_form()
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("user://data-editor-monsters.png")
	panel.queue_free()
	await process_frame
	quit()

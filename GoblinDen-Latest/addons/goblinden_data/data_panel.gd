@tool
extends VBoxContainer
const Catalog = preload("res://scripts/design_catalog.gd")
const Model = preload("res://addons/goblinden_data/data_model.gd")
var model = Model.new()
var category := "items"
var selected_id := ""
var search_text := ""
var categories: ItemList
var table: Tree
var form: VBoxContainer
var status: Label
var save_button: Button
var detail_title: Label
var summary: Label
var discard_dialog: ConfirmationDialog
var updating := false
var stat_field := ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 10)
	var header := HBoxContainer.new()
	add_child(header)
	var title := Label.new()
	title.text = "GOBLINDEN  /  GAME DATA"
	title.add_theme_font_size_override("font_size", 23)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	save_button = Button.new()
	save_button.text = "Save changes"
	save_button.pressed.connect(save_changes)
	header.add_child(save_button)
	var reload_button := Button.new()
	reload_button.text = "Discard / Reload"
	reload_button.pressed.connect(func():
		if model.is_dirty():
			discard_dialog.popup_centered()
		else:
			reload_data())
	header.add_child(reload_button)
	var help := Label.new()
	help.text = "Select a category, edit a name or value, then Save changes. Stop and restart the game to apply edits. IDs and behavior links stay fixed."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(help)
	var workspace := HSplitContainer.new()
	workspace.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(workspace)
	categories = ItemList.new()
	categories.custom_minimum_size.x = 195
	workspace.add_child(categories)
	for name in Catalog.CATEGORIES:
		categories.add_item({"npcs":"NPCs", "classes":"Player classes", "evolutions":"Class evolutions"}.get(name, str(name).capitalize()))
	categories.item_selected.connect(func(index):
		category = str(Catalog.CATEGORIES[index])
		selected_id = ""
		_rebuild_table()
		_build_form())
	var editor := VBoxContainer.new()
	workspace.add_child(editor)
	var search := LineEdit.new()
	search.placeholder_text = "Search names and IDs in this category…"
	search.text_changed.connect(func(value): search_text = value; _rebuild_table())
	editor.add_child(search)
	summary = Label.new()
	editor.add_child(summary)
	var split := HSplitContainer.new()
	split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	editor.add_child(split)
	table = Tree.new()
	table.columns = 3
	table.hide_root = true
	table.column_titles_visible = true
	table.set_column_title(0, "Display name — double-click to edit")
	table.set_column_title(1, "Value")
	table.set_column_title(2, "Stable ID")
	table.set_column_expand(0, true)
	table.set_column_custom_minimum_width(0, 220)
	table.set_column_expand(1, false)
	table.set_column_custom_minimum_width(1, 85)
	table.set_column_custom_minimum_width(2, 150)
	table.custom_minimum_size.x = 480
	table.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	table.item_selected.connect(_table_selected)
	table.item_edited.connect(_table_edited)
	split.add_child(table)
	var side := VBoxContainer.new()
	side.custom_minimum_size.x = 300
	split.add_child(side)
	detail_title = Label.new()
	detail_title.add_theme_font_size_override("font_size", 18)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side.add_child(detail_title)
	var revert := Button.new()
	revert.text = "Revert selected entry"
	revert.pressed.connect(func():
		if selected_id != "":
			model.reset_entry(category, selected_id)
			_rebuild_table()
			_build_form()
			_update_status())
	side.add_child(revert)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	side.add_child(scroll)
	form = VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.add_theme_constant_override("separation", 8)
	scroll.add_child(form)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.custom_minimum_size.y = 38
	add_child(status)
	discard_dialog = ConfirmationDialog.new()
	discard_dialog.dialog_text = "Discard all unsaved data changes and reload the files?"
	discard_dialog.confirmed.connect(reload_data)
	add_child(discard_dialog)
	reload_data()
	categories.select(0)

func reload_data() -> void:
	model.load_all()
	_rebuild_table()
	_build_form()
	_update_status()

func _rebuild_table() -> void:
	updating = true
	table.clear()
	var root := table.create_item()
	var records: Array = model.documents.get(category, {}).get("records", [])
	stat_field = ""
	for field in ["attack", "hp", "max_hp", "damage", "base_damage", "cooldown", "reward_scrap", "cost", "speed"]:
		if records.any(func(entry): return entry.has(field)):
			stat_field = field
			break
	table.set_column_title(1, stat_field.capitalize() if stat_field != "" else "Type")
	var count := 0
	for entry in records:
		if search_text != "" and not (str(entry.name) + " " + str(entry.id)).to_lower().contains(search_text.to_lower()):
			continue
		count += 1
		var row := table.create_item(root)
		row.set_metadata(0, str(entry.id))
		row.set_text(0, str(entry.name))
		row.set_editable(0, true)
		row.set_text(2, str(entry.id))
		row.set_tooltip_text(2, "Permanent ID used by saves and behavior. Change the display name instead.")
		if stat_field != "" and entry.has(stat_field):
			row.set_cell_mode(1, TreeItem.CELL_MODE_RANGE)
			row.set_range_config(1, -10000, 10000000, 0.01 if stat_field in ["speed", "cooldown"] else 1)
			row.set_range(1, float(entry[stat_field]))
			row.set_editable(1, true)
		else:
			row.set_text(1, str(entry.get("slot", entry.get("kind", "—"))))
		if str(entry.id) == selected_id:
			row.select(0)
	summary.text = "%s  •  %d of %d entries  •  %s" % [category.capitalize(), count, records.size(), "Unsaved changes" if model.is_dirty() else "Saved"]
	updating = false

func _table_selected() -> void:
	if updating:
		return
	var row := table.get_selected()
	if row != null:
		selected_id = str(row.get_metadata(0))
		_build_form()

func _table_edited() -> void:
	if updating:
		return
	var row := table.get_edited()
	if row == null:
		return
	var id := str(row.get_metadata(0))
	var column := table.get_edited_column()
	model.set_value(category, id, "name" if column == 0 else stat_field, row.get_text(0) if column == 0 else row.get_range(1))
	selected_id = id
	_build_form()
	_update_status()

func _build_form() -> void:
	for child in form.get_children():
		form.remove_child(child)
		child.queue_free()
	var entry: Dictionary = model.find_entry(category, selected_id)
	detail_title.text = str(entry.get("name", "Select an entry"))
	if entry.is_empty():
		return
	var fields: Array = entry.keys()
	fields.erase("name")
	fields.push_front("name")
	for field in fields:
		var value = entry[field]
		var locked: bool = Catalog.PROTECTED.has(str(field))
		var caption := Label.new()
		caption.text = str(field).capitalize() + ("  ·  fixed" if locked else "")
		caption.modulate = Color("9cae9e") if locked else Color.WHITE
		form.add_child(caption)
		if value is String:
			if str(field) in ["greeting", "rumor", "summary", "subtitle", "lore", "tradeoff"]:
				var text := TextEdit.new()
				text.text = str(value)
				text.editable = not locked
				text.custom_minimum_size.y = 95
				text.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
				text.text_changed.connect(func(): _change(str(field), text.text))
				form.add_child(text)
			else:
				var text := LineEdit.new()
				text.text = str(value)
				text.editable = not locked
				text.text_changed.connect(func(new_value): _change(str(field), new_value))
				form.add_child(text)
		elif value is bool:
			var toggle := CheckBox.new()
			toggle.text = "Enabled"
			toggle.button_pressed = value
			toggle.disabled = locked
			toggle.toggled.connect(func(new_value): _change(str(field), new_value))
			form.add_child(toggle)
		elif value is int or value is float:
			var number := SpinBox.new()
			number.min_value = -10000000
			number.max_value = 10000000
			number.step = 0.01 if str(field) in ["speed", "range", "radius", "attack_range", "attack_cooldown", "cooldown", "cooldown_length", "max_windup", "art_size", "speed_mult", "cooldown_mult", "armor", "armor_bonus", "crit_chance", "crit_bonus", "defense"] else 1
			number.value = float(value)
			number.editable = not locked
			number.value_changed.connect(func(new_value): _change(str(field), new_value))
			form.add_child(number)
		elif value is Dictionary and value.get("_type") == "Color":
			var picker := ColorPickerButton.new()
			picker.color = Color(value.r, value.g, value.b, value.a)
			picker.custom_minimum_size.y = 32
			picker.color_changed.connect(func(color): _change(str(field), {"_type":"Color", "r":color.r, "g":color.g, "b":color.b, "a":color.a}))
			form.add_child(picker)
		else:
			var info := Label.new()
			info.text = "Linked encounter layout (edit names in Monsters)" if str(field) in ["room_1","room_2"] else JSON.stringify(value)
			info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			info.modulate = Color("9cae9e")
			form.add_child(info)

func _change(field: String, value) -> void:
	if model.set_value(category, selected_id, field, value):
		model.errors.clear()
		if field == "name":
			detail_title.text = str(value)
		var row := table.get_selected()
		if row != null and str(row.get_metadata(0)) == selected_id:
			updating = true
			row.set_text(0, str(model.find_entry(category, selected_id).name))
			if field == stat_field:
				row.set_range(1, float(value))
			updating = false
		_update_status()

func _update_status() -> void:
	save_button.disabled = not model.is_dirty()
	var errors: PackedStringArray = Catalog.validate(model.documents)
	if not model.errors.is_empty():
		errors.append_array(model.errors)
	status.modulate = Color("f0bc86") if not errors.is_empty() else Color("a5d7ad")
	status.text = "\n".join(errors.slice(0, 3)) if not errors.is_empty() else ("Unsaved changes in %d categories. Save, then restart the game." % model.dirty_categories().size() if model.is_dirty() else "All data saved. Names can change; stable IDs keep saves connected.")

func save_changes() -> void:
	# Commit any SpinBox text still being edited before validating.
	var focus := get_viewport().gui_get_focus_owner()
	if focus != null:
		focus.release_focus()
	if model.save_all():
		_rebuild_table()
		_update_status()
		status.text = "Saved. Stop and restart the game to use the new data. The previous files are kept as .bak backups."
	else:
		_update_status()

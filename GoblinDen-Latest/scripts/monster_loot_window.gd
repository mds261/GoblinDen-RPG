extends CanvasLayer
## A deliberate, paused inspection; closing never takes or discards anything.
const Icons = preload("res://scripts/item_icons.gd")
var game: Node2D
var rpg: Node2D
var veil: ColorRect
var panel: PanelContainer
var body: VBoxContainer
var corpse: Dictionary = {}
var message := ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 24
	veil = ColorRect.new()
	veil.color = Color(0,0,0,0.45)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)
	veil.hide()
	panel = PanelContainer.new()
	panel.position = Vector2(286,140)
	panel.size = Vector2(580,440)
	var frame := StyleBoxFlat.new()
	frame.bg_color = Color(0.035,0.06,0.047,0.98)
	frame.border_color = Color("9a8050")
	frame.set_border_width_all(1)
	frame.set_corner_radius_all(6)
	frame.set_content_margin_all(22)
	panel.add_theme_stylebox_override("panel",frame)
	add_child(panel)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation",12)
	panel.add_child(body)
	panel.hide()

func open(record: Dictionary) -> bool:
	if not rpg.can_loot_monster(record) or get_tree().paused:
		return false
	corpse = record
	message = "Choose what to take. Anything you leave stays on the body."
	rpg.panel.hide()
	rpg.chat_entry.release_focus()
	veil.show()
	panel.show()
	get_tree().paused = true
	_rebuild()
	return true

func close() -> void:
	if not panel.visible:
		return
	panel.hide()
	veil.hide()
	corpse = {}
	get_tree().paused = false

func _exit_tree() -> void:
	if is_instance_valid(panel) and panel.visible:
		get_tree().paused = false

func _input(event: InputEvent) -> void:
	if panel.visible and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE,KEY_E]:
			close()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if panel.visible and not rpg.can_loot_monster(corpse):
		close()

func _label(parent: Node, text: String, size_px: int = 15) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",size_px)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 32
	button.pressed.connect(action)
	parent.add_child(button)
	return button

func _rebuild() -> void:
	if not rpg.can_loot_monster(corpse):
		close()
		return
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	_label(body,str(corpse.get("name","Defeated creature")),23).add_theme_color_override("font_color",Color("e9d6a8"))
	_label(body,"Backpack %d / %d slots" % [rpg.backpack.slots.size(),rpg.backpack.capacity],13)
	_label(body,message,14)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(536,210)
	body.add_child(scroll)
	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation",8)
	scroll.add_child(rows)
	if int(corpse.get("scrap",0)) > 0:
		var row := HBoxContainer.new()
		rows.add_child(row)
		_label(row,"Scrap ×%d" % int(corpse.scrap))
		_button(row,"Take scrap",func(): rpg.claim_monster_scrap(corpse); message = "Scrap claimed."; _rebuild())
	for index in range(corpse.items.size()):
		var entry: Dictionary = corpse.items[index]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		rows.add_child(row)
		var icon := TextureRect.new()
		icon.texture = Icons.get_icon(str(entry.id))
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40,40)
		row.add_child(icon)
		_label(row,"%s ×%d" % [rpg.items[entry.id].name,entry.count])
		var take := _button(row,"Take",func():
			message = "Item claimed." if rpg.claim_monster_item(corpse,index) else "Backpack full. This item is still on the body."
			_rebuild())
		take.tooltip_text = rpg._tooltip(str(entry.id))
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation",12)
	body.add_child(footer)
	_button(footer,"Take all that fits",func(): rpg.claim_all_monster_loot(corpse); message = "Claimed what fits. Remaining items stay here."; _rebuild())
	_button(footer,"Leave / Close",close)

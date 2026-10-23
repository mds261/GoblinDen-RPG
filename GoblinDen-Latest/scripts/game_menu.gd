extends CanvasLayer
## Pause and reference controls live here, outside the playfield.
var game: Node2D
var overlay: ColorRect
var content: VBoxContainer
var controls_visible := false
var audio_visible := false
func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	overlay = ColorRect.new()
	overlay.color = Color(0.012,0.02,0.017,0.84)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	var panel := PanelContainer.new()
	panel.position = Vector2(256,90)
	panel.size = Vector2(640,540)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("111b17")
	style.border_color = Color("8a744c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel",style)
	overlay.add_child(panel)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	panel.add_child(content)
	overlay.hide()
func _input(event: InputEvent) -> void:
	if overlay.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		if game.codex_panel.visible:
			game.codex_panel.hide()
		elif game.rpg == null or not game.rpg.input_blocked():
			open()
		get_viewport().set_input_as_handled()
func open() -> void:
	if get_tree().paused:
		return
	if game.rpg != null and game.rpg.dialogue.visible:
		return
	controls_visible = false
	audio_visible = false
	_rebuild()
	overlay.show()
	get_tree().paused = true
func close() -> void:
	overlay.hide()
	get_tree().paused = false
func _exit_tree() -> void:
	if is_instance_valid(overlay) and overlay.visible:
		get_tree().paused = false
func _label(text: String, size_px: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size_px)
	label.add_theme_color_override("font_color",color)
	content.add_child(label)
func _button(text: String, action: Callable) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 36
	button.pressed.connect(action)
	content.add_child(button)
func _rebuild() -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	_label("AUDIO" if audio_visible else ("FIELD GUIDE" if controls_visible else "GOBLIN DEN"),26,Color("e7d7b0"))
	_label("Music & sound effects" if audio_visible else ("Controls & training" if controls_visible else "A moment by the fire"),14,Color("a7b19b"))
	if audio_visible:
		_label("Adjust the soundtrack and world sounds separately. Set either slider to zero to mute it.",15,Color("ded9c8"))
		_audio_slider("Music",game.audio_system.music_level,game.audio_system.set_music_volume)
		_audio_slider("Sound effects",game.audio_system.effects_level,game.audio_system.set_effects_volume)
		_button("Test sound effects",func(): game.audio_system.play_sfx("interact"))
		_button("Restore default volumes",func(): game.audio_system.set_music_volume(0.35); game.audio_system.set_effects_volume(0.75); _rebuild())
		_button("Back",func(): audio_visible = false; _rebuild())
	elif controls_visible:
		_label("TRAVEL & COMBAT",12,Color("ba9a61"))
		_label("WASD                    Move\nMouse                  Aim\nLeft click / Space   Attack\nRight click / Q       Class special\nShift                     Dodge\nF                           Drink potion",15,Color("ded9c8"))
		_label("DEN ROUTES · Treasure north, armory south, daylight east. The Rootvein nest is optional.",13,Color("a7b19b"))
		_label("YOUR GOBLIN",12,Color("ba9a61"))
		_label("E  ·  Nearby interaction     I  ·  Backpack & equipment\n1–4  ·  Class     C  ·  Evolution     Tab  ·  Codex\nM  ·  Map     Enter  ·  Journal/chat     Esc  ·  Menu",14,Color("ded9c8"))
		_label("Assigned spells use the keys in the action belt. Change spell assignments and keys in your backpack. The Training Pit unlocks class evolutions.",13,Color("a7b19b"))
		_button("Back",func(): controls_visible = false; _rebuild())
	else:
		_label("%s  ·  Level %d\n%d scrap  ·  %d potions  ·  %d companions" % [game.player.get_class_title(),game.player.level,game.scrap,game.potions,game.active_companion_count()],16,Color("ded9c8"))
		_button("Resume",close)
		_button("Controls & training",func(): controls_visible = true; _rebuild())
		_button("Audio",func(): audio_visible = true; _rebuild())
		_button("Backpack & equipment",func(): close(); game.rpg.panel.show(); game.rpg._refresh_panel())
		_button("Tribe codex",func(): close(); game.codex_panel.show(); game._refresh_codex_text())
		_label("Progress saves automatically. Press Esc to return to the world.",13,Color("a7b19b"))


func _audio_slider(title: String, initial: float, setter: Callable) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation",16)
	content.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 120
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = initial*100
	slider.custom_minimum_size = Vector2(330,36)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(slider)
	var readout := Label.new()
	readout.text = "%d%%" % int(slider.value)
	readout.custom_minimum_size.x = 44
	row.add_child(readout)
	slider.value_changed.connect(func(value): setter.call(value/100.0); readout.text = "%d%%" % int(value))

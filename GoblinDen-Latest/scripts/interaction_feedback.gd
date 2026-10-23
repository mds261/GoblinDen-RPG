extends Node2D
## One focus resolver drives both the prompt and E activation.
const Starting = preload("res://scripts/starting_caves.gd")
const Den = preload("res://scripts/den_layout.gd")
var game: Node2D
var focus: Dictionary = {}
var prompt: PanelContainer
var label: Label
var pulse := 0.0
var activation_cooldown := 0.0

func _ready() -> void:
	game = get_parent()
	z_as_relative = false
	z_index = 3950
	var layer := CanvasLayer.new()
	layer.layer = 7
	add_child(layer)
	prompt = PanelContainer.new()
	prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.045, 0.035, 0.95)
	style.border_color = Color("bca16a")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 9
	style.content_margin_bottom = 9
	prompt.add_theme_stylebox_override("panel", style)
	layer.add_child(prompt)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color("f1dfb3"))
	prompt.add_child(label)
	prompt.hide()

func blocked() -> bool:
	return game.player.hp <= 0 or game.rpg.input_blocked() or game.codex_panel.visible or get_tree().paused

func choose(candidates: Array) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := INF
	for candidate in candidates:
		var d: float = game.player.position.distance_to(candidate.point)
		if d >= float(candidate.radius) or d >= distance:
			continue
		# Stop before the object's footprint, so a chest doesn't occlude itself.
		var end: Vector2 = candidate.point.move_toward(game.player.position, minf(38.0, d))
		var ray := PhysicsRayQueryParameters2D.create(game.player.global_position, end, 1)
		if d > 38.0 and not game.get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		nearest = candidate
		distance = d
	return nearest

func candidates() -> Array:
	var options: Array = game.rpg.interaction_candidates()
	for station in Den.STATIONS:
		if int(station.room) == game.current_room:
			var title: String = game._legacy_contextual_hint()
			if title.begins_with("E  "):
				title = title.trim_prefix("E  ").split("  •  ")[0]
			else:
				title = str(station.title).trim_prefix("E  ").capitalize()
			options.append({"point": station.pos, "radius": 85.0 if int(station.cell) in [0,1,7] else 80.0, "label": title, "action": game._interact_legacy})
	for portal in Den.PORTALS.get(game.current_room, []):
		options.append({"point": portal.pos, "radius": 75.0, "label": "Enter " + str(portal.title).capitalize(), "action": game.enter_room.bind(int(portal.to), portal.spawn)})
	if game.current_room == game.EXPANSE_ROOM_INDEX:
		for entry in game.EXPANSE_INTERACTIONS:
			if not game.used_expanse_interactions.has(entry.id):
				options.append({"point": entry.pos, "radius": 92.0, "label": str(entry.name), "action": game._interact_legacy})
	if game.current_room==0:
		options.append({"point":Starting.EXIT,"radius":100.0,"label":"Step outside to Thornwood Hollow","action":game._interact_legacy})
	if game.current_room > 0 and game.current_room <= game.EXPANSE_ROOM_INDEX:
		options.append({"point": game._left_gate_position(), "radius": 75.0, "label": "Return to the connected den" if game.current_room==5 else "Return to " + str(game.ROOM_NAMES[game.current_room - 1]), "action": game._interact_legacy})
	if game.current_room > 0 and game.current_room < game.EXPANSE_ROOM_INDEX:
		var locked: bool = game.living_enemies() > 0 and game.current_room!=5
		options.append({"point": game._right_gate_position(), "radius": 75.0, "label": "Defeat the enemies to open this passage" if locked else "Enter " + str(game.ROOM_NAMES[game.current_room + 1]), "ready": not locked, "action": game._interact_legacy})
	return options

func activate() -> bool:
	if blocked() or activation_cooldown > 0.0:
		return false
	focus = choose(candidates())
	if focus.is_empty():
		return false
	activation_cooldown = 0.18
	pulse = 0.25
	focus.action.call()
	get_tree().call_group("combat_feedback", "play_cue", "interact")
	return true

func _process(delta: float) -> void:
	activation_cooldown = maxf(0.0, activation_cooldown - delta)
	pulse = maxf(0.0, pulse - delta)
	focus = {} if blocked() else choose(candidates())
	prompt.visible = not focus.is_empty()
	if not focus.is_empty():
		label.text = ("[E]  " if bool(focus.get("ready", true)) else "•  ") + str(focus.label)
		label.modulate = Color.WHITE if bool(focus.get("ready", true)) else Color("bdb7a3")
		prompt.reset_size()
		var viewport_size := get_viewport_rect().size
		prompt.position = Vector2((viewport_size.x - prompt.size.x) * 0.5, viewport_size.y - 125.0)
	queue_redraw()

func _draw() -> void:
	if focus.is_empty():
		return
	var color := Color("e6c98a") if bool(focus.get("ready", true)) else Color("9c9582")
	color.a = 0.8
	var point: Vector2 = focus.point
	draw_arc(point, 30.0 + pulse * 16.0, 0, TAU, 40, color, 2.0, true)
	for direction in [Vector2.LEFT, Vector2.RIGHT]:
		draw_line(point + direction * 38 + Vector2(0,-6), point + direction * 32, color, 2, true)
		draw_line(point + direction * 32, point + direction * 38 + Vector2(0,6), color, 2, true)

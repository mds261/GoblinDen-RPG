extends CharacterBody2D
## Friendly noncombat characters reuse the game's directional goblin atlases.
const Appearance = preload("res://scripts/directional_actor.gd")
var definition: Dictionary = {}
var appearance = Appearance.new()
var game: Node2D
var elapsed := 0.0
var home := Vector2.ZERO
var destination := Vector2.ZERO
var wait_time := 0.0
var walk_time := 0.0
var rng := RandomNumberGenerator.new()
const ROAM_RADIUS := 88.0
const WALK_SPEED := 38.0

func _ready() -> void:
	add_to_group("friendly_npcs")
	rng.randomize()
	home = position
	destination = home
	wait_time = rng.randf_range(2.0,6.0)
	collision_layer = 0
	collision_mask = 1
	var body := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 12.0
	body.shape = shape
	add_child(body)
	appearance.configure(str(definition.get("class", "blade")), str(definition.get("evolution", "")))
	appearance.direction = "down"

func _process(delta: float) -> void:
	elapsed += delta
	z_index = int(position.y)
	if game != null:
		var offset: Vector2 = game.player.global_position - global_position
		if offset.length() < 160 and velocity.length() < 1.0:
			appearance.select_direction(offset.normalized() * 10.0)
	appearance.update(delta, velocity, true)
	queue_redraw()

func set_collision_active(_active: bool) -> void:
	# Friendly actors avoid scenery but never obstruct the player or combatants.
	collision_layer = 0
	collision_mask = 1
	velocity = Vector2.ZERO
	destination = position
	wait_time = rng.randf_range(2.0,6.0)

func _physics_process(delta: float) -> void:
	velocity = Vector2.ZERO
	if game == null or game.current_room != int(definition.get("room",-1)):
		return
	# Stop to greet someone approaching; the service target stays easy to use.
	if game.player.position.distance_to(position) < 108.0:
		destination = position
		wait_time = maxf(wait_time,1.2)
		return
	if position.distance_to(destination) < 5.0 or walk_time <= 0.0:
		wait_time -= delta
		if wait_time <= 0:
			_choose_destination()
		return
	walk_time -= delta
	velocity = position.direction_to(destination)*minf(WALK_SPEED,position.distance_to(destination)/delta)
	var before := position
	move_and_slide()
	if position.distance_to(before) < WALK_SPEED*delta*0.2:
		destination = position
		wait_time = rng.randf_range(2.5,6.5)
		velocity = Vector2.ZERO

func _choose_destination() -> bool:
	wait_time = rng.randf_range(3.0,7.0)
	var space := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = 14.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.collision_mask = 1
	var bounds: Vector2 = game.get_node("Cave").world_size_for_room()
	for attempt in range(16):
		var point := home+Vector2.from_angle(rng.randf()*TAU)*rng.randf_range(28.0,ROAM_RADIUS)
		if point.x < 106 or point.y < 126 or point.x > bounds.x-106 or point.y > bounds.y-106 or point.distance_to(position)<22:
			continue
		var crowded := false
		for npc in get_tree().get_nodes_in_group("friendly_npcs"):
			if npc != self and npc.is_visible_in_tree() and npc.position.distance_to(point)<44:
				crowded = true
		if crowded:
			continue
		query.transform = Transform2D(0,point)
		query.motion = Vector2.ZERO
		if not space.intersect_shape(query).is_empty():
			continue
		query.transform = Transform2D(0,position)
		query.motion = point-position
		var sweep := space.cast_motion(query)
		if sweep[0] < 0.999:
			continue
		destination = point
		walk_time = 6.0
		return true
	destination = position
	return false

func _draw() -> void:
	appearance.draw_actor(self, 78.0, false, false, false, false)
	# Small breathing motion, a friendly ground marker and a readable nearby name.
	var pulse := 0.5 + 0.15 * sin(elapsed * 2.2)
	draw_arc(Vector2(0, 12), 22, 0, TAU, 32, Color(0.55, 0.85, 0.65, pulse), 1.5, true)
	if game != null and game.player.global_position.distance_to(global_position) < 175:
		var title: String = str(definition.get("name", "Traveler"))
		var font := ThemeDB.fallback_font
		var width := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
		draw_style_box(_name_style(), Rect2(-width / 2 - 8, -85, width + 16, 24))
		draw_string(font, Vector2(-width / 2, -68), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("d9edbe"))

func _name_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.025, 0.88)
	style.set_corner_radius_all(3)
	return style

extends Node2D
## Painted backdrop, physical perimeter, shadow ambush alcoves, and optional
## cave chokepoint pillars for higher raid campaigns (Sections 3 & 8).

const BACKGROUND = preload("res://assets/cave.png")
const ROOTVEIN_BACKGROUND = preload("res://assets/cave_rootvein_grotto.png")
const CAVE_MOUTH_BACKGROUND = preload("res://assets/cave_mouth.png")
const THORNWOOD_BACKGROUND = preload("res://assets/thornwood_hollow.png")
const THORNWOOD_EXPANSE_BACKGROUND = preload("res://assets/thornwood_expanse.png")
const BACKGROUNDS: Array[Texture2D] = [
	BACKGROUND, BACKGROUND, BACKGROUND,
	ROOTVEIN_BACKGROUND, CAVE_MOUTH_BACKGROUND, THORNWOOD_BACKGROUND,
	THORNWOOD_EXPANSE_BACKGROUND,
	preload("res://assets/den_treasury.png"),
	preload("res://assets/den_armory.png"),
	preload("res://assets/den_strategy.png")
]
const ROOM_TINTS: Array[Color] = [
	Color(1.0, 0.97, 0.88), Color(0.82, 0.91, 1.0), Color(1.0, 0.84, 0.82),
	Color(0.88, 1.0, 0.94), Color(1.0, 1.0, 0.98), Color(1.0, 1.0, 1.0),
	Color(1.0, 1.0, 1.0), Color.WHITE, Color.WHITE, Color.WHITE
]
const STANDARD_WORLD_SIZE := Vector2(1152, 720)
const EXPANSE_WORLD_SIZE := Vector2(2304, 1440)
const EXPANSE_ROOM_INDEX := 6
const PERIMETER_THICKNESS := 80.0
const DenLayout = preload("res://scripts/den_layout.gd")
const ExpanseGeometry = preload("res://scripts/expanse_geometry.gd")
var expanse_obstacle_polygons: Array[PackedVector2Array] = ExpanseGeometry.polygons()
var navigation_obstacles: Array[PackedVector2Array] = []
var bridge_navigation_obstacles: Array[PackedVector2Array] = []
var debug_collision_overlay := false
const SHADOW_POOLS: Array[Rect2] = [
	Rect2(250, 118, 220, 56),
	Rect2(680, 118, 220, 56),
	Rect2(260, 548, 220, 56),
	Rect2(680, 548, 220, 56)
]
const CHOKEPOINT_PILLARS: Array[Rect2] = [
	Rect2(470, 210, 54, 90),
	Rect2(470, 420, 54, 90)
]
const TORCH_POINTS: Array[Vector2] = [
	Vector2(35, 285), Vector2(1118, 285), Vector2(180, 55), Vector2(970, 48)
]

var navigation := AStarGrid2D.new()
var room_index: int = 0
var time: float = 0.0
var chokepoints_active: bool = false
var pillar_bodies: Array[StaticBody2D] = []
var perimeter_bodies: Array[StaticBody2D] = []
var expanse_obstacle_bodies: Array[StaticBody2D] = []

func _ready() -> void:
	z_index = -1
	_configure_world_perimeter(STANDARD_WORLD_SIZE)
	for rect in CHOKEPOINT_PILLARS:
		var pillar := StaticBody2D.new()
		pillar.collision_layer = 0
		pillar.collision_mask = 0
		pillar.position = rect.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		collision.shape = shape
		pillar.add_child(collision)
		add_child(pillar)
		pillar_bodies.append(pillar)
	_create_expanse_obstacles()
	_set_expanse_obstacles_active(false)

func _create_expanse_obstacles() -> void:
	for index in range(expanse_obstacle_polygons.size()):
		var body := StaticBody2D.new()
		body.name = "ExpanseObstacle%d" % index
		var collision := CollisionPolygon2D.new()
		collision.polygon = expanse_obstacle_polygons[index]
		body.add_child(collision)
		add_child(body)
		expanse_obstacle_bodies.append(body)

func _set_expanse_obstacles_active(active: bool) -> void:
	for body in expanse_obstacle_bodies:
		body.collision_layer = 1 if active else 0
		body.collision_mask = 2 if active else 0

func _configure_world_perimeter(world_size: Vector2) -> void:
	for body in perimeter_bodies:
		if is_instance_valid(body):
			body.queue_free()
	perimeter_bodies.clear()
	var floor_bounds := Rect2(Vector2.ONE * PERIMETER_THICKNESS, world_size - Vector2.ONE * PERIMETER_THICKNESS * 2.0)
	if room_index in [DenLayout.TREASURY, DenLayout.ARMORY, DenLayout.STRATEGY]:
		floor_bounds = DenLayout.ROOM_FLOOR
	var walls: Array[Rect2] = [
		Rect2(0, 0, world_size.x, floor_bounds.position.y),
		Rect2(0, floor_bounds.end.y, world_size.x, world_size.y - floor_bounds.end.y),
		Rect2(0, floor_bounds.position.y, floor_bounds.position.x, floor_bounds.size.y),
		Rect2(floor_bounds.end.x, floor_bounds.position.y, world_size.x - floor_bounds.end.x, floor_bounds.size.y)
	]
	for rectangle in walls:
		var wall := StaticBody2D.new()
		wall.collision_layer = 1
		wall.collision_mask = 2
		wall.position = rectangle.get_center()
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = rectangle.size
		collision.shape = shape
		wall.add_child(collision)
		add_child(wall)
		perimeter_bodies.append(wall)

func configure_room(index: int) -> void:
	room_index = index
	_configure_world_perimeter(EXPANSE_WORLD_SIZE if room_index == EXPANSE_ROOM_INDEX else STANDARD_WORLD_SIZE)
	_set_expanse_obstacles_active(room_index == EXPANSE_ROOM_INDEX)
	_rebuild_navigation()
	queue_redraw()

func update_chokepoints(active: bool) -> void:
	chokepoints_active = active and room_index > 0 and room_index <= 2
	for pillar in pillar_bodies:
		pillar.collision_layer = 1 if chokepoints_active else 0
		pillar.collision_mask = 2 if chokepoints_active else 0
	_rebuild_navigation()
	queue_redraw()

func is_in_shadow_pool(world_point: Vector2) -> bool:
	if room_index == 0 or room_index > 2:
		return false
	for pool in SHADOW_POOLS:
		if pool.has_point(world_point):
			return true
	return false

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var safe_index := clampi(room_index, 0, BACKGROUNDS.size() - 1)
	var world_size := EXPANSE_WORLD_SIZE if room_index == EXPANSE_ROOM_INDEX else STANDARD_WORLD_SIZE
	draw_texture_rect(BACKGROUNDS[safe_index], Rect2(Vector2.ZERO, world_size), false, ROOM_TINTS[safe_index])
	# Shadow ambush alcoves in combat rooms (Section 3: win through darkness & ambushes)
	if room_index > 0 and room_index <= 2:
		for pool in SHADOW_POOLS:
			draw_rect(pool, Color(0.02, 0.03, 0.04, 0.42))
			draw_rect(pool, Color(0.38, 0.56, 0.48, 0.18), false, 1.5)
			draw_string(ThemeDB.fallback_font, pool.position + Vector2(62, 33), "SHADOW AMBUSH", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.58, 0.78, 0.68, 0.45))
	if chokepoints_active:
		for rect in CHOKEPOINT_PILLARS:
			draw_rect(rect.grow(4.0), Color(0.02, 0.02, 0.02, 0.55))
			draw_rect(rect, Color("3b3632"))
			draw_rect(rect.grow(-5.0), Color("524b44"))
			draw_rect(rect, Color("6e6459"), false, 2.0)
			# Faceted stone edges keep the collision silhouette readable.
			draw_colored_polygon(PackedVector2Array([rect.position, rect.position + Vector2(rect.size.x, 0), rect.position + Vector2(rect.size.x - 8, 10), rect.position + Vector2(8, 10)]), Color("847461"))
			draw_line(rect.position + Vector2(18, 10), rect.position + Vector2(27, 34), Color("302a25"), 2.0, true)
			draw_line(rect.position + Vector2(27, 34), rect.position + Vector2(14, 49), Color("302a25"), 2.0, true)
			draw_line(rect.position + Vector2(27, 34), rect.position + Vector2(39, 38), Color("302a25"), 2.0, true)
	# Subtle moving torch halos over the baked painterly lighting.
	for point in TORCH_POINTS:
		var flicker := 0.7 + 0.15 * sin(time * 7.0 + point.x) + 0.1 * sin(time * 13.0)
		for ring in range(5):
			draw_circle(point, 22.0 + ring * 10.0, Color(0.95, 0.47, 0.12, 0.012 * flicker))
	_draw_ambient_particles()
	if debug_collision_overlay and room_index == EXPANSE_ROOM_INDEX:
		for polygon in expanse_obstacle_polygons:
			draw_colored_polygon(polygon, Color(0.9, 0.1, 0.12, 0.28))
			var outline := polygon.duplicate()
			outline.append(polygon[0])
			draw_polyline(outline, Color(1.0, 0.5, 0.3, 0.8), 3.0, true)

## Layered ambient cave atmosphere: drifting dust motes, rising torch embers,
## slow fog wisps, and (in combat rooms) cold ceiling drips.
## Everything is deterministic + cheap, drawn at z_index -1 so it can never
## obscure actors, health bars, or the interaction markers.
func _draw_ambient_particles() -> void:
	if room_index in [5, EXPANSE_ROOM_INDEX]:
		_draw_outdoor_ambience()
		return
	# --- Layer 1: slow fog wisps (far depth, very low alpha) ---
	for index in range(7):
		var phase := float(index) * 1.7
		var drift := fmod(time * (5.0 + index * 1.3) + phase * 190.0, 1400.0) - 120.0
		var wisp_y := 175.0 + float(index) * 58.0 + sin(time * 0.4 + phase) * 9.0
		var wisp_alpha := 0.028 + 0.014 * sin(time * 0.7 + phase * 2.0)
		var wisp_col := Color(0.62, 0.68, 0.78, maxf(0.0, wisp_alpha))
		for segment in range(4):
			var seg_x := drift + float(segment) * 46.0
			draw_circle(Vector2(seg_x, wisp_y + sin(time * 0.9 + float(segment)) * 4.0),
				34.0 - float(segment) * 3.0, wisp_col)
	# --- Layer 2: drifting dust motes (mid depth) ---
	for index in range(30):
		var seed_x := float(index) * 71.0
		var seed_y := float(index) * 47.0
		var sway := sin(time * 0.8 + float(index) * 0.9) * 7.0
		var point := Vector2(
			90.0 + fmod(seed_x + time * 4.0, 970.0) + sway,
			130.0 + fmod(seed_y - time * 3.0 + 5000.0, 450.0)
		)
		var twinkle := 0.11 + 0.07 * sin(time * 1.6 + float(index))
		var mote_size := 1.1 + fmod(float(index), 3.0) * 0.28
		draw_circle(point, mote_size, Color(0.85, 0.75, 0.52, twinkle))
	# --- Layer 3: rising embers near the wall torches (near depth) ---
	for torch_index in range(4):
		var torch := TORCH_POINTS[torch_index]
		for index in range(6):
			var life := fmod(time * (0.42 + float(index) * 0.07) + float(index) * 0.31 + float(torch_index) * 0.53, 1.0)
			var rise := life * 118.0
			var flick := sin(time * 3.1 + float(index) * 2.2 + float(torch_index)) * (5.0 + life * 9.0)
			var ember := torch + Vector2(flick + float(index) * 3.0 - 8.0, 12.0 - rise)
			var ember_alpha := (1.0 - life) * 0.30
			if ember_alpha <= 0.0:
				continue
			var ember_size := 1.5 * (1.0 - life * 0.55)
			draw_circle(ember, ember_size + 1.6, Color(0.98, 0.52, 0.14, ember_alpha * 0.28))
			draw_circle(ember, ember_size, Color(1.0, 0.78, 0.36, ember_alpha))
	# --- Layer 4: cold ceiling drips in the enclosed cave rooms ---
	if room_index > 0 and room_index < 5:
		for index in range(5):
			var drip_x := 210.0 + float(index) * 178.0
			var cycle := fmod(time * 0.55 + float(index) * 0.37, 1.0)
			var drip_y := 118.0 + cycle * 470.0
			var drip_alpha := (1.0 - cycle) * 0.22
			if drip_alpha <= 0.0:
				continue
			draw_circle(Vector2(drip_x, drip_y), 1.3, Color(0.66, 0.82, 0.92, drip_alpha))
			draw_line(Vector2(drip_x, drip_y - 5.0), Vector2(drip_x, drip_y),
				Color(0.66, 0.82, 0.92, drip_alpha * 0.45), 1.0, true)
			# Faint impact ripple where the drip lands
			if cycle > 0.94:
				var ripple := (cycle - 0.94) / 0.06
				draw_arc(Vector2(drip_x, 590.0), 3.0 + ripple * 9.0, 0, TAU, 12,
					Color(0.66, 0.82, 0.92, (1.0 - ripple) * 0.16), 1.0, true)
	# Rootvein spores and cave-mouth sun dust make the new chambers feel distinct.
	if room_index == 3:
		for index in range(18):
			var phase := float(index) * 1.41
			var spore := Vector2(110.0 + fmod(float(index) * 79.0 + time * 7.0, 930.0),
				160.0 + fmod(float(index) * 53.0 - time * 5.0 + 2000.0, 400.0))
			var glow := 0.18 + 0.10 * sin(time * 1.8 + phase)
			draw_circle(spore, 2.1, Color(0.30, 0.95, 0.78, glow * 0.35))
			draw_circle(spore, 0.9, Color(0.66, 1.0, 0.90, glow))
	elif room_index == 4:
		for index in range(14):
			var ray_dust := Vector2(650.0 + fmod(float(index) * 43.0 + time * 9.0, 390.0),
				120.0 + fmod(float(index) * 67.0 + time * 3.0, 390.0))
			draw_circle(ray_dust, 1.4, Color(1.0, 0.92, 0.62, 0.18))

func _draw_outdoor_ambience() -> void:
	var world_size := EXPANSE_WORLD_SIZE if room_index == EXPANSE_ROOM_INDEX else STANDARD_WORLD_SIZE
	# Fireflies hug the shaded lower edge while windblown leaves cross the clearing.
	var firefly_count := 34 if room_index == EXPANSE_ROOM_INDEX else 16
	for index in range(firefly_count):
		var phase := float(index) * 1.73
		var firefly := Vector2(90.0 + fmod(float(index) * 137.0, world_size.x - 180.0),
			world_size.y * 0.58 + fmod(float(index) * 61.0, world_size.y * 0.28) + sin(time * 0.9 + phase) * 12.0)
		var pulse := 0.12 + 0.16 * maxf(0.0, sin(time * 2.1 + phase))
		draw_circle(firefly, 3.8, Color(0.82, 1.0, 0.38, pulse * 0.18))
		draw_circle(firefly, 1.1, Color(0.92, 1.0, 0.58, pulse))
	var leaf_count := 22 if room_index == EXPANSE_ROOM_INDEX else 10
	for index in range(leaf_count):
		var travel := fmod(time * (24.0 + float(index) * 2.0) + float(index) * 137.0, world_size.x + 180.0) - 90.0
		var leaf := Vector2(travel, 155.0 + fmod(float(index) * 67.0, world_size.y * 0.68) + sin(time * 1.5 + float(index)) * 22.0)
		var leaf_color := Color(0.45, 0.30 + float(index % 3) * 0.06, 0.10, 0.32)
		draw_colored_polygon(PackedVector2Array([
			leaf + Vector2(-3, 0), leaf + Vector2(0, -1.8), leaf + Vector2(3, 0), leaf + Vector2(0, 1.8)
		]), leaf_color)

func _rebuild_navigation() -> void:
	var world_size := EXPANSE_WORLD_SIZE if room_index == EXPANSE_ROOM_INDEX else STANDARD_WORLD_SIZE
	var columns := int(world_size.x / 24.0)
	var rows := int(world_size.y / 24.0)
	navigation.region = Rect2i(0, 0, columns, rows)
	navigation.cell_size = Vector2(24, 24)
	navigation.offset = Vector2(12, 12)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	navigation.update()
	navigation_obstacles.clear()
	bridge_navigation_obstacles.clear()
	if room_index == EXPANSE_ROOM_INDEX:
		for polygon in expanse_obstacle_polygons:
			# Actor radius 15 + cell half-diagonal 17: corner-safe pathfinding.
			navigation_obstacles.append_array(Geometry2D.offset_polygon(polygon, 32.0))
			# The narrow bridge needs body-sized clearance instead of full-cell padding.
			bridge_navigation_obstacles.append_array(Geometry2D.offset_polygon(polygon, 18.0))
	for station in DenLayout.STATIONS:
		if station["room"] == room_index:
			var rect: Rect2 = DenLayout.footprint(station["cell"]).grow(32.0)
			navigation_obstacles.append(PackedVector2Array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]))
	for y in range(rows):
		for x in range(columns):
			var point := Vector2(x * 24 + 12, y * 24 + 12)
			var blocked := point.x < 106 or point.x > world_size.x - 106 or point.y < 126 or point.y > world_size.y - 126
			if room_index in [DenLayout.TREASURY, DenLayout.ARMORY, DenLayout.STRATEGY]:
				blocked = blocked or not DenLayout.ROOM_FLOOR.grow(-32.0).has_point(point)
			var near_bridge := room_index == EXPANSE_ROOM_INDEX and Rect2(900, 525, 270, 110).has_point(point * ExpanseGeometry.SOURCE_SIZE / EXPANSE_WORLD_SIZE)
			var obstacles := bridge_navigation_obstacles if near_bridge else navigation_obstacles
			for polygon in obstacles:
				if Geometry2D.is_point_in_polygon(point, polygon):
					blocked = true
					break
			if chokepoints_active:
				for pillar in CHOKEPOINT_PILLARS:
					blocked = blocked or pillar.grow(25.0).has_point(point)
			navigation.set_point_solid(Vector2i(x, y), blocked)

func route_direction(origin: Vector2, destination: Vector2) -> Vector2:
	if navigation.is_dirty():
		_rebuild_navigation()
	var start := _nearest_open_cell(origin)
	var goal := _nearest_open_cell(destination)
	if start == goal:
		return origin.direction_to(destination)
	var path := navigation.get_point_path(start, goal)
	if path.size() > 1:
		return origin.direction_to(path[1])
	return Vector2.ZERO

func _nearest_open_cell(point: Vector2) -> Vector2i:
	var world_size := EXPANSE_WORLD_SIZE if room_index == EXPANSE_ROOM_INDEX else STANDARD_WORLD_SIZE
	var max_x := int(world_size.x / 24.0) - 5
	var max_y := int(world_size.y / 24.0) - 5
	var cell := Vector2i(clampi(int(point.x / 24), 4, max_x), clampi(int(point.y / 24), 5, max_y))
	if not navigation.is_point_solid(cell):
		return cell
	var best := Vector2i(5, 6)
	var distance := INF
	for y in range(5, max_y + 1):
		for x in range(4, max_x + 1):
			var candidate := Vector2i(x, y)
			if not navigation.is_point_solid(candidate):
				var d := Vector2(candidate).distance_squared_to(Vector2(cell))
				if d < distance:
					distance = d
					best = candidate
	return best

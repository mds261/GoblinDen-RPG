extends Node2D
## Renders all eight den facilities from two hand-painted sprite sheets.

const CORE_ART = preload("res://assets/den_props.png")
const STATION_ART = preload("res://assets/den_stations_v2.png")
const CELL_SIZE := Vector2(512, 512)

const DenLayout = preload("res://scripts/den_layout.gd")
var obstacle: StaticBody2D
var cell: int = 0
var time: float = 0.0

func _ready() -> void:
	z_index = int(position.y)
	obstacle = StaticBody2D.new()
	obstacle.collision_layer = 0
	obstacle.collision_mask = 2
	var collision := CollisionShape2D.new()
	var footprint: Rect2 = DenLayout.footprint(cell)
	var shape := RectangleShape2D.new()
	shape.size = footprint.size
	collision.shape = shape
	collision.position = footprint.get_center() - DenLayout.station_position(cell)
	obstacle.add_child(collision)
	add_child(obstacle)

func set_collision_active(active: bool) -> void:
	if is_instance_valid(obstacle):
		obstacle.collision_layer = 1 if active else 0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if cell == 0 or cell == 1:
		_draw_core_station()
	else:
		_draw_expanded_station()

func _draw_core_station() -> void:
	var width := 170.0 if cell == 0 else 125.0
	var source := Rect2(CORE_ART.get_width() * 0.5 * cell, 0, CORE_ART.get_width() * 0.5, CORE_ART.get_height())
	var height := width * source.size.y / source.size.x
	var flame := Vector2(-12, -30) if cell == 0 else Vector2(0, -16)
	for ring in range(5):
		draw_circle(flame, 25.0 + ring * 12.0, Color(1.0, 0.4, 0.08, 0.018 + 0.004 * sin(time * 9.0)))
	draw_texture_rect_region(CORE_ART, Rect2(-width / 2, -height * 0.75, width, height), source)
	for index in range(7):
		var age := fmod(time * 0.5 + index * 0.13, 1.0)
		var point := flame + Vector2(sin(index * 12.0 + age * 3.0) * 14.0, -age * 55.0)
		draw_circle(point, 1.2, Color(1.0, 0.65, 0.23, (1.0 - age) * 0.65))

func _draw_expanded_station() -> void:
	var atlas_index := cell - 2
	var column := atlas_index % 3
	var row: int = int(atlas_index / 3)
	var source := Rect2(Vector2(column, row) * CELL_SIZE, CELL_SIZE)
	var widths := [156.0, 164.0, 154.0, 154.0, 158.0, 166.0]
	var width: float = widths[clampi(atlas_index, 0, widths.size() - 1)]
	var height := width

	# Soft contact shadow keeps the new stations grounded in the cave floor.
	draw_set_transform(Vector2(0, 8), 0.0, Vector2(1.35, 0.42))
	draw_circle(Vector2.ZERO, width * 0.31, Color(0.01, 0.012, 0.01, 0.48))
	draw_set_transform(Vector2.ZERO)

	# Local light breathes gently without altering the painted artwork.
	var glow_color := _station_glow_color()
	if glow_color.a > 0.0:
		for ring in range(4):
			draw_circle(_glow_origin(), 18.0 + ring * 11.0, Color(glow_color.r, glow_color.g, glow_color.b, glow_color.a * (1.0 - ring * 0.18)))

	draw_texture_rect_region(STATION_ART, Rect2(-width * 0.5, -height * 0.80, width, height), source)
	_draw_station_particles()

func _station_glow_color() -> Color:
	match cell:
		4:
			return Color(0.28, 1.0, 0.48, 0.028 + sin(time * 4.0) * 0.006)
		5:
			return Color(1.0, 0.34, 0.08, 0.022 + sin(time * 7.0) * 0.005)
		6:
			return Color(1.0, 0.72, 0.18, 0.022 + sin(time * 5.0) * 0.005)
		7:
			return Color(1.0, 0.46, 0.12, 0.018 + sin(time * 6.0) * 0.004)
	return Color(0, 0, 0, 0)

func _glow_origin() -> Vector2:
	match cell:
		4: return Vector2(4, -40)
		5: return Vector2(0, -27)
		6: return Vector2(3, -28)
		7: return Vector2(12, -24)
	return Vector2.ZERO

func _draw_station_particles() -> void:
	if cell == 4:
		for index in range(6):
			var age := fmod(time * 0.42 + index * 0.17, 1.0)
			var point := Vector2(4 + sin(index * 4.7 + time) * 13.0, -35 - age * 46.0)
			draw_circle(point, 1.4 + (1.0 - age), Color(0.38, 1.0, 0.56, (1.0 - age) * 0.72))
	elif cell in [5, 7]:
		for index in range(5):
			var age := fmod(time * 0.55 + index * 0.2, 1.0)
			var point := _glow_origin() + Vector2(sin(index * 8.0) * 18.0, -age * 38.0)
			draw_circle(point, 1.2, Color(1.0, 0.56, 0.18, (1.0 - age) * 0.58))
	elif cell == 6:
		for index in range(5):
			var flicker := 0.45 + 0.45 * sin(time * 4.5 + index * 1.7)
			draw_circle(Vector2(-24 + index * 12, -20 - (index % 2) * 9), 1.5, Color(1.0, 0.88, 0.34, flicker))

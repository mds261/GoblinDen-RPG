extends Node2D
## Visual-only snare impact and lingering thorn cage. No damage or input effects.
var target: Node2D
var duration: float = 2.6
var radius: float = 44.0
var elapsed: float = 0.0

func _ready() -> void:
	z_index = 3000

func _process(delta: float) -> void:
	elapsed += delta
	if is_instance_valid(target) and target.hp > 0:
		global_position = target.global_position
	else:
		queue_free()
		return
	if elapsed >= duration:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var fade := clampf((duration - elapsed) / 0.4, 0.0, 1.0)
	var reveal := clampf(elapsed / 0.18, 0.0, 1.0)
	var impact := clampf(1.0 - elapsed / 0.65, 0.0, 1.0)
	var spring := 1.0 - pow(1.0 - reveal, 3.0)
	# Soft green underlight, with a sharp gold shock ring at the instant of capture.
	for ring in range(5):
		draw_circle(Vector2(0, 7), radius * (0.6 + ring * 0.14), Color(0.15, 0.9, 0.35, fade * 0.025))
	if impact > 0:
		draw_arc(Vector2.ZERO, radius * (1.0 + (1.0 - impact) * 1.4), 0, TAU, 64, Color(1.0, 0.86, 0.4, impact * 0.9), 4.0 * impact, true)
		for index in range(18):
			var direction := Vector2.from_angle(index * TAU / 18.0)
			var point := direction * radius * (0.8 + (1.0 - impact) * 1.7)
			draw_line(point, point + direction * (5 + 16 * impact), Color(0.8, 1, 0.45, impact), 2, true)
	# Six thorned roots rise from the ground and curl around the caught actor.
	for index in range(6):
		var angle := index * TAU / 6.0
		var base := Vector2(cos(angle) * radius * 0.65, sin(angle) * radius * 0.22 + 12)
		var points := PackedVector2Array()
		for step in range(17):
			var t := step / 16.0
			var curl := angle + t * 1.25 + sin(elapsed * 3 + index) * 0.06
			var width := radius * (0.65 - t * 0.35)
			points.append(Vector2(cos(curl) * width, 12 + sin(curl) * width * 0.3 - sin(t * PI * 0.55) * radius * 1.2 * spring))
		draw_polyline(points, Color(0.035, 0.13, 0.07, fade), 7, true)
		draw_polyline(points, Color(0.35, 0.78, 0.30, fade), 3.5, true)
		for thorn in [5, 9, 13]:
			var point: Vector2 = points[thorn]
			var tip := point + Vector2(8 if index % 2 == 0 else -8, -6) * spring
			draw_colored_polygon(PackedVector2Array([point + Vector2(-2, 3), tip, point + Vector2(2, -3)]), Color(0.85, 1, 0.52, fade))
	# Small motes wind upward through the cage for the remaining slow duration.
	for index in range(12):
		var phase := fmod(elapsed * 0.8 + index * 0.083, 1.0)
		var angle := index * 2.4 + elapsed * 2
		var point := Vector2(cos(angle) * radius * 0.45, 8 - phase * radius * 1.4)
		draw_circle(point, 1.5 + impact, Color(0.7, 1, 0.45, fade * sin(phase * PI)))

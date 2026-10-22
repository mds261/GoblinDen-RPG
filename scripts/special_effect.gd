extends Node2D
## Animated, code-native combat art for player and monster signature attacks.

var effect_kind: String = "blade"
var facing := Vector2.RIGHT
var radius: float = 120.0
var duration: float = 0.85
var elapsed: float = 0.0

func setup(kind: String, direction: Vector2, effect_radius: float) -> void:
	effect_kind = kind
	facing = direction.normalized() if direction != Vector2.ZERO else Vector2.RIGHT
	radius = effect_radius
	if kind == "ogre_smash":
		duration = 1.1

func _ready() -> void:
	z_as_relative = false
	z_index = 0
	var accent := preload("res://scripts/special_accent.gd").new()
	accent.source = self
	add_child(accent)

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		queue_free()

func _draw() -> void:
	var p := clampf(elapsed / duration, 0.0, 1.0)
	var fade := pow(1.0 - p, 1.2)
	var bloom := 1.0 - pow(1.0 - p, 3.0)
	_draw_sigils(p, fade)
	p = bloom
	fade *= 0.45
	match effect_kind:
		"blade":
			_draw_blade(p, fade)
		"archer":
			_draw_archer(p, fade)
		"knight":
			_draw_knight(p, fade)
		"mage":
			_draw_mage(p, fade)
		"assassin", "berserker", "hunter", "beastmaster", "warlord", "guardian", "shaman", "warlock", "necromancer":
			_draw_evolved(p, fade)
		"ogre_smash":
			_draw_ogre_smash(p, fade)

func _draw_evolved(p: float, fade: float) -> void:
	match effect_kind:
		"assassin":
			_draw_blade(p, fade)
			for index in range(6):
				var angle := facing.angle() + (float(index) - 2.5) * 0.34
				var tip := Vector2.from_angle(angle) * radius * (0.45 + p * 0.55)
				draw_line(tip - Vector2.from_angle(angle) * 46.0, tip, Color(0.18, 0.08, 0.27, fade), 8.0, true)
				draw_line(tip - Vector2.from_angle(angle) * 42.0, tip, Color(0.45, 1.0, 0.66, fade), 2.0, true)
		"berserker":
			var spin_radius := radius * (0.22 + p * 0.78)
			draw_circle(Vector2.ZERO, spin_radius, Color(0.42, 0.03, 0.02, fade * 0.2))
			for index in range(4):
				var angle := elapsed * 9.0 + float(index) * PI * 0.5
				draw_arc(Vector2.ZERO, spin_radius - index * 9.0, angle, angle + 2.2, 24, Color(1.0, 0.22 + index * 0.08, 0.08, fade * 0.9), 9.0 - index, true)
		"hunter":
			_draw_archer(p, fade)
			var sight := radius * (0.35 + p * 0.45)
			draw_arc(Vector2.ZERO, sight, 0, TAU, 48, Color(1.0, 0.82, 0.24, fade), 4.0, true)
			for axis in [Vector2.RIGHT, Vector2.DOWN]:
				draw_line(-axis * sight * 1.25, axis * sight * 1.25, Color(1.0, 0.92, 0.48, fade * 0.78), 2.0, true)
		"beastmaster":
			_draw_archer(p, fade)
			for claw in range(3):
				var x := (float(claw) - 1.0) * 25.0
				draw_arc(Vector2(x, 4), radius * (0.38 + p * 0.30), -2.15, -0.72, 18, Color(1.0, 0.61, 0.18, fade), 7.0, true)
			for toe in range(4):
				draw_circle(Vector2((float(toe) - 1.5) * 14.0, -42), 6.0 + p * 4.0, Color(0.92, 0.67, 0.28, fade * 0.75))
		"warlord":
			_draw_knight(p, fade)
			for index in range(12):
				var ray := Vector2.from_angle(TAU * float(index) / 12.0)
				draw_line(ray * 48.0, ray * radius * (0.62 + p * 0.38), Color(1.0, 0.56, 0.12, fade * 0.88), 5.0, true)
		"guardian":
			_draw_knight(p, fade)
			var dome_radius := radius * (0.3 + p * 0.7)
			draw_arc(Vector2.ZERO, dome_radius, PI, TAU, 40, Color(0.55, 0.93, 1.0, fade), 10.0, true)
			draw_circle(Vector2.ZERO, dome_radius, Color(0.20, 0.68, 1.0, fade * 0.11))
			for index in range(6):
				var a := PI + PI * float(index) / 5.0
				draw_line(Vector2.ZERO, Vector2.from_angle(a) * dome_radius, Color(0.68, 0.92, 1.0, fade * 0.35), 2.0, true)
		"shaman":
			var bloom := radius * (0.18 + p * 0.82)
			draw_circle(Vector2.ZERO, bloom, Color(0.08, 0.52, 0.22, fade * 0.13))
			for index in range(10):
				var a := TAU * float(index) / 10.0 + elapsed * 1.5
				var petal := Vector2.from_angle(a) * bloom * 0.62
				draw_circle(petal, 10.0 + 6.0 * sin(p * PI), Color(0.35, 1.0, 0.54, fade * 0.55))
			draw_arc(Vector2.ZERO, bloom, 0, TAU, 48, Color(0.64, 1.0, 0.60, fade), 5.0, true)
		"warlock":
			var impact := radius * p
			draw_circle(Vector2.ZERO, impact, Color(0.44, 0.04, 0.20, fade * 0.18))
			draw_arc(Vector2.ZERO, impact, 0, TAU, 48, Color(1.0, 0.18, 0.42, fade), 7.0, true)
			var meteor_pos := -facing * radius * (1.0 - p) + facing.rotated(-PI * 0.5) * radius * 0.55 * (1.0 - p)
			draw_line(meteor_pos - facing * 70.0, meteor_pos, Color(0.65, 0.10, 1.0, fade * 0.7), 18.0, true)
			draw_circle(meteor_pos, 18.0, Color(1.0, 0.36, 0.08, fade))
		"necromancer":
			var grave_radius := radius * (0.2 + p * 0.8)
			draw_circle(Vector2.ZERO, grave_radius, Color(0.04, 0.36, 0.32, fade * 0.16))
			draw_arc(Vector2.ZERO, grave_radius, elapsed * 3.0, TAU + elapsed * 3.0, 48, Color(0.48, 1.0, 0.83, fade), 5.0, true)
			for index in range(8):
				var a := TAU * float(index) / 8.0 - elapsed * 2.0
				var bone := Vector2.from_angle(a) * grave_radius * 0.65
				var tangent := Vector2.from_angle(a + PI * 0.5)
				draw_line(bone - tangent * 12.0, bone + tangent * 12.0, Color(0.78, 1.0, 0.90, fade), 5.0, true)
				draw_circle(bone - tangent * 12.0, 4.0, Color(0.68, 0.94, 0.82, fade))
				draw_circle(bone + tangent * 12.0, 4.0, Color(0.68, 0.94, 0.82, fade))

func _draw_blade(p: float, fade: float) -> void:
	var base_angle := facing.angle()
	for index in range(5):
		var phase := clampf(p * 1.8 - float(index) * 0.12, 0.0, 1.0)
		if phase <= 0.0:
			continue
		var slash_radius := 42.0 + phase * (radius - 28.0)
		var angle := base_angle - 1.25 + float(index) * 0.48
		var col := Color(0.48, 0.92, 0.86, fade * (0.72 - float(index) * 0.08))
		draw_arc(facing * 22.0, slash_radius, angle - 0.48, angle + 0.48, 18, col, 8.0 - float(index), true)
		draw_arc(facing * 22.0, slash_radius + 5.0, angle - 0.42, angle + 0.42, 18, Color(0.9, 1.0, 0.92, fade * 0.7), 2.0, true)
	for echo in range(3):
		var offset := -facing * (18.0 + float(echo) * 22.0) * (1.0 - p)
		var side := facing.rotated(PI * 0.5) * (float(echo) - 1.0) * 9.0
		draw_colored_polygon(PackedVector2Array([
			offset + side + facing * 25.0,
			offset + side + facing.rotated(2.5) * 13.0,
			offset + side + facing.rotated(-2.5) * 13.0
		]), Color(0.18, 0.55, 0.50, fade * 0.30))

func _draw_archer(p: float, fade: float) -> void:
	var ring_radius := radius * (0.25 + p * 0.75)
	draw_circle(Vector2.ZERO, ring_radius, Color(0.18, 0.48, 0.16, fade * 0.13))
	draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 40, Color(0.48, 1.0, 0.38, fade * 0.82), 3.0, true)
	draw_arc(Vector2.ZERO, ring_radius * 0.66, -elapsed * 5.0, TAU - elapsed * 5.0, 32, Color(0.82, 1.0, 0.48, fade * 0.62), 2.0, true)
	for index in range(8):
		var angle := TAU * float(index) / 8.0 + elapsed * 1.6
		var inner := Vector2.from_angle(angle) * ring_radius * 0.62
		var outer := Vector2.from_angle(angle) * ring_radius * 0.90
		draw_line(inner, outer, Color(0.72, 1.0, 0.38, fade * 0.65), 2.0, true)
	for index in range(5):
		var arrow_dir := facing.rotated((float(index) - 2.0) * 0.16)
		var start := arrow_dir * (20.0 + p * radius * 0.72)
		draw_line(start - arrow_dir * 22.0, start + arrow_dir * 12.0, Color(0.88, 0.72, 0.35, fade), 3.0, true)
		draw_line(start + arrow_dir * 12.0, start + arrow_dir.rotated(2.55) * 8.0, Color(0.72, 1.0, 0.42, fade), 2.0, true)

func _draw_knight(p: float, fade: float) -> void:
	for ring in range(3):
		var ring_p := clampf(p * 1.5 - float(ring) * 0.16, 0.0, 1.0)
		var ring_radius := 34.0 + ring_p * radius
		draw_arc(Vector2.ZERO, ring_radius, 0, TAU, 48, Color(0.55, 0.84, 1.0, fade * (0.75 - ring * 0.16)), 5.0 - ring, true)
	var shield_scale := 1.0 + p * 0.45
	var shield := PackedVector2Array([
		Vector2(0, -36), Vector2(28, -22), Vector2(23, 20), Vector2(0, 40), Vector2(-23, 20), Vector2(-28, -22)
	])
	for index in range(shield.size()):
		shield[index] *= shield_scale
	draw_colored_polygon(shield, Color(0.28, 0.62, 0.82, fade * 0.20))
	draw_polyline(shield, Color(0.78, 0.93, 1.0, fade * 0.9), 4.0, true)
	for index in range(10):
		var crack_dir := Vector2.from_angle(TAU * float(index) / 10.0)
		draw_line(crack_dir * 28.0, crack_dir * (38.0 + p * radius * 0.7), Color(0.92, 0.82, 0.52, fade * 0.65), 2.0, true)

func _draw_mage(p: float, fade: float) -> void:
	var blast_radius := radius * (0.18 + p * 0.82)
	for layer in range(5, 0, -1):
		var layer_radius := blast_radius * float(layer) / 5.0
		draw_circle(Vector2.ZERO, layer_radius, Color(0.48 + layer * 0.035, 0.18, 0.82, fade * 0.055))
	draw_arc(Vector2.ZERO, blast_radius, elapsed * 3.5, TAU + elapsed * 3.5, 48, Color(0.82, 0.48, 1.0, fade * 0.85), 4.0, true)
	draw_arc(Vector2.ZERO, blast_radius * 0.62, -elapsed * 5.0, TAU - elapsed * 5.0, 36, Color(0.34, 0.88, 1.0, fade * 0.82), 3.0, true)
	for index in range(12):
		var angle := TAU * float(index) / 12.0 + elapsed * (2.0 if index % 2 == 0 else -2.7)
		var orbit := Vector2.from_angle(angle) * blast_radius * (0.42 + float(index % 3) * 0.16)
		draw_circle(orbit, 3.0 + float(index % 2) * 2.0, Color(0.68, 0.84, 1.0, fade * 0.8))

func _draw_ogre_smash(p: float, fade: float) -> void:
	var wave := radius * p
	draw_circle(Vector2.ZERO, wave, Color(0.68, 0.24, 0.08, fade * 0.16))
	draw_arc(Vector2.ZERO, wave, 0, TAU, 52, Color(1.0, 0.58, 0.20, fade * 0.9), 8.0, true)
	draw_arc(Vector2.ZERO, wave * 0.72, 0, TAU, 42, Color(1.0, 0.86, 0.46, fade * 0.65), 3.0, true)
	for index in range(14):
		var crack_dir := Vector2.from_angle(TAU * float(index) / 14.0 + sin(float(index) * 4.1) * 0.12)
		var length := radius * (0.45 + float(index % 4) * 0.11) * minf(1.0, p * 2.0)
		draw_line(crack_dir * 12.0, crack_dir * length, Color(0.18, 0.08, 0.03, fade * 0.85), 4.0, true)


func _draw_sigils(p: float, fade: float) -> void:
	var col: Color = preload("res://scripts/special_accent.gd").COLORS.get(effect_kind, Color.WHITE)
	var bloom := 1.0 - pow(1.0 - minf(p * 2.5, 1.0), 3.0)
	var r := radius * (0.2 + bloom * 0.65)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1, 0.45))
	draw_circle(Vector2.ZERO, r, Color(col, fade * 0.06))
	for i in range(12):
		var angle := TAU * float(i) / 12.0 + elapsed * 0.35
		var ray := Vector2.from_angle(angle)
		var tangent := ray.orthogonal()
		var center := ray * r
		draw_arc(Vector2.ZERO, r, angle, angle + 0.25, 8, Color(col, fade * 0.6), 2.0, true)
		var rune := PackedVector2Array([center - tangent * 4.0 - ray * 8.0, center + ray * 4.0, center + tangent * 4.0 - ray * 8.0, center - ray * 4.0, center - tangent * 4.0 - ray * 8.0])
		draw_polyline(rune, Color(col, fade * 0.85), 1.5, true)
	draw_set_transform(Vector2.ZERO)

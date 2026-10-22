extends Node2D
## Airborne pass for signature attacks. Ground glyphs remain beneath actors.
var source: Node2D
const PAINTED_SHEET = preload("res://assets/summons/specials.png")
const COLORS := {
	"blade": Color("90ffe3"), "assassin": Color("91ffb2"),
	"berserker": Color("ff623a"), "archer": Color("b2f966"),
	"hunter": Color("ffdb6c"), "beastmaster": Color("ffb756"),
	"knight": Color("b7dfff"), "warlord": Color("ffc56b"),
	"guardian": Color("7deaff"), "mage": Color("cba1ff"),
	"shaman": Color("85ffb3"), "warlock": Color("ff609f"),
	"necromancer": Color("7cffe0"), "ogre_smash": Color("ffba67")
}

func _ready() -> void:
	z_as_relative = false
	z_index = 2000

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(source):
		return
	var p := clampf(source.elapsed / source.duration, 0.0, 1.0)
	var fade := pow(1.0 - p, 1.3)
	var burst := 1.0 - pow(1.0 - minf(p * 3.0, 1.0), 3.0)
	var col: Color = COLORS.get(source.effect_kind, Color.WHITE)
	var kind: String = source.effect_kind
	var radius: float = source.radius
	var aim: Vector2 = source.facing
	_draw_painted(kind, p, radius, aim)
	# Seeded trajectories are stable between frames, with ballistic falloff.
	for i in range(22):
		var angle := float(i) * 2.39996
		var ray := Vector2.from_angle(angle)
		var travel := radius * (0.26 + float(i % 5) * 0.13) * burst
		var point := ray * travel + Vector2(0, -sin(p * PI) * (18.0 + float(i % 4) * 11.0))
		var tail := point - ray * (5.0 + 16.0 * (1.0 - p))
		_glow_line(tail, point, col, fade * 0.65, 1.3 + float(i % 2))
	if kind in ["blade", "assassin", "berserker", "beastmaster"]:
		for i in range(3):
			var q := clampf(p * 2.8 - float(i) * 0.13, 0.0, 1.0)
			var opacity := sin(q * PI) * fade
			var curve := PackedVector2Array()
			for j in range(25):
				var t := float(j) / 24.0
				var a := aim.angle() - 1.4 + t * 2.5 + q * 0.6
				var r := radius * (0.42 + float(i) * 0.16) * (0.55 + q * 0.45)
				curve.append(Vector2.from_angle(a) * r + Vector2(0, -20))
			draw_polyline(curve, Color(col, opacity * 0.18), 16.0, true)
			draw_polyline(curve, Color(col, opacity), 4.0, true)
			draw_polyline(curve, Color(1, 1, 0.9, opacity), 1.0, true)
		if kind == "beastmaster":
			for i in range(3):
				var side := aim.orthogonal() * (float(i) - 1.0) * 18.0
				_glow_line(side - aim * 35.0, side + aim * radius * burst * 0.65, col, fade, 4.0)
	elif kind in ["archer", "hunter"]:
		for i in range(5 if kind == "archer" else 7):
			var ray := aim.rotated((float(i) - (2.0 if kind == "archer" else 3.0)) * 0.15)
			var tip := ray * radius * burst + Vector2(0, -15)
			_glow_line(tip - ray * 48.0, tip, col, fade, 3.0)
			draw_colored_polygon(PackedVector2Array([tip + ray * 8.0, tip - ray * 7.0 + ray.orthogonal() * 5.0, tip - ray * 7.0 - ray.orthogonal() * 5.0]), Color(col, fade))
	elif kind in ["knight", "guardian", "warlord", "ogre_smash"]:
		for i in range(8):
			var a := TAU * float(i) / 8.0
			var ray := Vector2.from_angle(a)
			var tip := ray * radius * burst * 0.75
			_glow_line(tip, tip + Vector2(0, -40.0 * sin(p * PI)), col, fade * 0.7, 3.0)
		if kind != "ogre_smash":
			var center := Vector2(0, -35.0 - sin(p * PI) * 28.0)
			var shield := PackedVector2Array([Vector2(-25,-24), Vector2(0,-30), Vector2(25,-24), Vector2(23,8), Vector2(0,30), Vector2(-23,8), Vector2(-25,-24)])
			for i in range(shield.size()):
				shield[i] = center + shield[i] * (0.7 + burst * 0.55)
			draw_colored_polygon(shield, Color(col, fade * 0.16))
			draw_polyline(shield, Color(col, fade), 3.0, true)
			_glow_line(center + Vector2(0,-18), center + Vector2(0,15), col, fade, 2.5)
			_glow_line(center + Vector2(-12,-5), center + Vector2(12,-5), col, fade, 2.5)
	else:
		for i in range(7):
			var a := float(i) * TAU / 7.0 + p * 1.5
			var start := Vector2.from_angle(a) * radius * 0.66
			var tip := start * (1.0 - burst * 0.5) + Vector2(0, -sin(p * PI) * 70.0)
			var bolt := PackedVector2Array([start, start.lerp(tip, 0.33) + Vector2(8, -4), start.lerp(tip, 0.66) - Vector2(7, 0), tip])
			draw_polyline(bolt, Color(col, fade * 0.2), 9.0, true)
			draw_polyline(bolt, Color(col, fade), 2.0, true)
			if kind == "necromancer":
				_skull(tip, col, fade)
			elif kind == "shaman":
				draw_arc(tip, 8.0, p * TAU, p * TAU + PI * 1.6, 12, Color(col, fade), 2.0, true)
		if kind == "warlock":
			var orb := Vector2(0, -90.0 * (1.0 - burst))
			for layer in range(4, 0, -1):
				draw_circle(orb, float(layer) * 9.0 * (0.6 + sin(p * PI)), Color(col, fade * 0.09))
			draw_circle(orb, 9.0 * (1.0 - p), Color(1, 0.92, 0.7, fade))

func _glow_line(a: Vector2, b: Vector2, color: Color, opacity: float, width: float) -> void:
	draw_line(a, b, Color(color, opacity * 0.12), width * 4.0, true)
	draw_line(a, b, Color(color, opacity), width, true)
	draw_line(a, b, Color(1, 1, 0.92, opacity * 0.9), maxf(0.7, width * 0.35), true)

func _skull(center: Vector2, color: Color, opacity: float) -> void:
	draw_circle(center, 9.0, Color(color, opacity * 0.18))
	draw_circle(center, 6.0, Color(0.83, 1, 0.92, opacity))
	draw_rect(Rect2(center + Vector2(-4, 2), Vector2(8, 6)), Color(0.83, 1, 0.92, opacity))
	for x in [-2.5, 2.5]:
		draw_circle(center + Vector2(x, 0), 1.8, Color(0.02, 0.18, 0.14, opacity))

func _draw_painted(kind: String, progress: float, radius: float, aim: Vector2) -> void:
	var row := 3
	if kind in ["blade", "assassin", "berserker", "beastmaster"]:
		row = 0
	elif kind in ["archer", "hunter"]:
		row = 1
	elif kind in ["knight", "guardian", "warlord", "ogre_smash"]:
		row = 2
	var cell := PAINTED_SHEET.get_size() / 4.0
	var phase := progress * 3.0
	var first := mini(3, int(phase))
	var blend := phase - float(first)
	var opacity := pow(1.0 - progress, 0.65) * 0.75
	var rotation_angle := aim.angle() if row < 2 else 0.0
	draw_set_transform(Vector2(0, -radius * 0.22), rotation_angle)
	var rect := Rect2(Vector2.ONE * -radius * 0.8, Vector2.ONE * radius * 1.6)
	for pass_index in range(2):
		var frame := mini(3, first + pass_index)
		var weight := (1.0 - blend) if pass_index == 0 else blend
		if weight <= 0.0:
			continue
		var region := Rect2(Vector2(float(frame) * cell.x, float(row) * cell.y) + Vector2.ONE, cell - Vector2.ONE * 2.0)
		draw_texture_rect_region(PAINTED_SHEET, rect, region, Color(1, 1, 1, opacity * weight))
	draw_set_transform(Vector2.ZERO)

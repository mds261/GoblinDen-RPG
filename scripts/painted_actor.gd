extends RefCounted
## Shared drawing helper. Animation transforms never change the physics body.
## Draws painted character poses plus procedural class/role weapons and status emblems.

static func draw_actor(canvas: Node2D, texture: Texture2D, size: float,
		faces_left: bool, time: float, moving: bool, swinging: bool,
		hurt: bool, dead: bool, tint: Color = Color.WHITE, role_tag: String = "") -> void:
	var direction: float = -1.0 if faces_left else 1.0
	var stride: float = sin(time * 13.5) if moving else sin(time * 2.6) * 0.14
	var footfall: float = absf(stride)
	var bob: float = -footfall * 3.4 if moving else sin(time * 2.6) * 0.65
	var side_shift: float = cos(time * 13.5) * 1.8 if moving else 0.0
	var lean: float = stride * 0.045 if moving else 0.0
	var body_scale: Vector2 = Vector2(1.0 + footfall * 0.018, 1.0 - footfall * 0.028) if moving else Vector2.ONE

	# Attacks have anticipation, a strong forward snap, and a short follow-through.
	if swinging:
		var attack_pulse: float = 0.5 + 0.5 * sin(time * 30.0)
		lean += direction * (0.12 + attack_pulse * 0.12)
		side_shift += direction * (3.0 + attack_pulse * 4.0)
		bob -= attack_pulse * 1.5
		body_scale *= Vector2(1.04 + attack_pulse * 0.035, 0.97 - attack_pulse * 0.02)

	if dead:
		lean = -1.35
		bob = 16.0
		side_shift = 0.0
		body_scale = Vector2.ONE

	# The shadow compresses during a step and stretches into attack lunges.
	var shadow_scale: Vector2 = Vector2(1.0 + (0.12 if swinging else 0.0), 0.36 - footfall * 0.035)
	canvas.draw_set_transform(Vector2(side_shift * 0.25, 10), 0.0, shadow_scale)
	canvas.draw_circle(Vector2.ZERO, size * 0.25, Color(0.01, 0.015, 0.01, 0.45))
	canvas.draw_set_transform(Vector2.ZERO)

	# Small dust puffs sell foot contact without touching physics.
	if moving and footfall > 0.76 and not dead:
		var dust_alpha: float = (footfall - 0.76) * 0.72
		canvas.draw_circle(Vector2(-direction * 8.0, 11.0), 3.2, Color(0.42, 0.38, 0.29, dust_alpha))
		canvas.draw_circle(Vector2(-direction * 13.0, 12.0), 1.8, Color(0.54, 0.48, 0.35, dust_alpha * 0.75))

	var color: Color = tint
	if hurt:
		color = Color(1.6, 1.3, 1.1)
	if dead:
		color = Color(0.45, 0.43, 0.4, 0.75)

	# Two restrained motion echoes make fast attacks read clearly at game scale.
	if swinging and not dead:
		for echo_index in range(2, 0, -1):
			var echo_offset: Vector2 = Vector2(-direction * float(echo_index) * 6.0, bob + float(echo_index) * 0.7)
			var echo_color: Color = Color(color.r, color.g, color.b, 0.08 + float(2 - echo_index) * 0.035)
			canvas.draw_set_transform(echo_offset, lean - direction * float(echo_index) * 0.035, Vector2(direction, 1.0) * body_scale)
			canvas.draw_texture_rect(texture, Rect2(-size * 0.5, -size * 0.78, size, size), false, echo_color)

	canvas.draw_set_transform(Vector2(side_shift, bob), lean, Vector2(direction, 1.0) * body_scale)
	canvas.draw_texture_rect(texture, Rect2(-size * 0.5, -size * 0.78, size, size), false, color)
	if not dead and role_tag != "":
		_draw_role_kit(canvas, size, time, role_tag)
	if swinging and not dead:
		var trail_color: Color = Color(1.0, 0.86, 0.52, 0.52)
		if role_tag in ["mage", "shaman", "warlock", "necromancer", "human_mage", "human_priest"]:
			trail_color = Color(0.72, 0.48, 1.0, 0.56)
		var trail_center: Vector2 = Vector2(direction * size * 0.24, -size * 0.30)
		var start_angle: float = -1.45 if direction > 0.0 else PI - 1.45
		canvas.draw_arc(trail_center, size * 0.34, start_angle, start_angle + direction * 1.9, 18, trail_color, 4.0, true)
	canvas.draw_set_transform(Vector2.ZERO)

static func _draw_role_kit(canvas: Node2D, size: float, time: float, role_tag: String) -> void:
	var hand := Vector2(size * 0.24, -size * 0.26)
	var offhand := Vector2(-size * 0.18, -size * 0.24)
	match role_tag:
		"archer", "hunter", "beastmaster":
			# Curved hunting bow and quiver tips
			canvas.draw_arc(hand + Vector2(2, 0), 18.0, -1.2, 1.2, 14, Color("c49a58"), 3.0, true)
			canvas.draw_line(hand + Vector2(-5, -16), hand + Vector2(-5, 16), Color("ded8c8"), 1.2, true)
		"knight", "warlord", "guardian":
			# Heavy scavenged iron buckler / tower shield on front arm
			canvas.draw_rect(Rect2(hand + Vector2(-6, -15), Vector2(14, 28)), Color("5c6268"))
			canvas.draw_rect(Rect2(hand + Vector2(-4, -13), Vector2(10, 24)), Color("8f734c"))
		"mage", "shaman", "warlock", "necromancer":
			# Gnarled shamanic staff with pulsing spell orb
			canvas.draw_line(hand + Vector2(0, 18), hand + Vector2(4, -22), Color("705136"), 3.0, true)
			var orb_col := Color("b86be6") if role_tag != "shaman" else Color("5fe08c")
			if role_tag == "necromancer":
				orb_col = Color("7ce8d4")
			canvas.draw_circle(hand + Vector2(4, -24), 6.0 + sin(time * 7.0) * 1.3, orb_col)
		"assassin", "rogue":
			# Offhand twin poisoned dagger
			canvas.draw_line(offhand, offhand + Vector2(15, 5), Color("88d97c"), 2.5, true)
		"berserker":
			# Crimson warpaint/frenzy shoulder spikes
			canvas.draw_circle(Vector2(0, -size * 0.42), 5.0, Color(0.9, 0.25, 0.18, 0.65))
		"human_priest":
			# Golden sun halo & clerical staff
			canvas.draw_arc(Vector2(0, -size * 0.68), 13.0, 0, TAU, 20, Color(1.0, 0.88, 0.45, 0.75), 2.0, true)
		"human_mage":
			# Floating arcane sigil orb
			var orbit := Vector2(cos(time * 4.0) * 18.0, -size * 0.48 + sin(time * 4.0) * 6.0)
			canvas.draw_circle(orbit, 5.5, Color(0.95, 0.45, 0.85, 0.85))
		"human_ranger":
			# Woodland longbow arc on left side (human art faces left)
			canvas.draw_arc(Vector2(-size * 0.26, -size * 0.28), 20.0, PI - 1.1, PI + 1.1, 14, Color("c99e5a"), 2.8, true)
		"human_rogue":
			# Dark hood tint & twin silver daggers
			canvas.draw_line(Vector2(-size * 0.25, -size * 0.20), Vector2(-size * 0.40, -size * 0.12), Color("d8e6eb"), 2.4, true)
		"human_boss":
			# Commander's golden crest above helm
			canvas.draw_colored_polygon(PackedVector2Array([
				Vector2(-10, -size * 0.72), Vector2(-5, -size * 0.82),
				Vector2(0, -size * 0.74), Vector2(5, -size * 0.82), Vector2(10, -size * 0.72)
			]), Color("f5c85b"))

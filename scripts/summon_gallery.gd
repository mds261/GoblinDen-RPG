extends Node2D
## F6 gallery: summons and every base/evolved signature effect, without unlocks.
const Anim = preload("res://scripts/summon_animation.gd")
const Effect = preload("res://scripts/special_effect.gd")
const KINDS := ["blade", "assassin", "berserker", "archer", "hunter", "beastmaster", "knight", "warlord", "guardian", "mage", "shaman", "warlock", "necromancer"]
var page := 0
var cycle := 0.0
var capture_directory := ""

func _ready() -> void:
	show_page(0)
	var args := OS.get_cmdline_user_args()
	var flag := args.find("--capture-summons")
	if flag >= 0 and args.size() > flag + 1:
		capture_directory = args[flag + 1]
		capture()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			show_page(event.keycode - KEY_1)
		elif event.keycode == KEY_RIGHT:
			show_page((page + 1) % 3)
		elif event.keycode == KEY_LEFT:
			show_page((page + 2) % 3)

func show_page(index: int) -> void:
	page = index
	for child in get_children():
		child.free()
	cycle = 0.0
	if page == 0:
		for row in range(2):
			for col in range(7):
				var sample := Sample.new()
				sample.kind = "wolf" if row == 0 else "skeleton"
				sample.mode = col
				sample.position = Vector2(85 + col * 163, 315 + row * 270)
				add_child(sample)
	else:
		spawn_effects()
	queue_redraw()

func _process(delta: float) -> void:
	cycle += delta
	if page > 0 and cycle >= 1.5:
		cycle = 0.0
		spawn_effects()

func spawn_effects() -> void:
	var first := 0 if page == 1 else 7
	var last := 7 if page == 1 else KINDS.size()
	for i in range(first, last):
		var effect := Effect.new()
		effect.setup(KINDS[i], Vector2.RIGHT, 95.0)
		effect.position = Vector2(145 + ((i - first) % 4) * 285, 290 + int((i - first) / 4.0) * 275)
		add_child(effect)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("101c20"))
	for x in range(0, 1200, 40):
		draw_line(Vector2(x, 115), Vector2(x, 720), Color(0.12, 0.19, 0.2, 0.35))
	draw_string(ThemeDB.fallback_font, Vector2(30, 42), "GOBLIN DEN / " + ["CAVE FANG & RISEN SKELETON", "SIGNATURE ATTACKS / I", "SIGNATURE ATTACKS / II"][page], HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("eddfba"))
	draw_string(ThemeDB.fallback_font, Vector2(30, 76), "1 Summons    2 Specials I    3 Specials II    /    Arrow keys change page", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("9db6b5"))
	if page == 0:
		for col in range(7):
			draw_string(ThemeDB.fallback_font, Vector2(30 + col * 163, 150), ["DOWN WALK", "UP WALK", "RIGHT WALK", "LEFT WALK", "ATTACK", "ARRIVAL / BUFF", "DEATH"][col], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("9db6b5"))
		draw_string(ThemeDB.fallback_font, Vector2(30, 380), "CAVE FANG WOLF / quadruped, heavy mane, saber fangs, biting pounce", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("eab474"))
		draw_string(ThemeDB.fallback_font, Vector2(30, 655), "RISEN SKELETON / exposed bones, rusty blade, teal soulfire, collapsing corpse", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("9ce8d3"))
	else:
		var first := 0 if page == 1 else 7
		var last := 7 if page == 1 else KINDS.size()
		for i in range(first, last):
			draw_string(ThemeDB.fallback_font, Vector2(65 + ((i - first) % 4) * 285, 390 + int((i - first) / 4.0) * 275), KINDS[i].to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("eddfba"))

func capture() -> void:
	for index in range(3):
		show_page(index)
		await get_tree().create_timer(0.24).timeout
		await RenderingServer.frame_post_draw
		var names := ["Summons-Animation-Preview", "Special-Attacks-I", "Special-Attacks-II"]
		get_viewport().get_texture().get_image().save_png(capture_directory.path_join(names[index] + ".png"))
	# Deterministic animation capture includes every movement, attack and collapse frame.
	show_page(0)
	set_process(false)
	for child in get_children():
		child.set_process(false)
	for frame in range(48):
		for child in get_children():
			child._process(1.0 / 16.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_directory.path_join("summons-%03d.png" % frame))
	await get_tree().process_frame
	for index in [1, 2]:
		show_page(index)
		for effect in get_children():
			effect.set_process(false)
		for frame in range(24):
			for effect in get_children():
				effect.elapsed = float(frame) / 24.0 * effect.duration
				effect.queue_redraw()
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(capture_directory.path_join("specials-%d-%03d.png" % [index, frame]))
		await get_tree().process_frame
	print("Captured summon gallery and 96 animation frames successfully.")
	get_tree().call_deferred("quit", 0)

class Sample extends Node2D:
	var kind := "wolf"
	var mode := 0
	var clock := 0.0
	var animation = Anim.new()
	func _ready() -> void:
		animation.configure(kind)
		animation.age = 1.0
		if mode == 4:
			animation.start_attack(false)
	func _process(delta: float) -> void:
		clock += delta
		var movement: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO][mode] * 100.0
		if clock >= 1.6:
			clock = 0.0
			if mode == 4:
				animation.start_attack(false)
			if mode == 5:
				animation.age = 0.0
				animation.buff_elapsed = 0.0
			animation.death_elapsed = 0.0
		animation.update(delta, movement, mode != 6)
		queue_redraw()
	func _draw() -> void:
		var size := 124.0 if kind == "wolf" else 132.0
		if mode == 4:
			size = 110.0
		animation.draw_actor(self, size, false, mode == 6)

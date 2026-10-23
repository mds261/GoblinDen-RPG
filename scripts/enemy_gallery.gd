extends Node2D
## F6 animated roster, independent of progression unlocks and combat saves.
const Anim = preload("res://scripts/enemy_animation.gd")
const Directional = preload("res://scripts/directional_actor.gd")
const PAGES := [
	["blade", "knight", "captain"],
	["ranger", "mage", "priest", "rogue"],
	["ogre", "wolf_rider", "wolf"],
	["spider", "spiderling"]
]
const TITLES := ["BLADE / FRONTLINE HUMANS", "HUMAN BACKLINE", "OGRE / WOLF RIDER / PACK", "ROOTVEIN SPIDERS"]
const FILES := ["Blade-and-Knights", "Human-Enemy-Roles", "Creature-Enemies", "Giant-Spider-and-Spiderlings"]
var page := 0

func _ready() -> void:
	show_page(0)
	var args := OS.get_cmdline_user_args()
	var flag := args.find("--capture-enemies")
	if flag >= 0 and args.size() > flag + 1:
		capture(args[flag + 1])

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			show_page(event.keycode - KEY_1)
		elif event.keycode == KEY_RIGHT:
			show_page((page + 1) % 4)
		elif event.keycode == KEY_LEFT:
			show_page((page + 3) % 4)

func show_page(index: int) -> void:
	page = index
	for child in get_children():
		child.free()
	var rows: int = PAGES[page].size()
	for row in range(rows):
		for col in range(7):
			var actor := Sample.new()
			actor.kind = PAGES[page][row]
			actor.mode = col
			actor.position = Vector2(80 + col * 164, 230 + row * (130 if rows == 4 else 180))
			actor.size = 96.0 if rows == 4 else 112.0
			if page == 3:
				actor.position.y = 310 + row * 240
				actor.size = 170.0
			if actor.kind == "spiderling":
				actor.size = 95.0
			add_child(actor)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("111c20"))
	draw_string(ThemeDB.fallback_font, Vector2(26, 40), "GOBLIN DEN / " + TITLES[page], HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("e8d9ad"))
	draw_string(ThemeDB.fallback_font, Vector2(26, 73), "1 Blade/Knights   2 Human roles   3 Creatures   4 Spiders   /   Arrow keys change page", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a5bab5"))
	for col in range(7):
		draw_string(ThemeDB.fallback_font, Vector2(28 + col * 164, 115), ["WALK DOWN", "WALK UP", "WALK RIGHT", "WALK LEFT", "ATTACK", "HURT / STUN", "DEATH"][col], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("a5bab5"))
	var rows: int = PAGES[page].size()
	for row in range(rows):
		var y := 265 + row * (130 if rows == 4 else 180)
		if page == 3:
			y = 350 + row * 240
		draw_string(ThemeDB.fallback_font, Vector2(24, y), PAGES[page][row].to_upper().replace("_", " "), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e8d9ad"))
		if row < rows - 1:
			draw_line(Vector2(24,y+18), Vector2(1128,y+18), Color("2b3a3d"), 1.0)

func capture(directory: String) -> void:
	for index in range(4):
		show_page(index)
		for child in get_children():
			child.set_process(false)
		for frame in range(48):
			for child in get_children():
				child._process(1.0 / 16.0)
			await RenderingServer.frame_post_draw
			var picture := get_viewport().get_texture().get_image()
			picture.save_png(directory.path_join("page-%d-%03d.png" % [index, frame]))
			if frame == 3:
				picture.save_png(directory.path_join(FILES[index] + ".png"))
		await get_tree().process_frame
	print("Enemy roster gallery rendered: four pages and 192 animation frames.")
	get_tree().call_deferred("quit", 0)

class Sample extends Node2D:
	var kind := "knight"
	var mode := 0
	var size := 112.0
	var clock := 0.0
	var animation = Anim.new()
	var blade = Directional.new()
	func _ready() -> void:
		animation.configure(kind)
		blade.configure("blade")
		if kind == "blade" and mode == 4:
			blade.start_attack(0.65)
	func _process(delta: float) -> void:
		clock += delta
		if clock >= 1.5:
			clock = 0.0
			animation.death_elapsed = 0.0
			if kind == "blade" and mode == 4:
				blade.start_attack(0.65)
		var movement: Vector2 = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.ZERO, Vector2.ZERO, Vector2.ZERO][mode] * 100.0
		if kind == "blade":
			blade.update(delta, movement, mode != 6)
		else:
			var windup := maxf(0.0, 0.45 - clock) if mode == 4 else 0.0
			if mode == 4 and clock >= 0.45 and clock < 0.45 + delta:
				animation.release_attack(0.3)
			animation.update(delta, movement, mode != 6, windup, 0.45, Vector2.RIGHT, mode == 5)
		queue_redraw()
	func _draw() -> void:
		var hurt := mode == 5 and fmod(clock, 0.65) < 0.25
		if kind == "blade":
			blade.draw_actor(self, size, false, mode < 4, hurt, mode == 6)
		else:
			animation.draw_actor(self, size, hurt)

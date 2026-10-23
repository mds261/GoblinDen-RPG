extends Node2D
## F6 preview. Keys 1-5 select base classes, evolution families, or all evolutions.
const Directional = preload("res://scripts/directional_actor.gd")
const ClassAnim = preload("res://scripts/class_animation.gd")
const BladeAnim = preload("res://scripts/blade_animation.gd")
const PAGES := [
	["blade", "archer", "knight", "mage"],
	["assassin", "berserker", "hunter", "beastmaster"],
	["warlord", "guardian"],
	["shaman", "warlock", "necromancer"]
]
const TITLES := ["BASE CLASSES", "BLADE / ARCHER EVOLUTIONS", "KNIGHT EVOLUTIONS", "MAGE EVOLUTIONS", "ALL NINE EVOLUTIONS"]
var page: int = 0

func _ready() -> void:
	show_page(0)
	var args := OS.get_cmdline_user_args()
	var flag := args.find("--capture-directional-dir")
	if flag >= 0 and args.size() > flag + 1:
		var names := ["Base-Classes-Four-Directions", "Blade-Archer-Evolutions", "Knight-Evolutions", "Mage-Evolutions", "All-Nine-Evolutions"]
		for index in range(5):
			show_page(index)
			await get_tree().create_timer(0.28).timeout
			await RenderingServer.frame_post_draw
			var output: String = args[flag + 1].path_join(names[index] + ".png")
			get_viewport().get_texture().get_image().save_png(output)
		print("Rendered five directional/evolution gallery pages")
		get_tree().quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode >= KEY_1 and event.keycode <= KEY_5:
			show_page(event.keycode - KEY_1)
		elif event.keycode == KEY_RIGHT:
			show_page((page + 1) % 5)
		elif event.keycode == KEY_LEFT:
			show_page((page + 4) % 5)

func show_page(index: int) -> void:
	page = index
	for child in get_children():
		child.queue_free()
	if page < 4:
		for row in range(PAGES[page].size()):
			for col in range(5):
				add_sample(PAGES[page][row], col, Vector2(136 + col * 220, 210 + row * 150), 112.0)
	else:
		var ids := ["assassin", "berserker", "hunter", "beastmaster", "warlord", "guardian", "shaman", "warlock", "necromancer"]
		for i in range(ids.size()):
			for col in range(3):
				var mode: int = [0, 1, 4][col]
				add_sample(ids[i], mode, Vector2(78 + (i % 3) * 382 + col * 112, 255 + int(i / 3.0) * 205), 126.0)
	queue_redraw()

func add_sample(id: String, mode: int, location: Vector2, draw_size: float) -> void:
	var actor := Sample.new()
	actor.visual_id = id
	actor.mode = mode
	actor.draw_size = draw_size
	actor.position = location
	add_child(actor)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("18221d"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 36), "GOBLIN DEN / " + TITLES[page], HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("e4d6a8"))
	draw_string(ThemeDB.fallback_font, Vector2(24, 65), "1 Base   2 Blade/Archer   3 Knight   4 Mage   5 All evolutions   /   Arrow keys change page", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a7b7a5"))
	if page < 4:
		for col in range(5):
			draw_string(ThemeDB.fallback_font, Vector2(90 + col * 220, 106), ["WALK DOWN", "WALK UP", "WALK RIGHT", "WALK LEFT", "ATTACK"][col], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("a7b7a5"))
	else:
		draw_string(ThemeDB.fallback_font, Vector2(24, 98), "Each evolution: front walk / rear walk / attack", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("a7b7a5"))

class Sample extends Node2D:
	var visual_id: String = "blade"
	var mode: int = 0
	var draw_size: float = 112.0
	var cycle: float = 0.0
	var direction: Vector2 = Vector2.DOWN
	var appearance = Directional.new()
	var blade = BladeAnim.new()
	var base_animation = ClassAnim.new()
	func _ready() -> void:
		var base: String = Directional.Frames.DATA[visual_id]["base"]
		appearance.configure(base, visual_id if visual_id != base else "")
		base_animation.set_class(base)
		direction = [Vector2.DOWN, Vector2.UP, Vector2.RIGHT, Vector2.LEFT, Vector2.ZERO][mode] * 100.0
		appearance.select_direction(direction)
		if mode == 4:
			start_attack()
	func start_attack() -> void:
		appearance.start_attack(0.65)
		blade.start_attack(0.65)
		base_animation.start_attack(0.65)
	func _process(delta: float) -> void:
		cycle += delta
		appearance.update(delta, direction, true)
		blade.update(delta, mode != 4, true)
		base_animation.update(delta, mode != 4, true)
		if mode == 4 and cycle >= 1.1:
			cycle = 0.0
			start_attack()
		queue_redraw()
	func _draw() -> void:
		if appearance.uses_sheet():
			appearance.draw_actor(self, draw_size, mode == 3, mode != 4, false, false)
		elif appearance.class_id == "blade":
			blade.draw_actor(self, draw_size, mode == 3, mode != 4, false, false)
		else:
			base_animation.draw_actor(self, draw_size, mode == 3, mode != 4, false, false)
		draw_string(ThemeDB.fallback_font, Vector2(-45, 30), visual_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color("e4d6a8"))

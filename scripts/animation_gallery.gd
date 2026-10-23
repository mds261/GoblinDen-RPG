extends Node2D
## Open scenes/animation_gallery.tscn and press F6 to inspect all six new clips.
const ClassAnim = preload("res://scripts/class_animation.gd")

func _ready() -> void:
	for row in range(3):
		for col in range(4):
			var actor := PreviewActor.new()
			actor.role = ["archer", "knight", "mage"][row]
			actor.faces_left = col % 2 == 1
			actor.attack_demo = col >= 2
			actor.position = Vector2(155 + col * 280, 240 + row * 205)
			add_child(actor)
	var args := OS.get_cmdline_user_args()
	var flag := args.find("--capture-gallery")
	if flag >= 0 and args.size() > flag + 1:
		await get_tree().create_timer(0.25).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(args[flag + 1])
		print("Animation gallery rendered")
		get_tree().quit()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("1a231f"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 40), "GOBLIN DEN / CLASS ANIMATION GALLERY", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color("e3d8b1"))
	draw_string(ThemeDB.fallback_font, Vector2(28, 69), "Archer: bow shot    /    Knight: mace swing    /    Mage: staff cast", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("acbaaa"))
	for col in range(4):
		var title: String = ["WALK RIGHT", "WALK LEFT", "ATTACK RIGHT", "ATTACK LEFT"][col]
		draw_string(ThemeDB.fallback_font, Vector2(95 + col * 280, 110), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("acbaaa"))

class PreviewActor extends Node2D:
	var role: String = "archer"
	var faces_left: bool = false
	var attack_demo: bool = false
	var cycle: float = 0.0
	var animation = ClassAnim.new()
	func _ready() -> void:
		animation.set_class(role)
		if attack_demo:
			animation.start_attack(0.65)
	func _process(delta: float) -> void:
		cycle += delta
		animation.update(delta, not attack_demo, true)
		if attack_demo and cycle > 1.1:
			cycle = 0.0
			animation.start_attack(0.65)
		queue_redraw()
	func _draw() -> void:
		animation.draw_actor(self, 138.0, faces_left, not attack_demo, false, false)
		draw_string(ThemeDB.fallback_font, Vector2(-42, 36), role.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("e3d8b1"))

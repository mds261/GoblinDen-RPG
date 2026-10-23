extends Node2D
const Art = preload("res://scripts/descent_art.gd")
var dungeon: Node2D
var kind := "stairs_up"
var floor_id := 13
var seal_index := 0
var age := 0.0

func _ready() -> void:
	z_as_relative = false
	z_index = int(position.y) - 1
	# Keep static art below actors at the same foot position.

func _process(delta: float) -> void:
	age += delta
	queue_redraw()

func _draw() -> void:
	var index := 1
	var box := Vector2(155,155)
	var active := false
	match kind:
		"stairs_down":
			index = 0
			box = Vector2(180,155)
			active = dungeon.seal_count(floor_id) >= 2
		"seal":
			active = dungeon.seals.has("%d_%d" % [floor_id, seal_index])
			index = 3 if active else 2
			box = Vector2(115,145)
		"cache":
			index = 5 if dungeon.caches.has("cache_%d" % floor_id) else 4
			box = Vector2(110,95)
		"reliquary":
			index = 5 if dungeon.vault_opened else 4
			box = Vector2(145,125)
			active = dungeon.boss_defeated
		"entrance":
			index = 0
			box = Vector2(170,165)
	if active:
		for ring in range(5):
			draw_circle(Vector2(0,4), 22 + ring * 9, Color(0.54,0.72,0.32,0.025 * (1.0 + sin(age * 2.0) * 0.2)))
	var texture := Art.prop(index)
	draw_texture_rect(texture, Art.fitted(texture, Vector2.ZERO, box), false)
	if kind == "stairs_down" and not active:
		# The seal is an in-world barrier; the stair remains visible behind it.
		var color := Color(0.58,0.7,0.66,0.38 + sin(age * 1.5) * 0.05)
		draw_arc(Vector2(0,-15),28,0,TAU,48,color,2,true)
		for line in range(3):
			var x := float(line - 1) * 16
			draw_line(Vector2(x,-40),Vector2(x,7),color,1.5,true)

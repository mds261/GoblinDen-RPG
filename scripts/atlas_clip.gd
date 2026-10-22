extends RefCounted
## UV clip geometry isolates each connected pose; source PNGs retain their alpha.
static func draw_frame(canvas: Node2D, texture: Texture2D, region: Rect2, anchor: Vector2,
		factor: float, color: Color, clips: Array = []) -> void:
	if clips.is_empty():
		canvas.draw_texture_rect_region(texture, Rect2(-anchor * factor, region.size * factor), region, color)
		return
	for contour in clips:
		var points := PackedVector2Array()
		var uvs := PackedVector2Array()
		for point in contour:
			points.append((point - anchor) * factor)
			uvs.append((point + region.position) / texture.get_size())
		canvas.draw_polygon(points, PackedColorArray([color]), uvs, texture)

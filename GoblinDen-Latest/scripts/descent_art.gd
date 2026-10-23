extends RefCounted
## Painted art regions are trimmed once, then shared by every floor and boss.
const PROPS = preload("res://assets/descent/dungeon_props.png")
const BOSS = preload("res://assets/descent/vault_hunger.png")
static var cache: Dictionary = {}

static func prop(index: int) -> AtlasTexture:
	var regions := [Rect2i(0,0,452,630), Rect2i(452,0,390,630), Rect2i(842,0,438,630), Rect2i(0,630,412,650), Rect2i(412,630,425,650), Rect2i(837,630,443,650)]
	return trimmed(PROPS, regions[index], "prop_%d" % index)

static func boss_frame(index: int) -> AtlasTexture:
	var cell := Vector2i(BOSS.get_size()) / Vector2i(3,2)
	return trimmed(BOSS, Rect2i(Vector2i(index % 3, index / 3) * cell, cell), "boss_%d" % index)

static func trimmed(sheet: Texture2D, cell: Rect2i, key: String) -> AtlasTexture:
	if cache.has(key):
		return cache[key]
	var bounds := sheet.get_image().get_region(cell).get_used_rect()
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = Rect2(cell.position + bounds.position, bounds.size)
	texture.filter_clip = true
	cache[key] = texture
	return texture

static func fitted(texture: Texture2D, point: Vector2, box: Vector2, anchor_y: float = 0.7) -> Rect2:
	var scale_factor := minf(box.x / texture.get_width(), box.y / texture.get_height())
	var size := texture.get_size() * scale_factor
	return Rect2(point - Vector2(size.x * 0.5, size.y * anchor_y), size)

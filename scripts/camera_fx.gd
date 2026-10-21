extends RefCounted
## Procedural camera shake & screen-flash utility.
## Call CameraFX.shake(camera, intensity, duration) from anywhere to add juice.

static func shake(cam: Camera2D, intensity: float = 6.0, duration: float = 0.22) -> void:
	if not is_instance_valid(cam):
		return
	# Stack shakes: if already shaking, blend to the stronger one
	var existing: float = cam.get_meta("shake_intensity", 0.0)
	if intensity > existing:
		cam.set_meta("shake_intensity", intensity)
		cam.set_meta("shake_duration", duration)
		cam.set_meta("shake_elapsed", 0.0)
		cam.set_meta("shake_seed", randf() * 100.0)

static func update_shake(cam: Camera2D, delta: float) -> void:
	if not is_instance_valid(cam):
		return
	var dur: float = cam.get_meta("shake_duration", 0.0)
	if dur <= 0.0:
		return
	var elapsed: float = cam.get_meta("shake_elapsed", 0.0) + delta
	var intensity: float = cam.get_meta("shake_intensity", 0.0)
	if elapsed >= dur:
		cam.offset = Vector2.ZERO
		cam.set_meta("shake_duration", 0.0)
		cam.set_meta("shake_intensity", 0.0)
		return
	cam.set_meta("shake_elapsed", elapsed)
	# Decaying shake with multiple octaves for organic feel
	var t := elapsed
	var seed_val: float = cam.get_meta("shake_seed", 0.0)
	var decay := 1.0 - (elapsed / dur)
	var offsetX := (sin(t * 37.0 + seed_val) * 0.6 + sin(t * 73.0 + seed_val * 2.1) * 0.3 + sin(t * 11.0 + seed_val * 0.7) * 0.1) * intensity * decay
	var offsetY := (cos(t * 41.0 + seed_val * 1.3) * 0.6 + cos(t * 67.0 + seed_val * 0.9) * 0.3 + cos(t * 13.0 + seed_val * 1.7) * 0.1) * intensity * decay
	cam.offset = Vector2(offsetX, offsetY)

static func flash_screen(overlay: ColorRect, color: Color = Color(1, 1, 1, 0.35), duration: float = 0.12) -> void:
	if not is_instance_valid(overlay):
		return
	overlay.color = color
	overlay.set_meta("flash_duration", duration)
	overlay.set_meta("flash_elapsed", 0.0)
	overlay.visible = true

static func update_flash(overlay: ColorRect, delta: float) -> void:
	if not is_instance_valid(overlay) or not overlay.visible:
		return
	var dur: float = overlay.get_meta("flash_duration", 0.0)
	if dur <= 0.0:
		overlay.visible = false
		return
	var elapsed: float = overlay.get_meta("flash_elapsed", 0.0) + delta
	overlay.set_meta("flash_elapsed", elapsed)
	if elapsed >= dur:
		overlay.visible = false
		return
	var alpha := overlay.color.a * (1.0 - elapsed / dur)
	overlay.color.a = alpha

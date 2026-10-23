extends Node
## Local hit feedback: short slowdown, bounded camera offset, synthesized cues.
const CameraFX = preload("res://scripts/camera_fx.gd")
var impact_time: float = 0.0
var shake: float = 0.0
var sound_cooldown: float = 0.0
var voices: Array[AudioStreamPlayer] = []
var sounds: Dictionary = {}
var cooldown_label: Label

func _ready() -> void:
	add_to_group("combat_feedback")
	for index in range(4):
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -17.0
		add_child(voice)
		voices.append(voice)
	for cue in ["hit", "hurt", "swing", "dodge", "interact"]:
		sounds[cue] = _make_sound(cue)
	var layer := CanvasLayer.new()
	add_child(layer)
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(560, 73)
	cooldown_label.add_theme_font_size_override("font_size", 13)
	cooldown_label.add_theme_color_override("font_color", Color("f5d69b"))
	layer.add_child(cooldown_label)

func _process(delta: float) -> void:
	var real_delta := delta / maxf(Engine.time_scale, 0.01)
	impact_time = maxf(0.0, impact_time - real_delta)
	sound_cooldown = maxf(0.0, sound_cooldown - real_delta)
	if impact_time <= 0.0:
		Engine.time_scale = 1.0
	shake = move_toward(shake, 0.0, real_delta * 28.0)
	# NOTE: never write get_viewport().canvas_transform here. Camera2D drives that
	# value to scroll the view, so overwriting it every frame pins the screen to
	# the first frame in any area bigger than one screen (the Thornwood Expanse).
	# Hit shake goes through the player's Camera2D offset instead (see impact()).
	var player = get_parent().get_node_or_null("BladeGoblin")
	if is_instance_valid(player):
		var dodge := "READY" if player.dodge_cooldown <= 0.0 else "%.1fs" % player.dodge_cooldown
		var special := "READY" if player.special_cooldown <= 0.0 else "%.1fs" % player.special_cooldown
		cooldown_label.text = "SHIFT Dodge: %s    Q Special: %s" % [dodge, special]

func impact(heavy: bool = false) -> void:
	impact_time = 0.055 if heavy else 0.035
	Engine.time_scale = 0.22
	shake = maxf(shake, 3.0 if heavy else 1.5)
	var cam := get_parent().get_node_or_null("BladeGoblin/Camera2D") as Camera2D
	if is_instance_valid(cam):
		CameraFX.shake(cam, 3.0 if heavy else 1.5, 0.12)
	play_cue("hurt" if heavy else "hit")

func play_cue(cue: String) -> void:
	if sound_cooldown > 0.0 or not sounds.has(cue):
		return
	for voice in voices:
		if not voice.playing:
			voice.stream = sounds[cue]
			voice.play()
			sound_cooldown = 0.025
			return

func _make_sound(cue: String) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var data := PackedByteArray()
	var count := 2646
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var phase := 0.0
	for index in range(count):
		var t := float(index) / count
		var frequency := 160.0 if cue in ["hit", "hurt"] else (720.0 if cue == "interact" else 500.0)
		phase += TAU * frequency * (1.0 - t * 0.7) / 22050.0
		var noise := 0.04 if cue == "interact" else 0.35
		var sample := (sin(phase) * (1.0 - noise) + rng.randf_range(-1.0, 1.0) * noise) * pow(1.0 - t, 3.0) * minf(t * 30.0, 1.0)
		data.encode_s16(index * 2, int(sample * 24000.0))
	stream.data = data
	return stream

func _exit_tree() -> void:
	for voice in voices:
		voice.stop()
		voice.stream = null
	sounds.clear()
	Engine.time_scale = 1.0

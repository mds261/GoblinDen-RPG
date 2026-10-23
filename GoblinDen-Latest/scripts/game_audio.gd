extends Node
## Local original score, crossfades, voice-limited effects and independent volume.
const MUSIC := {
	"haven":preload("res://assets/audio/music_haven.wav"),
	"woodland":preload("res://assets/audio/music_woodland.wav"),
	"descent":preload("res://assets/audio/music_descent.wav")
}
const EFFECTS := {
	"hit":preload("res://assets/audio/hit.wav"),"hurt":preload("res://assets/audio/hurt.wav"),
	"swing":preload("res://assets/audio/swing.wav"),"dodge":preload("res://assets/audio/dodge.wav"),
	"interact":preload("res://assets/audio/interact.wav"),"bow":preload("res://assets/audio/bow.wav"),
	"magic":preload("res://assets/audio/magic.wav"),"loot":preload("res://assets/audio/loot.wav"),
	"coin":preload("res://assets/audio/coin.wav"),"potion":preload("res://assets/audio/potion.wav"),
	"death":preload("res://assets/audio/death.wav"),"level_up":preload("res://assets/audio/level_up.wav"),
	"stairs":preload("res://assets/audio/stairs.wav"),"boss":preload("res://assets/audio/boss.wav"),
	"step_stone":preload("res://assets/audio/step_stone.wav"),"step_grass":preload("res://assets/audio/step_grass.wav")
}
# Cue-specific balance keeps small repeated actions behind music and combat.
const CUE_GAIN_DB := {
	"hit":-10.0,"hurt":-11.0,"swing":-13.0,"dodge":-14.0,"bow":-12.0,
	"magic":-15.0,"interact":-16.0,"loot":-15.0,"coin":-16.0,
	"potion":-14.0,"death":-13.0,"level_up":-14.0,"stairs":-15.0,
	"boss":-15.0,"step_stone":-24.0,"step_grass":-24.0
}
const COMBAT_CUES := ["hit","hurt","swing","bow","magic","boss"]
const SETTINGS := "user://audio_settings.cfg"
var game: Node2D
var music_level := 0.35
var effects_level := 0.75
var music_players: Array[AudioStreamPlayer] = []
var voices: Array[AudioStreamPlayer] = []
var gains: Array[float] = [0.0,0.0]
var desired: Array[float] = [0.0,0.0]
var current_mood := ""
var cooldowns: Dictionary = {}
var duck_db := 0.0
var last_room := -1
var last_position := Vector2.ZERO
var step_distance := 0.0
var loops: Dictionary = {}

static func ensure_buses() -> void:
	for bus_name in ["Music","SFX"]:
		if AudioServer.get_bus_index(bus_name)<0:
			AudioServer.add_bus()
			var index := AudioServer.bus_count-1
			AudioServer.set_bus_name(index,bus_name)
			AudioServer.set_bus_send(index,"Master")
	for index in range(AudioServer.get_bus_effect_count(0)):
		if AudioServer.get_bus_effect(0,index).resource_name=="GoblinMixLimiter":
			return
	var limiter := AudioEffectHardLimiter.new()
	limiter.resource_name = "GoblinMixLimiter"
	limiter.ceiling_db = -1.0
	limiter.pre_gain_db = 0.0
	AudioServer.add_bus_effect(0,limiter)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_audio")
	add_to_group("combat_feedback")
	ensure_buses()
	var settings := ConfigFile.new()
	if settings.load(SETTINGS)==OK:
		music_level = clampf(float(settings.get_value("audio","music",0.35)),0,1)
		effects_level = clampf(float(settings.get_value("audio","effects",0.75)),0,1)
	_apply_levels()
	for mood in MUSIC:
		var stream: AudioStreamWAV = MUSIC[mood].duplicate()
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = int(round(stream.get_length()*stream.mix_rate))
		loops[mood] = stream
	for index in range(2):
		var player := AudioStreamPlayer.new()
		player.bus = "Music"
		player.volume_db = -60
		add_child(player)
		music_players.append(player)
	for index in range(8):
		var voice := AudioStreamPlayer.new()
		voice.bus = "SFX"
		add_child(voice)
		voices.append(voice)
	_switch_music(mood_for_room(game.current_room))

func mood_for_room(room_id: int) -> String:
	if room_id==0 and is_instance_valid(game.player):
		return "haven" if game.is_den_room() else "descent"
	if room_id in [0,7,8,9,10]:
		return "haven"
	return "woodland" if room_id in [5,6] else "descent"

func _switch_music(mood: String) -> void:
	if mood==current_mood or not loops.has(mood):
		return
	current_mood = mood
	# Preserve the louder voice during rapid room transitions.
	var slot := 0 if gains[0]<=gains[1] else 1
	music_players[slot].stop()
	music_players[slot].stream = loops[mood]
	gains[slot] = 0.0
	music_players[slot].volume_db = -60
	music_players[slot].play()
	desired[slot] = 1.0
	desired[1-slot] = 0.0

func _process(delta: float) -> void:
	var real_delta := delta/maxf(Engine.time_scale,0.01)
	_switch_music(mood_for_room(game.current_room))
	duck_db = move_toward(duck_db,-4.0 if get_tree().paused else 0.0,real_delta*6.0)
	for index in range(2):
		gains[index] = move_toward(gains[index],desired[index],real_delta*0.6)
		music_players[index].volume_db = -5.0+linear_to_db(maxf(gains[index],0.001))+duck_db
		if gains[index]<=0 and desired[index]<=0:
			music_players[index].stop()
	for cue in cooldowns.keys():
		cooldowns[cue] = maxf(0,float(cooldowns[cue])-real_delta)
	_update_footsteps()

func _update_footsteps() -> void:
	if not is_instance_valid(game.player):
		return
	var position: Vector2 = game.player.position
	var distance := last_position.distance_to(position)
	last_position = position
	if game.current_room!=last_room or distance>120.0 or get_tree().paused or game.player.hp<=0 or game.player.dodge_time>0.0 or game.rpg!=null and game.rpg.input_blocked():
		last_room = game.current_room
		step_distance = 0.0
		return
	step_distance += distance
	if step_distance>=68.0:
		step_distance = fmod(step_distance,68.0)
		play_sfx("step_grass" if game.current_room in [5,6,10] else "step_stone")

func play_sfx(cue: String) -> bool:
	if not EFFECTS.has(cue) or float(cooldowns.get(cue,0.0))>0.0:
		return false
	if cue in COMBAT_CUES and float(cooldowns.get("combat_mix",0.0))>0.0:
		return false
	for voice in voices:
		if voice.playing:
			continue
		voice.stream = EFFECTS[cue]
		voice.pitch_scale = randf_range(0.97,1.03) if cue not in ["level_up","interact"] else 1.0
		voice.volume_db = float(CUE_GAIN_DB.get(cue,-14.0))
		voice.play()
		cooldowns[cue] = 0.22 if cue.begins_with("step_") else (0.25 if cue in ["coin","loot","interact","magic"] else 0.12)
		if cue in COMBAT_CUES:
			cooldowns["combat_mix"] = 0.075
		return true
	return false

func play_cue(cue: String) -> void:
	if cue=="swing" and is_instance_valid(game.player):
		cue = "bow" if game.player.class_id=="archer" else ("magic" if game.player.class_id=="mage" else "swing")
	play_sfx(cue)

func impact(heavy: bool = false) -> void:
	play_sfx("hurt" if heavy else "hit")

func set_music_volume(value: float) -> void:
	music_level = clampf(value,0,1)
	_apply_levels()
	_save_settings()

func set_effects_volume(value: float) -> void:
	effects_level = clampf(value,0,1)
	_apply_levels()
	_save_settings()

func _apply_levels() -> void:
	for entry in [["Music",music_level],["SFX",effects_level]]:
		var index := AudioServer.get_bus_index(str(entry[0]))
		AudioServer.set_bus_volume_db(index,linear_to_db(maxf(float(entry[1]),0.0001)))
		AudioServer.set_bus_mute(index,float(entry[1])<=0.001)

func _save_settings() -> void:
	var settings := ConfigFile.new()
	settings.set_value("audio","music",music_level)
	settings.set_value("audio","effects",effects_level)
	settings.save(SETTINGS)

func _exit_tree() -> void:
	for player in music_players:
		player.stop()
		player.stream = null
	for voice in voices:
		voice.stop()
		voice.stream = null
	loops.clear()
	music_players.clear()
	voices.clear()

extends "res://scripts/large_enemy.gd"
## An original treasure-vault ambush. Visual states and damage states are separate.
const Art = preload("res://scripts/descent_art.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const Coin = preload("res://scripts/projectile.gd")
var boss_state := "dormant"
var state_time := 0.0
var state_total := 1.0
var attack_index := 0
var locked_direction := Vector2.LEFT
var phase_two := false
var attack_hit := false
var death_elapsed := 0.0
var hit_reaction := 0.0
var pulse_elapsed := 5.0
var pulse_point := Vector2.ZERO
var home := Vector2(2330,1260)
var journal_owner: Node
func _ready() -> void:
	var definition: Dictionary = preload("res://scripts/design_catalog.gd").record("monsters", "vault_hunger")
	display_name = str(definition.name)
	enemy_kind = "vault_hunger"
	role = "boss"
	max_hp = int(definition.hp)
	hp = max_hp
	speed = float(definition.speed)
	damage = int(definition.damage)
	scrap_reward = int(definition.scrap)
	xp_reward = int(definition.xp)
	loot_drop_id = str(definition.loot)
	target = get_tree().get_first_node_in_group("player")
	collision_layer = 0
	collision_mask = 1
func awaken() -> void:
	if boss_state != "dormant":
		return
	add_to_group("enemies")
	collision_layer = 2
	boss_state = "reveal"
	get_tree().call_group("game_audio","play_sfx","boss")
	state_time = 1.5
	state_total = state_time
	show_floating_text("THAT ISN'T TREASURE...")
	get_parent().get_parent().show_notice("The vault stirs. Watch the ground and keep moving!")
func reset_encounter_motion() -> void:
	velocity = Vector2.ZERO
	knockback = Vector2.ZERO
	windup = 0.0
	if hp > 0 and boss_state != "dormant":
		boss_state = "recover"
		state_time = 1.5
func _process(delta: float) -> void:
	animation_time += delta
	pulse_elapsed += delta
	hit_reaction = maxf(0,hit_reaction-delta)
	if hp <= 0:
		death_elapsed += delta
	queue_redraw()
func _physics_process(delta: float) -> void:
	z_index = int(position.y)
	flash = maxf(0,flash-delta)
	status_text_time = maxf(0,status_text_time-delta)
	velocity = Vector2.ZERO
	if hp <= 0 or not is_instance_valid(target):
		return
	if boss_state == "dormant":
		if Layout.ARENA.grow(-50).has_point(target.position):
			awaken()
		return
	_process_damage_over_time(delta)
	if hp <= 0:
		return
	slow_timer = maxf(0,slow_timer-delta)
	if stun_timer > 0:
		stun_timer = maxf(0,stun_timer-delta)
		boss_state = "recover"
		state_time = 0.8
		return
	state_time -= delta
	match boss_state:
		"reveal", "enrage":
			if state_time <= 0:
				_recover(1.0)
		"recover":
			if state_time <= 0:
				if hp <= max_hp*0.45 and not phase_two:
					phase_two = true
					_begin("enrage",1.5)
					show_floating_text("THE VAULT AWAKENS")
				else:
					boss_state = "hunt"
		"hunt":
			var offset: Vector2 = target.position-position
			if not Layout.ARENA.has_point(target.position):
				_recover(1.0)
			elif offset.length() < 270:
				attack_index += 1
				var kind: String = ["bite", "coins", "slam"][(attack_index-1)%3]
				_begin(kind,1.2 if kind == "slam" else 0.95)
			else:
				velocity = _route_to(target.position)*speed*(1.2 if phase_two else 1.0)*(0.6 if slow_timer>0 else 1.0)
		"bite", "coins", "slam":
			windup = maxf(0,state_time)
			if state_time <= 0:
				_release()
		"lunging":
			velocity = locked_direction*320
			if not attack_hit and target.position.distance_to(position)<125 and locked_direction.dot(position.direction_to(target.position))>0.15:
				target.take_damage(damage)
				attack_hit = true
			if state_time <= 0:
				_recover(1.4)
	velocity += knockback
	knockback = knockback.move_toward(Vector2.ZERO,900*delta)
	move_and_slide()
	position = position.clamp(Layout.ARENA.position+Vector2(65,65),Layout.ARENA.end-Vector2(65,65))
func _begin(kind: String, duration: float) -> void:
	boss_state = kind
	state_time = duration
	state_total = duration
	windup_total = duration
	windup = duration
	locked_direction = position.direction_to(target.position)
	strike_position = target.position.clamp(Layout.ARENA.position+Vector2(100,100),Layout.ARENA.end-Vector2(100,100))
	if kind in ["bite","coins","slam"]:
		show_floating_text({"bite":"JAWS — STEP ASIDE", "coins":"COIN STORM — FIND A GAP", "slam":"VAULT CRASH — LEAVE THE RING"}[kind])
func _release() -> void:
	get_tree().call_group("game_audio","play_sfx","coin" if boss_state=="coins" else ("boss" if boss_state=="slam" else "swing"))
	windup = 0
	match boss_state:
		"bite":
			boss_state = "lunging"
			state_time = 0.35
			attack_hit = false
		"coins":
			var count := 16 if phase_two else 12
			for i in range(count):
				var angle := TAU*i/count + locked_direction.angle()
				var shot := Coin.new()
				shot.position = position+Vector2.from_angle(angle)*75
				shot.velocity = Vector2.from_angle(angle)*210
				shot.damage = 8
				shot.from_player_team = false
				shot.style = "cursed_coin"
				shot.owner_actor = self
				shot.add_to_group("dungeon_boss_projectiles")
				get_parent().add_child(shot)
			_recover(1.5)
		"slam":
			position = strike_position
			pulse_point = position
			pulse_elapsed = 0.0
			if target.position.distance_to(position) < 150:
				target.take_damage(damage+5)
			get_parent().get_parent()._shake_camera(7,0.25)
			_recover(1.8)
func _recover(duration: float) -> void:
	boss_state = "recover"
	state_time = duration
	state_total = duration
	windup = 0
func take_damage(amount: int, direction: Vector2 = Vector2.ZERO) -> void:
	if boss_state == "dormant" or hp <= 0:
		return
	hit_reaction = 0.2
	super.take_damage(int(amount*1.25) if boss_state == "recover" else amount,direction*0.2)
	if hp <= 0:
		boss_state = "dying"
		death_elapsed = 0
		remove_from_group("enemies")
		for shot in get_tree().get_nodes_in_group("dungeon_boss_projectiles"):
			shot.queue_free()
func _draw() -> void:
	if pulse_elapsed < 0.65:
		var p := pulse_elapsed/0.65
		draw_arc(to_local(pulse_point),30+180*p,0,TAU,64,Color(1,0.7,0.25,1-p),7*(1-p),true)
	if boss_state in ["bite","coins","slam"]:
		var progress := 1.0-state_time/maxf(0.1,state_total)
		if boss_state == "slam":
			var center := to_local(strike_position)
			draw_circle(center,150,Color(0.85,0.13,0.12,0.18))
			draw_arc(center,150,0,TAU,64,Color("ffce83"),3,true)
			draw_arc(center,150,-PI/2,-PI/2+TAU*progress,64,Color("ff5f48"),6,true)
		elif boss_state == "bite":
			var angle := locked_direction.angle()
			var points := PackedVector2Array([Vector2.ZERO])
			for i in range(17):
				points.append(Vector2.from_angle(angle-0.65+1.3*i/16)*230)
			draw_colored_polygon(points,Color(0.9,0.18,0.1,0.22))
		else:
			draw_arc(Vector2.ZERO,150+progress*30,0,TAU,48,Color(0.95,0.7,0.15,0.5),3,true)
	var awake := boss_state != "dormant"
	var death := clampf(death_elapsed/1.8,0,1) if hp<=0 else 0.0
	var bob := sin(animation_time*(8 if velocity.length()>10 else 3))* (5 if velocity.length()>10 else 2)
	var leap := -sin(clampf(1-state_time/maxf(0.1,state_total),0,1)*PI)*50 if boss_state == "slam" else 0.0
	draw_set_transform(Vector2(sin(hit_reaction*80)*hit_reaction*18,bob+leap+death*25),death*0.2,Vector2(1,1-death*0.45))
	var frame := 0
	if awake:
		frame = 2 if velocity.length() > 10 and int(animation_time*6)%2==1 else 1
		if boss_state in ["bite","lunging","reveal"]:
			frame = 3
		elif boss_state in ["slam","coins","enrage"]:
			frame = 4
	if hp <= 0:
		frame = 5
	var art := Art.boss_frame(frame)
	var box := Vector2(260,245) if frame > 0 else Vector2(165,145)
	var tint := Color(1,1,1) if flash <= 0 else Color(1.65,1.45,1.2)
	if phase_two and hp > 0:
		tint = tint.lerp(Color(1.25,0.88,0.7),0.24)
	draw_texture_rect(art,Art.fitted(art,Vector2.ZERO,box,0.76),false,tint)
	if hp<=0:
		for i in range(20):
			var direction := Vector2.from_angle(i*2.4)
			var point := direction*death*140+Vector2(0,-sin(death*PI)*65)
			draw_circle(point,4,Color(1,0.75,0.2,1-death))
	draw_set_transform(Vector2.ZERO)
	if awake and hp>0:
		draw_rect(Rect2(-115,-226,230,24),Color(0.03,0.02,0.025,0.9))
		draw_string(ThemeDB.fallback_font,Vector2(-108,-209),display_name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("ffe0a1"))
		draw_rect(Rect2(-105,-198,210,8),Color("38242a"))
		draw_rect(Rect2(-105,-198,210*float(hp)/max_hp,8),Color("be5943"))
		if status_text_time>0:
			draw_string(ThemeDB.fallback_font,Vector2(-110,-242),status_text,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffcf85"))

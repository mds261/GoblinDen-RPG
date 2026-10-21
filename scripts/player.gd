extends CharacterBody2D
## Playable Goblin Hero (Sections 1, 3, 6 & 7 of Concept Document).
## Supports 4 Core Classes (Blade, Archer, Knight, Mage), 9 Class Evolutions,
## Secondary Tactical Skills (Q / Right Click), Shadow Ambush Stealth,
## Traps, Potions (F), XP/Leveling, and Story-Driven Human Equipment.

const CLASS_ART := {
	"blade": preload("res://assets/goblin_class_blade.png"),
	"archer": preload("res://assets/goblin_class_archer.png"),
	"knight": preload("res://assets/goblin_class_knight.png"),
	"mage": preload("res://assets/goblin_class_mage.png")
}
const PaintedActor = preload("res://scripts/painted_actor.gd")
const GoblinData = preload("res://scripts/goblin_data.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Trap = preload("res://scripts/trap.gd")
const FloatingText = preload("res://scripts/floating_text.gd")
const DeathEffect = preload("res://scripts/death_effect.gd")
const HitSpark = preload("res://scripts/hit_spark.gd")
const CameraFX = preload("res://scripts/camera_fx.gd")
const SpecialEffect = preload("res://scripts/special_effect.gd")

signal health_changed(current: int, maximum: int)
signal died
signal special_used(skill_name: String)
signal camera_shake_requested(intensity: float, duration: float)

@export var speed: float = 220.0
@export var max_hp: int = 100
@export var attack_damage: int = 25
@export var attack_range: float = 84.0

var animation_time: float = 0.0
var hp: int = 100
var facing := Vector2.RIGHT
var attack_cooldown: float = 0.0
var swing_time: float = 0.0
var invulnerability: float = 0.0
var dodge_cooldown: float = 0.0
var dodge_time: float = 0.0
var dodge_direction := Vector2.RIGHT
var attack_buffer: float = 0.0
var mouse_aim: bool = false

# Expanded RPG Class, Evolution, Level & Gear state
var class_id: String = "blade"
var evolution_id: String = ""
var level: int = 1
var xp: int = 0
var xp_to_next: int = 100
var bonus_damage: int = 0
var armor_rating: float = 0.0
var crit_chance: float = 0.22
var swing_counter: int = 0
var special_cooldown: float = 0.0
var bulwark_timer: float = 0.0
var miasma_flash_timer: float = 0.0
var miasma_center := Vector2.ZERO
var stealth_ambush: bool = false
var stealth_timer: float = 0.0
var venom_coating_timer: float = 0.0
var equipped_loot_id: String = ""
var trap_bonus_damage: int = 0
var ranged_bonus_damage: int = 0
var magic_bonus_damage: int = 0
var last_damage_taken: int = 0
var hit_flash_time: float = 0.0

func _ready() -> void:
	hp = max_hp

func apply_class_and_gear(new_class_id: String, new_evo_id: String = "", keep_hp_ratio: bool = true) -> void:
	if not GoblinData.CLASSES.has(new_class_id):
		return
	var ratio := float(hp) / float(maxi(1, max_hp))
	class_id = new_class_id
	evolution_id = new_evo_id if GoblinData.EVOLUTIONS.has(new_evo_id) else ""
	var cdata: Dictionary = GoblinData.CLASSES[class_id]
	var edata: Dictionary = GoblinData.EVOLUTIONS.get(evolution_id, {})
	var ldata: Dictionary = GoblinData.LOOT_ITEMS.get(equipped_loot_id, {})
	var base_max_hp: int = int(cdata["max_hp"]) + int(edata.get("hp_bonus", 0)) + int(ldata.get("max_hp", 0)) + (level - 1) * 10
	max_hp = maxi(50, base_max_hp)
	if keep_hp_ratio:
		hp = clampi(int(round(max_hp * ratio)), 1, max_hp)
	else:
		hp = max_hp
	var base_spd: float = float(cdata["speed"]) + float(edata.get("speed_bonus", 0.0))
	speed = base_spd * float(ldata.get("speed_mult", 1.0))
	attack_range = float(cdata["attack_range"])
	armor_rating = clampf(float(cdata["armor"]) + float(edata.get("armor_bonus", 0.0)) + float(ldata.get("armor_bonus", 0.0)), 0.0, 0.70)
	crit_chance = clampf(float(cdata["crit_chance"]) + float(edata.get("crit_bonus", 0.0)) + float(ldata.get("crit_bonus", 0.0)), 0.0, 0.85)
	bonus_damage = int(edata.get("damage_bonus", 0)) + int(ldata.get("damage", 0)) + (level - 1) * 4
	health_changed.emit(hp, max_hp)
	queue_redraw()

func get_class_title() -> String:
	if evolution_id != "" and GoblinData.EVOLUTIONS.has(evolution_id):
		return GoblinData.EVOLUTIONS[evolution_id]["name"]
	return GoblinData.CLASSES[class_id]["name"]

func get_effective_damage() -> int:
	var cdata: Dictionary = GoblinData.CLASSES[class_id]
	var class_offset: int = int(cdata["base_damage"]) - 25
	var extra: int = bonus_damage + class_offset
	if class_id == "archer":
		extra += ranged_bonus_damage
	elif class_id == "mage":
		extra += magic_bonus_damage
	# Berserker deals up to +35% more damage when wounded
	if evolution_id == "berserker" and hp < max_hp:
		var missing := 1.0 - float(hp) / float(max_hp)
		extra += int(round((attack_damage + extra) * missing * 0.35))
	return maxi(5, attack_damage + extra)

func heal(amount: int) -> void:
	if hp <= 0:
		return
	hp = mini(max_hp, hp + amount)
	health_changed.emit(hp, max_hp)
	queue_redraw()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		mouse_aim = true
	elif event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_SPACE:
			mouse_aim = false
	if event is InputEventMouseButton and event.pressed:
		mouse_aim = true

func _physics_process(delta: float) -> void:
	animation_time += delta
	z_index = int(position.y)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	swing_time = maxf(0.0, swing_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_time = maxf(0.0, dodge_time - delta)
	special_cooldown = maxf(0.0, special_cooldown - delta)
	bulwark_timer = maxf(0.0, bulwark_timer - delta)
	miasma_flash_timer = maxf(0.0, miasma_flash_timer - delta)
	venom_coating_timer = maxf(0.0, venom_coating_timer - delta)
	hit_flash_time = maxf(0.0, hit_flash_time - delta)
	# Update camera shake on the Camera2D child
	var cam := get_node_or_null("Camera2D")
	if is_instance_valid(cam):
		CameraFX.update_shake(cam, delta)
	if hp <= 0:
		return
	# Check shadow ambush zone in cave
	var cave = get_parent().get_node_or_null("Cave")
	if is_instance_valid(cave) and cave.has_method("is_in_shadow_pool") and cave.is_in_shadow_pool(global_position):
		stealth_timer += delta
		if stealth_timer >= 0.45:
			stealth_ambush = true
	else:
		stealth_timer = 0.0
		stealth_ambush = false
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction != Vector2.ZERO:
		facing = direction
	if mouse_aim and global_position.distance_to(get_global_mouse_position()) > 12.0:
		facing = global_position.direction_to(get_global_mouse_position())
	if Input.is_action_just_pressed("dodge"):
		start_dodge()
	velocity = direction * speed
	if dodge_time > 0.0:
		velocity = dodge_direction * speed * 2.8
	move_and_slide()
	# The exterior disables camera smoothing. Force the scroll transform after
	# movement so Web builds cannot display one frame (or more) of stale view.
	if is_instance_valid(cam) and not cam.position_smoothing_enabled:
		cam.force_update_scroll()
	attack_buffer = maxf(0.0, attack_buffer - delta)
	if Input.is_action_just_pressed("attack"):
		attack_buffer = 0.14
	if attack_buffer > 0.0 and attack_cooldown <= 0.0 and dodge_time <= 0.0:
		attack_buffer = 0.0
		attack()
	if Input.is_action_just_pressed("special_skill") and special_cooldown <= 0.0:
		use_special()
	queue_redraw()

func start_dodge() -> void:
	if hp <= 0 or dodge_cooldown > 0.0:
		return
	var movement := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	dodge_direction = movement if movement != Vector2.ZERO else facing
	get_tree().call_group("combat_feedback", "play_cue", "dodge")
	dodge_time = 0.18
	dodge_cooldown = 1.1 if class_id != "blade" else 0.92
	invulnerability = maxf(invulnerability, 0.25)

func attack() -> void:
	if hp <= 0 or attack_cooldown > 0.0 or dodge_time > 0.0:
		return
	var cdata: Dictionary = GoblinData.CLASSES[class_id]
	var ldata: Dictionary = GoblinData.LOOT_ITEMS.get(equipped_loot_id, {})
	var cd_mult: float = float(ldata.get("cooldown_mult", 1.0))
	if evolution_id == "berserker" and hp < max_hp * 0.6:
		cd_mult *= 0.82
	attack_cooldown = float(cdata["attack_cooldown"]) * cd_mult
	swing_time = 0.16
	get_tree().call_group("combat_feedback", "play_cue", "swing")
	swing_counter += 1
	var base_dmg := get_effective_damage()
	var is_ambush_or_combo := stealth_ambush or (swing_counter % 3 == 0 and (level > 1 or evolution_id != "" or class_id != "blade"))
	if is_ambush_or_combo:
		base_dmg = int(round(base_dmg * (1.65 if evolution_id == "assassin" else 1.45)))
		stealth_ambush = false
		stealth_timer = 0.0
	var bleed_val: int = int(cdata["bleed_dps"]) + (6 if evolution_id in ["assassin", "berserker"] else 0)
	var poison_val: int = int(cdata["poison_dps"]) + (8 if venom_coating_timer > 0.0 or evolution_id in ["assassin", "shaman", "hunter"] else 0)
	# Close-range melee check works for all classes (and is primary for Blade & Knight Goblin)
	var hit_any_melee := false
	var melee_reach := attack_range if not bool(cdata["ranged"]) else 84.0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() <= melee_reach and facing.dot(offset.normalized()) > 0.25:
			var ray := PhysicsRayQueryParameters2D.create(global_position, enemy.global_position, 1)
			if get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
				enemy.take_damage(base_dmg, facing)
				# Polish: hit spark + floating damage number
				HitSpark.melee_hit(get_parent(), enemy.global_position, is_ambush_or_combo)
				FloatingText.spawn_damage(get_parent(), enemy.global_position + Vector2(0, -20), base_dmg, is_ambush_or_combo)
				if is_ambush_or_combo:
					camera_shake_requested.emit(5.0, 0.18)
					if enemy.has_method("show_floating_text"):
						enemy.show_floating_text("AMBUSH CRIT!")
				if (is_ambush_or_combo or venom_coating_timer > 0.0 or evolution_id != "") and enemy.has_method("apply_status"):
					enemy.apply_status(bleed_val, poison_val, 1.2 if class_id == "mage" else 0.0)
				if evolution_id == "berserker":
					var heal_amt := maxi(2, int(base_dmg * 0.18))
					heal(heal_amt)
					FloatingText.spawn_heal(get_parent(), global_position + Vector2(0, -16), heal_amt)
				hit_any_melee = true
	# Ranged classes (Archer Goblin & Mage Goblin) also launch projectiles!
	if bool(cdata["ranged"]):
		_spawn_class_projectiles(base_dmg, bleed_val, poison_val)
	queue_redraw()

func _spawn_class_projectiles(dmg: int, bleed_val: int, poison_val: int) -> void:
	var room_node := _get_active_room_node()
	if not is_instance_valid(room_node):
		return
	var angles: Array[float] = [0.0]
	if evolution_id == "hunter":
		angles = [-0.18, 0.0, 0.18]
	for ang in angles:
		var shot := Projectile.new()
		shot.global_position = global_position + facing * 20.0 + Vector2(0, -10)
		var dir := facing.rotated(ang).normalized()
		shot.velocity = dir * (460.0 if class_id == "archer" else 395.0)
		shot.damage = dmg if ang == 0.0 else maxi(6, int(dmg * 0.65))
		shot.from_player_team = true
		shot.owner_actor = self
		shot.style = "arrow" if class_id == "archer" else ("fire" if evolution_id == "warlock" else "hex")
		shot.poison_dps = poison_val
		shot.bleed_dps = bleed_val
		shot.slow_time = 1.6 if class_id == "mage" else 0.0
		shot.splash_radius = 64.0 if class_id == "mage" else 0.0
		shot.lifesteal_ratio = 0.20 if evolution_id == "warlock" else 0.0
		room_node.add_child(shot)

func use_special() -> void:
	if hp <= 0 or special_cooldown > 0.0:
		return
	var cdata: Dictionary = GoblinData.CLASSES[class_id]
	special_cooldown = float(cdata["special_cooldown"])
	swing_time = 0.25
	var room_node := _get_active_room_node()
	var dmg := int(round(get_effective_damage() * 1.45))
	match class_id:
		"blade":
			if evolution_id == "assassin":
				dodge_direction = facing
				dodge_time = 0.42
				invulnerability = maxf(invulnerability, 0.72)
				var execution_center := global_position + facing * 72.0
				_spawn_special_vfx("assassin", execution_center, 168.0)
				_damage_special_area(execution_center, 138.0, int(dmg * 1.65), 20, 16, 2.4, 0.35, "EXECUTED!")
				camera_shake_requested.emit(12.0, 0.32)
			elif evolution_id == "berserker":
				invulnerability = maxf(invulnerability, 0.42)
				_spawn_special_vfx("berserker", global_position, 174.0)
				var blood_hits := _damage_special_area(global_position, 148.0, int(dmg * 1.45), 24, 0, 0.8, 0.2, "BLOODSTORM!")
				var blood_heal := 14 + blood_hits * 8
				heal(blood_heal)
				FloatingText.spawn_heal(get_parent(), global_position + Vector2(0, -16), blood_heal)
				camera_shake_requested.emit(13.0, 0.38)
			else:
				dodge_direction = facing
				dodge_time = 0.28
				invulnerability = maxf(invulnerability, 0.52)
				_spawn_special_vfx("blade", global_position + facing * 42.0, 142.0)
				_damage_special_area(global_position + facing * 36.0, 115.0, dmg, 12, 0, 1.5, 0.0, "BLEED FLURRY!")
				camera_shake_requested.emit(9.0, 0.28)
		"archer":
			if is_instance_valid(room_node):
				var trap := Trap.new()
				trap.global_position = global_position + facing * 54.0
				trap.damage = 42 + trap_bonus_damage
				trap.bleed_dps = 12
				trap.poison_dps = 16
				trap.lifetime = 8.0
				if evolution_id == "hunter":
					trap.damage += 24
					trap.bleed_dps = 22
					trap.trigger_radius = 54.0
				elif evolution_id == "beastmaster":
					trap.damage += 12
					trap.snare_time = 4.4
					trap.trigger_radius = 58.0
					trap.lifetime = 10.0
				room_node.add_child(trap)
				if evolution_id == "hunter":
					_spawn_special_vfx("hunter", trap.global_position, 145.0)
					_spawn_venom_barrage(room_node, int(dmg * 1.18), 7, 0.13, 18, 15)
				elif evolution_id == "beastmaster":
					_spawn_special_vfx("beastmaster", trap.global_position, 152.0)
					_spawn_venom_barrage(room_node, dmg, 3, 0.20, 12, 8)
					for ally in get_tree().get_nodes_in_group("allies"):
						if is_instance_valid(ally):
							ally.warcry_timer = 8.0
							ally.hp = mini(ally.max_hp, ally.hp + 28)
				else:
					_spawn_special_vfx("archer", trap.global_position, 108.0)
					_spawn_venom_barrage(room_node, dmg)
			camera_shake_requested.emit(5.5, 0.18)
		"knight":
			if evolution_id == "warlord":
				bulwark_timer = 3.5
				_spawn_special_vfx("warlord", global_position, 184.0)
				_damage_special_area(global_position, 158.0, int(dmg * 1.35), 0, 0, 1.2, 1.7, "WARCRY!")
				for ally in get_tree().get_nodes_in_group("allies"):
					if is_instance_valid(ally):
						ally.warcry_timer = 8.0
				camera_shake_requested.emit(14.0, 0.42)
			elif evolution_id == "guardian":
				bulwark_timer = 8.0
				invulnerability = maxf(invulnerability, 1.0)
				_spawn_special_vfx("guardian", global_position, 178.0)
				_damage_special_area(global_position, 142.0, int(dmg * 0.9), 0, 0, 2.4, 2.8, "AEGIS STUN!")
				heal(32)
				FloatingText.spawn_heal(get_parent(), global_position + Vector2(0, -16), 32)
				for ally in get_tree().get_nodes_in_group("allies"):
					if is_instance_valid(ally):
						ally.hp = mini(ally.max_hp, ally.hp + 24)
				camera_shake_requested.emit(11.0, 0.40)
			else:
				bulwark_timer = 4.5
				invulnerability = maxf(invulnerability, 0.55)
				_spawn_special_vfx("knight", global_position, 148.0)
				_damage_special_area(global_position, 125.0, dmg, 0, 0, 1.2, 1.6, "IRONQUAKE!")
				camera_shake_requested.emit(11.0, 0.36)
		"mage":
			miasma_center = global_position + facing * 110.0
			miasma_flash_timer = 0.55
			if evolution_id == "shaman":
				_spawn_special_vfx("shaman", miasma_center, 164.0)
				_damage_special_area(miasma_center, 142.0, int(dmg * 1.05), 0, 22, 3.8, 0.5, "SPIRIT VENOM!")
				heal(38)
				FloatingText.spawn_heal(get_parent(), global_position + Vector2(0, -16), 38)
				for ally in get_tree().get_nodes_in_group("allies"):
					if is_instance_valid(ally) and ally.hp > 0:
						ally.hp = mini(ally.max_hp, ally.hp + 38)
						FloatingText.spawn_heal(get_parent(), ally.global_position + Vector2(0, -16), 38)
			elif evolution_id == "warlock":
				_spawn_special_vfx("warlock", miasma_center, 182.0)
				var soul_hits := _damage_special_area(miasma_center, 158.0, int(dmg * 1.62), 0, 18, 2.6, 0.8, "SOUL BURN!")
				var soul_heal := 12 + soul_hits * 10
				heal(soul_heal)
				FloatingText.spawn_heal(get_parent(), global_position + Vector2(0, -16), soul_heal)
			elif evolution_id == "necromancer":
				_spawn_special_vfx("necromancer", miasma_center, 172.0)
				_damage_special_area(miasma_center, 148.0, int(dmg * 1.25), 0, 8, 4.2, 1.2, "SOUL CLAIMED!")
			else:
				_spawn_special_vfx("mage", miasma_center, 138.0)
				_damage_special_area(miasma_center, 120.0, dmg, 0, 12, 2.8, 0.0, "HEXED!")
			camera_shake_requested.emit(9.0, 0.3)
	special_used.emit(get_special_name())
	queue_redraw()

func get_special_name() -> String:
	if evolution_id != "" and GoblinData.EVOLUTIONS.has(evolution_id):
		return str(GoblinData.EVOLUTIONS[evolution_id].get("special_name", GoblinData.CLASSES[class_id]["special_name"]))
	return str(GoblinData.CLASSES[class_id]["special_name"])

func _damage_special_area(center: Vector2, effect_radius: float, amount: int, bleed: int, poison: int, slow: float, stun: float, callout: String) -> int:
	var hit_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy.is_visible_in_tree() or enemy.hp <= 0:
			continue
		if enemy.global_position.distance_to(center) > effect_radius:
			continue
		var knockback: Vector2 = (enemy.global_position - center).normalized()
		if knockback == Vector2.ZERO:
			knockback = facing
		enemy.take_damage(amount, knockback)
		HitSpark.melee_hit(get_parent(), enemy.global_position, amount >= 50)
		FloatingText.spawn_damage(get_parent(), enemy.global_position + Vector2(0, -20), amount, amount >= 50)
		if enemy.has_method("apply_status") and (bleed > 0 or poison > 0 or slow > 0.0):
			enemy.apply_status(bleed, poison, slow)
		if stun > 0.0 and enemy.has_method("apply_stun"):
			enemy.apply_stun(stun)
		if callout != "" and enemy.has_method("show_floating_text"):
			enemy.show_floating_text(callout)
		hit_count += 1
	return hit_count

func _spawn_special_vfx(kind: String, world_position: Vector2, effect_radius: float) -> void:
	var room_node := _get_active_room_node()
	if not is_instance_valid(room_node):
		return
	var effect = SpecialEffect.new()
	effect.setup(kind, facing, effect_radius)
	room_node.add_child(effect)
	effect.global_position = world_position

func _spawn_venom_barrage(room_node: Node2D, dmg: int, arrow_count: int = 5, spread: float = 0.16, poison: int = 15, bleed: int = 8) -> void:
	var center_index := float(arrow_count - 1) * 0.5
	for index in range(arrow_count):
		var angle := (float(index) - center_index) * spread
		var shot := Projectile.new()
		shot.global_position = global_position + facing * 24.0 + Vector2(0, -10)
		shot.velocity = facing.rotated(angle).normalized() * 520.0
		shot.damage = dmg if is_equal_approx(float(index), center_index) else int(dmg * 0.72)
		shot.from_player_team = true
		shot.owner_actor = self
		shot.style = "arrow"
		shot.poison_dps = poison
		shot.bleed_dps = bleed
		room_node.add_child(shot)

func _get_active_room_node() -> Node2D:
	var game = get_parent()
	if is_instance_valid(game) and game.get("rooms") != null and game.rooms.size() > game.current_room:
		return game.rooms[game.current_room]
	return get_parent()

func take_damage(amount: int) -> void:
	if hp <= 0 or invulnerability > 0.0:
		return
	var final_amount := amount
	# Apply Knight Goblin / Guardian / Bulwark / Equipment armor reduction on normal combat hits
	if amount < 500:
		var total_reduction := armor_rating + (0.35 if bulwark_timer > 0.0 else 0.0)
		total_reduction = clampf(total_reduction, 0.0, 0.75)
		if total_reduction > 0.0:
			final_amount = maxi(1, int(round(amount * (1.0 - total_reduction))))
	hp = maxi(0, hp - final_amount)
	last_damage_taken = final_amount
	hit_flash_time = 0.15
	get_tree().call_group("combat_feedback", "impact", true)
	invulnerability = 0.65
	health_changed.emit(hp, max_hp)
	# Polish: floating damage number + camera shake on hit
	FloatingText.spawn_player_hit(get_parent(), global_position + Vector2(0, -30), final_amount)
	if final_amount >= 20:
		camera_shake_requested.emit(4.0, 0.15)
	queue_redraw()
	if hp == 0:
		# Polish: death burst effect
		DeathEffect.burst_ally(get_parent(), global_position)
		camera_shake_requested.emit(10.0, 0.35)
		died.emit()

func _draw() -> void:
	var cdata: Dictionary = GoblinData.CLASSES[class_id]
	var tint: Color = cdata["tint"]
	if stealth_ambush:
		tint = Color(0.55, 0.78, 0.68, 0.72)
	# Polish: brief red damage flash, brighter on heavier hits
	if hit_flash_time > 0.0:
		var flash_strength := clampf(hit_flash_time / 0.15, 0.0, 1.0)
		var heaviness := clampf(float(last_damage_taken) / 40.0, 0.35, 1.0)
		tint = tint.lerp(Color(1.0, 0.32, 0.28), flash_strength * 0.8 * heaviness)
	var role_visual := evolution_id if evolution_id != "" else ""
	var class_texture: Texture2D = CLASS_ART.get(class_id, CLASS_ART["blade"])
	var class_size := 94.0 if class_id != "knight" else 98.0
	PaintedActor.draw_actor(self, class_texture, class_size, facing.x < -0.05,
		animation_time, velocity.length() > 5.0, swing_time > 0.0,
		invulnerability > 0.0 and dodge_time <= 0.0, hp <= 0, tint, role_visual)
	if hp <= 0:
		return
	# Evolution aura ring
	if evolution_id != "" and GoblinData.EVOLUTIONS.has(evolution_id):
		var aura_col: Color = GoblinData.EVOLUTIONS[evolution_id]["aura_color"]
		draw_arc(Vector2(0, 8), 24.0, 0, TAU, 24, Color(aura_col.r, aura_col.g, aura_col.b, 0.38), 2.0, true)
	if bulwark_timer > 0.0:
		draw_arc(Vector2.ZERO, 34.0, 0, TAU, 28, Color(0.55, 0.82, 0.98, 0.65), 3.0, true)
	if stealth_ambush:
		draw_string(ThemeDB.fallback_font, Vector2(-34, -76), "AMBUSH READY", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color("8ce8b5"))
	if miasma_flash_timer > 0.0:
		var local_miasma := to_local(miasma_center)
		draw_circle(local_miasma, 110.0, Color(0.68, 0.25, 0.82, miasma_flash_timer * 0.45))
		draw_arc(local_miasma, 110.0, 0, TAU, 36, Color("d279f5"), 2.5, true)
	# A small ground chevron makes the actual attack direction unambiguous.
	var tip := facing * 32.0
	draw_line(tip, tip - facing.rotated(0.5) * 9.0, Color("d3d9a1"), 2, true)
	draw_line(tip, tip - facing.rotated(-0.5) * 9.0, Color("d3d9a1"), 2, true)
	if dodge_time > 0.0:
		draw_arc(Vector2.ZERO, 27, 0, TAU, 24, Color("a8d6c5"), 2, true)
	if swing_time > 0.0:
		var sweep := facing.angle() - 1.1 + (1.0 - swing_time / 0.16) * 2.2
		var arc_col := Color("f0dfac") if class_id != "mage" else Color("d88cf2")
		draw_arc(Vector2.ZERO, 65, sweep - 0.7, sweep, 16, Color(arc_col.r, arc_col.g, arc_col.b, 0.25), 12, true)
		draw_arc(Vector2.ZERO, 65, sweep - 0.7, sweep, 16, arc_col, 3, true)
	# Polish: cooldown arc indicators (ability + dodge)
	if special_cooldown > 0.0 and hp > 0:
		var cdata_cd: Dictionary = GoblinData.CLASSES[class_id]
		var max_cd: float = float(cdata_cd["special_cooldown"])
		var ratio := special_cooldown / max_cd
		var arc_angle := TAU * (1.0 - ratio)
		draw_arc(Vector2(0, 8), 30.0, -PI / 2, -PI / 2 + arc_angle, 24, Color("d4a0e8", 0.45), 2.0, true)
	if dodge_cooldown > 0.0 and hp > 0:
		var max_dodge_cd: float = 1.1 if class_id != "blade" else 0.92
		var dodge_ratio := dodge_cooldown / max_dodge_cd
		var dodge_arc := TAU * (1.0 - dodge_ratio)
		draw_arc(Vector2(0, 8), 34.0, -PI / 2, -PI / 2 + dodge_arc, 24, Color("a8d6c5", 0.35), 1.5, true)
	# Polish: venom coating glow
	if venom_coating_timer > 0.0 and hp > 0:
		draw_arc(Vector2(0, 4), 26.0, 0, TAU, 20, Color("5ce66a", 0.25 + 0.15 * sin(animation_time * 6.0)), 1.5, true)

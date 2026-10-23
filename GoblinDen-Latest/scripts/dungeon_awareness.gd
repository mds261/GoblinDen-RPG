extends RefCounted
## Local perception for dungeon guards. There is no floor-wide alarm.
const NOTICE_RADIUS := 350.0
const HOME_LEASH := 480.0
const TARGET_LEASH := 620.0
const LOST_SIGHT_SECONDS := 3.0
var home := Vector2.ZERO
var state := "idle"
var unseen_time := 0.0

func configure(actor: CharacterBody2D) -> void:
	home = actor.global_position
	state = "idle"
	unseen_time = 0.0

func sees(actor: CharacterBody2D, point: Vector2) -> bool:
	var ray := PhysicsRayQueryParameters2D.create(actor.global_position,point,1)
	return actor.get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func alert(actor: CharacterBody2D) -> void:
	if state != "engaged":
		actor.show_floating_text("ALERT")
	state = "engaged"
	unseen_time = 0.0

func reset(actor: CharacterBody2D) -> void:
	actor.velocity = Vector2.ZERO
	actor.windup = 0.0
	unseen_time = 0.0
	state = "returning" if actor.global_position.distance_to(home)>12.0 else "idle"

func step(actor: CharacterBody2D, delta: float) -> bool:
	if not is_instance_valid(actor.target) or actor.target.hp <= 0:
		state = "returning"
	else:
		var target_point: Vector2 = actor.target.global_position
		var distance := actor.global_position.distance_to(target_point)
		if state == "idle":
			if distance <= NOTICE_RADIUS and sees(actor,target_point):
				alert(actor)
		elif state == "engaged":
			if actor.global_position.distance_to(home)>HOME_LEASH or target_point.distance_to(home)>TARGET_LEASH:
				state = "returning"
			elif sees(actor,target_point) and distance<=HOME_LEASH:
				unseen_time = 0.0
			else:
				unseen_time += delta
				if unseen_time >= LOST_SIGHT_SECONDS:
					state = "returning"
	if state == "engaged":
		return true
	# Cancel pending ranged/spell attacks as soon as the guard disengages.
	actor.windup = 0.0
	actor.velocity = Vector2.ZERO
	if state == "returning":
		if actor.global_position.distance_to(home)<=12.0:
			state = "idle"
			unseen_time = 0.0
		else:
			actor.velocity = actor._route_to(home)*actor.speed*(0.55 if actor.slow_timer>0.0 else 1.0)
	return false

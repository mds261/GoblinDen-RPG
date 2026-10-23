extends Node2D
## Persistent fog-of-exploration. Terrain and landmarks reveal through actual sight lines.
const Starting = preload("res://scripts/starting_caves.gd")
const Layout = preload("res://scripts/dungeon_layout.gd")
const Den = preload("res://scripts/den_layout.gd")
const CELL := 48.0
const SIGHT := 192.0
var game: Node2D
var rpg: Node2D
var explored: Dictionary = {}
var known_markers: Dictionary = {}
var shown := true
var canvas: Node2D
var toggle: Button
var scan_timer := 0.0
var dirty_time := 0.0
var dirty := false
var last_room := -1
var last_position := Vector2(-9999,-9999)
func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 4
	add_child(layer)
	canvas = Node2D.new()
	canvas.position = Vector2(918,56)
	canvas.draw.connect(func(): _draw_map())
	layer.add_child(canvas)
	toggle = Button.new()
	toggle.position = Vector2(918,18)
	toggle.custom_minimum_size = Vector2(78,28)
	toggle.text = "Map [M]"
	toggle.pressed.connect(_toggle)
	layer.add_child(toggle)
func _toggle() -> void:
	shown = not shown
	canvas.visible = shown
	toggle.text = "Map [M]" if shown else "Map [M]"
	game._auto_save()
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode==KEY_M and not rpg.input_blocked():
		_toggle()
		get_viewport().set_input_as_handled()
func _physics_process(delta: float) -> void:
	if get_tree().paused or game.player.hp<=0:
		return
	scan_timer -= delta
	if dirty:
		dirty_time += delta
		if dirty_time>=5.0:
			dirty_time = 0.0
			dirty = false
			game._auto_save()
	if scan_timer>0:
		return
	scan_timer = 0.15
	# Exploration continues with a collapsed map, but standing still does not cast rays.
	if game.current_room != last_room or game.player.position.distance_to(last_position)>8.0:
		last_room = game.current_room
		last_position = game.player.position
		reveal_near_player()
	_discover_markers()
	canvas.queue_redraw()
func _notification(what: int) -> void:
	if what==NOTIFICATION_WM_CLOSE_REQUEST and game!=null and is_instance_valid(game):
		game._auto_save()
func cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point/CELL).floor())
func is_explored(room_id: int, point: Vector2) -> bool:
	return explored.has(room_id) and explored[room_id].has(cell_at(point))
func _visible(point: Vector2) -> bool:
	if point.distance_to(game.player.position)>SIGHT:
		return false
	var ray := PhysicsRayQueryParameters2D.create(game.player.position,point,1)
	var hit: Dictionary = game.get_world_2d().direct_space_state.intersect_ray(ray)
	return hit.is_empty() or Vector2(hit.position).distance_to(point)<=3.0
func reveal_near_player() -> void:
	var room_id: int = game.current_room
	if not explored.has(room_id):
		explored[room_id] = {}
	var bounds: Vector2 = game.get_node("Cave").world_size_for_room()
	var center := cell_at(game.player.position)
	for y in range(center.y-4,center.y+5):
		for x in range(center.x-4,center.x+5):
			var cell := Vector2i(x,y)
			var point := (Vector2(cell)+Vector2.ONE*0.5)*CELL
			if point.x<0 or point.y<0 or point.x>=bounds.x or point.y>=bounds.y or point.distance_to(game.player.position)>SIGHT:
				continue
			var ray := PhysicsRayQueryParameters2D.create(game.player.position,point,1)
			var hit: Dictionary = game.get_world_2d().direct_space_state.intersect_ray(ray)
			# A visible wall face may reveal its own cell, never the cells beyond it.
			if not hit.is_empty() and Vector2(hit.position).distance_to(point)>CELL*0.71:
				continue
			var query := PhysicsPointQueryParameters2D.new()
			query.position = point
			query.collision_mask = 1
			var floor_tile := game.get_world_2d().direct_space_state.intersect_point(query).is_empty()
			if not explored[room_id].has(cell) or bool(explored[room_id][cell])!=floor_tile:
				explored[room_id][cell] = floor_tile
				dirty = true
	# Always retain the tile occupied by the player.
	explored[room_id][center] = true
	_discover_markers()
func _markers() -> Array:
	var room_id: int = game.current_room
	var result: Array = []
	if Layout.is_dungeon(room_id):
		result.append({"id":"stairs_up","point":Layout.entry(room_id),"type":"route"})
		if room_id<15:
			result.append({"id":"stairs_down","point":Layout.stairs(room_id),"type":"route"})
			var positions: Array = Layout.seals(room_id)
			for i in range(2):
				result.append({"id":"seal_%d"%i,"point":positions[i],"type":"seal","active":rpg.dungeon.seals.has("%d_%d"%[room_id,i])})
		else:
			result.append({"id":"reliquary","point":Vector2(2440,1660),"type":"treasure"})
		result.append({"id":"side_vault","point":Layout.point(Vector2(480,400),room_id),"type":"treasure"})
	elif room_id in Den.PORTALS:
		for portal in Den.PORTALS[room_id]:
			result.append({"id":"door_%d"%int(portal.to),"point":portal.pos,"type":"route"})
	if room_id==0:
		result.append_array([{"id":"surface_exit","point":Starting.EXIT,"type":"route"},{"id":"chest","point":Starting.CHEST,"type":"treasure"}])
		for station in Den.STATIONS:
			result.append({"id":"station_%d"%int(station.cell),"point":station.pos,"type":"treasure"})
	if room_id>=1 and room_id<=5:
		result.append({"id":"back","point":Vector2(140,365),"type":"route"})
	if room_id>0 and room_id<6:
		result.append({"id":"forward","point":Vector2(1010,365),"type":"route"})
	if room_id==6:
		result.append_array([{"id":"settlement","point":Vector2(500,350),"type":"route"},{"id":"home","point":Vector2(700,350),"type":"route"},{"id":"bog","point":Vector2(1900,1000),"type":"route"},{"id":"cave","point":Vector2(310,245),"type":"route"}])
	if room_id in [10,11,12]:
		result.append({"id":"back","point":Vector2(145,365),"type":"route"})
	if room_id in [11,12]:
		result.append({"id":"forward","point":Vector2(1000,365),"type":"route"})
	for npc in get_tree().get_nodes_in_group("friendly_npcs"):
		if is_instance_valid(npc) and npc.is_visible_in_tree() and int(npc.definition.get("room",-1))==room_id:
			result.append({"id":"npc_"+str(npc.definition.id),"point":npc.position,"type":"npc"})
	for record in rpg.monster_corpses:
		if int(record.room)==room_id:
			result.append({"id":"loot_"+str(record.id),"point":record.position,"type":"treasure"})
	return result
func _discover_markers() -> void:
	var room_id: int = game.current_room
	if not known_markers.has(room_id):
		known_markers[room_id] = {}
	for marker in _markers():
		if not known_markers[room_id].has(marker.id) and is_explored(room_id,marker.point) and _visible(marker.point):
			known_markers[room_id][marker.id] = true
			dirty = true
func snapshot() -> Dictionary:
	return {"explored":explored,"known_markers":known_markers,"shown":shown}
func restore(state: Dictionary) -> void:
	explored = state.get("explored",{}).duplicate(true)
	known_markers = state.get("known_markers",{}).duplicate(true)
	shown = bool(state.get("shown",true))
	canvas.visible = shown
	toggle.text = "Map [M]" if shown else "Map [M]"
	last_room = -1
	scan_timer = 0
	canvas.queue_redraw()
func _draw_map() -> void:
	var room_id: int = game.current_room
	var size: Vector2 = game.get_node("Cave").world_size_for_room()
	var factor := minf(186.0/size.x,120.0/size.y)
	var offset := Vector2(0,22)
	canvas.draw_rect(Rect2(-10,-3,210,153),Color(0.015,0.025,0.03,0.96))
	var title := "FLOOR %d / 3"%(room_id-12) if Layout.is_dungeon(room_id) else "LOCAL AREA"
	canvas.draw_string(ThemeDB.fallback_font,Vector2(0,13),title+"",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("dccca5"))
	canvas.draw_rect(Rect2(offset,size*factor),Color("080b0e"))
	if explored.has(room_id):
		for cell in explored[room_id]:
			var color := Color("53665d") if bool(explored[room_id][cell]) else Color("293438")
			canvas.draw_rect(Rect2(offset+Vector2(cell)*CELL*factor,Vector2.ONE*CELL*factor+Vector2.ONE*0.3),color)
	for marker in _markers():
		if not known_markers.get(room_id,{}).has(marker.id) or not is_explored(room_id,marker.point):
			continue
		var color: Color = {"route":Color("eee1c1"),"npc":Color("9be190"),"treasure":Color("dfb45d"),"seal":Color("b9a6ed")}.get(str(marker.type),Color.WHITE)
		if bool(marker.get("active",false)):
			color = Color("a7ee74")
		canvas.draw_circle(offset+Vector2(marker.point)*factor,2.5,color)
	for corpse in rpg.corpses:
		if int(corpse.room)==room_id and is_explored(room_id,corpse.position):
			canvas.draw_circle(offset+Vector2(corpse.position)*factor,3,Color("e17a73"))
	var player_point: Vector2 = offset+game.player.position*factor
	canvas.draw_circle(player_point,3.5,Color("5ce6ef"))
	canvas.draw_line(player_point,player_point+game.player.facing.normalized()*8,Color("b4faff"),2,true)
	canvas.draw_rect(Rect2(-10,-3,210,153),Color("756342"),false,1)

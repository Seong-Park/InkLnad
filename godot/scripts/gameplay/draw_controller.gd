class_name DrawController
extends Node2D

signal tutorial_event(event: StringName, amount: float)
signal stamps_changed(stamps: Array[Dictionary])
var ink = preload("res://scripts/combat/combat_ink.gd").new()
var strokes = preload("res://scripts/combat/stroke_rules.gd").new()
var rules: Resource
var player: PlayerController
var camera: CameraController
var tool_id: StringName = &"brush"
var now: float = 0.0
var anchor: Vector2 = Vector2.ZERO
var cursor: Vector2 = Vector2.ZERO
var blocked_gesture: bool = false
var skill_locked: bool = false
var pending: Array[Vector2] = []
var direct_stamps: Array[Dictionary] = []
var _tool_data: Dictionary = {}
var stamp_batch: MultiMeshInstance2D

func configure(rule_resource: Resource, player_value: PlayerController, camera_value: CameraController) -> void:
	rules = rule_resource
	_tool_data.clear()
	for id in rules.tools:
		_tool_data[id] = rules.get_tool(StringName(id))
	player = player_value
	camera = camera_value
	ink.configure(100.0,100.0/3.5,0.5)
	strokes.configure(rules)
	if stamp_batch == null:
		stamp_batch = preload("res://scripts/combat/brush_stamp_batch.gd").new()
		stamp_batch.name = "BrushStampBatch"
		add_child(stamp_batch)

func handle_pointer(sample: Dictionary) -> void:
	var phase: StringName = sample.phase
	if sample.has("screen"):
		cursor = sample.screen
	if phase == &"release" or phase == &"cancel":
		cancel()
		return
	if phase == &"press":
		if skill_locked:
			return
		blocked_gesture = sample.get("ui_consumed",false) or not Rect2(0,0,1280,720).has_point(cursor)
		if blocked_gesture:
			return
		anchor = camera.screen_to_world(cursor)
		pending.clear()
		ink.press()
		player.start_cast()
	if phase == &"move" and sample.get("physical_motion",false) and ink.holding and not blocked_gesture:
		pending.append(camera.screen_to_world(cursor))
	queue_redraw()

func cancel() -> void:
	ink.release()
	blocked_gesture = false
	pending.clear()
	direct_stamps.clear()

func set_tool(value: StringName) -> void:
	cancel()
	tool_id = value

func tick(dt: float) -> void:
	if not player.casting:
		skill_locked = false
	now += dt
	direct_stamps.clear()
	strokes.expire(now)
	var data: Dictionary = _tool_data[String(tool_id)]
	var center: Vector2 = player.global_position
	var radius: float = 180.0 - float(data.width)/2.0
	var paths: Array[Dictionary] = []
	var total: float = 0.0
	var start: Vector2 = anchor
	for endpoint in pending:
		var clip: Dictionary = strokes.clip_path(start,endpoint,center,180.0,float(data.width)/2.0,start.distance_to(center)<=radius)
		if clip.valid:
			paths.append(clip)
			total += clip.start.distance_to(clip.end)
		start = endpoint
	anchor = start
	pending.clear()
	var in_range: bool = anchor.distance_to(center) <= radius
	ink.set_in_range(in_range or not paths.is_empty())
	if ink.holding and not blocked_gesture and not ink.depleted and (in_range or not paths.is_empty()):
		var ratio: float = ink.spend(float(data.upkeep)*dt+total*float(data.length_cost))
		var remaining: float = total * ratio
		for path in paths:
			if path.start.is_equal_approx(path.end) and ratio>0.0:
				direct_stamps.append_array(strokes.paint(path.start,path.end,tool_id,center,now))
				continue
			if remaining <= 0.0:
				break
			var distance: float = path.start.distance_to(path.end)
			var end: Vector2 = path.start.lerp(path.end,minf(1.0,remaining/maxf(distance,0.001)))
			direct_stamps.append_array(strokes.paint(path.start,end,tool_id,center,now))
			remaining -= distance
		if in_range and paths.is_empty() and ratio > 0.0:
			direct_stamps.append_array(strokes.paint(anchor,anchor,tool_id,center,now))
		if tool_id == &"brush":
			tutorial_event.emit(&"line",total*ratio)
			tutorial_event.emit(&"hold",dt*ratio)
	ink.set_in_range(in_range)
	var prior: float = ink.current
	ink.advance(dt)
	if ink.current > prior:
		tutorial_event.emit(&"recover",ink.current-prior)
	if stamps_changed.has_connections():
		stamps_changed.emit(strokes.get_active_stamps())
	queue_redraw()

func damage_at(point: Vector2, target_radius: float) -> Vector2:
	var direct: float = 0.0
	var residual: float = 0.0
	for stamp in direct_stamps:
		var reach: float = float(stamp.radius)+target_radius
		if point.distance_squared_to(stamp.center) <= reach*reach:
			direct = maxf(direct,float(_tool_data[String(stamp.tool_id)].direct_damage))
	for stamp in strokes.damage_candidates(point,target_radius):
		var reach: float = float(stamp.radius)+target_radius
		if point.distance_squared_to(stamp.center) <= reach*reach:
			residual = maxf(residual,float(_tool_data[String(stamp.tool_id)].residual_damage))
	return Vector2(direct,residual)

func _draw() -> void:
	if player == null:
		return
	stamp_batch.update_stamps(strokes.active_stamps_view(),now,_tool_data)
	if ink.holding:
		draw_arc(player.global_position,180,0,TAU,80,Color(0.23,0.2,0.18,0.25),1.0,true)
		var world_cursor: Vector2 = camera.screen_to_world(cursor)
		draw_circle(world_cursor,3,Color("D99835"))
		var valid: bool = anchor.distance_to(player.global_position)<=180.0-float(_tool_data[String(tool_id)].width)/2.0
		draw_arc(anchor,9,0,TAU,24,Color("1749C6") if valid else Color("8D3154"),2.0,true)
		if not valid:
			draw_line(anchor-Vector2(6,6),anchor+Vector2(6,6),Color("8D3154"),2.0)
			draw_line(anchor-Vector2(6,-6),anchor+Vector2(6,-6),Color("8D3154"),2.0)

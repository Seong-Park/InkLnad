extends Control

signal direction_changed(value: Vector2)
var direction: Vector2 = Vector2.ZERO
var finger: int = -1
var mouse_owned: bool = false

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index
			_set_direction(event.position-get_global_rect().get_center())
			get_viewport().set_input_as_handled()
		elif not event.pressed and event.index == finger:
			reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag and event.index == finger:
		_set_direction(event.position-get_global_rect().get_center())
		get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if event.device == -1:
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_owned = event.pressed
		_set_direction(event.position-size*0.5) if event.pressed else reset()
		accept_event()
	elif event is InputEventMouseMotion and mouse_owned:
		_set_direction(event.position-size*0.5)
		accept_event()

func _set_direction(offset: Vector2) -> void:
	var radius: float = size.x*0.30
	direction = (offset/radius).limit_length()
	if direction.length() < 0.16:
		direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func reset() -> void:
	finger = -1
	mouse_owned = false
	direction = Vector2.ZERO
	direction_changed.emit(direction)
	queue_redraw()

func _draw() -> void:
	var center: Vector2 = size*0.5
	draw_circle(center,size.x*0.46,Color(0.91,0.87,0.74,0.35))
	draw_arc(center,size.x*0.43,0,TAU,64,Color(0.47,0.56,0.49,0.42),1.5,true)
	draw_arc(center+Vector2(1,-1),size.x*0.40,0.2,TAU-0.2,60,Color(0.47,0.56,0.49,0.15),3,true)
	var knob: Vector2 = center+direction*size.x*0.30
	draw_circle(knob,size.x*0.20,Color(0.74,0.80,0.65,0.70))
	draw_circle(knob+Vector2(-2,-2),size.x*0.17,Color(0.94,0.91,0.78,0.75))
	draw_arc(knob,size.x*0.20,0,TAU,48,Color(0.47,0.56,0.49,0.55),1,true)

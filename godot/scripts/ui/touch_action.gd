extends Control

signal activated
signal held_changed(value: bool)
var caption: String = ""
var tint: Color = Color("e8dfc6")
var disabled: bool = false
var active: bool = false
var finger: int = -1
var mouse_owned: bool = false
var icon: String = ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size",20 if size.x > 80 else 16)
	label.add_theme_color_override("font_color",Color("43554d"))
	add_child(label)
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if icon.is_empty():
		icon = String(name).to_lower()
	if icon in ["attack","brush","pencil","map","bag","flower","paint","spring"]:
		label.add_theme_font_size_override("font_size",14 if size.x > 80 else 11)
		label.offset_top = size.y*0.60
		label.offset_bottom = -4

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and not event.pressed and event.index == finger:
		reset()
		get_viewport().set_input_as_handled()
		return
	if not is_visible_in_tree() or disabled:
		return
	if event is InputEventScreenTouch:
		if event.pressed and finger == -1 and get_global_rect().has_point(event.position):
			finger = event.index
			_begin()
			get_viewport().set_input_as_handled()

func _gui_input(event: InputEvent) -> void:
	if disabled or event.device == -1:
		accept_event()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_owned = event.pressed
		_begin() if event.pressed else reset()
		accept_event()

func _begin() -> void:
	if active:
		return
	active = true
	held_changed.emit(true)
	activated.emit()
	queue_redraw()

func reset() -> void:
	finger = -1
	mouse_owned = false
	if active:
		active = false
		held_changed.emit(false)
	queue_redraw()

func _draw() -> void:
	var radius: float = minf(size.x,size.y)*0.48
	var paint: Color = tint
	paint.a = 0.35 if disabled else (0.96 if active else 0.82)
	draw_circle(size*0.5,radius,paint)
	draw_circle(size*0.5-Vector2(2,2),radius*0.90,Color(0.98,0.96,0.86,0.20))
	draw_arc(size*0.5,radius,0,TAU,64,Color(0.42,0.47,0.39,0.30 if disabled else 0.65),1.3,true)
	draw_arc(size*0.5+Vector2(1,-1),radius*0.94,0.3,TAU-0.3,60,Color(0.63,0.59,0.45,0.20),2,true)
	_draw_icon()

func _draw_icon() -> void:
	var ink := Color("4d665c")
	if disabled:
		ink.a = 0.35
	draw_set_transform(size*Vector2(0.5,0.37),0.0,Vector2.ONE*minf(size.x,size.y)/72.0)
	match icon:
		"paint":
			draw_circle(Vector2(-3,0),8.0,Color("729bcf"))
			draw_line(Vector2(-18,7),Vector2(-6,3),ink,3.0,true)
		"spring":
			for ring in range(3):
				draw_arc(Vector2(0,ring*3.0),5.0+ring*5.0,0,TAU,32,ink,1.7,true)
		"flower":
			for petal in range(5):
				draw_circle(Vector2.from_angle(petal*TAU/5.0)*9.0,6.0,Color(0.77,0.46,0.57,0.4 if disabled else 0.8))
			draw_circle(Vector2.ZERO,4.0,Color("dfbe78"))
		"attack", "brush":
			draw_line(Vector2(-11,12),Vector2(8,-10),Color("ae8061"),6.0,true)
			draw_line(Vector2(-11,12),Vector2(8,-10),ink,1.0,true)
			draw_colored_polygon(PackedVector2Array([Vector2(5,-8),Vector2(13,-4),Vector2(18,-21),Vector2(8,-15)]),Color("6c9ea6"))
			if icon == "attack":
				draw_arc(Vector2(-1,0),20.0,0.3,2.7,28,Color("6c9ea6"),3.0,true)
		"pencil":
			draw_line(Vector2(-10,11),Vector2(11,-14),Color("c39359"),7.0,true)
			draw_line(Vector2(-10,11),Vector2(11,-14),Color("f3d39b"),2.0,true)
			draw_colored_polygon(PackedVector2Array([Vector2(-13,9),Vector2(-7,14),Vector2(-18,19)]),ink)
		"map":
			draw_colored_polygon(PackedVector2Array([Vector2(-18,-12),Vector2(-6,-16),Vector2(6,-12),Vector2(18,-16),Vector2(18,12),Vector2(6,16),Vector2(-6,12),Vector2(-18,16)]),Color("f4efd9"))
			for x in [-18,-6,6,18]:
				draw_line(Vector2(x,-12),Vector2(x,13),ink,1.5,true)
			draw_polyline(PackedVector2Array([Vector2(-13,6),Vector2(-5,-4),Vector2(5,3),Vector2(13,-5)]),Color("a77761"),2.0,true)
		"bag":
			draw_colored_polygon(PackedVector2Array([Vector2(-15,-8),Vector2(15,-8),Vector2(18,15),Vector2(-18,15)]),Color("b7b991"))
			draw_arc(Vector2(0,-6),8,PI,TAU,20,ink,2.5,true)
			draw_line(Vector2(-14,-7),Vector2(14,-7),ink,2.0,true)
			draw_line(Vector2(-10,3),Vector2(10,3),ink,1.5,true)
	draw_set_transform(Vector2.ZERO)

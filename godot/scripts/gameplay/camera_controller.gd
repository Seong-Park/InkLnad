class_name CameraController
extends Camera2D

var area_size: Vector2 = Vector2(1120,560)
var mode: StringName = &"fixed"
var target: Node2D
var focus: Vector2 = Vector2(640,360)
var framing_offset: Vector2 = Vector2.ZERO

func set_area(size_value: Vector2, mode_value: StringName) -> void:
	zoom = Vector2.ONE
	area_size = size_value
	mode = mode_value
	framing_offset = Vector2(0,-70) if mode == &"follow_2d" else Vector2.ZERO
	focus = target.global_position+framing_offset if mode == &"follow_2d" and target != null else Vector2(640,360)
	if mode == &"follow_2d":
		focus = _clamp_focus(focus)
	global_position = focus
	reset_smoothing()
	force_update_scroll()

func _clamp_focus(value: Vector2) -> Vector2:
	var half_view: Vector2 = get_viewport_rect().size / (zoom * 2.0)
	return Vector2(clampf(value.x,half_view.x,maxf(half_view.x,area_size.x-half_view.x)),clampf(value.y,half_view.y,maxf(half_view.y,area_size.y-half_view.y)))

func follow(dt: float) -> void:
	if mode != &"fixed" and target != null:
		var difference: Vector2 = target.global_position+framing_offset - focus
		var overflow: Vector2 = Vector2(maxf(absf(difference.x)-80.0/zoom.x,0.0)*signf(difference.x),maxf(absf(difference.y)-50.0/zoom.y,0.0)*signf(difference.y))
		focus += overflow * (1.0-exp(-dt/0.15))
		if mode == &"follow_2d":
			focus = _clamp_focus(focus)
		else:
			focus.x = clampf(focus.x,640.0,maxf(640.0,area_size.x-480.0))
			focus.y = 360.0
	global_position = focus
	force_update_scroll()

func screen_to_world(screen: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * screen

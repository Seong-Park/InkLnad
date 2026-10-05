extends Control

const Layouts = preload("res://scripts/areas/coastal_layouts.gd")
var region: StringName = &""
var info: Dictionary = {}
var terrain: Dictionary = {}
var player_position: Vector2 = Vector2.ZERO
var font := SystemFont.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true
	font.font_names = PackedStringArray(["Malgun Gothic"])

func update_map(id: StringName, value: Dictionary, point: Vector2) -> void:
	if region != id:
		region = id
		info = value
		terrain = Layouts.get_layout(StringName(info.coastal_layout)) if info.has("coastal_layout") else {}
	player_position = point
	queue_redraw()

func project_point(point: Vector2) -> Vector2:
	var available := Rect2(10,30,size.x-20,size.y-53)
	var scale_value: float = minf(available.size.x/info.size.x,available.size.y/info.size.y)
	return available.get_center()-info.size*scale_value*0.5+point.clamp(Vector2.ZERO,info.size)*scale_value

func projected(points: PackedVector2Array) -> PackedVector2Array:
	var output := PackedVector2Array()
	for point in points:
		output.append(project_point(point))
	return output

func _draw() -> void:
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color("f2ead5")
	paper.border_color = Color("aaad92")
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(12)
	draw_style_box(paper,Rect2(Vector2.ZERO,size))
	if info.is_empty():
		return
	draw_string(font,Vector2(12,21),String(info.name).replace("수채화 ",""),HORIZONTAL_ALIGNMENT_LEFT,size.x-32,14,Color("43554d"))
	var corner: Vector2 = project_point(Vector2.ZERO)
	draw_rect(Rect2(corner,project_point(info.size)-corner),Color("e2dab9"))
	for shape in terrain.get("grass",[]):
		draw_colored_polygon(projected(shape),Color("bcc7a0"))
	for shape in terrain.get("water",[]):
		draw_colored_polygon(projected(shape),Color("8dbbb7"))
	for path in terrain.get("paths",[]):
		draw_polyline(projected(path),Color("faf1da"),3.5,true)
	for prop in terrain.get("props",[]):
		if not String(prop.get("title","")).is_empty():
			var spot: Vector2 = project_point(prop.position)
			draw_rect(Rect2(spot-Vector2(3,3),Vector2(6,6)),Color("a07660"))
	for obstacle in info.get("obstacles",[]):
		draw_rect(Rect2(project_point(obstacle.position),project_point(obstacle.end)-project_point(obstacle.position)),Color("9d9e8b"))
	for exit_id in info.get("exits",{}):
		var point: Vector2 = info.get("portals",{}).get(exit_id,Vector2(55 if exit_id == "west" else info.size.x-55,info.size.y*0.5))
		var spot: Vector2 = project_point(point)
		draw_colored_polygon(PackedVector2Array([spot+Vector2(0,-4),spot+Vector2(4,0),spot+Vector2(0,4),spot+Vector2(-4,0)]),Color("bd9149"))
	var dot: Vector2 = project_point(player_position)
	draw_circle(dot,5.0,Color("fff8e5"))
	draw_circle(dot,3.2,Color("c56553"))
	draw_string(font,Vector2(12,size.y-9),"● 나    ■ 상점    ◆ 출구",HORIZONTAL_ALIGNMENT_LEFT,size.x-24,11,Color("596557"))

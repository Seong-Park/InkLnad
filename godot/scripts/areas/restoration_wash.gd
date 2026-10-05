extends Node2D

var pigment: Color = Color("9572b3")
var elapsed: float = 0.0
var silhouettes: Array[PackedVector2Array] = []

func _ready() -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 731
	for layer in 3:
		var outline := PackedVector2Array()
		for index in 40:
			outline.append(Vector2.from_angle(TAU*index/40.0)*random.randf_range(0.85,1.1))
		silhouettes.append(outline)
	z_index = 6

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= 1.5:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress: float = elapsed/1.5
	for layer in silhouettes.size():
		var shape := PackedVector2Array()
		for point in silhouettes[layer]:
			shape.append(point*Vector2(105,42)*(0.35+progress*0.75)*(1.0-layer*0.13))
		draw_colored_polygon(shape,Color(pigment,0.10*(1.0-progress)))
	for index in 12:
		var angle: float = float(index)*2.399
		var point: Vector2 = Vector2.from_angle(angle)*(25.0+progress*85.0)
		point.y *= 0.55
		point.y -= progress*20.0
		draw_circle(point,2.0+float(index%3),Color(pigment,0.35*(1.0-progress)))

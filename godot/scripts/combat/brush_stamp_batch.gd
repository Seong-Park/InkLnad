extends MultiMeshInstance2D

func _ready() -> void:
	var vertices := PackedVector3Array()
	var colors := PackedColorArray()
	for index in range(32):
		var a: Vector2 = Vector2.from_angle(index*TAU/32.0)
		var b: Vector2 = Vector2.from_angle((index+1)*TAU/32.0)
		for point in [Vector2.ZERO,a,b]:
			vertices.append(Vector3(point.x,point.y,0.0))
			colors.append(Color.WHITE)
		# A narrow translucent edge avoids jagged circles without individual arcs.
		for point in [a,a*1.04,b*1.04,a,b*1.04,b]:
			vertices.append(Vector3(point.x,point.y,0.0))
			colors.append(Color(1,1,1,0.0 if point.length_squared()>1.01 else 1.0))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	multimesh.mesh = mesh
	z_index = -1

func update_stamps(stamps: Array[Dictionary], now: float, tools: Dictionary) -> void:
	if stamps.size() > multimesh.instance_count:
		multimesh.instance_count = ceili(stamps.size()/64.0)*64
	multimesh.visible_instance_count = stamps.size()
	for index in range(stamps.size()):
		var stamp: Dictionary = stamps[index]
		var radius: float = stamp.radius
		multimesh.set_instance_transform_2d(index,Transform2D(Vector2(radius,0),Vector2(0,radius),stamp.center))
		var color := Color("1749C6")
		var life: float = tools[String(stamp.tool_id)].lifetime
		color.a = 0.18+0.35*clampf((float(stamp.expires_at)-now)/life,0,1)
		multimesh.set_instance_color(index,color)

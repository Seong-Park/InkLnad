extends RefCounted

const SPACING: float = 16.0
static var masks: Dictionary = {}

# RGB stores signed grass distance, signed water distance and footpath coverage.
# This is numeric terrain data; generated artwork remains untouched.
static func weights(id: String, size: Vector2, layout: Dictionary) -> ImageTexture:
	if masks.has(id):
		return masks[id]
	var width: int = int(ceil(size.x/SPACING))
	var height: int = int(ceil(size.y/SPACING))
	var grass := PackedByteArray()
	var water := PackedByteArray()
	var road := PackedFloat32Array()
	grass.resize(width*height)
	water.resize(width*height)
	road.resize(width*height)
	for y in range(height):
		for x in range(width):
			var point := Vector2((x+0.5)*SPACING,(y+0.5)*SPACING)
			var index: int = y*width+x
			for polygon in layout.grass:
				if Geometry2D.is_point_in_polygon(point,polygon):
					grass[index] = 1
			for polygon in layout.water:
				if Geometry2D.is_point_in_polygon(point,polygon):
					water[index] = 1
			var distance: float = 1000.0
			for path in layout.paths:
				for step in range(0,path.size()-1,3):
					var a: Vector2 = path[step]
					var b: Vector2 = path[mini(step+3,path.size()-1)]
					var segment: Vector2 = b-a
					var t: float = clampf((point-a).dot(segment)/maxf(segment.length_squared(),0.001),0.0,1.0)
					distance = minf(distance,point.distance_to(a+segment*t))
			road[index] = 1.0-smoothstep(50.0,210.0,distance)
	var grass_distance: PackedFloat32Array = _distance(grass,width,height)
	var water_distance: PackedFloat32Array = _distance(water,width,height)
	var image := Image.create(width,height,false,Image.FORMAT_RGB8)
	for y in range(height):
		for x in range(width):
			var index: int = y*width+x
			var g: float = grass_distance[index]*SPACING*(1.0 if grass[index] == 1 else -1.0)
			var w: float = water_distance[index]*SPACING*(1.0 if water[index] == 1 else -1.0)
			image.set_pixel(x,y,Color(clampf(0.5+g/256.0,0.0,1.0),clampf(0.5+w/256.0,0.0,1.0),road[index]))
	var texture := ImageTexture.create_from_image(image)
	masks[id] = texture
	return texture

static func _distance(inside: PackedByteArray, width: int, height: int) -> PackedFloat32Array:
	var distance := PackedFloat32Array()
	distance.resize(inside.size())
	distance.fill(1000.0)
	for y in range(height):
		for x in range(width):
			var index: int = y*width+x
			for neighbor in [Vector2i(-1,0),Vector2i(1,0),Vector2i(0,-1),Vector2i(0,1)]:
				var nx: int = x+neighbor.x
				var ny: int = y+neighbor.y
				if nx>=0 and nx<width and ny>=0 and ny<height and inside[ny*width+nx]!=inside[index]:
					distance[index] = 0.5
	for y in range(height):
		for x in range(width):
			var index: int = y*width+x
			if x>0: distance[index] = minf(distance[index],distance[index-1]+1.0)
			if y>0: distance[index] = minf(distance[index],distance[index-width]+1.0)
			if x>0 and y>0: distance[index] = minf(distance[index],distance[index-width-1]+1.414)
			if x<width-1 and y>0: distance[index] = minf(distance[index],distance[index-width+1]+1.414)
	for y in range(height-1,-1,-1):
		for x in range(width-1,-1,-1):
			var index: int = y*width+x
			if x<width-1: distance[index] = minf(distance[index],distance[index+1]+1.0)
			if y<height-1: distance[index] = minf(distance[index],distance[index+width]+1.0)
			if x<width-1 and y<height-1: distance[index] = minf(distance[index],distance[index+width+1]+1.414)
			if x>0 and y<height-1: distance[index] = minf(distance[index],distance[index+width-1]+1.414)
	return distance

extends RefCounted

static func area(id: StringName, original: Dictionary) -> Dictionary:
	var info: Dictionary = original.duplicate(true)
	info.size = Vector2(1600,1100)
	info.name = {&"C":"보랏빛 꽃 공터",&"D":"빗빛 갈림숲",&"E":"잊힌 폐허 정원"}[id]
	info.camera = "follow_2d"
	info.coastal_layout = String(id)
	info.entry_west = Vector2(170,630)
	info.entry_east = Vector2(1430,390)
	info.portals = {"west":Vector2(100,630),"east":Vector2(1500,390)}
	info.safe_point = Vector2(260,790)
	info.obstacles = []
	var places: Array[Vector2] = [Vector2(620,460),Vector2(970,730),Vector2(1190,300)]
	if id == &"D": places = [Vector2(580,740),Vector2(1030,460),Vector2(1210,770)]
	if id == &"E": places = [Vector2(990,550)]
	for index in info.spawns.size():
		info.spawns[index].position = places[index]
	return preload("res://scripts/areas/world_dimensions.gd").expand(info)

static func layout(id: StringName) -> Dictionary:
	var grass: Array = [oval(Vector2(280,250),Vector2(400,310)),oval(Vector2(1220,900),Vector2(450,300))]
	if id == &"C": grass.append(oval(Vector2(810,650),Vector2(570,380)))
	var paths: Array = [PackedVector2Array([Vector2(100,630),Vector2(450,520),Vector2(800,580),Vector2(1100,480),Vector2(1500,390)]),PackedVector2Array([Vector2(500,950),Vector2(630,700),Vector2(800,580),Vector2(870,280),Vector2(1060,120)])]
	if id == &"D":
		paths = [PackedVector2Array([Vector2(100,630),Vector2(510,680),Vector2(800,570),Vector2(1100,430),Vector2(1500,390)]),PackedVector2Array([Vector2(380,950),Vector2(650,700),Vector2(800,570),Vector2(890,250),Vector2(700,100)])]
	for index in paths.size():
		paths[index] = subdivide(paths[index])
	var props: Array = []
	var motifs: Array[String] = ["flowerpots","pine","willow","bamboo","lantern","flowerpots","shrub","fountain"]
	if id == &"D": motifs = ["bamboo","lantern","willow","flowerpots","market","pine","flowerpots","shrub"]
	if id == &"E": motifs = ["flowerpots","lantern","pine","fountain","flowerpots","willow","bamboo","market"]
	var points: Array[Vector2] = [Vector2(420,650),Vector2(650,850),Vector2(1040,860),Vector2(1260,580),Vector2(1160,210),Vector2(780,340),Vector2(440,350),Vector2(820,690)]
	if id == &"D": points[6] = Vector2(610,520)
	for index in points.size():
		var kind: String = motifs[index]
		var height: float = 170.0 if kind in ["pine","willow","bamboo"] else (95.0 if kind in ["fountain","market"] else 55.0)
		props.append({"kind":kind,"position":points[index],"height":height})
	for index in 12:
		var x: float = 120.0+float(index)*118.0
		props.append({"kind":"rock" if id==&"E" else "pine","position":Vector2(x,130 if index%2==0 else 1030),"height":110.0 if id==&"E" else 205.0,"body":Rect2(-30,-24,60,24)})
	if id == &"E":
		for point in [Vector2(600,260),Vector2(1100,830),Vector2(1390,690),Vector2(850,420),Vector2(1150,440),Vector2(920,730)]:
			props.append({"kind":"stele","position":point,"height":145.0,"body":Rect2(-30,-25,60,25)})
	var water: Array = [oval(Vector2(440,300),Vector2(235,170))] if id == &"D" else []
	var result: Dictionary = {"water":water,"banks":water,"grass":grass,"paths":paths,"props":props,"decor":[],"solids":water,"bridge":Rect2(),"plaza":Vector2(990,570) if id==&"E" else Vector2.ZERO,"dig_sites":[],"dock":Rect2()}
	return preload("res://scripts/areas/world_dimensions.gd").expand(result)

static func oval(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in 64:
		var angle: float = TAU*index/64.0
		points.append(center+Vector2(cos(angle),sin(angle))*radius*(1.0+0.04*sin(angle*5.0)))
	return points

static func subdivide(points: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in points.size()-1:
		for step in 8:
			result.append(points[index].lerp(points[index+1],float(step)/8.0))
	result.append(points[-1])
	return result

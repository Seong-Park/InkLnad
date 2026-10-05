extends RefCounted

# Ink Land coordinates, not measured Trickster map data.
# Terrain contours, routes and independent props share one world coordinate system.
static func contour(points: Array, closed: bool = false) -> PackedVector2Array:
	var result := PackedVector2Array()
	var count: int = points.size()
	for index in range(count if closed else count-1):
		var a: Vector2 = points[posmod(index-1,count)] if closed else points[maxi(0,index-1)]
		var b: Vector2 = points[index]
		var c: Vector2 = points[(index+1)%count]
		var d: Vector2 = points[(index+2)%count] if closed else points[mini(count-1,index+2)]
		for step in range(8):
			var t: float = float(step)/8.0
			result.append(0.5*((2.0*b)+(-a+c)*t+(2.0*a-5.0*b+4.0*c-d)*t*t+(-a+3.0*b-3.0*c+d)*t*t*t))
	if not closed:
		result.append(points[-1])
	return result

static func oval(center: Vector2, radius: Vector2) -> PackedVector2Array:
	var result := PackedVector2Array()
	for index in range(72):
		var angle: float = TAU*float(index)/72.0
		var wobble: float = 1.0+0.045*sin(angle*3.0)+0.025*cos(angle*5.0)
		result.append(center+Vector2(cos(angle),sin(angle))*radius*wobble)
	return result

static func river() -> PackedVector2Array:
	var center := contour([Vector2(2100,1100),Vector2(2230,1090),Vector2(2360,1100),Vector2(2390,1250),Vector2(2400,1430),Vector2(2390,1620),Vector2(2420,1710)])
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	for index in range(center.size()):
		var direction: Vector2 = center[mini(index+1,center.size()-1)]-center[maxi(index-1,0)]
		var normal: Vector2 = direction.normalized().orthogonal()*42.0
		left.append(center[index]+normal)
		right.append(center[index]-normal)
	right.reverse()
	left.append_array(right)
	return left

static func get_layout(id: StringName) -> Dictionary:
	if id in [&"C",&"D",&"E"]:
		return preload("res://scripts/areas/exploration_layouts.gd").layout(id)
	var town: bool = id == &"A"
	var shoreline: PackedVector2Array = contour([
		Vector2(0,1500),Vector2(450,1450),Vector2(650,1520),Vector2(870,1510),Vector2(1000,1400),Vector2(1150,1340),Vector2(1340,1340),Vector2(1480,1390),Vector2(1560,1480),Vector2(1760,1550),Vector2(1950,1500),Vector2(2100,1450),Vector2(2370,1370),Vector2(2560,1380)
	] if town else [
		Vector2(0,1660),Vector2(400,1710),Vector2(760,1660),Vector2(1150,1700),Vector2(1500,1690),Vector2(1810,1620),Vector2(2130,1670),Vector2(2520,1630),Vector2(2780,1710),Vector2(3072,1650)
	])
	var sea: PackedVector2Array = shoreline.duplicate()
	sea.append(Vector2(2560 if town else 3072,1792 if town else 2048))
	sea.append(Vector2(0,1792 if town else 2048))
	var water: Array[PackedVector2Array] = [sea]
	var banks: Array[PackedVector2Array] = [shoreline]
	var grass: Array[PackedVector2Array] = []
	var paths: Array[PackedVector2Array] = []
	var props: Array[Dictionary] = []
	var solids: Array[PackedVector2Array] = []
	var bridge := Rect2()
	if town:
		var bay := contour([Vector2(2560,320),Vector2(2410,460),Vector2(2190,490),Vector2(2040,650),Vector2(2090,820),Vector2(2280,920),Vector2(2560,1070)])
		banks.append(bay)
		var bay_water: PackedVector2Array = bay.duplicate()
		bay_water.append(Vector2(2560,320))
		water.append(bay_water)
		grass.append(contour([Vector2(0,0),Vector2(2560,0),Vector2(2560,240),Vector2(1990,320),Vector2(1730,200),Vector2(1560,300),Vector2(1350,210),Vector2(1200,170),Vector2(1050,180),Vector2(880,120),Vector2(730,210),Vector2(530,280),Vector2(320,430),Vector2(190,730),Vector2(0,900)],true))
		grass.append(contour([Vector2(0,1030),Vector2(270,930),Vector2(330,1050),Vector2(300,1300),Vector2(550,1380),Vector2(760,1370),Vector2(870,1320),Vector2(940,1370),Vector2(760,1450),Vector2(400,1420),Vector2(0,1450)],true))
		grass.append(oval(Vector2(1630,680),Vector2(210,140)))
		grass.append(contour([Vector2(480,980),Vector2(660,930),Vector2(850,1000),Vector2(840,1170),Vector2(650,1250),Vector2(440,1170)],true))
		paths = [
			contour([Vector2(580,680),Vector2(780,700),Vector2(1000,780),Vector2(1410,850),Vector2(1810,1030),Vector2(2170,1160),Vector2(2400,1210)]),
			contour([Vector2(920,760),Vector2(820,970),Vector2(650,1100),Vector2(510,1260)]),
			contour([Vector2(1050,750),Vector2(1270,1030),Vector2(1390,1210)]),
			contour([Vector2(960,530),Vector2(970,700)])
		]
		props = [
			{"kind":"cottage","position":Vector2(620,550),"height":345.0,"title":"제작 공방","roof":Color("829fad"),"body":Rect2(-116,-86,232,86)},
			{"kind":"cottage","position":Vector2(1000,420),"height":300.0,"title":"화구점 · 무기","roof":Color("c9897e"),"body":Rect2(-101,-75,202,75)},
			{"kind":"cottage","position":Vector2(1370,520),"height":305.0,"title":"약방 · 포션","roof":Color("a3ad88"),"body":Rect2(-103,-76,206,76)},
			{"kind":"fountain","position":Vector2(1010,690),"height":135.0,"body":Rect2(-72,-40,144,40)}
		]
		for point in [Vector2(180,430),Vector2(300,680),Vector2(140,1020),Vector2(390,1330),Vector2(940,1360),Vector2(1560,430),Vector2(1940,780),Vector2(2010,1000),Vector2(2280,1340),Vector2(2500,1220)]:
			props.append({"kind":"palm","position":point,"height":235.0,"body":Rect2(-10,-20,20,20)})
		for point in [Vector2(370,410),Vector2(1630,650),Vector2(1780,800),Vector2(480,1390),Vector2(2100,1320),Vector2(2400,360)]:
			props.append({"kind":"rock","position":point,"height":85.0,"body":Rect2(-46,-30,92,30)})
		for point in [Vector2(150,170),Vector2(290,160),Vector2(440,200),Vector2(650,140),Vector2(790,140),Vector2(1350,170),Vector2(1550,170),Vector2(1750,140),Vector2(1950,160),Vector2(2150,150),Vector2(2400,170),Vector2(130,580),Vector2(90,750),Vector2(140,1230),Vector2(270,1350),Vector2(600,1370),Vector2(730,1330),Vector2(1580,620),Vector2(1690,610),Vector2(1740,720),Vector2(1520,730),Vector2(2080,460),Vector2(2010,580),Vector2(2010,900),Vector2(2240,1000),Vector2(2490,1080)]:
			props.append({"kind":"shrub","position":point,"height":100.0,"body":Rect2(-35,-25,70,25)})
	else:
		var lagoon := contour([Vector2(890,970),Vector2(1040,790),Vector2(1250,750),Vector2(1410,770),Vector2(1490,820),Vector2(1730,730),Vector2(1900,830),Vector2(1960,920),Vector2(2180,1100),Vector2(2020,1210),Vector2(1930,1290),Vector2(1710,1360),Vector2(1500,1320),Vector2(1380,1260),Vector2(1180,1310),Vector2(960,1170)],true)
		var joined: Array[PackedVector2Array] = Geometry2D.merge_polygons(lagoon,river())
		water = Geometry2D.merge_polygons(sea,joined[0])
		banks = water.duplicate()
		bridge = Rect2(2250,1170,280,140)
		# Carve the bridge deck out of the same water contour used for rendering.
		var deck := PackedVector2Array([Vector2(2260,1230),Vector2(2440,1188),Vector2(2520,1235),Vector2(2340,1300)])
		for polygon in water:
			solids.append_array(Geometry2D.clip_polygons(polygon,deck))
		grass.append(contour([Vector2(0,0),Vector2(3072,0),Vector2(3072,630),Vector2(2700,610),Vector2(2480,500),Vector2(2200,440),Vector2(1880,370),Vector2(1430,390),Vector2(1050,450),Vector2(760,520),Vector2(620,730),Vector2(410,690),Vector2(300,430),Vector2(0,500)],true))
		grass.append(contour([Vector2(0,850),Vector2(230,940),Vector2(470,1050),Vector2(560,1260),Vector2(440,1420),Vector2(300,1350),Vector2(0,1560)],true))
		grass.append(oval(Vector2(2810,870),Vector2(160,120)))
		paths = [
			contour([Vector2(230,780),Vector2(430,860),Vector2(650,1000)]),
			contour([Vector2(650,1000),Vector2(750,670),Vector2(1250,520),Vector2(1880,600),Vector2(2290,870),Vector2(2540,950),Vector2(2670,1190),Vector2(2930,1190)]),
			contour([Vector2(650,1000),Vector2(790,1340),Vector2(1160,1500),Vector2(1700,1540),Vector2(2020,1420),Vector2(2190,1240),Vector2(2400,1240),Vector2(2670,1190)])
		]
		for point in [Vector2(450,580),Vector2(820,420),Vector2(1670,330),Vector2(2240,470),Vector2(2860,790),Vector2(2870,1480),Vector2(1880,1590),Vector2(680,1520),Vector2(240,1260)]:
			props.append({"kind":"palm","position":point,"height":230.0,"body":Rect2(-10,-20,20,20)})
		for point in [Vector2(440,460),Vector2(1000,390),Vector2(1480,370),Vector2(1960,430),Vector2(2290,650),Vector2(940,1230),Vector2(1350,1390),Vector2(1840,1350),Vector2(2120,980),Vector2(2800,890),Vector2(200,1470)]:
			props.append({"kind":"rock","position":point,"height":100.0,"body":Rect2(-55,-30,110,30)})
		for point in [Vector2(160,280),Vector2(300,320),Vector2(520,270),Vector2(710,350),Vector2(940,300),Vector2(1180,340),Vector2(1410,290),Vector2(1630,300),Vector2(1850,320),Vector2(2050,340),Vector2(2210,360),Vector2(2470,400),Vector2(2640,470),Vector2(2840,520),Vector2(3000,500),Vector2(80,1040),Vector2(200,1120),Vector2(350,1190),Vector2(400,1310),Vector2(280,1390),Vector2(860,810),Vector2(910,680),Vector2(1070,670),Vector2(1240,640),Vector2(1710,700),Vector2(1820,740),Vector2(900,1290),Vector2(1000,1370),Vector2(1190,1410),Vector2(1540,1440),Vector2(1810,1450),Vector2(2000,1320),Vector2(2070,1230),Vector2(2830,930),Vector2(2990,1020),Vector2(2790,1450),Vector2(3010,1480),Vector2(2000,1560)]:
			props.append({"kind":"shrub","position":point,"height":95.0,"body":Rect2(-33,-24,66,24)})
	var dock := Rect2(1300,1260,120,200) if town else Rect2()
	if town:
		var deck := PackedVector2Array([dock.position,dock.position+Vector2(dock.size.x,0),dock.end,dock.position+Vector2(0,dock.size.y)])
		for polygon in water:
			solids.append_array(Geometry2D.clip_polygons(polygon,deck))
	var tree_index: int = 0
	for prop in props:
		if prop.kind == "shrub":
			prop.height = float(prop.height)*(0.76+0.22*(sin(prop.position.x*0.037)*0.5+0.5))
		if prop.kind == "cottage":
			prop.kind = "eastern-cottage"
			prop.height = float(prop.height)*0.87
		elif prop.kind == "palm":
			prop.kind = "willow" if tree_index%3 == 1 else "pine"
			prop.height = 255.0 if prop.kind == "willow" else 220.0
			tree_index += 1
	if town:
		props[0].kind = "craft-workshop"
		props[1].kind = "tool-shop"
		props[2].kind = "apothecary"
		props[0].body = Rect2(-195,-72,390,72)
		props[0].label_offset = Vector2(-170,18)
		props[1].body = Rect2(-128,-60,256,60)
		props[2].body = Rect2(-120,-65,240,65)
		for index in range(3):
			props[index].erase("roof")
		props.append_array([
			{"kind":"outfit-shop","position":Vector2(620,900),"height":240.0,"title":"옷방 · 방어구","body":Rect2(-100,-60,200,60)},
			{"kind":"village-teahouse","position":Vector2(1810,600),"height":235.0,"title":"물빛 찻집","body":Rect2(-145,-52,290,52)},
			{"kind":"pavilion","position":Vector2(1810,1300),"height":200.0,"title":"바람 누각","body":Rect2(-70,-45,140,45)},
			{"kind":"storehouse","position":Vector2(1110,1270),"height":195.0,"title":"해안 창고","body":Rect2(-90,-50,180,50)}])
	for point in ([Vector2(400,460),Vector2(1500,460),Vector2(1620,760),Vector2(300,1240),Vector2(2060,1040)] if town else [Vector2(520,580),Vector2(1290,360),Vector2(2080,440),Vector2(2910,940),Vector2(370,1270)]):
		props.append({"kind":"bamboo","position":point,"height":135.0,"body":Rect2(-15,-18,30,18)})
	var decor: Array[Dictionary] = []
	if town:
		props.append_array([
			{"kind":"market","position":Vector2(1290,750),"height":170.0,"body":Rect2(-55,-30,110,30)},
			{"kind":"cart","position":Vector2(810,540),"height":100.0,"body":Rect2(-45,-24,90,24)},
			{"kind":"bench","position":Vector2(1220,950),"height":70.0,"body":Rect2(-55,-20,110,20)},
			{"kind":"lantern","position":Vector2(440,650),"height":100.0,"body":Rect2(-19,-22,38,22)},
			{"kind":"lantern","position":Vector2(1450,800),"height":100.0,"body":Rect2(-19,-22,38,22)}
		])
		for point in [Vector2(500,600),Vector2(740,580),Vector2(900,470),Vector2(1470,550),Vector2(1110,900)]:
			props.append({"kind":"flowerpots","position":point,"height":65.0})
		for point in [Vector2(470,990),Vector2(800,1180),Vector2(1630,650),Vector2(1730,710),Vector2(1570,770),Vector2(220,520),Vector2(190,1150),Vector2(770,340)]:
			decor.append({"tile":2,"position":point})
		for point in [Vector2(330,780),Vector2(290,1230),Vector2(890,1290),Vector2(1520,650)]:
			decor.append({"tile":3,"position":point})
	else:
		props.append_array([
			{"kind":"stele","position":Vector2(1560,430),"height":175.0,"body":Rect2(-65,-40,130,40)},
			{"kind":"lantern","position":Vector2(1120,680),"height":100.0,"body":Rect2(-19,-22,38,22)},
			{"kind":"lantern","position":Vector2(1930,700),"height":100.0,"body":Rect2(-19,-22,38,22)},
			{"kind":"driftwood","position":Vector2(1260,1590),"height":60.0},
			{"kind":"driftwood","position":Vector2(1870,1520),"height":50.0}
		])
		for point in [Vector2(860,1040),Vector2(1090,730),Vector2(1540,730),Vector2(2000,950),Vector2(1900,1350),Vector2(2280,1400)]:
			props.append({"kind":"reeds","position":point,"height":70.0})
		for point in [Vector2(950,1490),Vector2(1090,1570),Vector2(1220,1530),Vector2(1410,1580),Vector2(1640,1610),Vector2(1870,1500),Vector2(2020,1530),Vector2(2670,1580)]:
			decor.append({"tile":0,"position":point})
		for point in [Vector2(600,480),Vector2(870,470),Vector2(1360,420),Vector2(1680,490),Vector2(2000,580),Vector2(2850,810)]:
			decor.append({"tile":2,"position":point})
		for point in [Vector2(930,740),Vector2(1780,740),Vector2(2070,1020),Vector2(860,1230)]:
			decor.append({"tile":3,"position":point})
	if town:
		for prop in props:
			if prop.kind in ["craft-workshop","tool-shop","apothecary","outfit-shop","village-teahouse","pavilion","storehouse"]:
				# Original painted facades face left; mirror western buildings inward.
				prop.flip_h = prop.position.x < 1010.0
	return preload("res://scripts/areas/world_dimensions.gd").expand({"water":water,"banks":banks,"grass":grass,"paths":paths,"props":props,"decor":decor,"solids":solids,"bridge":bridge,"plaza":Vector2(1010,730) if town else Vector2.ZERO,"dig_sites":[Vector2(1180,1560),Vector2(1930,1480)] if not town else [],"dock":dock})

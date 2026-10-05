extends Node2D

const Layouts = preload("res://scripts/areas/coastal_layouts.gd")
const Terrain = preload("res://scripts/areas/coastal_terrain.gd")
const Art = preload("res://scripts/areas/watercolor_art.gd")
const Resident = preload("res://scripts/areas/village_resident.gd")
const Population = preload("res://scripts/areas/village_population.gd")
const Animal = preload("res://scripts/areas/village_animal.gd")
const ASSETS: String = "res://assets/world/coast-modular-v3/"
const TILE_ART: String = "res://assets/world/coast-tiles-v4/"
const DECOR_ART: String = "res://assets/world/coast-watercolor-v8/decor-atlas.png"
const WASH_ART: String = "res://assets/world/coast-watercolor-v7/props-atlas-loose.png"
const WASH_KINDS: Array[String] = ["eastern-cottage","pine","willow","bamboo","shrub","rock","fountain","bridge","tuft"]
const DECOR_KINDS: Array[String] = ["market","lantern","bench","flowerpots","cart","reeds","stele","driftwood"]
const Dimensions = preload("res://scripts/areas/world_dimensions.gd")
const CELL: int = 64
var info: Dictionary = {}
var layout: Dictionary = {}
var textures: Dictionary = {}
var regions: Dictionary = {}
var font := SystemFont.new()
var tile_set: TileSet
var elapsed: float = 0.0
var redraw_clock: float = 0.0
var player: Node2D
var restoration = preload("res://scripts/areas/object_restoration.gd").new()
var residents: Array[Node2D] = []
var animals: Array[Node2D] = []

func configure(value: Dictionary) -> void:
	restoration.objects.clear()
	residents.clear()
	animals.clear()
	for child in get_children():
		child.free()
	info = value
	layout = Layouts.get_layout(StringName(info.coastal_layout))
	y_sort_enabled = true
	font.font_names = PackedStringArray(["Malgun Gothic"])
	player = get_parent().get_node_or_null("Player") as Node2D
	if textures.is_empty():
		for kind in ["sand","grass","water","dirt","paving","tuft","pebbles","shrub","rock","eastern-cottage","pine","willow","bamboo","fountain","bridge"]:
			textures[kind] = load(ASSETS+kind+".webp")
			regions[kind] = Rect2(textures[kind].get_image().get_used_rect())
		var wash: Texture2D = load(WASH_ART)
		var wash_image: Image = wash.get_image()
		for index in range(WASH_KINDS.size()):
			var frame: Rect2i = _wash_frame(index,wash_image.get_size())
			var occupied: Rect2i = wash_image.get_region(frame).get_used_rect()
			textures[WASH_KINDS[index]] = wash
			regions[WASH_KINDS[index]] = Rect2(Rect2i(frame.position+occupied.position,occupied.size))
		for kind in ["brush-workshop","pigment-shop","map-house","teahouse","pavilion","storehouse","apothecary","tool-shop","outfit-shop","craft-workshop","village-teahouse"]:
			textures[kind] = Art.texture(kind)
			regions[kind] = Rect2(Vector2.ZERO,textures[kind].get_size())
		textures.npc = Art.texture("npc")
		regions.npc = Rect2(textures.npc.get_image().get_used_rect())
		textures.target = Art.texture("target")
		regions.target = Rect2(textures.target.get_image().get_used_rect())
		textures.dock = load("res://assets/world/coast-watercolor-v8/dock.png")
		regions.dock = Rect2(textures.dock.get_image().get_used_rect())
		var decorations: Texture2D = load(DECOR_ART)
		var art: Image = decorations.get_image()
		for index in range(DECOR_KINDS.size()):
			var frame: Rect2i = _decor_frame(index)
			var occupied: Rect2i = art.get_region(frame).get_used_rect()
			textures[DECOR_KINDS[index]] = decorations
			regions[DECOR_KINDS[index]] = Rect2(Rect2i(frame.position+occupied.position,occupied.size))
		textures.pebbles = decorations
		var pebble_frame: Rect2i = _decor_frame(8)
		var pebble_bounds: Rect2i = art.get_region(pebble_frame).get_used_rect()
		regions.pebbles = Rect2(Rect2i(pebble_frame.position+pebble_bounds.position,pebble_bounds.size))
		var sheet: Image = load(TILE_ART+"terrain-atlas.png").get_image()
		var step: float = sheet.get_width()/4.0
		for row in range(4):
			var kind: String = ["sand","grass","water","paving"][row]
			var start := Vector2i(int(step*3.0),int(step*row))+Vector2i(4,4)
			var end := Vector2i(sheet.get_width(),int(step*(row+1)))-Vector2i(4,4)
			textures[kind] = ImageTexture.create_from_image(sheet.get_region(Rect2i(start,end-start)))
		_create_tileset()
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2.ZERO,Vector2(info.size.x,0),info.size,Vector2(0,info.size.y)])
	base.color = Color("f1ead8")
	base.z_index = -4
	add_child(base)
	_create_ground()
	_create_cliffs()
	_create_decor_tiles()
	for prop in layout.props:
		_create_prop(prop)
	_add_ground_details()
	if info.coastal_layout == "A":
		for original in Population.definitions(info.npc_position / Dimensions.SCALE):
			var data: Dictionary = Dimensions.expand(original)
			data.height = float(original.get("height",80.0)) * Dimensions.SCALE
			data.world_scale = Dimensions.SCALE
			var resident: Node2D = Resident.new()
			add_child(resident)
			resident.configure(data,player)
			residents.append(resident)
		var animal_data: Array[Dictionary] = [
			{"id":"tea-cat","art":"cat","height":36.0,"phase":0.3,"route":PackedVector2Array([Vector2(1720,940),Vector2(1810,960),Vector2(1720,940)])},
			{"id":"garden-cat","art":"cat","height":32.0,"phase":2.0,"tint":Color("f3e9db"),"route":PackedVector2Array([Vector2(860,1040),Vector2(920,1050),Vector2(860,1040)])},
			{"id":"plaza-puppy","art":"dog","height":43.0,"pace":26.0,"phase":0.0,"route":PackedVector2Array([Vector2(1130,1030),Vector2(1220,1040),Vector2(1130,1030)])},
			{"id":"fountain-sparrow","art":"sparrow-flight","folder":"village-animals-v17","flies":true,"height":18.0,"pace":55.0,"phase":1.0,"route":PackedVector2Array([Vector2(1040,620),Vector2(1140,640)])},
			{"id":"garden-sparrow","art":"sparrow-flight","folder":"village-animals-v17","flies":true,"height":17.0,"pace":55.0,"phase":3.0,"route":PackedVector2Array([Vector2(1610,830),Vector2(1690,840)])}
		]
		animal_data.append_array([
			{"id":"resting-calico","art":"calico-rest","folder":"village-animals-v16","height":37.0,"resting":true,"route":PackedVector2Array([Vector2(1680,900)])},
			{"id":"siamese-cat","art":"siamese","folder":"village-animals-v16","height":34.0,"phase":1.5,"route":PackedVector2Array([Vector2(890,980),Vector2(950,990),Vector2(890,980)])},
			{"id":"corgi-dog","art":"corgi","folder":"village-animals-v16","height":32.0,"phase":2.5,"route":PackedVector2Array([Vector2(1260,920),Vector2(1320,930),Vector2(1260,920)])},
			{"id":"poodle-dog","art":"poodle","folder":"village-animals-v16","height":38.0,"phase":4.0,"route":PackedVector2Array([Vector2(1480,960),Vector2(1550,970),Vector2(1480,960)])}
		])
		animal_data.append_array([
			{"id":"sleeping-cat","art":"sleep-cat","folder":"village-animals-v17","height":22.0,"resting":true,"sleeping":true,"route":PackedVector2Array([Vector2(1780,880)])},
			{"id":"sleeping-puppy","art":"sleep-dog","folder":"village-animals-v17","height":24.0,"resting":true,"sleeping":true,"route":PackedVector2Array([Vector2(1400,1010)])}
		])
		for original in animal_data:
			var data: Dictionary = Dimensions.expand(original)
			var animal: Node2D = Animal.new()
			add_child(animal)
			animal.configure(data,player)
			animals.append(animal)
		_create_prop({"kind":"target","position":info.target_position+Vector2(0,30),"height":100.0*Dimensions.SCALE})
	if layout.bridge.has_area():
		var sprite := Sprite2D.new()
		sprite.texture = textures.bridge
		sprite.region_enabled = true
		sprite.region_rect = regions.bridge
		# The new painted deck slopes the opposite way; preserve the collision carve.
		sprite.flip_h = true
		sprite.position = layout.bridge.get_center()
		sprite.scale = Vector2(layout.bridge.size.x/regions.bridge.size.x,layout.bridge.size.y/regions.bridge.size.y)
		sprite.z_index = 2
		add_child(sprite)
	if layout.dock.has_area():
		var dock_sprite := Sprite2D.new()
		dock_sprite.name = "PaintedDock"
		dock_sprite.texture = textures.dock
		dock_sprite.region_enabled = true
		dock_sprite.region_rect = regions.dock
		dock_sprite.position = layout.dock.get_center()
		dock_sprite.scale = layout.dock.size/regions.dock.size
		dock_sprite.z_index = 2
		add_child(dock_sprite)
	queue_redraw()

func _wash_frame(index: int, size: Vector2i) -> Rect2i:
	# Measured transparent gaps of this generated sheet, not a regular grid.
	var columns: PackedInt32Array = PackedInt32Array([0,450,900,size.x])
	var rows: Array[int] = [0,475,830,size.y]
	var column: int = index%3
	var row: int = index/3
	return Rect2i(columns[column],rows[row],columns[column+1]-columns[column],rows[row+1]-rows[row])

func _decor_frame(index: int) -> Rect2i:
	var columns := PackedInt32Array([0,395,730,1100,1448])
	if index >= 8:
		columns = PackedInt32Array([0,370,735,1070,1448])
	var rows := PackedInt32Array([0,450,800,1086])
	var column: int = index%4
	var row: int = index/4
	return Rect2i(columns[column],rows[row],columns[column+1]-columns[column],rows[row+1]-rows[row])

func _create_decor_tiles() -> void:
	var tiles := TileSet.new()
	tiles.tile_size = Vector2i(362,286)
	for column in range(4):
		var texture := AtlasTexture.new()
		texture.atlas = load(DECOR_ART)
		texture.region = Rect2(_decor_frame(column+8))
		texture.filter_clip = true
		var source := TileSetAtlasSource.new()
		source.texture = texture
		source.texture_region_size = Vector2i(texture.region.size)
		source.create_tile(Vector2i.ZERO)
		tiles.add_source(source,column)
	var layer := TileMapLayer.new()
	layer.name = "GroundDecorTiles"
	layer.tile_set = tiles
	layer.scale = Vector2(64.0/tiles.tile_size.x,64.0/tiles.tile_size.y) * Dimensions.SCALE
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	layer.z_index = -1
	add_child(layer)
	for decoration in layout.decor:
		var coord := Vector2i(floori(decoration.position.x/(64.0*Dimensions.SCALE)),floori(decoration.position.y/(64.0*Dimensions.SCALE)))
		if _on_land((Vector2(coord)*64.0+Vector2(32,32))*Dimensions.SCALE):
			layer.set_cell(coord,decoration.tile,Vector2i.ZERO)
	for path in layout.paths:
		for index in range(4,path.size()-1,12):
			var point: Vector2 = path[index]
			var coord := Vector2i(floori(point.x/64.0),floori(point.y/64.0))
			if _on_land((Vector2(coord)*64.0+Vector2(32,32))*Dimensions.SCALE):
				layer.set_cell(coord,1,Vector2i.ZERO)

func _create_cliffs() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://resources/coastal_cliff.gdshader")
	material.set_shader_parameter("cliff_atlas",load(TILE_ART+"coast-atlas-v2.png"))
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for bank in layout.banks:
		var distance: float = 0.0
		for index in range(bank.size()-1):
			var a: Vector2 = bank[index]
			var b: Vector2 = bank[index+1]
			var middle: Vector2 = (a+b)*0.5
			var length: float = a.distance_to(b)
			# Render only banks whose land is above water in the camera's view.
			if _on_land(middle-Vector2(0,24)*Dimensions.SCALE) and not _on_land(middle+Vector2(0,24)*Dimensions.SCALE):
				var offset: int = points.size()
				points.append_array(PackedVector2Array([a-Vector2(0,48)*Dimensions.SCALE,b-Vector2(0,48)*Dimensions.SCALE,b+Vector2(0,16)*Dimensions.SCALE,a+Vector2(0,16)*Dimensions.SCALE]))
				uvs.append_array(PackedVector2Array([Vector2(distance/180.0,0),Vector2((distance+length)/180.0,0),Vector2((distance+length)/180.0,1),Vector2(distance/180.0,1)]))
				indices.append_array(PackedInt32Array([offset,offset+1,offset+2,offset,offset+2,offset+3]))
			distance += length
	if points.is_empty():
		return
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var cliff := MeshInstance2D.new()
	cliff.name = "CoastalCliffs"
	cliff.mesh = mesh
	cliff.material = material
	cliff.z_index = -2
	add_child(cliff)

func _create_tileset() -> void:
	tile_set = TileSet.new()
	tile_set.tile_size = Vector2i(CELL,CELL)
	for id in range(5):
		var atlas := TileSetAtlasSource.new()
		atlas.texture = textures[["sand","grass","water","dirt","paving"][id]]
		atlas.texture_region_size = Vector2i(CELL,CELL)
		for x in range(atlas.texture.get_width()/CELL):
			for y in range(atlas.texture.get_height()/CELL):
				atlas.create_tile(Vector2i(x,y))
		tile_set.add_source(atlas,id)

func _create_ground() -> void:
	var layer := TileMapLayer.new()
	layer.name = "GroundTiles"
	layer.tile_set = tile_set
	layer.z_index = -3
	var material := ShaderMaterial.new()
	material.shader = preload("res://resources/coastal_terrain.gdshader")
	var weights: ImageTexture = Terrain.weights(String(info.coastal_layout),info.size,layout)
	material.set_shader_parameter("terrain_weights",weights)
	material.set_shader_parameter("world_size",info.size)
	material.set_shader_parameter("terrain_origin",global_position)
	material.set_shader_parameter("plaza_center",layout.plaza)
	material.set_shader_parameter("world_scale",Dimensions.SCALE)
	material.set_shader_parameter("environment_tint",{"C":Color("f3edff"),"D":Color("c2d1e4"),"E":Color("e4dfcf")}.get(String(info.coastal_layout),Color.WHITE))
	for kind in ["sand","grass","water","dirt","paving"]:
		material.set_shader_parameter(kind+"_art",textures[kind])
	layer.material = material
	if info.coastal_layout in ["C","D","E"]:
		var ground := Polygon2D.new()
		ground.name = "ContinuousExplorationGround"
		ground.polygon = PackedVector2Array([Vector2.ZERO,Vector2(info.size.x,0),info.size,Vector2(0,info.size.y)])
		ground.material = material
		ground.z_index = -3
		add_child(ground)
		layer.free()
		return
	add_child(layer)
	var atlas: TileSetAtlasSource = tile_set.get_source(0)
	var atlas_size: Vector2i = atlas.texture.get_size()/CELL
	var mask: Image = weights.get_image()
	for x in range(int(ceil(info.size.x/CELL))):
		for y in range(int(ceil(info.size.y/CELL))):
			var center := Vector2(x*CELL+CELL*0.5,y*CELL+CELL*0.5)
			var sample: Color = mask.get_pixel(clampi(int(center.x/Terrain.SPACING),0,mask.get_width()-1),clampi(int(center.y/Terrain.SPACING),0,mask.get_height()-1))
			var source: int = 2 if sample.g>0.5 else (1 if sample.r>0.5 else (3 if sample.b>0.5 else 0))
			if layout.plaza != Vector2.ZERO and ((center-layout.plaza)/(Vector2(285,185)*Dimensions.SCALE)).length()<0.8:
				source = 4
			layer.set_cell(Vector2i(x,y),source,Vector2i(x%atlas_size.x,y%atlas_size.y))

func _add_ground_details() -> void:
	for polygon in layout.grass:
		for index in range(0,polygon.size(),5):
			var point: Vector2 = polygon[index]+Vector2(sin(index*1.7)*28.0,cos(index*2.4)*22.0)
			if _on_land(point):
				_create_prop({"kind":"tuft","position":point,"height":(25.0+float(index%4)*5.0)*Dimensions.SCALE})
	for bank in layout.banks:
		for index in range(3,bank.size()-1,11):
			var direction: Vector2 = bank[index+1]-bank[index-1]
			var normal: Vector2 = direction.normalized().orthogonal()*38.0
			var point: Vector2 = bank[index]+normal
			if not _on_land(point):
				point = bank[index]-normal
			if _on_land(point):
				_create_prop({"kind":"pebbles","position":point,"height":(18.0+float(index%3)*4.0)*Dimensions.SCALE})

func _on_land(point: Vector2) -> bool:
	if not Rect2(Vector2.ZERO,info.size).has_point(point):
		return false
	for polygon in layout.water:
		if Geometry2D.is_point_in_polygon(point,polygon):
			return false
	return true

func _create_prop(data: Dictionary) -> void:
	var prop := Node2D.new()
	prop.position = data.position
	prop.z_index = 5
	prop.name = String(data.kind).capitalize()+str(get_child_count())
	var sprite := Sprite2D.new()
	var region: Rect2 = regions[data.kind]
	sprite.texture = textures[data.kind]
	sprite.region_enabled = true
	sprite.region_rect = region
	sprite.scale = Vector2.ONE*float(data.height)/maxf(region.size.y,1.0)
	sprite.position.y = -float(data.height)*0.5
	if data.has("flip_h"):
		sprite.flip_h = bool(data.flip_h)
	elif data.kind in ["shrub","rock","tuft","pebbles"]:
		sprite.flip_h = int(data.position.x+data.position.y)%3 == 1
	if data.has("roof"):
		var shader := Shader.new()
		shader.code = "shader_type canvas_item; uniform vec4 roof_color:source_color; void fragment(){vec4 c=texture(TEXTURE,UV); float m=smoothstep(0.025,0.09,c.g-c.r)*(1.0-smoothstep(0.78,0.94,c.r)); float v=dot(c.rgb,vec3(0.299,0.587,0.114)); vec3 roof=roof_color.rgb*(v/0.64); COLOR=vec4(mix(c.rgb,roof,m*0.8),c.a); }"
		var material := ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("roof_color",data.roof)
		sprite.material = material
	prop.add_child(sprite)
	add_child(prop)
	restoration.register(sprite,String(data.kind),data.position,String(info.coastal_layout))
	if data.has("title"):
		var label := Label.new()
		label.text = data.title
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",18)
		label.add_theme_color_override("font_color",Color("4c5b52"))
		label.position = data.get("label_offset",Vector2(-65,18))
		prop.add_child(label)

func _process(delta: float) -> void:
	elapsed += delta
	redraw_clock += delta
	if visible and redraw_clock >= 0.1:
		redraw_clock = 0.0
		queue_redraw()

func _draw() -> void:
	if layout.is_empty():
		return
	# Soft contour washes hide the grid along curved terrain boundaries.
	for bank in layout.banks:
		draw_polyline(bank,Color(0.96,0.97,0.85,0.22+sin(elapsed)*0.03),2.0,true)
	if info.coastal_layout == "A":
		var fence := PackedVector2Array([Vector2(465,1040),Vector2(445,1120),Vector2(480,1190),Vector2(570,1230),Vector2(650,1245),Vector2(755,1210),Vector2(820,1160)])
		fence = Dimensions.expand(fence)
		var rail := PackedVector2Array()
		for foot in fence:
			rail.append(foot-Vector2(0,18))
		draw_polyline(rail,Color("a39270"),3.0,true)
		for foot in fence:
			draw_line(foot,foot-Vector2(0,32),Color("89785b"),5.0,true)
		for index in range(36):
			var a: float = TAU*index/36.0
			var point: Vector2 = layout.plaza+Vector2(cos(a)*275.0,sin(a)*170.0)*Dimensions.SCALE
			draw_arc(point,7.0,0.2,PI+0.5,10,Color(0.55,0.51,0.4,0.16),1.5,true)
		_draw_caption(info.target_position+Vector2(-50,-110),"연습 정원")
	for point in layout.dig_sites:
		for offset in [Vector2(-32,3),Vector2(0,-18),Vector2(30,16)]:
			draw_arc(point+offset,9,0,PI,12,Color(0.51,0.43,0.32,0.4),2,true)
	for exit_id in info.portals:
		var point: Vector2 = info.portals[exit_id]
		var title: String = "물빛 해안" if info.coastal_layout == "A" else ("해안 마을" if exit_id == "west" else "내륙 길")
		if info.coastal_layout in ["C","D","E"]:
			var signs: Dictionary = {"C":["물빛 해안","빗빛 갈림숲"],"D":["꽃 공터","폐허 정원"],"E":["갈림숲","꽃집"]}
			title = signs[info.coastal_layout][0 if exit_id == "west" else 1]
		draw_line(point+Vector2(0,-15),point+Vector2(0,-67),Color("8a7655"),5.0,true)
		draw_style_box(_sign_style(),Rect2(point+Vector2(-58,-86),Vector2(116,35)))
		_draw_caption(point+Vector2(-45,-62),title,16)
		draw_arc(point,24,0,TAU,40,Color(0.28,0.55,0.54,0.3),2.0,true)
	if info.coastal_layout == "D":
		for index in 90:
			var point := Vector2(fmod(float(index)*173.0+elapsed*17.0,info.size.x),fmod(float(index)*211.0+elapsed*110.0,info.size.y))
			draw_line(point,point+Vector2(-6,21),Color(0.63,0.73,0.83,0.16),1.2,true)

func _sign_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("e8d8b5")
	style.border_color = Color("b7a47e")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	return style

func _draw_caption(point: Vector2, title: String, size: int = 18) -> void:
	draw_string_outline(font,point,title,HORIZONTAL_ALIGNMENT_LEFT,-1,size,3,Color(0.97,0.95,0.87,0.8))
	draw_string(font,point,title,HORIZONTAL_ALIGNMENT_LEFT,-1,size,Color("4c5b52"))

extends Node2D

const ROOT: String = "res://assets/world/coast-tiles-v4/"

func _ready() -> void:
	var coast: TileSet = load(ROOT+"coast-tileset.tres")
	var grass: TileSet = load(ROOT+"terrain-tileset.tres")
	# The same nine coastal cells make a longer island through repeated edges.
	var shore := TileMapLayer.new()
	shore.name = "CoastalTiles"
	shore.tile_set = coast
	shore.position = Vector2(64,0)
	shore.scale = Vector2.ONE*144.0/float(coast.tile_size.x)
	shore.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(shore)
	for y in range(5):
		for x in range(8):
			shore.set_cell(Vector2i(x,y),0,Vector2i(0 if x == 0 else (2 if x == 7 else 1),0 if y == 0 else (2 if y == 4 else 1)))
	_add_grass_patch(grass,Vector2(240,120),Vector2i(3,3),120.0,"GrassPatch")
	_add_grass_patch(grass,Vector2(650,190),Vector2i(4,3),88.0,"ExtendedGrassPatch")
	var label := Label.new()
	label.position = Vector2(24,16)
	label.text = "수채화 타일 조합 · 풀밭 / 모래 / 물가 / 절벽"
	label.add_theme_font_size_override("font_size",22)
	label.add_theme_color_override("font_color",Color("374c45"))
	label.add_theme_color_override("font_shadow_color",Color("eee6cb"))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	add_child(label)

func _add_grass_patch(set: TileSet, origin: Vector2, size: Vector2i, cell: float, title: String) -> void:
	var layer := TileMapLayer.new()
	layer.name = title
	layer.tile_set = set
	layer.position = origin
	layer.scale = Vector2.ONE*cell/float(set.tile_size.x)
	layer.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var material := ShaderMaterial.new()
	material.shader = preload("res://resources/watercolor_grass_overlay.gdshader")
	layer.material = material
	add_child(layer)
	for y in range(size.y):
		for x in range(size.x):
			var column: int = 0 if x == 0 else (2 if x == size.x-1 else 1)
			var row: int = 0 if y == 0 else (2 if y == size.y-1 else 1)
			layer.set_cell(Vector2i(x,y),row*4+column,Vector2i.ZERO)

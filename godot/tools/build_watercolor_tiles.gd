extends SceneTree

const ROOT: String = "res://assets/world/coast-tiles-v4/"

func _initialize() -> void:
	var terrain: Texture2D = load(ROOT+"terrain-atlas.png")
	var coast: Texture2D = load(ROOT+"coast-atlas-v2.png")
	if terrain == null or coast == null:
		print("FAIL missing watercolor atlases")
		quit(1)
		return
	var grass_set := TileSet.new()
	var cell: float = float(terrain.get_width())/4.0
	grass_set.tile_size = Vector2i(int(cell),int(cell))
	# Fractional source regions retain the generated atlas's 1254px dimensions.
	# Each source contains one tile; neither raster is resized or overwritten.
	for y in range(4):
		for x in range(4):
			var region := AtlasTexture.new()
			region.atlas = terrain
			region.region = Rect2(Vector2(x,y)*cell,Vector2.ONE*cell)
			region.filter_clip = true
			var source := TileSetAtlasSource.new()
			source.texture = region
			source.texture_region_size = grass_set.tile_size
			source.create_tile(Vector2i.ZERO)
			grass_set.add_source(source,y*4+x)
	var coast_set := TileSet.new()
	coast_set.tile_size = Vector2i(coast.get_width()/3,coast.get_height()/3)
	var shore := TileSetAtlasSource.new()
	shore.texture = coast
	shore.texture_region_size = coast_set.tile_size
	for y in range(3):
		for x in range(3):
			shore.create_tile(Vector2i(x,y))
	coast_set.add_source(shore,0)
	var first: Error = ResourceSaver.save(grass_set,ROOT+"terrain-tileset.tres")
	var second: Error = ResourceSaver.save(coast_set,ROOT+"coast-tileset.tres")
	var passed: bool = first == OK and second == OK
	print("INK_WATERCOLOR_TILE_BUILD_PASS" if passed else "FAIL saving watercolor tilesets")
	quit(0 if passed else 1)

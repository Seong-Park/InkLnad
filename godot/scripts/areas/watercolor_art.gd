extends RefCounted

static var cache: Dictionary = {}

static func texture(kind: String) -> Texture2D:
	if cache.has(kind):
		return cache[kind]
	var actors: Dictionary = {
		"npc":Rect2i(0,0,490,670),"target":Rect2i(490,0,534,670),
		"drop":Rect2i(0,670,480,345),"dash":Rect2i(480,670,544,345),
		"blot":Rect2i(0,1015,475,521),"elite_dash":Rect2i(475,1015,549,521)}
	var buildings: Dictionary = {
		"brush-workshop":Rect2i(0,0,575,530),"pigment-shop":Rect2i(575,0,465,530),"map-house":Rect2i(1040,0,496,530),
		"teahouse":Rect2i(0,530,590,494),"pavilion":Rect2i(590,530,450,494),"storehouse":Rect2i(1040,530,496,494)}
	var village: Array[String] = ["apothecary","tool-shop","outfit-shop","craft-workshop","village-teahouse"]
	var path: String = "res://assets/characters/watercolor-v8/actors-atlas.png" if actors.has(kind) else "res://assets/world/coast-watercolor-v8/buildings-atlas.png"
	if kind in village:
		path = "res://assets/world/village-buildings-v9/"+kind+".png"
	var source: Texture2D = load(path)
	var frame: Rect2i = Rect2i(Vector2i.ZERO,source.get_size()) if kind in village else (actors[kind] if actors.has(kind) else buildings[kind])
	var occupied: Rect2i = source.get_image().get_region(frame).get_used_rect()
	var result := AtlasTexture.new()
	result.atlas = source
	result.region = Rect2(Rect2i(frame.position+occupied.position,occupied.size))
	result.filter_clip = true
	cache[kind] = result
	return result

extends RefCounted

var objects: Array[Dictionary] = []

func register(sprite: Sprite2D, kind: String, foot: Vector2, region_id: String) -> void:
	if kind not in ["flowerpots","pine","willow","bamboo","shrub","lantern","market","fountain"]:
		return
	var id: String = "color_%s_%s_%d_%d" % [region_id,kind,roundi(foot.x),roundi(foot.y)]
	var material := ShaderMaterial.new()
	material.shader = preload("res://resources/object_restoration.gdshader")
	material.set_shader_parameter("purple_flowers",kind == "flowerpots")
	var size: Vector2 = sprite.texture.get_size()
	var region: Rect2 = sprite.region_rect
	material.set_shader_parameter("source_region",Vector4(region.position.x/size.x,region.position.y/size.y,region.size.x/size.x,region.size.y/size.y))
	sprite.material = material
	objects.append({"id":id,"kind":kind,"point":foot,"sprite":sprite,"material":material,"restored":false,"cost":1})

func apply_flags(flags: Dictionary) -> void:
	for item in objects:
		item.restored = bool(flags.get(item.id,false))
		item.material.set_shader_parameter("restored",1.0 if item.restored else 0.0)

func nearest(point: Vector2) -> Dictionary:
	var nearest_item: Dictionary = {}
	var distance: float = 145.0
	for item in objects:
		var candidate: float = point.distance_to(item.point)
		if not item.restored and candidate < distance:
			distance = candidate
			nearest_item = item
	return nearest_item

func reveal(item: Dictionary) -> void:
	item.restored = true
	var wash: Node2D = preload("res://scripts/areas/restoration_wash.gd").new()
	wash.pigment = Color("9270b0") if item.kind == "flowerpots" else (Color("71936a") if item.kind in ["pine","willow","bamboo","shrub"] else Color("719baf"))
	wash.position = item.point
	item.sprite.get_parent().get_parent().add_child(wash)
	var tween: Tween = item.sprite.create_tween()
	tween.tween_method(func(value: float): item.material.set_shader_parameter("restored",value),0.0,1.0,1.5)

class_name FoxFrontRig
extends Node2D

signal attack_finished
signal foot_contact(side: StringName)
const MASTER := preload("res://assets/characters/fox-mage-master-v27/master.png")
const ORIGIN := Vector2(192,500)
const DURATIONS := {"idle":3.8,"walk":2.0/3.0,"attack":0.8}
var skeleton: Skeleton2D
var animator: AnimationPlayer
var bones: Dictionary = {}
var meshes: Dictionary = {}
var current_state: StringName = &"neutral"
var fixed_texture: Texture2D = MASTER
var patches: Dictionary = {}

func _ready() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton"
	add_child(skeleton)
	# Rest landmarks are in the original 384x512 texture, not fitted per clip.
	bone("hips","",Vector2(210,390))
	bone("torso","hips",Vector2(211,284))
	bone("head","torso",Vector2(214,191))
	bone("ear_l","head",Vector2(161,72))
	bone("ear_r","head",Vector2(273,69))
	bone("hair_l","head",Vector2(150,127))
	bone("hair_r","head",Vector2(282,127))
	bone("cape","torso",Vector2(210,214))
	bone("skirt","hips",Vector2(210,331))
	bone("arm_l","torso",Vector2(146,251))
	bone("forearm_l","arm_l",Vector2(121,307))
	bone("hand_l","forearm_l",Vector2(116,337))
	bone("weapon","hand_l",Vector2(113,349))
	bone("arm_r","torso",Vector2(281,248))
	bone("forearm_r","arm_r",Vector2(293,303))
	bone("hand_r","forearm_r",Vector2(299,337))
	bone("thigh_l","hips",Vector2(181,391))
	bone("shin_l","thigh_l",Vector2(174,445))
	bone("foot_l","shin_l",Vector2(174,479))
	bone("thigh_r","hips",Vector2(244,391))
	bone("shin_r","thigh_r",Vector2(247,445))
	bone("foot_r","shin_r",Vector2(246,479))
	build_parts()
	build_patches()
	animator = AnimationPlayer.new()
	animator.name = "AnimationPlayer"
	add_child(animator)
	var library := AnimationLibrary.new()
	for state in DURATIONS:
		library.add_animation(state,make_clip(state))
	animator.add_animation_library(&"",library)
	animator.animation_finished.connect(func(name: StringName):
		if name == &"attack":
			attack_finished.emit()
			play_state(&"idle"))

func bone(id: String, parent_id: String, atlas_position: Vector2) -> void:
	var node := Bone2D.new()
	node.name = id
	node.set_autocalculate_length_and_angle(false)
	node.length = 20.0
	var parent: Node2D = skeleton if parent_id.is_empty() else bones[parent_id]
	parent.add_child(node)
	var parent_atlas: Vector2 = ORIGIN if parent_id.is_empty() else parent.get_meta("atlas_position")
	node.position = atlas_position-parent_atlas
	node.rest = Transform2D(0.0,node.position)
	node.set_meta("atlas_position",atlas_position)
	bones[id] = node

func part_at(p: Vector2) -> String:
	if Rect2(168,136,104,40).has_point(p): return "eyes"
	if p.y < 84:
		return "ear_l" if p.x < 213 else "ear_r"
	if p.y < 200:
		if p.x < 158: return "hair_l"
		if p.x > 278: return "hair_r"
		return "head"
	if p.distance_to(Geometry2D.get_closest_point_to_segment(p,Vector2(97,275),Vector2(145,441))) < (24.0 if p.y > 391 else 13.0): return "weapon"
	if Rect2(304,328,32,40).has_point(p): return "hand_r"
	if p.y < 254: return "cape"
	if p.y < 365 and p.x < 133:
		return "weapon" if p.x < 109 or p.y > 350 else ("forearm_l" if p.y < 325 else "hand_l")
	if p.y < 376 and p.x > 280:
		return "forearm_r"
	if p.y < 317:
		return "arm_l" if p.x < 161 else ("arm_r" if p.x > 264 else "torso")
	if p.y < 405: return "skirt"
	var side := "l" if p.x < 212 else "r"
	return ("thigh_" if p.y < 439 else ("shin_" if p.y < 475 else "foot_"))+side

func vertex_weights(p: Vector2) -> Dictionary:
	# Shared boundary vertices get identical weights in every part mesh.
	var primary := part_at(p)
	if primary == "eyes": return {"head":1.0}
	if primary in ["head","weapon"]:
		return {primary:1.0}
	var result: Dictionary = {}
	var candidates: Array = [primary]
	if primary.begins_with("ear") or primary.begins_with("hair"):
		candidates.append("head")
	elif primary in ["cape","skirt"]:
		candidates.append("torso" if primary == "cape" else "hips")
	elif primary.begins_with("foot"):
		candidates.append("shin_"+primary.right(1))
	elif primary.begins_with("shin"):
		candidates.append("thigh_"+primary.right(1))
	elif primary.begins_with("thigh"):
		candidates.append("hips")
	elif primary.begins_with("hand"):
		candidates.append("forearm_"+primary.right(1))
	elif primary.begins_with("forearm"):
		candidates.append("arm_"+primary.right(1))
	elif primary.begins_with("arm"):
		candidates.append("torso")
	if candidates.size() == 1: return {primary:1.0}
	var anchor: Vector2 = bones[primary].get_meta("atlas_position")
	var child_weight := clampf(p.distance_to(anchor)/28.0,0.0,1.0)
	result[primary] = child_weight
	result[candidates[1]] = 1.0-child_weight
	return result

func build_parts() -> void:
	var groups: Dictionary = {}
	for y in range(0,512,8):
		for x in range(0,384,8):
			var points := [Vector2(x,y),Vector2(x+8,y),Vector2(x+8,y+8),Vector2(x,y+8)]
			var id := part_at(Vector2(x+4,y+4))
			if not groups.has(id): groups[id] = []
			groups[id].append(points)
	for id in groups:
		var mesh := Polygon2D.new()
		mesh.name = id
		add_child(mesh)
		mesh.texture = MASTER
		mesh.skeleton = NodePath("../Skeleton")
		var vertices := PackedVector2Array()
		var uv := PackedVector2Array()
		var polygons: Array[PackedInt32Array] = []
		for quad in groups[id]:
			var start := vertices.size()
			for p in quad:
				vertices.append(p-ORIGIN)
				uv.append(p)
			polygons.append(PackedInt32Array([start,start+1,start+2,start+3]))
		mesh.polygon = vertices
		mesh.uv = uv
		mesh.polygons = polygons
		for bone_id in bones:
			var weights := PackedFloat32Array()
			for p in uv: weights.append(vertex_weights(p).get(bone_id,0.0))
			mesh.add_bone(skeleton.get_path_to(bones[bone_id]),weights)
		meshes[id] = mesh

func track(clip: Animation, id: String, property: String, times: Array, values: Array) -> void:
	var index := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(index,NodePath(String(get_path_to(bones[id]))+":"+property))
	for i in times.size(): clip.track_insert_key(index,times[i],values[i])

func make_clip(state: String) -> Animation:
	var clip := Animation.new()
	clip.length = DURATIONS[state]
	clip.loop_mode = Animation.LOOP_NONE if state == "attack" else Animation.LOOP_LINEAR
	# Reset every bone in every clip: no residual pose after a transition.
	for id in bones:
		track(clip,id,"rotation",[0.0,clip.length],[0.0,0.0])
		var base: Vector2 = bones[id].position
		track(clip,id,"position",[0.0,clip.length],[base,base])
	for key in patches:
		visibility_track(clip,patches[key],[0.0,clip.length],[false,false])
	for key in ["eyes","hand_r","foot_l","foot_r"]:
		visibility_track(clip,meshes[key],[0.0,clip.length],[true,true])
	if state == "idle":
		visibility_track(clip,patches.blink,[0.0,2.72,2.84,3.8],[false,true,false,false])
		visibility_track(clip,meshes.eyes,[0.0,2.72,2.84,3.8],[true,false,true,true])
		for id in ["ear_l","ear_r","hair_l","hair_r","cape","skirt"]:
			var amplitude := 0.025 if id.begins_with("ear") else 0.012
			key_rotation(clip,id,[0.0,0.95,1.9,2.85,3.8],[0.0,amplitude,0.0,-amplitude,0.0])
		key_position(clip,"torso",[0.0,1.9,3.8],[Vector2.ZERO,Vector2(0,-1.5),Vector2.ZERO])
	elif state == "walk":
		visibility_track(clip,patches.foot_l,[0.0,0.12,0.27,clip.length],[false,true,false,false])
		visibility_track(clip,meshes.foot_l,[0.0,0.12,0.27,clip.length],[true,false,true,true])
		visibility_track(clip,patches.foot_r,[0.0,0.45,0.60,clip.length],[false,true,false,false])
		visibility_track(clip,meshes.foot_r,[0.0,0.45,0.60,clip.length],[true,false,true,true])
		for side in ["l","r"]:
			var sign_value: float = 1.0 if side == "l" else -1.0
			key_position(clip,"thigh_"+side,[0.0,clip.length/4,clip.length/2,clip.length*3/4,clip.length],[Vector2.ZERO,Vector2(0,-8 if side == "l" else 0),Vector2.ZERO,Vector2(0,-8 if side == "r" else 0),Vector2.ZERO])
			key_rotation(clip,"arm_"+side,[0.0,clip.length/4,clip.length/2,clip.length*3/4,clip.length],[0.0,0.035*sign_value,0.0,-0.035*sign_value,0.0])
		for id in ["hair_l","hair_r","cape","skirt"]:
			key_rotation(clip,id,[0.0,clip.length/4,clip.length/2,clip.length*3/4,clip.length],[0.0,0.018,0.0,-0.018,0.0])
	elif state == "attack":
		visibility_track(clip,patches.hand,[0.0,0.20,0.62,0.8],[false,true,false,false])
		visibility_track(clip,meshes.hand_r,[0.0,0.20,0.62,0.8],[true,false,true,true])
		key_rotation(clip,"arm_l",[0.0,0.2,0.36,0.52,0.8],[0.0,0.10,-0.15,-0.12,0.0])
		key_rotation(clip,"forearm_l",[0.0,0.2,0.36,0.52,0.8],[0.0,0.05,-0.25,-0.18,0.0])
		key_rotation(clip,"arm_r",[0.0,0.2,0.36,0.52,0.8],[0.0,-0.10,-0.18,-0.14,0.0])
		key_rotation(clip,"cape",[0.0,0.36,0.55,0.8],[0.0,0.018,-0.012,0.0])
	return clip

func replace_track(clip: Animation,id: String,property: String,times: Array,values: Array) -> void:
	var path := NodePath(String(get_path_to(bones[id]))+":"+property)
	var index := clip.find_track(path,Animation.TYPE_VALUE)
	clip.remove_track(index)
	track(clip,id,property,times,values)

func key_rotation(clip: Animation,id: String,times: Array,values: Array) -> void:
	replace_track(clip,id,"rotation",times,values)

func key_position(clip: Animation,id: String,times: Array,offsets: Array) -> void:
	var values: Array = []
	for offset in offsets: values.append(bones[id].position+offset)
	replace_track(clip,id,"position",times,values)

func play_state(state: StringName) -> void:
	if not DURATIONS.has(String(state)): return
	current_state = state
	animator.play(state,0.10)

func neutral() -> void:
	animator.stop()
	current_state = &"neutral"
	for id in bones:
		bones[id].position = bones[id].rest.origin
		bones[id].rotation = 0.0
	for patch in patches.values(): patch.visible = false
	for mesh in meshes.values(): mesh.visible = true

func build_patches() -> void:
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-front-rig-v28/parts.json"))
	patch("blink","blink","head",Rect2(168,136,104,40),meta)
	patch("hand","open-hand","hand_r",Rect2(303,328,34,41),meta)
	patch("foot_l","lifted-foot","foot_l",Rect2(150,475,49,32),meta)
	patch("foot_r","lifted-foot","foot_r",Rect2(220,475,49,32),meta)

func patch(id: String,texture_id: String,bone_id: String,target: Rect2,meta: Dictionary) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "Patch_"+id
	var atlas := AtlasTexture.new()
	atlas.atlas = load("res://assets/characters/fox-front-rig-v28/"+texture_id+".png")
	var rect: Array = meta[texture_id].rect
	atlas.region = Rect2(rect[0],rect[1],rect[2],rect[3])
	if texture_id == "lifted-foot":
		atlas.region.position.y += atlas.region.size.y*0.56
		atlas.region.size.y *= 0.44
	atlas.filter_clip = true
	sprite.texture = atlas
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.scale = target.size/atlas.region.size
	sprite.position = target.get_center()-Vector2(bones[bone_id].get_meta("atlas_position"))
	sprite.visible = false
	sprite.z_index = 5
	bones[bone_id].add_child(sprite)
	patches[id] = sprite

func visibility_track(clip: Animation,node: CanvasItem,times: Array,values: Array) -> void:
	var path := NodePath(String(get_path_to(node))+":visible")
	var previous := clip.find_track(path,Animation.TYPE_VALUE)
	if previous >= 0: clip.remove_track(previous)
	var index := clip.add_track(Animation.TYPE_VALUE)
	clip.track_set_path(index,path)
	clip.value_track_set_update_mode(index,Animation.UPDATE_DISCRETE)
	for i in times.size(): clip.track_insert_key(index,times[i],values[i])

extends Node2D

const ASSETS: String = "res://assets/characters/village-npcs-v10/"
var resident_id: String = ""
var role: String = ""
var player: Node2D
var sprite: AnimatedSprite2D
var route: PackedVector2Array = PackedVector2Array()
var waypoint: int = 1
var wait_remaining: float = 0.0
var moving: bool = false
var height: float = 80.0
var elapsed: float = 0.0
var phase: float = 0.0
var home: Vector2
var stroll: bool = false
var walk_faces_left: bool = false
var travel_speed: float = 0.0
var frame_feet: Dictionary = {}
var bubble: Label
var query := PhysicsShapeQueryParameters2D.new()

func configure(data: Dictionary, player_value: Node2D) -> void:
	resident_id = data.id
	role = data.role
	name = resident_id
	player = player_value
	position = data.position
	home = position
	stroll = bool(data.get("stroll",false))
	walk_faces_left = String(data.art) == "tool-merchant"
	height = float(data.get("height",80.0))
	phase = float(data.get("phase",0.0))
	route = data.get("route",PackedVector2Array())
	if stroll:
		route = PackedVector2Array([home,home+Vector2(28,0)*float(data.get("world_scale",1.0)),home,home-Vector2(28,0)*float(data.get("world_scale",1.0))])
		wait_remaining = 2.0+fmod(phase,5.0)
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shape := CircleShape2D.new()
	shape.radius = 12.0 * float(data.get("world_scale",1.0))
	query.shape = shape
	query.collision_mask = 1
	var source: Texture2D = load(ASSETS+String(data.art)+".png")
	var still := AtlasTexture.new()
	still.atlas = source
	still.region = Rect2(source.get_image().get_used_rect())
	still.filter_clip = true
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	frames.add_animation(&"idle")
	frames.add_frame(&"idle",still)
	frames.set_animation_speed(&"idle",1.0)
	_load_clip(frames,String(data.art),&"idle")
	if not route.is_empty():
		_load_clip(frames,String(data.art),&"walk")
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.animation = &"idle"
	sprite.play(&"idle")
	sprite.frame = int(phase)%frames.get_frame_count(&"idle")
	sprite.flip_h = bool(data.get("flip_h",false))
	sprite.modulate = data.get("tint",Color.WHITE)
	add_child(sprite)
	bubble = Label.new()
	bubble.modulate.a = 0.0
	bubble.text = data.speech
	bubble.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bubble.position = Vector2(-112,-height-32)
	bubble.size = Vector2(224,28)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic"])
	bubble.add_theme_font_override("font",font)
	bubble.add_theme_font_size_override("font_size",14)
	bubble.add_theme_color_override("font_color",Color("43554d"))
	var paper := StyleBoxFlat.new()
	paper.bg_color = Color(0.97,0.94,0.83,0.93)
	paper.border_color = Color(0.60,0.65,0.54,0.6)
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(9)
	paper.content_margin_left = 8
	paper.content_margin_right = 8
	bubble.add_theme_stylebox_override("normal",paper)
	bubble.hide()
	add_child(bubble)
	_pose()
	queue_redraw()

func _load_clip(frames: SpriteFrames, art: String, animation: StringName) -> void:
	var path: String = ASSETS+art+"-"+String(animation)+".json"
	if not FileAccess.file_exists(path):
		return
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var sheet: Texture2D = load(ASSETS+art+"-"+String(animation)+".webp")
	var image: Image = sheet.get_image()
	var size := Vector2i(image.get_width()/int(metadata.num_cols),image.get_height()/int(metadata.num_rows))
	var occupied := Rect2i()
	for index in int(metadata.num_frames):
		var origin := Vector2i(index%int(metadata.num_cols),index/int(metadata.num_cols))*size
		var bounds: Rect2i = image.get_region(Rect2i(origin,size)).get_used_rect()
		if bounds.has_area():
			occupied = bounds if not occupied.has_area() else occupied.merge(bounds)
	if frames.has_animation(animation):
		frames.remove_animation(animation)
	frames.add_animation(animation)
	frames.set_animation_loop(animation,true)
	var pace: float = 0.65+fmod(phase,3.0)*0.05 if animation == &"idle" else 1.0
	frames.set_animation_speed(animation,float(metadata.num_frames)/float(metadata.duration)*pace)
	var feet: Array[float] = []
	for index in int(metadata.num_frames):
		var origin := Vector2i(index%int(metadata.num_cols),index/int(metadata.num_cols))*size
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(Rect2i(origin+occupied.position,occupied.size))
		texture.filter_clip = true
		frames.add_frame(animation,texture)
		var bounds: Rect2i = image.get_region(Rect2i(origin,size)).get_used_rect()
		feet.append(float(bounds.end.y-occupied.position.y))
	frame_feet[animation] = feet

func _draw() -> void:
	# Layered translucent washes ground the character without a hard black oval.
	for layer in 4:
		var radius: float = height*(0.13+float(layer)*0.035)
		draw_set_transform(Vector2(0,-1),0.0,Vector2(1,0.30))
		draw_circle(Vector2.ZERO,radius,Color(0.34,0.37,0.29,0.025))
	draw_set_transform(Vector2.ZERO)

func obstructed(local_point: Vector2) -> bool:
	query.transform = Transform2D(0,get_parent().to_global(local_point))
	return not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _physics_process(delta: float) -> void:
	moving = false
	if route.size() < 2:
		return
	if wait_remaining > 0.0:
		travel_speed = 0.0
		wait_remaining = maxf(0.0,wait_remaining-delta)
		return
	var target: Vector2 = route[waypoint]
	if position.distance_to(target) < 2.0:
		travel_speed = 0.0
		waypoint = (waypoint+1)%route.size()
		wait_remaining = (4.0+fmod(phase,3.0)) if stroll else (1.4+fmod(phase,1.2))
		return
	var maximum_speed: float = 22.0 if stroll else 38.0
	var desired_speed: float = minf(maximum_speed,sqrt(2.0*80.0*position.distance_to(target)))
	travel_speed = move_toward(travel_speed,desired_speed,80.0*delta)
	var candidate: Vector2 = position.move_toward(target,travel_speed*delta)
	if obstructed(candidate) or (is_instance_valid(player) and player.global_position.distance_to(get_parent().to_global(candidate)) < 34.0):
		wait_remaining = 0.3
		travel_speed = 0.0
		return
	# The brush merchant's source faces left; the other walk sources face right.
	sprite.flip_h = (candidate.x > position.x) if walk_faces_left else (candidate.x < position.x)
	position = candidate
	moving = true

func _process(delta: float) -> void:
	if sprite == null:
		return
	elapsed += delta
	if moving and sprite.sprite_frames.has_animation(&"walk"):
		sprite.speed_scale = clampf(travel_speed/(22.0 if stroll else 38.0),0.30,1.0)
		if sprite.animation != &"walk" or not sprite.is_playing():
			sprite.play(&"walk")
	else:
		sprite.speed_scale = 1.0
		if sprite.animation != &"idle" or not sprite.is_playing():
			sprite.play(&"idle")
	_pose()
	var speaking: bool = not moving and is_instance_valid(player) and player.global_position.distance_to(global_position) < 145.0 and fmod(elapsed+phase,24.0) < 2.8
	bubble.modulate.a = move_toward(bubble.modulate.a,1.0 if speaking else 0.0,delta*5.0)
	bubble.visible = bubble.modulate.a > 0.01

func _pose() -> void:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var breathing: float = 1.0 if sprite.sprite_frames.get_frame_count(sprite.animation) > 1 else 1.0+sin(elapsed*1.7+phase)*0.006
	sprite.scale = Vector2.ONE*height/maxf(texture.get_height(),1.0)
	sprite.scale.y *= breathing
	var bottom: float = texture.get_height()
	# A lifted walking foot must not drag the entire body up/down.
	# Keep walk frames on their shared baseline; idle poses can anchor their feet.
	if sprite.animation != &"walk" and frame_feet.has(sprite.animation):
		bottom = frame_feet[sprite.animation][sprite.frame]
	sprite.position.y = (texture.get_height()*0.5-bottom)*sprite.scale.y

extends Node2D

var sprite: AnimatedSprite2D
var route: PackedVector2Array
var waypoint: int = 1
var wait_remaining: float = 0.0
var player: Node2D
var pace: float = 22.0
var moving: bool = false
var resting: bool = false
var sleeping: bool = false
var flies: bool = false
var flight_height: float = 0.0
var flight_elapsed: float = 0.0
var flight_start: Vector2
var airborne: bool = false
var breath_time: float = 0.0
var floors: Dictionary = {}
var image_scale: float = 1.0
var query := PhysicsShapeQueryParameters2D.new()

func configure(data: Dictionary, companion: Node2D) -> void:
	name = data.id
	position = data.route[0]
	route = data.route
	player = companion
	pace = data.get("pace",22.0)
	wait_remaining = data.get("phase",0.0)
	resting = data.get("resting",false)
	sleeping = data.get("sleeping",false)
	flies = data.get("flies",false)
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	query.shape = shape
	query.collision_mask = 1
	var folder: String = data.get("folder","village-animals-v15")
	var asset_path: String = "res://assets/characters/"+folder+"/"
	var texture: Texture2D = load(asset_path+String(data.art)+".png")
	# Read-only alpha-core measurements avoid scaling faint padding as animal art.
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(asset_path+"bounds.json"))[String(data.art)]
	var cell := Vector2i(metadata.cell[0],metadata.cell[1])
	var occupied := Rect2i()
	var tallest: int = 1
	for index in 8:
		var box: Array = metadata.frames[index]
		var bounds := Rect2i(box[0],box[1],box[2],box[3])
		occupied = bounds if not occupied.has_area() else occupied.merge(bounds)
		if not flies or index < 4:
			tallest = maxi(tallest,bounds.size.y)
	image_scale = float(data.height)/tallest
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for row in 2:
		var animation: StringName = &"idle" if row == 0 else (&"fly" if flies else &"walk")
		frames.add_animation(animation)
		frames.set_animation_speed(animation,1.0 if sleeping else (4.0 if row == 0 else (10.0 if flies else 6.5)))
		frames.set_animation_loop(animation,true)
		var bottom: int = 0
		for column in 4:
			var origin := Vector2i(column,row)*cell
			var box: Array = metadata.frames[row*4+column]
			var bounds := Rect2i(box[0],box[1],box[2],box[3])
			bottom = maxi(bottom,bounds.end.y)
			var frame := AtlasTexture.new()
			frame.atlas = texture
			frame.region = Rect2(Rect2i(origin+occupied.position,occupied.size))
			frame.filter_clip = true
			var duration: float = [8.0,0.5,2.0,0.5][column] if row == 0 and not sleeping else 1.0
			frames.add_frame(animation,frame,duration)
		floors[animation] = float(bottom-occupied.position.y)
		if animation == &"fly":
			# Wings change the outline, not the torso's fixed cell anchor.
			floors[animation] = cell.y*0.5-occupied.position.y+tallest*0.5
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.modulate = data.get("tint",Color.WHITE)
	sprite.scale = Vector2.ONE*image_scale
	add_child(sprite)
	sprite.play(&"idle")
	_pose()

func obstructed(point: Vector2) -> bool:
	query.transform = Transform2D(0,get_parent().to_global(point))
	return not get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

func _physics_process(delta: float) -> void:
	moving = false
	if resting:
		return
	if flies:
		_update_flight(delta)
		return
	if wait_remaining > 0.0:
		wait_remaining = maxf(wait_remaining-delta,0.0)
		return
	var target: Vector2 = route[waypoint]
	if position.distance_to(target) < 1.0:
		waypoint = (waypoint+1)%route.size()
		wait_remaining = 3.0+float(waypoint)*0.6
		return
	var next: Vector2 = position.move_toward(target,pace*delta)
	if obstructed(next) or (is_instance_valid(player) and player.global_position.distance_to(get_parent().to_global(next)) < 28.0):
		wait_remaining = 0.35
		return
	if absf(next.x-position.x) > 0.01:
		sprite.flip_h = next.x < position.x
	position = next
	moving = true

func _update_flight(delta: float) -> void:
	if not airborne:
		wait_remaining = maxf(wait_remaining-delta,0.0)
		if is_instance_valid(player) and player.global_position.distance_to(global_position) < 45.0:
			wait_remaining = 0.0
		if wait_remaining > 0.0:
			return
		flight_start = position
		flight_elapsed = 0.0
		airborne = true
	var target: Vector2 = route[waypoint]
	flight_elapsed += delta
	var duration: float = maxf(flight_start.distance_to(target)/pace,1.2)
	var progress: float = clampf(flight_elapsed/duration,0.0,1.0)
	position = flight_start.lerp(target,smoothstep(0.0,1.0,progress))
	flight_height = 64.0*sin(progress*PI)
	sprite.flip_h = target.x < flight_start.x
	moving = true
	if progress >= 1.0:
		position = target
		flight_height = 0.0
		airborne = false
		moving = false
		waypoint = (waypoint+1)%route.size()
		wait_remaining = 4.0+float(waypoint)

func _process(delta: float) -> void:
	breath_time += delta
	var animation: StringName = (&"fly" if flies else &"walk") if moving else &"idle"
	if sprite.animation != animation:
		sprite.play(animation)
	_pose()
	if sleeping:
		sprite.scale.y = image_scale*(1.0+0.018*sin(breath_time*TAU/4.0))

func _pose() -> void:
	var texture: Texture2D = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	# One baseline per clip preserves lifted paws and the bird's drawn hop.
	sprite.position.y = (texture.get_height()*0.5-floors[sprite.animation])*image_scale-flight_height

func _draw() -> void:
	draw_set_transform(Vector2.ZERO,0.0,Vector2(1,0.3))
	draw_circle(Vector2.ZERO,10.0,Color(0.35,0.39,0.30,0.09))
	draw_set_transform(Vector2.ZERO)

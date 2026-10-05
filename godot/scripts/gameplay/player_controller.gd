class_name PlayerController
extends CharacterBody2D

signal moved(distance: float)
signal footstep_contact(frame_index: int)
const WALK_FPS: float = 27.0
# Match the painted head/body rather than staff/tail-inclusive atlas bounds.
const WALK_VISUAL_SCALE: Dictionary = {"e":1.0,"se":0.94,"s":0.91,"ne":0.98,"n":0.90}
const WALK_CONTACT_FRAMES: Array[int] = [0,9,18,27]
const FACINGS: Array[StringName] = [&"e",&"se",&"s",&"sw",&"w",&"nw",&"n",&"ne"]
var facing: StringName = &"se"
var casting: bool = false
var changing_walk_direction: bool = false
var last_contact_frame: int = -1
@onready var footstep_audio: AudioStreamPlayer = $FootstepAudio
var hp: float = 100.0
var actual_velocity: Vector2 = Vector2.ZERO
var enabled: bool = false
var immunity: float = 0.0
var walk_time: float = 0.0
var speed: float = 180.0
var tool_id: StringName = &"brush"
var use_phase: StringName = &"ready"
@onready var portrait: AnimatedSprite2D = $Portrait
var portrait_frames: Dictionary = {}
var native_ludo_v27: bool = false
var secondary_material: ShaderMaterial
var secondary_weight: float = 0.0
var expression_time: float = 0.0
var touch_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/fox_mage_frames.json"))
	portrait_frames = metadata.get("frames", metadata)
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation(&"default")
	for animation in [&"idle", &"walk", &"cast"]:
		var texture: Texture2D = load(metadata.textures[String(animation)])
		frames.add_animation(animation)
		frames.set_animation_loop(animation, animation != &"cast")
		frames.set_animation_speed(animation, float(metadata.fps[String(animation)]))
		for entry in portrait_frames[String(animation)]:
			var frame_texture: AtlasTexture = AtlasTexture.new()
			frame_texture.atlas = texture
			frame_texture.filter_clip = true
			var rect: Array = entry.rect
			frame_texture.region = Rect2(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]))
			frames.add_frame(animation, frame_texture)
	_load_directional_frames(frames)
	portrait.sprite_frames = frames
	secondary_material = ShaderMaterial.new()
	secondary_material.shader = load("res://resources/fox_secondary_motion.gdshader")
	portrait.material = secondary_material
	if native_ludo_v27:
		portrait.material = null
	portrait.scale = Vector2.ONE * float(metadata.get("scale", 1.0))
	portrait.animation_finished.connect(_finish_cast)
	portrait.frame_changed.connect(_align_portrait_frame)
	portrait.frame_changed.connect(_on_footstep_frame)
	portrait.animation_changed.connect(_align_portrait_frame)
	portrait.play(&"idle_se")
	_align_portrait_frame()

func _align_portrait_frame() -> void:
	if portrait_frames.is_empty():
		return
	# animation_changed may precede frame reset when a 16-frame cast switches
	# to a four-frame directional clip. Align the valid destination frame.
	var entries: Array = portrait_frames[String(portrait.animation)]
	var entry: Dictionary = entries[mini(portrait.frame,entries.size()-1)]
	portrait.scale = Vector2.ONE * float(entry.get("scale", 0.4133476856835307))
	var rect: Array = entry.rect
	var foot: Array = entry.foot_anchor
	var offset: Vector2 = Vector2(float(rect[2]) * 0.5 - float(foot[0]), float(rect[3]) * 0.5 - float(foot[1])) * portrait.scale
	offset.x *= -1.0 if portrait.flip_h else 1.0
	portrait.position = offset
	_update_secondary_frame()

func _update_secondary_frame() -> void:
	if native_ludo_v27:
		return
	if secondary_material == null:
		return
	var texture: AtlasTexture = portrait.sprite_frames.get_frame_texture(portrait.animation, mini(portrait.frame, portrait.sprite_frames.get_frame_count(portrait.animation)-1)) as AtlasTexture
	if texture == null:
		return
	var atlas_size: Vector2 = texture.atlas.get_size()
	var region: Rect2 = texture.region
	secondary_material.set_shader_parameter("frame_rect", Vector4(region.position.x/atlas_size.x, region.position.y/atlas_size.y, region.size.x/atlas_size.x, region.size.y/atlas_size.y))
	var source: String = {"sw":"se","w":"e","nw":"ne"}.get(String(facing),String(facing))
	secondary_material.set_shader_parameter("tail_center", {"e":Vector2(0.22,0.65),"se":Vector2(0.23,0.61),"s":Vector2(0.82,0.53),"ne":Vector2(0.30,0.66),"n":Vector2(0.55,0.74)}[source])
	var hair_center: Vector2 = Vector2(0.43,0.24) if source == "e" else Vector2(0.52,0.24)
	if is_walking():
		hair_center = {"e":Vector2(0.59,0.24),"se":Vector2(0.50,0.24),"s":Vector2(0.56,0.24),"ne":Vector2(0.52,0.23),"n":Vector2(0.43,0.25)}[source]
	elif is_idle() or is_cast_animation():
		hair_center = {"e":Vector2(0.57,0.23),"se":Vector2(0.57,0.23),"s":Vector2(0.53,0.23),"ne":Vector2(0.53,0.23),"n":Vector2(0.53,0.23)}[source]
	secondary_material.set_shader_parameter("hair_center", hair_center)
	var proportions: Vector2 = Vector2.ONE
	if is_idle() or is_cast_animation():
		proportions = {"e":Vector2.ONE,"se":Vector2.ONE,"s":Vector2(0.83,1.0),"ne":Vector2(0.90,1.01),"n":Vector2(0.92,1.0)}[source]
	if is_cast_animation():
		# Cast atlas calibration is independent of the native idle atlas.
		proportions = {"e":Vector2.ONE,"se":Vector2.ONE,"s":Vector2(0.72,1.0),"ne":Vector2(0.90,1.01),"n":Vector2(1.05,1.0)}[source]
	secondary_material.set_shader_parameter("head_proportion",proportions)
	secondary_material.set_shader_parameter("head_pivot",Vector2(hair_center.x,0.42 if is_cast_animation() and source == "s" else 0.33))
	secondary_material.set_shader_parameter("skirt_center", Vector2(0.53,0.71))

func _process(delta: float) -> void:
	if secondary_material == null:
		return
	expression_time += delta
	if native_ludo_v27:
		secondary_material.set_shader_parameter("motion_weight", 0.0)
		secondary_material.set_shader_parameter("cloth_tail_weight", 0.0)
		return
	var walking: bool = enabled and not casting and is_walking() and actual_velocity.length() > 1.0
	# A relaxed planted stance needs subtle follow-through, not a deformed frozen step.
	var native_idle: bool = is_idle()
	var target_weight: float = (0.65 if walking else (0.0 if native_idle else 0.40)) if enabled and not casting else 0.0
	secondary_weight = move_toward(secondary_weight, target_weight, delta*6.0)
	var phase: float = (float(portrait.frame)+portrait.frame_progress)*TAU/18.0 if is_walking() else expression_time*TAU/3.8
	secondary_material.set_shader_parameter("gait_phase", phase)
	secondary_material.set_shader_parameter("motion_weight", secondary_weight if not casting and not native_idle else 0.0)
	secondary_material.set_shader_parameter("cloth_tail_weight", 0.0 if is_walking() else 1.0)
	secondary_material.set_shader_parameter("idle_breath", 1.0 if enabled and is_idle() and not casting else 0.0)

func start_cast(aim: Vector2 = Vector2.ZERO) -> void:
	if not enabled or casting:
		return
	if aim.length_squared() > 0.001:
		facing = FACINGS[posmod(roundi(aim.angle()/(PI/4.0)),8)]
	casting = true
	footstep_audio.stop()
	portrait.flip_h = not native_ludo_v27 and facing in [&"sw",&"w",&"nw"]
	portrait.speed_scale = 1.0
	portrait.play(StringName("cast_"+String(facing)))
	_align_portrait_frame()

func _load_directional_frames(frames: SpriteFrames) -> void:
	var pack_path: String = "res://assets/characters/fox-mage-master-v27/runtime-frames.json"
	if FileAccess.file_exists(pack_path):
		var pack: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(pack_path))
		native_ludo_v27 = true
		for clip_name in pack.clips:
			var clip: Dictionary = pack.clips[clip_name]
			var texture: Texture2D = load(clip.texture)
			var animation: StringName = StringName(clip_name)
			frames.add_animation(animation)
			frames.set_animation_loop(animation, not String(clip_name).begins_with("cast_"))
			frames.set_animation_speed(animation, float(clip.fps))
			portrait_frames[clip_name] = clip.frames
			for entry in clip.frames:
				var atlas: AtlasTexture = AtlasTexture.new()
				atlas.atlas = texture
				atlas.filter_clip = true
				var rect: Array = entry.rect
				atlas.region = Rect2(rect[0], rect[1], rect[2], rect[3])
				frames.add_frame(animation, atlas)
		return
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-mage-ludo-v21/frames.json"))
	var native_idle_metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-mage-idle-v25/frames.json"))
	var cast_metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-mage-cast-v26/frames.json"))
	for direction in FACINGS:
		var source: String = {"sw":"se","w":"e","nw":"ne"}.get(String(direction),String(direction))
		for state in ["idle","walk","cast"]:
			var image_path: String = "res://assets/characters/fox-mage-ludo-v21/walk-"+source+".webp"
			if state == "idle":
				image_path = "res://assets/characters/fox-mage-idle-v25/"+String(native_idle_metadata[source].get("texture","idle-"+source+"-expressive.png"))
			elif state == "cast":
				image_path = "res://assets/characters/fox-mage-cast-v26/"+String(cast_metadata[source].texture)
			var texture: Texture2D = load(image_path)
			var animation := StringName(state+"_"+String(direction))
			frames.add_animation(animation)
			frames.set_animation_loop(animation,state != "cast")
			frames.set_animation_speed(animation,4.0 if state == "idle" else (10.0 if state == "cast" else WALK_FPS))
			var entries: Array = (native_idle_metadata[source].idle if state == "idle" else (cast_metadata[source].cast if state == "cast" else metadata[source].walk)).duplicate(true)
			if state == "walk":
				for entry in entries:
					entry.scale = float(entry.scale)*float(WALK_VISUAL_SCALE[source])
			portrait_frames[String(animation)] = entries
			for entry in entries:
				var frame := AtlasTexture.new()
				frame.atlas = texture
				var rect: Array = entry.rect
				frame.region = Rect2(rect[0],rect[1],rect[2],rect[3])
				frame.filter_clip = true
				frames.add_frame(animation,frame,float(entry.get("duration",1.0)))

func is_walking() -> bool:
	return String(portrait.animation).begins_with("walk_")

func is_idle() -> bool:
	return String(portrait.animation).begins_with("idle_")

func is_cast_animation() -> bool:
	return portrait.animation == &"cast" or String(portrait.animation).begins_with("cast_")

func _finish_cast() -> void:
	if is_cast_animation():
		casting = false
		_update_portrait()

func _update_portrait() -> void:
	if casting:
		_align_portrait_frame()
		return
	if actual_velocity.length() > 1.0:
		var sector: int = posmod(roundi(actual_velocity.angle()/(PI/4.0)),8)
		var current_angle: float = FACINGS.find(facing)*PI/4.0
		# Keep the current view near a sector boundary to avoid joystick flicker.
		if absf(wrapf(actual_velocity.angle()-current_angle,-PI,PI)) > PI/8.0+deg_to_rad(6.0):
			facing = FACINGS[sector]
	portrait.flip_h = not native_ludo_v27 and facing in [&"sw",&"w",&"nw"]
	if enabled and actual_velocity.length() > 1.0:
		var animation := StringName("walk_"+String(facing))
		if portrait.animation != animation or not portrait.is_playing():
			var preserve: bool = is_walking()
			var frame: int = portrait.frame
			var progress: float = portrait.frame_progress
			changing_walk_direction = preserve
			portrait.play(animation)
			if preserve:
				portrait.set_frame_and_progress(frame,progress)
			changing_walk_direction = false
			_on_footstep_frame()
		portrait.speed_scale = actual_velocity.length() / maxf(speed, 0.001)
	else:
		last_contact_frame = -1
		footstep_audio.stop()
		portrait.speed_scale = 1.0
		var animation := StringName("idle_"+String(facing))
		if portrait.animation != animation or not portrait.is_playing():
			portrait.play(animation)
	_align_portrait_frame()

func _on_footstep_frame() -> void:
	if changing_walk_direction or not enabled or actual_velocity.length() <= 1.0 or not is_walking():
		return
	if portrait.frame not in WALK_CONTACT_FRAMES or portrait.frame == last_contact_frame:
		return
	last_contact_frame = portrait.frame
	footstep_audio.play()
	footstep_contact.emit(portrait.frame)

func set_enabled(value: bool) -> void:
	enabled = value
	if not value:
		casting = false
		velocity = Vector2.ZERO
		actual_velocity = Vector2.ZERO
		if is_node_ready():
			_update_portrait()

func _physics_process(dt: float) -> void:
	immunity = maxf(0.0, immunity - dt)
	var before: Vector2 = position
	var direction: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if touch_direction != Vector2.ZERO:
		direction = touch_direction
	velocity = direction * speed if enabled else Vector2.ZERO
	move_and_slide()
	actual_velocity = (position - before) / dt
	if actual_velocity.length() > 0.1:
		walk_time += dt
		moved.emit(position.distance_to(before))
	_update_portrait()
	queue_redraw()

func apply_hit(amount: float) -> bool:
	if immunity > 0.0 or hp <= 0.0:
		return false
	hp = maxf(0.0, hp - amount)
	immunity = 0.75
	return true

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color(0.23,0.2,0.18,0.12))
	if tool_id == &"pencil":
		draw_line(Vector2(13,-29),Vector2(24,-52),Color("3B3430"),3.0,true)
	if use_phase == &"recharging":
		draw_arc(Vector2(0,-26),24,0,TAU,24,Color(0.09,0.29,0.78,0.3),1.5,true)


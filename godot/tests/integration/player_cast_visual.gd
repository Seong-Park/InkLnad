extends SceneTree

const FOLDER := "C:/workspace/Ink-Land/docs/verification/player-cast-v26/captures/"
var sprites: Array[AnimatedSprite2D] = []
var entries: Array[Array] = []

func _initialize() -> void:
	call_deferred("run")

func align(sprite: AnimatedSprite2D, frames: Array) -> void:
	var entry: Dictionary = frames[sprite.frame]
	var rect: Array = entry.rect
	var foot: Array = entry.foot_anchor
	sprite.scale = Vector2.ONE*float(entry.scale)*2.0
	var offset := Vector2(float(rect[2])*0.5-float(foot[0]),float(rect[3])*0.5-float(foot[1]))*sprite.scale
	offset.x *= -1.0 if sprite.flip_h else 1.0
	sprite.position = sprite.get_meta("ground_position")+offset
	var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var size: Vector2 = atlas.atlas.get_size()
	var region: Rect2 = atlas.region
	(sprite.material as ShaderMaterial).set_shader_parameter("frame_rect",Vector4(region.position.x/size.x,region.position.y/size.y,region.size.x/size.x,region.size.y/size.y))

func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	DirAccess.make_dir_recursive_absolute(FOLDER)
	create_timer(40.0).timeout.connect(func(): print("FAIL idle visual watchdog"); quit(1))
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var paper := ColorRect.new()
	paper.size = Vector2(1280,720)
	paper.color = Color("f1ead8")
	layer.add_child(paper)
	var player: PlayerController = load("res://scenes/gameplay/Player.tscn").instantiate()
	root.add_child(player)
	player.hide()
	await process_frame
	for index in 8:
		var direction: StringName = player.FACINGS[index]
		for state in ["idle","cast"]:
			var sprite := AnimatedSprite2D.new()
			sprite.sprite_frames = player.portrait.sprite_frames
			sprite.animation = StringName(state+"_"+String(direction))
			sprite.flip_h = direction in [&"w",&"sw",&"nw"]
			sprite.position = Vector2(95+320*(index%4)+(130 if state == "cast" else 0),260+330*(index/4))
			sprite.set_meta("ground_position",sprite.position)
			layer.add_child(sprite)
			player.facing = direction
			player.portrait.animation = sprite.animation
			player._update_secondary_frame()
			sprite.material = player.secondary_material.duplicate()
			(sprite.material as ShaderMaterial).set_shader_parameter("motion_weight",0.0)
			(sprite.material as ShaderMaterial).set_shader_parameter("idle_breath",1.0 if state == "idle" else 0.0)
			(sprite.material as ShaderMaterial).set_shader_parameter("cloth_tail_weight",1.0 if state == "idle" else 0.0)
			var frames: Array = player.portrait_frames[String(sprite.animation)]
			sprite.frame_changed.connect(align.bind(sprite,frames))
			align(sprite,frames)
			sprites.append(sprite)
			entries.append(frames)
		var label := Label.new()
		label.text = String(direction)+"    IDLE / CAST"
		label.position = Vector2(35+320*(index%4),285+330*(index/4))
		label.add_theme_color_override("font_color",Color("43554d"))
		layer.add_child(label)
	var first: Image
	for frame in 8:
		for sprite in sprites:
			sprite.frame = frame%sprite.sprite_frames.get_frame_count(sprite.animation)
			(sprite.material as ShaderMaterial).set_shader_parameter("gait_phase",float(frame)*TAU/18.0)
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot: Image = root.get_texture().get_image()
		for index in 8:
			for state in 2:
				var visible: int = 0
				for y in range(50+330*(index/4),280+330*(index/4),2):
					for x in range(10+320*(index%4)+150*state,160+320*(index%4)+150*state,2):
						var paint: Color = screenshot.get_pixel(x,y)
						if absf(paint.r-paper.color.r)+absf(paint.g-paper.color.g)+absf(paint.b-paper.color.b)>0.15:
							visible += 1
				if visible < 200:
					print("FAIL invisible cast gallery sprite ",index," ",state," ",frame)
					quit(1)
					return
		if screenshot.save_png(FOLDER+"idle-cast-%02d.png"%frame) != OK:
			print("FAIL idle screenshot save")
			quit(1)
			return
		if frame == 0:
			first = screenshot
		if frame == 3:
			for index in 8:
				var changed: int = 0
				for y in range(50+330*(index/4),280+330*(index/4)):
					for x in range(160+320*(index%4),310+320*(index%4)):
						var a: Color = first.get_pixel(x,y)
						var b: Color = screenshot.get_pixel(x,y)
						if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.04:
							changed += 1
				print("CAST_CHANGED_PIXELS ",index," ",changed)
				if changed < 100:
					print("FAIL invisible idle motion ",index)
					quit(1)
					return
	print("INK_PLAYER_CAST_VISUAL_PASS")
	quit(0)

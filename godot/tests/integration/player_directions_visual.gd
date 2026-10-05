extends SceneTree

const FOLDER := "C:/workspace/Ink-Land/docs/verification/player-size-brush/captures/"
var failures: int = 0

func align_frame(sprite: AnimatedSprite2D) -> void:
	var texture: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame) as AtlasTexture
	var size: Vector2 = texture.atlas.get_size()
	var region: Rect2 = texture.region
	var material: ShaderMaterial = sprite.material as ShaderMaterial
	material.set_shader_parameter("frame_rect",Vector4(region.position.x/size.x,region.position.y/size.y,region.size.x/size.x,region.size.y/size.y))
	material.set_shader_parameter("gait_phase",float(sprite.frame)*TAU/18.0)
	material.set_shader_parameter("motion_weight",0.65)
	material.set_shader_parameter("cloth_tail_weight",0.0)

func _initialize() -> void:
	call_deferred("run")

func capture(title: String) -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var screenshot: Image = root.get_texture().get_image()
	if screenshot.save_png(FOLDER+title+".png") != OK:
		failures += 1
	var background: Color = screenshot.get_pixel(0,0)
	for index in 8:
		var visible: int = 0
		for y in range(75+330*(index/4),290+330*(index/4),4):
			for x in range(70+320*(index%4),250+320*(index%4),4):
				var color: Color = screenshot.get_pixel(x,y)
				if absf(color.r-background.r)+absf(color.g-background.g)+absf(color.b-background.b) > 0.15:
					visible += 1
		if visible < 100:
			print("FAIL missing sprite ",title," direction ",index)
			failures += 1
	return screenshot

func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	create_timer(40.0).timeout.connect(func(): print("FAIL directions visual watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var paper := ColorRect.new()
	paper.size = Vector2(1280,720)
	paper.color = Color("f1ead8")
	layer.add_child(paper)
	var player = load("res://scenes/gameplay/Player.tscn").instantiate()
	root.add_child(player)
	player.hide()
	await process_frame
	var sprites: Array[AnimatedSprite2D] = []
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic"])
	for index in 8:
		var direction: StringName = player.FACINGS[index]
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = player.portrait.sprite_frames
		sprite.animation = StringName("walk_"+String(direction))
		sprite.flip_h = direction in [&"w",&"sw",&"nw"]
		var entry: Dictionary = player.portrait_frames[String(sprite.animation)][0]
		sprite.scale = Vector2.ONE*float(entry.scale)*1.8
		sprite.position = Vector2(160+320*(index%4),200+330*(index/4))
		layer.add_child(sprite)
		player.facing = direction
		player.portrait.animation = sprite.animation
		player._update_secondary_frame()
		sprite.material = player.secondary_material.duplicate()
		sprite.frame_changed.connect(align_frame.bind(sprite))
		align_frame(sprite)
		sprites.append(sprite)
		var label := Label.new()
		label.text = ["오른쪽 →","오른쪽 아래 ↘","아래 ↓","왼쪽 아래 ↙","왼쪽 ←","왼쪽 위 ↖","위 ↑","오른쪽 위 ↗"][index]
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",22)
		label.add_theme_color_override("font_color",Color("43554d"))
		label.position = Vector2(20+320*(index%4),300+330*(index/4))
		label.size = Vector2(280,40)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		layer.add_child(label)
	var first: Image
	for frame in 36:
		for sprite in sprites:
			sprite.frame = frame
		var screenshot: Image = await capture("directions-%02d" % frame)
		if frame == 0:
			first = screenshot
		if frame == 9:
			for index in 8:
				var changed: int = 0
				for y in range(75+330*(index/4),290+330*(index/4),2):
					for x in range(70+320*(index%4),250+320*(index%4),2):
						var a: Color = first.get_pixel(x,y)
						var b: Color = screenshot.get_pixel(x,y)
						if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b) > 0.03:
							changed += 1
				if changed < 100:
					print("FAIL frozen native poses direction ",index)
					failures += 1
	layer.queue_free()
	player.queue_free()
	await process_frame
	print("INK_PLAYER_DIRECTIONS_VISUAL_PASS" if failures == 0 else "FAIL direction captures")
	quit(0 if failures == 0 else 1)

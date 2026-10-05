extends SceneTree

const FOLDER := "C:/workspace/Ink-Land/docs/verification/player-idle-v25/playback/"
var sprites: Array[AnimatedSprite2D] = []
var entries: Array[Array] = []
var visited: Array[Dictionary] = []
var events: Array[Array] = []
var loops: Array[int] = []
var started: int

func _initialize() -> void:
	call_deferred("run")

func align(index: int) -> void:
	var sprite: AnimatedSprite2D = sprites[index]
	var entry: Dictionary = entries[index][sprite.frame]
	var rect: Array = entry.rect
	var foot: Array = entry.foot_anchor
	sprite.scale = Vector2.ONE*float(entry.scale)*2.0
	var offset := Vector2(float(rect[2])*0.5-float(foot[0]),float(rect[3])*0.5-float(foot[1]))*sprite.scale
	sprite.position = Vector2(135+240*index,430)+offset
	var atlas: AtlasTexture = sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	var size: Vector2 = atlas.atlas.get_size()
	var region: Rect2 = atlas.region
	(sprite.material as ShaderMaterial).set_shader_parameter("frame_rect",Vector4(region.position.x/size.x,region.position.y/size.y,region.size.x/size.x,region.size.y/size.y))
	visited[index][sprite.frame] = true
	events[index].append({"frame":sprite.frame,"seconds":float(Time.get_ticks_msec()-started)/1000.0})

func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	DirAccess.make_dir_recursive_absolute(FOLDER)
	create_timer(25.0).timeout.connect(func(): print("FAIL playback watchdog"); quit(1))
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
	started = Time.get_ticks_msec()
	for direction in [&"e",&"s",&"se",&"ne",&"n"]:
		var index: int = sprites.size()
		var sprite := AnimatedSprite2D.new()
		sprite.sprite_frames = player.portrait.sprite_frames
		sprite.animation = StringName("idle_"+String(direction))
		player.facing = direction
		player.portrait.animation = sprite.animation
		player._update_secondary_frame()
		sprite.material = player.secondary_material.duplicate()
		(sprite.material as ShaderMaterial).set_shader_parameter("motion_weight",0.0)
		layer.add_child(sprite)
		sprites.append(sprite)
		entries.append(player.portrait_frames[String(sprite.animation)])
		visited.append({})
		events.append([])
		loops.append(0)
		sprite.frame_changed.connect(align.bind(index))
		sprite.animation_looped.connect(func(): loops[index] += 1)
		align(index)
		sprite.play()
		var label := Label.new()
		label.text = String(direction)+" — real-time idle"
		label.position = Vector2(60+240*index,455)
		label.add_theme_color_override("font_color",Color("43554d"))
		layer.add_child(label)
	for sample in 19:
		await RenderingServer.frame_post_draw
		if root.get_texture().get_image().save_png(FOLDER+"idle-%02d.png"%sample) != OK:
			print("FAIL playback capture")
			quit(1)
			return
		await create_timer(0.4).timeout
	var report: Array[Dictionary] = []
	var failed: bool = false
	for index in sprites.size():
		report.append({"animation":String(sprites[index].animation),"loops":loops[index],"events":events[index]})
		if visited[index].size()!=8 or loops[index]<1:
			print("FAIL incomplete real-time idle ",sprites[index].animation," ",visited[index].size()," ",loops[index])
			failed = true
		if index in [0,1,2]:
			for event_index in events[index].size()-1:
				if events[index][event_index].frame == 4:
					var duration: float = events[index][event_index+1].seconds-events[index][event_index].seconds
					if duration<0.08 or duration>0.25:
						print("FAIL blink duration ",duration)
						failed = true
	var file := FileAccess.open(FOLDER+"events.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	if not failed:
		print("INK_PLAYER_IDLE_PLAYBACK_PASS")
	quit(1 if failed else 0)

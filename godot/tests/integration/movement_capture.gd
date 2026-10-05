extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(15.0).timeout.connect(func(): print("FAIL capture watchdog"); quit(1))
	var folder: String = "C:/workspace/Ink-Land/docs/verification/player-frame-edge-fix/frames/"
	DirAccess.make_dir_recursive_absolute(folder)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/first_journey/motion-capture/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	await create_timer(0.3).timeout
	game.player.position = Vector2(530,400)
	game.camera.focus = Vector2(620,360)
	game.camera.zoom = Vector2(2,2)
	game.ui.visible = false
	game.draw_controller.hide()
	var durations: Array[int] = []
	var frames: Array[int] = []
	var index: int = 0
	var failed: bool = false
	for action in ["","move_right","move_left",""]:
		var delay: float = 0.125 if action=="" else (1.0 / game.player.portrait.sprite_frames.get_animation_speed(&"walk"))
		if action!="": Input.action_press(action)
		for frame in range(4 if action=="" else 36):
			await create_timer(delay).timeout
			await RenderingServer.frame_post_draw
			failed = root.get_texture().get_image().save_png(folder+"frame-%02d.png" % index)!=OK or failed
			frames.append(game.player.portrait.frame)
			durations.append(int(delay*1000))
			index += 1
		if action!="": Input.action_release(action)
	var manifest := FileAccess.open(folder+"timing.json",FileAccess.WRITE)
	manifest.store_string(JSON.stringify({"durations":durations,"animation_frames":frames}))
	manifest.close()
	game.queue_free()
	await process_frame
	print("INK_MOTION_CAPTURE_PASS" if not failed else "FAIL PNG write")
	quit(1 if failed else 0)

extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var render: bool = "--render" in OS.get_cmdline_user_args()
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/brush-profile/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	game.tutorial_flags = {"move":true,"line":true,"hold":true,"recover":true}
	game.player.position = Vector2(1050,950)
	game.camera.follow(1.0)
	var draw: DrawController = game.draw_controller
	for mode in ["idle","brush"]:
		draw.strokes.clear()
		draw.cancel()
		var times: Array[int] = [0,0,0]
		var count: int = 180
		var frame_times: Array[int] = []
		if mode == "brush":
			draw.ink.press()
		for frame in count:
			var frame_start: int = Time.get_ticks_usec()
			draw.ink.current = 100.0
			if mode == "brush":
				for sample in range(8):
					var angle: float = (frame*8+sample)*0.07
					draw.pending.append(game.player.global_position+Vector2.from_angle(angle)*120.0)
			var start: int = Time.get_ticks_usec()
			draw.tick(1.0/60.0)
			times[0] += Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			for target in range(10):
				draw.damage_at(game.player.global_position+Vector2(target*12.0,0),16.0)
			times[1] += Time.get_ticks_usec()-start
			start = Time.get_ticks_usec()
			game._update_ui()
			times[2] += Time.get_ticks_usec()-start
			if render:
				await process_frame
				await RenderingServer.frame_post_draw
				if frame >= 20:
					frame_times.append(Time.get_ticks_usec()-frame_start)
		print("BRUSH_PROFILE ",mode," us/tick=",times[0]/count," damage10=",times[1]/count," ui=",times[2]/count," stamps=",draw.strokes.get_active_stamps().size())
		if render:
			frame_times.sort()
			print("BRUSH_RENDER ",mode," median_us=",frame_times[frame_times.size()/2]," p95_us=",frame_times[int(frame_times.size()*0.95)])
			if mode == "brush":
				var image: Image = root.get_texture().get_image()
				image.save_png("C:/workspace/Ink-Land/docs/verification/player-size-brush/captures/brush-stress.png")
				var painted: int = 0
				for y in range(300,660,4):
					for x in range(500,950,4):
						var color: Color = image.get_pixel(x,y)
						if color.b-color.r > 0.3 and color.b-color.g > 0.2:
							painted += 1
				if painted < 500 or draw.stamp_batch.multimesh.visible_instance_count != draw.strokes.get_active_stamps().size():
					print("FAIL batched paint visibility")
					failures += 1
	if render:
		draw.cancel()
		draw.strokes.clear()
		draw.queue_redraw()
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		if draw.stamp_batch.multimesh.visible_instance_count != 0:
			print("FAIL cleared paint still visible")
			failures += 1
	game.free()
	if failures == 0:
		print("INK_BRUSH_PROFILE_PASS")
	quit(0 if failures == 0 else 1)

extends SceneTree

const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/world-scale-physical/"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(FOLDER+name+".png") != OK:
		failures += 1

func run() -> void:
	create_timer(60.0).timeout.connect(func(): print("FAIL v27 visual watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/v27-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(900,680)*2.0
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game.player.set_physics_process(false)
	if not is_equal_approx(game.camera.zoom.x, 1.0):
		failures += 1
	if game.area.area_size != Vector2(5120,3584):
		failures += 1
	if not is_equal_approx(game.area.coastal_map.residents[0].height,168.0):
		failures += 1
	if game.area.coastal_map.layout.props[0].position != Vector2(1240,1100):
		failures += 1
	var point: Vector2 = game.player.global_position
	var screen: Vector2 = root.get_canvas_transform() * point
	if game.camera.screen_to_world(screen).distance_to(point) > 0.01:
		failures += 1
	for direction in game.player.FACINGS:
		game.player.facing = direction
		for state in ["idle", "walk", "cast"]:
			game.player.portrait.play(StringName(state+"_"+String(direction)))
			game.player.portrait.pause()
			game.player.portrait.frame = 18 if state == "cast" else 0
			game.player._align_portrait_frame()
			await capture(state+"-"+String(direction))
	game.queue_free()
	await process_frame
	print("INK_V27_GAME_VISUAL_PASS" if failures == 0 else "FAIL v27 visual")
	quit(0 if failures == 0 else 1)

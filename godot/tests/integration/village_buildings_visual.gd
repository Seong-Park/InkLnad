extends SceneTree

var failures: int = 0
const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/village-buildings-v9/captures/"

func _initialize() -> void:
	call_deferred("run")

func capture(title: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var code: int = root.get_texture().get_image().save_png(FOLDER+title+".png")
	if code != OK:
		failures += 1
		print("FAIL capture ",title,code)

func run() -> void:
	create_timer(30.0).timeout.connect(func(): print("FAIL building capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-buildings-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.pause(true)
	game.ui.hide_modal()
	game.ui.hide()
	game.player.hide()
	game.camera.zoom = Vector2.ONE*0.65
	game.camera.set_area(game.area.area_size,&"follow_2d")
	game.camera.global_position = game.area.to_global(Vector2(1150,640))
	game.camera.force_update_scroll()
	await capture("village-layout")
	game.camera.zoom = Vector2.ONE
	game.camera.set_area(game.area.area_size,&"follow_2d")
	for prop in game.area.coastal_map.layout.props:
		if prop.kind in ["apothecary","tool-shop","outfit-shop","craft-workshop","village-teahouse"]:
			game.camera.global_position = game.area.to_global(prop.position-Vector2(0,60))
			game.camera.force_update_scroll()
			await capture(prop.kind)
	game.ui.show()
	game.player.show()
	game.player.position = Vector2(1050,700)
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game._update_ui()
	await capture("plaza-hud")
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_BUILDINGS_VISUAL_PASS" if failures == 0 else "FAIL building captures")
	quit(0 if failures == 0 else 1)

extends SceneTree

var failures: int = 0
const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/mobile-hud/captures/"

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
	create_timer(30.0).timeout.connect(func(): print("FAIL HUD capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/mobile-hud-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(900,680)
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game._update_ui()
	await capture("village-hud")
	game.player.position = game.rules.get_area(&"A").npc_position+Vector2(0,35)
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game._update_ui()
	await capture("interaction")
	game.ui._open_bag()
	await capture("bag")
	game._ui_action(&"resume")
	game.ui._open_map()
	await capture("map")
	game._ui_action(&"resume")
	game.queue_free()
	await process_frame
	print("INK_MOBILE_HUD_VISUAL_PASS" if failures == 0 else "FAIL HUD captures")
	quit(0 if failures == 0 else 1)

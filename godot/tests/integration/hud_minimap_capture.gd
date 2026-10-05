extends SceneTree

const FOLDER = "C:/workspace/Ink-Land/docs/verification/hud-v14/captures/"

func _initialize() -> void:
	call_deferred("run")

func capture(title: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(FOLDER+title+".png") != OK:
		quit(1)

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL HUD capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/hud-minimap-capture/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(1050,730)
	game._update_ui()
	await create_timer(0.5).timeout
	game.pause(true)
	game.ui.hide_modal()
	await capture("village")
	for scale_value in [1.25,1.5]:
		game.ui.render_state({"settings":{"ui_scale":scale_value,"mute":false}})
		await capture("village-%d" % int(scale_value*100))
	game.ui.render_state({"settings":{"ui_scale":1.0,"mute":false}})
	game.pause(false)
	game._travel(&"B",&"west")
	await create_timer(0.4).timeout
	game._update_ui()
	game.pause(true)
	game.ui.hide_modal()
	await capture("field")
	game.pause(false)
	game._travel(&"C",&"west")
	await create_timer(0.4).timeout
	game._update_ui()
	game.pause(true)
	game.ui.hide_modal()
	await capture("clearing")
	game.queue_free()
	await process_frame
	print("INK_HUD_MINIMAP_VISUAL_PASS")
	quit(0)

extends SceneTree

# Visual staging only. Gameplay acceptance belongs to the existing suites.
var folder: String = "C:/workspace/Ink-Land/docs/verification/visual-redesign/captures/"
var failed: bool = false

func _initialize() -> void:
	call_deferred("run")

func capture(name_value: String) -> void:
	await RenderingServer.frame_post_draw
	var result: int = root.get_texture().get_image().save_png(folder+name_value+".png")
	failed = failed or result != OK

func run() -> void:
	create_timer(25.0).timeout.connect(func(): print("FAIL art capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(folder)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/first_journey/art-capture/profile.json"
	root.add_child(game)
	await process_frame
	for scale_value in [1.0,1.25,1.5]:
		game.menu_settings = {"ui_scale":scale_value,"mute":false}
		game.ui.render_state({"settings":game.menu_settings})
		game.ui.show_menu(false)
		await capture("menu-%d" % int(scale_value*100))
		game.ui.show_settings(game.menu_settings)
		await capture("settings-%d" % int(scale_value*100))
	game.ui.show_menu(false)
	game.start_new_game()
	await create_timer(0.3).timeout
	game.pause(true)
	game.ui.hide_modal()
	await capture("workshop-150")
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	for area in [&"C",&"D"]:
		game.pause(false)
		game._travel(area,&"west")
		await create_timer(0.3).timeout
		game.pause(true)
		game.ui.hide_modal()
		await capture("ruins-150" if area==&"C" else "rain-150")
	game.queue_free()
	await process_frame
	print("INK_ART_CAPTURE_PASS" if not failed else "FAIL png write")
	quit(1 if failed else 0)

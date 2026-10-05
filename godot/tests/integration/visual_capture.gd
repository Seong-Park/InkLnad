extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(10.0).timeout.connect(func(): print("FAIL capture watchdog"); quit(1))
	var window_size: Vector2i = DisplayServer.window_get_size()
	var label: String = "%dx%d" % [window_size.x,window_size.y]
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/first_journey/visual-%s/profile.json" % label
	root.add_child(game)
	await process_frame
	game.menu_settings = {"ui_scale":1.5,"mute":true}
	game.ui.render_state({"settings":game.menu_settings})
	game.ui.show_menu(false)
	await RenderingServer.frame_post_draw
	var folder: String = "C:/workspace/Ink-Land/docs/verification/first-journey/captures/"
	root.get_texture().get_image().save_png(folder+"menu-"+label+".png")
	game.start_new_game()
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	game._travel(&"E",&"west")
	await create_timer(0.3).timeout
	game.player.position = Vector2(650,280)
	await create_timer(0.9).timeout
	game.pause(true)
	game.ui.hide_modal()
	await RenderingServer.frame_post_draw
	var code: int = root.get_texture().get_image().save_png(folder+"elite-"+label+".png")
	print("VISUAL window=",window_size," logical=",root.get_visible_rect().size," texture=",root.get_texture().get_size()," enemy_phase=",game.area.enemies[0].phase," save_png=",code)
	# Visual fixtures below stage progress through the same transaction APIs.
	# Enemy receive_damage here is fixture setup, not evidence of input combat.
	game.area.enemies[0].receive_damage(1000.0)
	game.pause(false)
	game._travel(&"F",&"west")
	await create_timer(0.3).timeout
	game.pause(true)
	game.ui.hide_modal()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"flower-before-"+label+".png")
	game.restore_flower()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"flower-after-"+label+".png")
	game.player.position = Vector2(180,450)
	game.pause(false)
	game.return_home()
	await create_timer(0.3).timeout
	game.pause(true)
	game.ui.show_shop(false,int(game.get_snapshot().wallet_ink))
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder+"shop-"+label+".png")
	game.queue_free()
	await process_frame
	if code==OK:
		print("INK_VISUAL_CAPTURE_PASS")
	quit(0 if code==OK else 1)

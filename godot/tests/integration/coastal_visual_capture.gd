extends SceneTree

var failures: int = 0
var folder: String = "C:/workspace/Ink-Land/docs/verification/coast-watercolor-v8/captures/"

func _initialize() -> void:
	call_deferred("run")

func capture(game: Node, title: String, foot: Vector2, overview: bool = false) -> void:
	game.player.position = foot
	game.camera.zoom = Vector2.ONE*(0.42 if overview else 1.0)
	game.camera.set_area(game.area.area_size,&"follow_2d")
	if overview:
		game.camera.global_position = game.area.area_size*0.5
		game.camera.force_update_scroll()
	game.ui.visible = not overview
	game.player.visible = not overview
	game.get_node("DrawController").visible = not overview
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var code: int = root.get_texture().get_image().save_png(folder+title+".png")
	if code != OK:
		failures += 1
		print("FAIL capture ",title," ",code)

func run() -> void:
	create_timer(30.0).timeout.connect(func(): print("FAIL capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(folder)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/coastal-modular-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	if game.area.coastal_map == null or game.area.coastal_map.get_node_or_null("CoastalCliffs") == null:
		print("FAIL coastal renderer missing")
		quit(1)
		return
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	game.pause(true)
	game.ui.hide_modal()
	await capture(game,"village-plaza",Vector2(1100,640))
	await capture(game,"village-overview",game.area.area_size*0.5,true)
	await capture(game,"behind-workshop",Vector2(620,395))
	await capture(game,"front-workshop",Vector2(620,600))
	await capture(game,"village-dock",Vector2(1360,1420))
	await capture(game,"village-garden",Vector2(650,1080))
	await capture(game,"village-teahouse",Vector2(1810,700))
	await capture(game,"village-pavilion",Vector2(1810,1350))
	await capture(game,"village-storehouse",Vector2(1110,1320))
	game.pause(false)
	game._travel(&"B",&"west")
	await create_timer(0.3).timeout
	game.pause(true)
	game.ui.hide_modal()
	await capture(game,"field-bridge",Vector2(2400,1240))
	await capture(game,"field-fork",Vector2(650,1000))
	await capture(game,"field-north-route",Vector2(1250,520))
	await capture(game,"field-south-route",Vector2(1700,1540))
	await capture(game,"field-overview",game.area.area_size*0.5,true)
	game.queue_free()
	await process_frame
	print("INK_COASTAL_VISUAL_PASS" if failures == 0 else "FAIL coastal captures")
	quit(0 if failures == 0 else 1)

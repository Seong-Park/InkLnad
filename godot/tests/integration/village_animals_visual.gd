extends SceneTree

const FOLDER := "C:/workspace/Ink-Land/docs/verification/animals-v17/captures/"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func capture(title: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(FOLDER+title+".png") != OK:
		failures += 1

func frame_at(game: Node, center: Vector2, zoom: float) -> void:
	game.camera.zoom = Vector2.ONE*zoom
	game.camera.set_area(game.area.area_size,&"follow_2d")
	game.camera.global_position = game.area.to_global(center)
	game.camera.focus = game.camera.global_position
	game.camera.mode = &"fixed"
	game.camera.force_update_scroll()

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL animal capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-animals-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(1100,950)
	await create_timer(1.0).timeout
	game.pause(true)
	game.ui.hide_modal()
	game.ui.hide()
	frame_at(game,Vector2(1150,950),1.0)
	await capture("plaza-animals")
	game.area.coastal_map.animals[3].wait_remaining = 0.0
	game.pause(false)
	for index in 24:
		frame_at(game,Vector2(1090,620),3.0)
		await capture("bird-motion-%02d" % index)
		await create_timer(0.1).timeout
	game.pause(true)
	frame_at(game,Vector2(1750,900),2.0)
	await capture("sleeping-cat-village")
	var layer := CanvasLayer.new()
	layer.layer = 30
	root.add_child(layer)
	var background := ColorRect.new()
	background.color = Color("f1ead8")
	background.size = Vector2(1280,720)
	layer.add_child(background)
	var indices := [9,10,3]
	for index in 3:
		var animal = game.area.coastal_map.animals[indices[index]]
		var sprite := Sprite2D.new()
		sprite.texture = animal.sprite.sprite_frames.get_frame_texture(&"fly" if index == 2 else &"idle",0)
		sprite.scale = Vector2.ONE*210.0/sprite.texture.get_height()
		sprite.position = Vector2(230+410*index,330)
		layer.add_child(sprite)
		var label := Label.new()
		label.text = ["잠자는 고양이","잠자는 강아지","날아가는 참새"][index]
		var font := SystemFont.new()
		font.font_names = PackedStringArray(["Malgun Gothic"])
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",28)
		label.add_theme_color_override("font_color",Color("43554d"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = Vector2(100+410*index,520)
		label.size = Vector2(260,50)
		layer.add_child(label)
	await capture("animal-lineup")
	layer.queue_free()
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_ANIMALS_VISUAL_PASS" if failures == 0 else "FAIL animal captures")
	quit(0 if failures == 0 else 1)

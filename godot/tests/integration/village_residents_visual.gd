extends SceneTree

var failures: int = 0
const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/village-npcs-v13/captures/"

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

func frame_at(game: Node, local_center: Vector2, zoom: float = 1.0) -> void:
	game.camera.zoom = Vector2.ONE*zoom
	game.camera.set_area(game.area.area_size,&"follow_2d")
	game.camera.global_position = game.area.to_global(local_center)
	game.camera.focus = game.camera.global_position
	game.camera.mode = &"fixed"
	game.camera.force_update_scroll()

func character_gallery() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 30
	root.add_child(layer)
	var background := ColorRect.new()
	background.color = Color("f1ead8")
	background.size = Vector2(1280,720)
	layer.add_child(background)
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Malgun Gothic"])
	var items: Array = [["apothecary","약사"],["tool-merchant","화구 상인"],["tailor","재봉사"],["craft-master","공방 장인"],["tea-host","찻집 주인"],["tea-guest","찻집 손님"],["chat-resident","광장 주민"],["gardener","정원사"],["basket-walker","장보는 주민"],["courier-walker","배달 주민"]]
	for index in items.size():
		var item: Array = items[index]
		var source: Texture2D = load("res://assets/characters/village-npcs-v10/"+String(item[0])+".png")
		var texture := AtlasTexture.new()
		texture.atlas = source
		texture.region = Rect2(source.get_image().get_used_rect())
		texture.filter_clip = true
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.scale = Vector2.ONE*180.0/texture.get_height()
		sprite.position = Vector2(128+256*(index%5),220+310*(index/5))
		layer.add_child(sprite)
		var label := Label.new()
		label.text = item[1]
		label.add_theme_font_override("font",font)
		label.add_theme_font_size_override("font_size",20)
		label.add_theme_color_override("font_color",Color("43554d"))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = sprite.position+Vector2(-110,105)
		label.size = Vector2(220,30)
		layer.add_child(label)
	return layer

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL residents capture watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-residents-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(1100,950)
	await create_timer(1.2).timeout
	game.pause(true)
	game.ui.hide_modal()
	game.ui.hide()
	game.player.hide()
	frame_at(game,Vector2(1150,640),0.65)
	await capture("village-populated")
	frame_at(game,Vector2(970,690))
	await capture("plaza-residents")
	frame_at(game,Vector2(1730,690))
	await capture("teahouse-residents")
	game.area.coastal_map.residents[4].wait_remaining = 0.0
	game.pause(false)
	for index in 36:
		frame_at(game,Vector2(1810,660),2.0)
		await capture("motion-%02d" % index)
		await create_timer(1.0/12.0).timeout
	game.pause(true)
	frame_at(game,Vector2(650,920))
	await capture("tailor-garden")
	game.ui.show()
	game.player.show()
	game.player.position = Vector2(1050,700)
	game._update_ui()
	frame_at(game,Vector2(1050,700))
	await capture("plaza-hud")
	var gallery: CanvasLayer = character_gallery()
	await capture("npc-lineup")
	gallery.queue_free()
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_RESIDENTS_VISUAL_PASS" if failures == 0 else "FAIL resident captures")
	quit(0 if failures == 0 else 1)

extends SceneTree

const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/object-restoration/"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func capture(label: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if root.get_texture().get_image().save_png(FOLDER+label+".png") != OK:
		failures += 1

func run() -> void:
	create_timer(60.0).timeout.connect(func(): print("FAIL restoration visual timeout"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/object-restoration-visual/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.economy.grant_defeat(&"e01",{"enemies":{"e01":{"hp":0,"alive":false}}})
	game.player.set_physics_process(false)
	game.set_physics_process(false)
	var restoration = game.area.coastal_map.restoration
	for kind in ["flowerpots","pine","fountain","lantern"]:
		var selected: Dictionary = {}
		for item in restoration.objects:
			if item.kind == kind and selected.is_empty(): selected = item
		if selected.is_empty():
			failures += 1
			continue
		game.player.position = selected.point+Vector2(100,60)
		game.camera.global_position = game.area.to_global(selected.point)+Vector2(0,-100)
		game.camera.force_update_scroll()
		game._update_ui()
		await capture(kind+"-before")
		game._interact()
		await create_timer(0.65).timeout
		await capture(kind+"-wash")
		await create_timer(1.0).timeout
		game._update_ui()
		await capture(kind+"-after")
	game.queue_free()
	await process_frame
	print("INK_OBJECT_RESTORATION_VISUAL_PASS" if failures==0 else "FAIL restoration visual")
	quit(0 if failures==0 else 1)

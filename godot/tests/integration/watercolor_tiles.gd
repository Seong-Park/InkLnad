extends SceneTree

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(15.0).timeout.connect(func(): print("FAIL tile capture watchdog"); quit(1))
	var scene: Node = load("res://scenes/areas/WatercolorTileStudy.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	var coast: TileMapLayer = scene.get_node("CoastalTiles")
	var grass: TileMapLayer = scene.get_node("ExtendedGrassPatch")
	var passed: bool = coast.get_used_cells().size() == 40 and grass.get_used_cells().size() == 12
	var folder: String = "C:/workspace/Ink-Land/docs/verification/coast-tiles-v4/"
	DirAccess.make_dir_recursive_absolute(folder)
	var code: Error = root.get_texture().get_image().save_png(folder+"tile-assembly.png")
	passed = passed and code == OK
	print("INK_WATERCOLOR_TILES_PASS" if passed else "FAIL tile assembly")
	scene.queue_free()
	await process_frame
	quit(0 if passed else 1)

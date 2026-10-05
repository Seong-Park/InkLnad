extends SceneTree

const FOLDER := "C:/workspace/Ink-Land/docs/verification/fox-front-rig-v28/"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL visual watchdog"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var review: Node2D = load("res://scenes/previews/FoxFrontRigReview.tscn").instantiate()
	root.add_child(review)
	await process_frame
	for index in 8:
		await create_timer(0.16).timeout
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png(FOLDER+"review-%02d.png"%index)
		if index == 0:
			var changed := 0
			var compared := 0
			for y in range(242,580):
				for x in range(5,250):
					var a := shot.get_pixel(x,y)
					var b := shot.get_pixel(x+255,y)
					compared += 1
					if absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)>0.03: changed += 1
			print("NEUTRAL_CHANGED_PIXELS ",changed," / ",compared)
			if float(changed)/compared > 0.01:
				print("FAIL neutral reconstruction")
				quit(1)
				return
	print("INK_FOX_FRONT_RIG_VISUAL_PASS")
	quit(0)

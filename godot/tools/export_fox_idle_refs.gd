extends SceneTree

func _initialize() -> void:
	var folder := "C:/workspace/Ink-Land/docs/verification/player-idle-v25/"
	DirAccess.make_dir_recursive_absolute(folder)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-mage-idle-v24/frames.json"))
	var texture: Texture2D = load("res://assets/characters/fox-mage-idle-v24/standing.png")
	var image: Image = texture.get_image()
	for direction in ["e","se","s","ne","n"]:
		var rect: Array = data[direction].idle[0].rect
		if image.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3])).save_png(folder+"reference-"+direction+".png") != OK:
			quit(1)
			return
	print("INK_IDLE_REFS_PASS")
	quit(0)

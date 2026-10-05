extends SceneTree

func _initialize() -> void:
	var folder: String = "C:/workspace/Ink-Land/docs/verification/player-idle-v22/rejected-ludo/"
	DirAccess.make_dir_recursive_absolute(folder)
	var metadata: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/fox-mage-ludo-v21/frames.json"))
	for direction in ["e","se","s","ne","n"]:
		var texture: Texture2D = load("res://assets/characters/fox-mage-ludo-v21/walk-"+direction+".webp")
		var sheet: Image = texture.get_image()
		var rect: Array = metadata[direction].walk[0].rect
		var frame: Image = sheet.get_region(Rect2i(rect[0],rect[1],rect[2],rect[3]))
		if frame.save_png(folder+"reference-"+direction+".png") != OK:
			quit(1)
			return
	print("INK_FOX_REFS_PASS")
	quit(0)

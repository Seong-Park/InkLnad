extends SceneTree
var body_heights: Array[float] = []

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var player = load("res://scenes/gameplay/Player.tscn").instantiate()
	root.add_child(player)
	await process_frame
	var heights: Array[float] = []
	var idle_heights: Array[float] = []
	for direction in player.FACINGS:
		for state in ["walk","idle"]:
			var measured: float = measure_head(player, StringName(state+"_"+String(direction)))
			if measured <= 0.0:
				quit(1)
				return
			(heights if state == "walk" else idle_heights).append(measured)
		var transition_ratio: float = maxf(heights[-1],idle_heights[-1])/minf(heights[-1],idle_heights[-1])
		var body_transition: float = maxf(body_heights[-1],body_heights[-2])/minf(body_heights[-1],body_heights[-2])
		if body_transition > 1.08:
			print("FAIL idle/walk body size ",direction," ",body_transition)
			quit(1)
			return
		print("IDLE_WALK_HEAD_RATIO ",direction," ",transition_ratio)
		if transition_ratio > 1.08:
			print("FAIL idle/walk size discontinuity")
			quit(1)
			return
	heights.append_array(idle_heights)
	heights.sort()
	body_heights.sort()
	var body_ratio: float = body_heights[-1]/body_heights[0]
	print("BODY_LANDMARK_SIZE_RATIO ",body_ratio)
	var ratio: float = heights[-1]/heights[0]
	print("DIRECTION_SIZE_RATIO ",ratio)
	player.free()
	# Rear three-quarter art has a smaller head relative to its torso.
	# Enforce body-landmark height below rather than enlarging it to match heads.
	# Fur components differ by viewing angle; compare heads within the same facing.
	if body_ratio > 1.15:
		print("FAIL direction size discontinuity")
		quit(1)
	else:
		print("INK_PLAYER_DIRECTION_SIZE_PASS")
		quit(0)

func measure_head(player: PlayerController, animation: StringName) -> float:
		var atlas: AtlasTexture = player.portrait.sprite_frames.get_frame_texture(animation,0)
		var image: Image = atlas.atlas.get_image()
		var samples: Array[float] = []
		var body_samples: Array[float] = []
		var count: int = player.portrait.sprite_frames.get_frame_count(animation)
		for sample in 4:
			var frame: int = sample*count/4
			var entry: Dictionary = player.portrait_frames[String(animation)][frame]
			var rect: Array = entry.rect
			var bounds: Vector2i = head_fur_bounds(image,rect)
			var low: int = bounds.x
			var high: int = bounds.y
			if high < low:
				print("FAIL head pixels missing ",animation)
				return -1.0
			samples.append((high-low+1)*float(entry.scale))
			body_samples.append((float(entry.foot_anchor[1])-low)*float(entry.scale))
		samples.sort()
		body_samples.sort()
		var body_height: float = (body_samples[1]+body_samples[2])*0.5
		body_heights.append(body_height)
		print("BODY_LANDMARK_HEIGHT ",animation," ",body_height)
		var height: float = (samples[1]+samples[2])*0.5
		print("DIRECTION_HEAD_HEIGHT ",animation," ",height)
		return height

func head_fur_bounds(image: Image, rect: Array) -> Vector2i:
	# Connected fur excludes separate brown sleeve outlines in the upper crop.
	var width: int = ceili(float(rect[2])/2.0)
	var height: int = int(ceilf(float(rect[3])/2.0)*0.43)
	var mask := PackedByteArray()
	mask.resize(width*height)
	for y in height:
		for x in width:
			var pixel: Color = image.get_pixel(int(rect[0])+x*2,int(rect[1])+y*2)
			if pixel.a > 0.5 and pixel.r > pixel.g*1.12 and pixel.r < pixel.g*2.5 and pixel.g > 65.0/255.0 and pixel.r > pixel.b*1.6 and pixel.r > 100.0/255.0:
				mask[y*width+x] = 1
	var best_count: int = 0
	var best := Vector2i(999999,-1)
	for index in mask.size():
		if mask[index] == 0:
			continue
		var queue: Array[int] = [index]
		mask[index] = 0
		var cursor: int = 0
		var low: int = height
		var high: int = -1
		while cursor < queue.size():
			var current: int = queue[cursor]
			cursor += 1
			var point := Vector2i(current%width,current/width)
			low = mini(low,point.y)
			high = maxi(high,point.y)
			for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var next: Vector2i = point+delta
				if next.x < 0 or next.x >= width or next.y < 0 or next.y >= height:
					continue
				var neighbor: int = next.y*width+next.x
				if mask[neighbor] == 1:
					mask[neighbor] = 0
					queue.append(neighbor)
		if queue.size() > best_count:
			best_count = queue.size()
			best = Vector2i(low*2,high*2)
	return best

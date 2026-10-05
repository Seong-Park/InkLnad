extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",message)

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL residents watchdog"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-residents/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok,"isolated game starts")
	game.player.position = Vector2(1100,950)
	var residents = game.area.coastal_map.get("residents")
	check(residents is Array and residents.size() == 12,"twelve village residents")
	if not residents is Array or residents.size() != 12:
		game.queue_free()
		await process_frame
		quit(1)
		return
	var walker = residents[9]
	for resident in residents:
		if resident.frame_feet.has(&"idle"):
			var initial_frame: int = resident.sprite.frame
			for index in resident.sprite.sprite_frames.get_frame_count(&"idle"):
				resident.sprite.frame = index
				resident._pose()
				var texture: Texture2D = resident.sprite.sprite_frames.get_frame_texture(&"idle",index)
				var bottom: float = texture.get_image().get_used_rect().end.y-texture.get_height()*0.5
				var foot: Vector2 = resident.sprite.to_global(Vector2(0,bottom))
				check(absf(foot.y-resident.global_position.y) < 0.1,"visible feet remain on ground across idle frames")
			resident.sprite.frame = initial_frame
	for index in [0,1,2,3,4,5,6,7,8,11]:
		check(residents[index].sprite.sprite_frames.get_frame_count(&"idle") > 1,"stationary resident has articulated idle frames")
		check(residents[index].sprite.is_playing(),"resident idle animation plays")
	for index in [0,1,2,3,4,9,10]:
		var resident = residents[index]
		resident.sprite.animation = &"walk"
		resident.sprite.frame = 0
		resident._pose()
		var baseline: float = resident.sprite.position.y
		for frame in resident.sprite.sprite_frames.get_frame_count(&"walk"):
			resident.sprite.frame = frame
			resident._pose()
			check(absf(resident.sprite.position.y-baseline) < 0.1,"walk does not move whole body to compensate lifted feet")
		resident.sprite.play(&"idle")
	var start: Vector2 = walker.position
	for frame in 60:
		await physics_frame
	check(walker.position.distance_to(start) > 15,"walker moves along village route")
	check(walker.sprite.sprite_frames.has_animation(&"walk") and walker.sprite.sprite_frames.get_frame_count(&"walk") > 1,"walker has actual animation frames")
	game.pause(true)
	var paused_at: Vector2 = walker.position
	var idle_frame: int = residents[5].sprite.frame
	var idle_progress: float = residents[5].sprite.frame_progress
	await create_timer(0.15).timeout
	check(walker.position.is_equal_approx(paused_at),"resident freezes while paused")
	check(residents[5].sprite.frame == idle_frame and is_equal_approx(residents[5].sprite.frame_progress,idle_progress),"idle clip freezes while paused")
	game.pause(false)
	for frame in 45:
		await physics_frame
	check(walker.position.distance_to(paused_at) > 8,"resident resumes movement")
	for index in 5:
		var merchant = residents[index]
		merchant.wait_remaining = 0.0
		var merchant_start: Vector2 = merchant.position
		for frame in 30:
			await physics_frame
		check(merchant.position.distance_to(merchant_start) > 4.0,"merchant strolls in front of shop")
		check(merchant.position.distance_to(merchant.home) <= 30.0,"merchant stays near home")
		check(merchant.sprite.animation == &"walk","merchant plays walk while strolling")
	for resident in residents:
		check(not resident.obstructed(resident.position),"resident starts outside buildings and water")
		for segment in resident.route.size():
			var a: Vector2 = resident.route[segment]
			var b: Vector2 = resident.route[(segment+1)%resident.route.size()]
			for sample in 9:
				check(not resident.obstructed(a.lerp(b,float(sample)/8.0)),"walker route stays outside terrain and building solids")
	game.player.position = walker.position+Vector2(20,0)
	var waiting_at: Vector2 = walker.position
	for frame in 20:
		await physics_frame
	check(walker.position.distance_to(waiting_at) < 1.0,"walker waits for nearby player")
	game.player.position = game.rules.get_area(&"A").npc_position
	game._interact()
	check(game.ui.has_modal() and paused,"tutorial guide interaction preserved")
	game.pause(false)
	game.ui.hide_modal()
	game._travel(&"B",&"west")
	await create_timer(0.3).timeout
	check(game.area.coastal_map.residents.is_empty(),"town residents removed in field")
	game._travel(&"A",&"east")
	await create_timer(0.3).timeout
	check(game.area.coastal_map.residents.size() == 12,"return creates exactly twelve residents")
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_RESIDENTS_PASS" if failures == 0 else "RESIDENTS failures=%d" % failures)
	quit(0 if failures == 0 else 1)

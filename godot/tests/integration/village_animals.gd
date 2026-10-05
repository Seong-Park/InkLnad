extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",message)

func run() -> void:
	create_timer(35.0).timeout.connect(func(): print("FAIL animal watchdog"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-animals/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	game.player.position = Vector2(1100,950)
	var animals: Array = game.area.coastal_map.animals
	check(animals.size() == 11,"eleven watercolor village animals")
	check(game.area.coastal_map.residents.size() == 12,"existing twelve residents preserved")
	for animal in animals:
		for animation in [&"idle",&"fly" if animal.flies else &"walk"]:
			check(animal.sprite.sprite_frames.get_frame_count(animation) == 4,"animal has four actual poses in each clip")
		for segment in animal.route.size():
			for sample in 9:
				var a: Vector2 = animal.route[segment]
				var b: Vector2 = animal.route[(segment+1)%animal.route.size()]
				check(not animal.obstructed(a.lerp(b,float(sample)/8.0)),"animal route avoids water and buildings")
		animal.wait_remaining = 0.0
	var first = animals[0]
	var resting = animals[5]
	var rest_start: Vector2 = resting.position
	var rest_progress: float = resting.sprite.frame_progress
	var start: Vector2 = first.position
	for frame in 45:
		await physics_frame
	check(first.position.distance_to(start) > 5,"animal actually walks")
	check(first.sprite.animation == &"walk","movement plays walk clip")
	check(resting.position == rest_start and resting.sprite.animation == &"idle","seated cat rests without sliding")
	check(resting.sprite.frame_progress != rest_progress or resting.sprite.frame > 0,"seated cat remains animated")
	var bird = animals[3]
	check(bird.airborne and bird.flight_height > 30.0 and bird.sprite.animation == &"fly","bird takes off with wingbeat and height")
	var sleep_cat = animals[9]
	var sleep_position: Vector2 = sleep_cat.position
	var breath_scale: float = sleep_cat.sprite.scale.y
	await create_timer(0.3).timeout
	check(sleep_cat.position == sleep_position and sleep_cat.sprite.animation == &"idle","sleeping cat stays curled at rest")
	check(not is_equal_approx(sleep_cat.sprite.scale.y,breath_scale),"sleeping animal breathes gently")
	await create_timer(1.2).timeout
	check(not bird.airborne and is_zero_approx(bird.flight_height) and bird.position.distance_to(bird.route[1]) < 0.1,"bird lands at destination")
	game.pause(true)
	var paused_position: Vector2 = first.position
	var progress: float = first.sprite.frame_progress
	await create_timer(0.15).timeout
	check(first.position == paused_position and is_equal_approx(first.sprite.frame_progress,progress),"pause freezes animal position and animation")
	game.pause(false)
	game.player.position = first.position+Vector2(10,0)
	for frame in 20:
		await physics_frame
	check(first.position.distance_to(paused_position) < 1,"animal yields to nearby player")
	game._travel(&"B",&"west")
	await create_timer(0.4).timeout
	check(game.area.coastal_map.animals.is_empty(),"animals removed when leaving village")
	game._travel(&"A",&"east")
	await create_timer(0.4).timeout
	check(game.area.coastal_map.animals.size() == 11,"return creates exactly eleven animals")
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_ANIMALS_PASS" if failures == 0 else "ANIMAL failures=%d" % failures)
	quit(0 if failures == 0 else 1)

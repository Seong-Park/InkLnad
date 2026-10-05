extends SceneTree

var game: Node
var previous: Vector2 = Vector2.ZERO
var phase: String = "C"

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(50.0).timeout.connect(func(): print("FAIL combat watchdog ",phase); quit(1))
	game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/first_journey/combat/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	game._travel(&"C",&"west")
	await create_timer(0.3).timeout
	var cleared: bool = await fight(&"C",1300)
	print("COMBAT C cleared=",cleared," HP=",game.player.hp," reward=",game.state.capture().run_ink," player=",game.player.position," enemies=",game.area.capture_enemies()," ink=",game.draw_controller.ink.current," holding=",game.draw_controller.ink.holding," modal=",game.ui.has_modal()," anchor=",game.draw_controller.anchor," viewport=",game.get_viewport().get_visible_rect())
	if not cleared:
		quit(1)
		return
	phase = "E"
	game._travel(&"E",&"west")
	await create_timer(0.3).timeout
	cleared = await fight(&"E",1500)
	print("COMBAT E cleared=",cleared," HP=",game.player.hp," reward=",game.state.capture().run_ink)
	var valid: bool = cleared and game.state.capture().run_ink==74
	game.queue_free()
	await process_frame
	if valid:
		print("INK_REAL_INPUT_COMBAT_PASS")
	quit(0 if valid else 1)

func pointer(pressed: bool, screen: Vector2) -> void:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = screen
	event.global_position = screen
	game.get_viewport().push_input(event,true)

func fight(area_id: StringName, frames: int) -> bool:
	for frame in range(frames):
		if paused:
			print("COMBAT unexpected pause frame=",frame," modal=",game.ui._modal," retry=",game.retry_save.call()," runtime=",game.capture_runtime())
			_release()
			return false
		if game.area_id!=area_id:
			break
		var target: EnemyController = null
		var closest: float = INF
		for enemy in game.area.enemies:
			var distance: float = enemy.position.distance_to(game.player.position)
			if enemy.alive and distance<closest:
				target = enemy
				closest = distance
		if target == null:
			_release()
			return true
		var difference: Vector2 = target.position-game.player.position
		var direction: Vector2 = difference.normalized() if closest>130 else (-difference.normalized() if closest<95 else Vector2.ZERO)
		if target.phase in [&"telegraph",&"dash"]:
			direction = difference.normalized().rotated(PI/2.0)
		for pair in [["move_right",direction.x>0.2],["move_left",direction.x< -0.2],["move_down",direction.y>0.2],["move_up",direction.y< -0.2]]:
			if pair[1]:
				Input.action_press(pair[0])
			else:
				Input.action_release(pair[0])
		var screen: Vector2 = game.get_viewport().get_canvas_transform()*target.global_position
		var motion: InputEventMouseMotion = InputEventMouseMotion.new()
		motion.position = screen
		motion.global_position = screen
		motion.relative = screen-previous
		game.get_viewport().push_input(motion,true)
		previous = screen
		var ink: CombatInk = game.draw_controller.ink
		if (ink.current<3.0 or closest>165.0) and ink.holding:
			pointer(false,screen)
		elif closest<=155.0 and not ink.holding and ink.current>=90.0:
			pointer(true,screen)
		await physics_frame
	_release()
	return false

func _release() -> void:
	for action in ["move_right","move_left","move_up","move_down"]:
		Input.action_release(action)
	pointer(false,previous)

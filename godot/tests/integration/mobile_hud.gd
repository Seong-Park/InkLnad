extends SceneTree

var failures: int = 0

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",message)

func touch(index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	# Coordinates already belong to the logical viewport, not the headless window.
	root.push_input(event,true)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(30.0).timeout.connect(func(): print("FAIL HUD watchdog"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/mobile-hud/profile.json"
	root.add_child(game)
	await process_frame
	game.start_new_game()
	await process_frame
	var hud: Control = game.ui._views.hud
	var stick: Control = hud.get_node_or_null("Joystick")
	var attack: Control = hud.get_node_or_null("Attack")
	var mini_map: Control = hud.get_node_or_null("MiniMap")
	check(mini_map != null,"minimap exists")
	if mini_map != null:
		check(mini_map.region == &"A","minimap starts in village")
		var before: Vector2 = mini_map.project_point(game.player.position)
		game.player.position += Vector2(100,0)
		game._update_ui()
		check(mini_map.project_point(game.player.position).x > before.x,"minimap follows actual local player coordinates")
		check(mini_map.mouse_filter == Control.MOUSE_FILTER_IGNORE,"minimap does not intercept touch input")
	check(stick != null and attack != null,"mobile controls exist")
	if stick == null or attack == null:
		quit(1)
		return
	game.player.position = Vector2(1050,950)
	var start: Vector2 = game.player.position
	var stick_point: Vector2 = stick.get_global_rect().get_center()+Vector2(48,0)
	touch(0,stick_point,true)
	for frame in 12:
		await physics_frame
	check(game.player.position.x > start.x+8.0,"touch joystick moves actual player")
	var attack_point: Vector2 = attack.get_global_rect().get_center()
	touch(1,attack_point,true)
	await create_timer(0.15).timeout
	check(game.draw_controller.ink.holding and game.draw_controller.ink.current < 100.0,"second finger attacks while moving")
	var brush_point: Vector2 = hud.get_node("Brush").get_global_rect().get_center()
	touch(5,brush_point,true)
	touch(5,brush_point,false)
	check(game.draw_controller.ink.holding,"tool selection preserves held attack")
	touch(0,stick_point,false)
	await process_frame
	check(game.draw_controller.ink.holding,"joystick release does not cancel attack finger")
	touch(1,attack_point,false)
	await process_frame
	check(not game.draw_controller.ink.holding,"attack release ends stroke")
	touch(0,stick_point,true)
	touch(1,attack_point,true)
	game.ui._pause_button_pressed()
	await process_frame
	check(game.player.touch_direction == Vector2.ZERO and not game.draw_controller.ink.holding,"pause releases mobile movement and attack")
	game._ui_action(&"resume")
	await process_frame
	check(game.player.touch_direction == Vector2.ZERO,"resume has no stuck movement")
	game.player.position = game.rules.get_area(&"A").npc_position+Vector2(0,35)
	game._update_ui()
	check(hud.get_node("Interact").visible,"nearby NPC interaction shown")
	game.player.position = Vector2(1100,950)
	game._update_ui()
	check(not hud.get_node("Interact").visible,"distant interaction hidden")
	game.ui._open_bag()
	check(game.ui.has_modal() and paused,"bag pauses play")
	var bag_panel: Node = game.ui._views.confirm.get_child(1)
	touch(2,hud.get_node("Map").get_global_rect().get_center(),true)
	touch(2,hud.get_node("Map").get_global_rect().get_center(),false)
	check(game.ui._views.confirm.get_child(1) == bag_panel,"modal blocks underlying native touch controls")
	game._ui_action(&"resume")
	game.ui._open_map()
	check(game.ui.has_modal() and paused,"map pauses play")
	game._ui_action(&"resume")
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	game.player.position = game.rules.get_area(&"A").portals.east
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game._update_ui()
	var interaction: Control = hud.get_node("Interact")
	touch(3,interaction.get_global_rect().get_center(),true)
	await create_timer(0.4).timeout
	check(game.area_id == &"B","touch interaction travels through portal")
	check(mini_map.region == &"B","minimap switches to field terrain")
	touch(3,interaction.get_global_rect().get_center(),false)
	check(interaction.finger == -1 and not interaction.active,"hidden interaction releases finger after travel")
	game.player.position = game.rules.get_area(&"B").portals.west
	game.camera.global_position = game.player.global_position
	game.camera.force_update_scroll()
	game._update_ui()
	touch(4,interaction.get_global_rect().get_center(),true)
	await create_timer(0.4).timeout
	touch(4,interaction.get_global_rect().get_center(),false)
	check(game.area_id == &"A","interaction works again after travel")
	game.queue_free()
	await process_frame
	print("INK_MOBILE_HUD_PASS" if failures == 0 else "MOBILE_HUD failures=%d" % failures)
	quit(0 if failures == 0 else 1)

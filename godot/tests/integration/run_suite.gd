extends SceneTree

var failures: int = 0

class FailingStore extends SaveStore:
	func write_snapshot(_snapshot: Dictionary) -> Dictionary:
		return {"ok":false,"reason":"save_failed"}

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(30.0).timeout.connect(func(): print("FAIL: integration watchdog"); quit(1))
	var path: String = "res://scenes/gameplay/Main.tscn"
	check(ResourceLoader.exists(path), "Playable main scene exists")
	if not ResourceLoader.exists(path):
		quit(1)
		return
	var scene: PackedScene = load(path)
	var game = scene.instantiate()
	game.save_path_override = "user://tests/first_journey/integration/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok, "Start new profile")
	game.record_tutorial(&"move", 120.0)
	game.record_tutorial(&"line", 80.0)
	game.record_tutorial(&"hold", 0.5)
	game.record_tutorial(&"recover", 10.0)
	check(game.tutorial_complete(), "Tutorial remembers all four steps")
	check(game.request_exit(&"east").ok, "Workshop opens after tutorial")
	await create_timer(0.3).timeout
	check(game.area_id == &"B", "Enter B")
	check(game.request_exit(&"east").ok, "B connects C")
	await create_timer(0.3).timeout
	check(not game.request_exit(&"east").ok, "C east locked with enemies")
	await create_timer(0.8).timeout
	for enemy in game.area.enemies:
		enemy.receive_damage(1000.0)
	await process_frame
	check(game.state.capture().run_ink == 24, "Three drops grant 24")
	check(game.request_exit(&"east").ok, "Cleared C opens D")
	await create_timer(0.3).timeout
	check(game.request_exit(&"east").reason == &"confirmation", "Elite entry asks confirmation")
	check(game.confirm_elite(false).reason == &"cancelled", "Elite warning cancels")
	check(game.area_id == &"D", "Cancel keeps D")
	check(game.request_exit(&"east").reason == &"confirmation", "Confirm needs a new entry request after cancel")
	check(game.confirm_elite(true).ok, "Elite confirmed entry")
	await create_timer(0.3).timeout
	check(not game.request_exit(&"west").ok, "Elite locks retreat")
	await create_timer(0.8).timeout
	check(game.area_id == &"E" and game.area.enemies.size()==1,"Elite scene contains elite")
	if game.area.enemies.is_empty():
		quit(1)
		return
	game.area.enemies[0].receive_damage(1000.0)
	await process_frame
	check(game.state.capture().run_ink == 74, "Mandatory path earns 74")
	game.request_exit(&"east")
	await create_timer(0.3).timeout
	check(game.restore_flower().ok, "Flower restores after elite")
	game.player.position = Vector2(180, 450)
	check(game.return_home().ok, "Safety return")
	await create_timer(0.3).timeout
	check(game.state.capture().wallet_ink == 73, "Return settles reward minus restoration cost")
	check(game.purchase_pencil().ok, "Pencil purchase")
	check(game.state.capture().wallet_ink == 13, "Pencil costs 60")
	game.mark_pencil_test()
	check(game.journey_complete(), "All first journey flags complete")
	check(game.continue_game().ok, "Saved profile reloads")
	check(game.state.capture().pencil_test_completed, "Pencil test survives reload")
	game.draw_controller.cancel()
	game.draw_controller.handle_pointer({"phase": &"press", "screen": Vector2(800,360), "ui_consumed":true, "physical_motion":true})
	check(not game.draw_controller.ink.holding, "UI gesture is excluded")
	await input_cases(game)
	await optional_and_failure_cases(game)
	print("INTEGRATION failures=", failures)
	game.queue_free()
	await process_frame
	if failures == 0:
		print("INK_FIRST_JOURNEY_PASS")
	quit(0 if failures == 0 else 1)

func input_cases(game: Node) -> void:
	game.player.position = Vector2(500,300)
	# Start the pointer fixture with a matching camera, rather than the old town spawn view.
	game.camera.set_area(game.area.area_size,&"follow_2d")
	game.draw_controller.strokes.clear()
	game.draw_controller.ink.configure(100.0,100.0/3.5,0.5)
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(650,380),"ui_consumed":false})
	game.draw_controller.tick(1.0)
	var anchor: Vector2 = game.draw_controller.anchor
	check(is_equal_approx(game.draw_controller.ink.current,80.0),"Stationary upkeep charged once")
	game.camera.position.x += 50.0
	game.camera.force_update_scroll()
	game.draw_controller.tick(1.0)
	check(game.draw_controller.anchor==anchor,"Camera motion retains world anchor")
	check(is_equal_approx(game.draw_controller.ink.current,60.0),"Camera creates no length cost")
	game.player.position.x += 300.0
	game.draw_controller.tick(0.25)
	check(is_equal_approx(game.draw_controller.ink.current,60.0),"Outside hold neither spends nor recharges")
	check(game.draw_controller.direct_stamps.is_empty(),"Moving knight away stops direct paint")
	game.draw_controller.cancel()
	game.draw_controller.tick(0.5)
	game.draw_controller.tick(3.5)
	check(is_equal_approx(game.draw_controller.ink.current,100.0),"Release then four seconds recharges")
	game.camera.set_area(Vector2(1120,560),&"fixed")
	game.player.position = Vector2(500,300)
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(580,380),"ui_consumed":false})
	game.draw_controller.handle_pointer({"phase":&"move","screen":Vector2(900,380),"physical_motion":true})
	game.draw_controller.tick(0.1)
	check(game.draw_controller.ink.current<100.0,"Inside to outside approves valid prefix")
	for stamp in game.draw_controller.direct_stamps:
		check(stamp.center.distance_to(game.player.global_position)+stamp.radius<=180.001,"Paint full width stays in radius")
	var remaining: float = game.draw_controller.ink.current
	game.draw_controller.tick(0.1)
	check(is_equal_approx(remaining,game.draw_controller.ink.current),"Outside stop has no upkeep")
	game.draw_controller.cancel()
	game.draw_controller.strokes.clear()
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(950,380),"ui_consumed":false})
	game.draw_controller.handle_pointer({"phase":&"move","screen":Vector2(650,380),"physical_motion":true})
	game.draw_controller.tick(0.1)
	check(not game.draw_controller.direct_stamps.is_empty(),"Reentry paints valid new point on the same tick")
	game.draw_controller.cancel()
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(-10,-10),"ui_consumed":false})
	check(not game.draw_controller.ink.holding,"Letterbox outside press is excluded")
	game.draw_controller.cancel()
	game.draw_controller.ink.configure(100.0,100.0/3.5,0.5)
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(580,380),"ui_consumed":false})
	game.draw_controller.tick(5.0)
	game.draw_controller.tick(10.0)
	check(game.draw_controller.ink.current==0.0,"Empty hold cannot regenerate or restart")
	game.draw_controller.cancel()
	game.draw_controller.tick(4.0)
	game.pause(true)
	var before: float = game.draw_controller.now
	await create_timer(0.1).timeout
	check(game.draw_controller.now==before,"Pause stops game clock")
	game.pause(false)
	game.ui.hide_modal()

func optional_and_failure_cases(game: Node) -> void:
	check(game.start_new_game().ok,"New isolated profile replaces old only after save")
	for pair in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
		game.record_tutorial(pair[0],pair[1])
	game.request_exit(&"east")
	await create_timer(0.3).timeout
	game.request_exit(&"east")
	await create_timer(0.3).timeout
	for enemy in game.area.enemies:
		enemy.protection = 0.0
		enemy.receive_damage(1000.0)
	game.request_exit(&"east")
	await create_timer(0.3).timeout
	for enemy in game.area.enemies:
		enemy.protection = 0.0
		enemy.receive_damage(1000.0)
	check(game.state.capture().run_ink==60,"Optional room adds 36")
	var waypoint: Vector2 = game.area.next_waypoint(Vector2(340,600),Vector2(1450,600),18.0)
	check(not Geometry2D.is_point_in_polygon(waypoint,game.area.coastal_map.layout.water[0]),"D navigation avoids rain pond")
	await physics_frame
	var footprint := Rect2()
	for prop in game.area.coastal_map.layout.props:
		if prop.has("body") and not footprint.has_area():
			footprint = prop.body
			footprint.position += prop.position
	game.area.projectiles.append({"position":footprint.position+Vector2(-20,-4),"direction":Vector2.RIGHT,"life":4.0})
	game.area.tick(1.0)
	check(game.area.projectiles.is_empty(),"Radius-five swept projectile touches obstacle edge")
	game.request_exit(&"east")
	game.confirm_elite(true)
	await create_timer(0.3).timeout
	game.area.enemies[0].protection = 0.0
	game.area.enemies[0].receive_damage(12.0)
	game.player.hp = 0.0
	check(game.return_home(true).ok,"Elite death settles without reward loss")
	await create_timer(0.3).timeout
	check(game.state.capture().wallet_ink==60 and game.state.capture().run_ink==0,"Death settles exactly once")
	check(game.state.capture().enemies.e01.hp==108,"Elite remaining HP persists after death")
	check(game.continue_game().ok,"Death profile reload")
	check(game.player.hp==100 and game.draw_controller.ink.current==100,"Reload safe HP and ink")
	game._travel(&"E",&"west")
	await create_timer(0.3).timeout
	check(game.area.enemies.size()==1 and game.area.enemies[0].hp==108,"Elite retry uses saved HP")
	game.area.enemies[0].protection = 0.0
	var before: Dictionary = game.state.capture()
	var failing: FailingStore = FailingStore.new()
	game.economy.configure(game.state,failing,game.rules)
	game.area.enemies[0].receive_damage(1000.0)
	check(game.state.capture()==before,"Failed defeat rolls back full persisted snapshot")
	check(game.area.enemies[0].alive and game.area.enemies[0].hp==108,"Failed defeat restores enemy HP")
	check(paused and game.ui.has_modal(),"Save failure pauses with retry UI")
	game.draw_controller.ink.current = 33.0
	game.economy.configure(game.state,game.store,game.rules)
	game._ui_action(&"retry_save")
	check(not paused and not game.area.enemies[0].alive,"Retry commits captured defeat")
	check(game.draw_controller.ink.current==33.0,"Retry is not disk resume/free ink refill")
	check(game.state.capture().run_ink==50,"Retry grants elite reward once")
	game._travel(&"F",&"west")
	await create_timer(0.3).timeout
	game.restore_flower()
	game.player.position = Vector2(180,450)
	game.return_home()
	await create_timer(0.3).timeout
	game.purchase_pencil()
	check(game.state.capture().wallet_ink==49,"Optional journey wallet includes restoration cost")
	game.economy.configure(game.state,failing,game.rules)
	game._ui_action(&"save_menu")
	check(game.started and paused,"Failed menu save remains in game")
	game.economy.configure(game.state,game.store,game.rules)
	game._ui_action(&"retry_save")
	check(not game.started and paused and game.ui.has_modal(),"Menu retry preserves original intent and stops simulation")
	game.continue_game()
	check(game.started and not paused,"Menu continue unpauses")
	game._ui_action(&"save_menu")
	var previous: Dictionary = game.state.capture()
	game._ui_action(&"new_game")
	game._ui_action(&"cancel_new")
	check(game.state.capture()==previous,"New-game cancellation preserves existing profile")
	check(game._apply_settings({"ui_scale":1.5,"mute":true}).ok,"Menu settings commit without starting gameplay")
	check(not game.started and game.state.capture().settings.ui_scale==1.5,"Menu retains selected UI scale")
	check(game.state.capture().wallet_ink==49 and "pencil" in game.state.capture().owned_tools,"Menu settings preserve journey progress")
	game.continue_game()
	check(game.state.capture().settings.mute,"Continue loads saved mute preference")

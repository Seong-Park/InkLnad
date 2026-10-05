extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL ", label)

func run() -> void:
	create_timer(60.0).timeout.connect(func(): print("FAIL coast watchdog"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/coastal-maps/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok, "isolated new game")
	var town: Dictionary = game.rules.get_area(&"A")
	var field: Dictionary = game.rules.get_area(&"B")
	check(town.size.x > 1280 and town.size.y > 720, "town spans multiple screens")
	check(field.size.x > 1280 and field.size.y > 720, "field spans multiple screens")
	check(town.camera == "follow_2d" and field.camera == "follow_2d", "two axis cameras")
	game.player.position = (Vector2(1800,1000)*2.0)
	game.camera.follow(1.0)
	check(game.camera.focus.y > 500, "vertical follow")
	game.player.position = town.size - Vector2.ONE * 20
	game.camera.follow(1.0)
	var half_view: Vector2 = game.get_viewport_rect().size / (game.camera.zoom * 2.0)
	check(game.camera.focus.x <= town.size.x - half_view.x, "right camera bound")
	check(game.camera.focus.y <= town.size.y - half_view.y, "bottom camera bound")
	check(game.area.get_node_or_null("CoastalMap") != null, "world terrain renderer")
	var pointer_world: Vector2 = game.player.global_position+(Vector2(-60,-40)*2.0)
	var pointer_screen: Vector2 = game.get_viewport().get_canvas_transform()*pointer_world
	check(game.camera.screen_to_world(pointer_screen).distance_to(pointer_world)<0.01,"scrolling camera preserves pointer world coordinates")
	check(town.has("portals") and field.has("portals"), "positioned portal data")
	game.player.position = town.npc_position
	game._interact()
	check(game.ui.has_modal() and paused,"shop interaction follows relocated NPC")
	game.pause(false)
	game.ui.hide_modal()
	if town.has("portals") and field.has("portals"):
		for event in [[&"move",120.0],[&"line",80.0],[&"hold",0.5],[&"recover",10.0]]:
			game.record_tutorial(event[0],event[1])
		game.player.position = town.portals.east
		game._interact()
		await create_timer(0.3).timeout
		check(game.area_id == &"B", "portal interaction enters field")
		check(game.player.position.distance_to(field.entry_west) < 1, "paired field arrival")
		game.player.position = field.portals.west
		game._interact()
		await create_timer(0.3).timeout
		check(game.area_id == &"A", "return portal enters town")
		check(game.player.position.distance_to(town.entry_east) < 1, "paired town arrival")
		game.player.position = (Vector2(1280,1320)*2.0)
		Input.action_press("move_down")
		await create_timer(2.0).timeout
		Input.action_release("move_down")
		check(game.player.position.y <= 2680.0, "curved sea blocks movement at beach")
		check(game.area.coastal_map.get_node_or_null("GroundTiles") is TileMapLayer, "ground is a tile map")
		check(game.area.coastal_map.get_node("GroundTiles").material is ShaderMaterial,"ground supports continuous terrain transitions")
		game._travel(&"B",&"west")
		await create_timer(0.3).timeout
		await physics_frame
		check(blocked(game,(Vector2(1500,1000)*2.0)), "lagoon interior has collision")
		check(not blocked(game,(Vector2(2390,1240)*2.0)), "bridge crosses stream without invisible wall")
		check(blocked(game,(Vector2(2390,1400)*2.0)), "stream below bridge blocks movement")
		for route in [
			[(Vector2(650,1000)*2.0),(Vector2(750,670)*2.0),(Vector2(1250,520)*2.0),(Vector2(1880,600)*2.0),(Vector2(2290,870)*2.0),(Vector2(2540,950)*2.0),(Vector2(2670,1190)*2.0),(Vector2(2930,1190)*2.0)],
			[(Vector2(650,1000)*2.0),(Vector2(790,1340)*2.0),(Vector2(1160,1500)*2.0),(Vector2(1700,1540)*2.0),(Vector2(2020,1420)*2.0),(Vector2(2190,1240)*2.0),(Vector2(2400,1240)*2.0),(Vector2(2670,1190)*2.0),(Vector2(2930,1190)*2.0)]
		]:
			for index in range(route.size()-1):
				var count: int = int(route[index].distance_to(route[index+1])/20.0)+1
				for step in range(count+1):
					var point: Vector2 = route[index].lerp(route[index+1],float(step)/count)
					if blocked(game,point):
						check(false,"connected walking route blocked at %s" % point)
						break
		game.player.position = (Vector2(2250,1240)*2.0)
		Input.action_press("move_right")
		await create_timer(3.2).timeout
		Input.action_release("move_right")
		check(game.player.position.x > 5000.0,"actual character can walk across bridge")
		game._travel(&"A",&"east")
		await create_timer(0.3).timeout
		check(not blocked(game,game.player.position),"town portal arrival is on land")
		game.player.position = (Vector2(620,620)*2.0)
		Input.action_press("move_up")
		await create_timer(1.2).timeout
		Input.action_release("move_up")
		check(game.player.position.y > 1100.0,"workshop base stops character")
		game.player.position = (Vector2(1360,1280)*2.0)
		Input.action_press("move_down")
		await create_timer(2.0).timeout
		Input.action_release("move_down")
		check(game.player.position.y > 2840.0 and game.player.position.y < 2920.0,"town dock reaches its end without walking into sea")
	game.queue_free()
	await process_frame
	print("COASTAL_MAPS failures=", failures)
	if failures == 0:
		print("INK_COASTAL_MAPS_PASS")
	quit(0 if failures == 0 else 1)

func blocked(game: Node, point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	query.shape = circle
	query.transform = Transform2D(0,game.area.to_global(point))
	query.collision_mask = 1
	return not game.area.get_world_2d().direct_space_state.intersect_shape(query,1).is_empty()

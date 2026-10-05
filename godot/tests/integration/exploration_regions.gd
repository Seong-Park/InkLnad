extends SceneTree

var failures: int = 0
var total: int = 0
const FOLDER: String = "C:/workspace/Ink-Land/docs/verification/exploration-regions/"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",label)

func capture(game: Node, id: StringName) -> void:
	game.camera.global_position = game.player.global_position+Vector2(0,-90)
	game.camera.force_update_scroll()
	game._update_ui()
	await process_frame
	await RenderingServer.frame_post_draw
	if DisplayServer.get_name() != "headless":
		check(root.get_texture().get_image().save_png(FOLDER+String(id)+".png")==OK,"capture")

func run() -> void:
	create_timer(120.0).timeout.connect(func(): print("FAIL exploration timeout"); quit(1))
	DirAccess.make_dir_recursive_absolute(FOLDER)
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/exploration-regions/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok,"isolated new profile")
	for id in [&"C",&"D",&"E"]:
		check(game._travel(id,&"west").ok,"travel to exploration region")
		await create_timer(0.3).timeout
		var info: Dictionary = game.rules.get_area(id)
		check(info.size == Vector2(3200,2200) and game.camera.mode==&"follow_2d","two-dimensional region")
		check(info.portals.west.y != info.portals.east.y,"portals on different elevations")
		check(game.area.exploration_navigation != null,"two-dimensional navigation")
		check(game.area.coastal_map.get_node_or_null("ContinuousExplorationGround") is Polygon2D,"continuous watercolor terrain")
		if id == &"D":
			var query := PhysicsShapeQueryParameters2D.new()
			var circle := CircleShape2D.new()
			circle.radius = 12.0
			query.shape = circle
			query.transform = Transform2D(0,game.area.to_global(Vector2(880,600)))
			query.collision_mask = 1
			await physics_frame
			check(not game.area.get_world_2d().direct_space_state.intersect_shape(query).is_empty(),"rain pond collision matches art")
			var path: PackedVector2Array = game.area.exploration_navigation.get_point_path(Vector2i(4,7),Vector2i(18,7),true)
			check(path.size()>4,"monster can route around pond")
			for point in path:
				check(not Geometry2D.is_point_in_polygon(point,game.area.coastal_map.layout.water[0]),"navigation avoids pond")
		var restoration = game.area.coastal_map.restoration
		check(restoration.objects.size()>=8,"at least eight new restoration elements per region")
		total += restoration.objects.size()
		await physics_frame
		for element in restoration.objects:
			var reachable: bool = false
			for index in 16:
				var point: Vector2 = element.point+Vector2.from_angle(TAU*index/16.0)*100.0
				var probe := PhysicsShapeQueryParameters2D.new()
				var shape := CircleShape2D.new()
				shape.radius = 12.0
				probe.shape = shape
				probe.collision_mask = 1
				probe.transform = Transform2D(0,game.area.to_global(point))
				reachable = reachable or game.area.get_world_2d().direct_space_state.intersect_shape(probe).is_empty()
			check(reachable,"reachable restoration "+element.id)
		var item: Dictionary = restoration.objects[0]
		check(not game._restore_world_object(item).ok and not item.restored,"no monster ink means no restoration")
		game.player.position = Vector2(1550,1250)
		for direction in ["move_up","move_down","move_left","move_right"]:
			var before: Vector2 = game.player.position
			Input.action_press(direction)
			await create_timer(0.2).timeout
			Input.action_release(direction)
			check(game.player.position.distance_to(before)>20,"actual movement "+direction)
		for enemy in game.area.enemies:
			enemy.set_physics_process(false)
		game.player.position = game.area.enemies[0].position+Vector2(0,80)
		game.set_physics_process(false)
		await capture(game,id)
		game.camera.zoom = Vector2.ONE*0.36
		game.camera.global_position = game.area.to_global(info.size*0.5)
		game.camera.force_update_scroll()
		await process_frame
		await RenderingServer.frame_post_draw
		if DisplayServer.get_name() != "headless":
			check(root.get_texture().get_image().save_png(FOLDER+String(id)+"-overview.png")==OK,"overview capture")
		game.camera.zoom = Vector2.ONE
		game.set_physics_process(true)
	check(total>=24,"minimum twenty additional elements")
	game._travel(&"C",&"west")
	await create_timer(0.3).timeout
	var enemy = game.area.enemies[0]
	game.player.position = enemy.position+Vector2(0,65)
	enemy.protection = 0.0
	game._cast_skill("flower")
	await create_timer(1.1).timeout
	check(not enemy.alive,"actual skill defeats monster")
	var earned: int = game.state.capture().run_ink
	check(earned==8,"monster reward credited")
	var item: Dictionary = game.area.coastal_map.restoration.objects[0]
	check(game._restore_world_object(item).ok,"spend earned ink")
	check(game.state.capture().run_ink==earned-1 and item.restored,"atomic deduction and restoration")
	check(game._restore_world_object(item).ok and game.state.capture().run_ink==earned-1,"repeat does not double-charge")
	var saved: Dictionary = game.store.read_snapshot()
	check(saved.ok and saved.snapshot.run_ink==earned-1 and saved.snapshot.tutorial_flags.get(item.id,false),"deduction and color persist together")
	game.queue_free()
	await process_frame
	print("EXPLORATION elements=",total," failures=",failures)
	print("INK_EXPLORATION_REGIONS_PASS" if failures==0 else "FAIL exploration")
	quit(0 if failures==0 else 1)

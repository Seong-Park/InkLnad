extends SceneTree

var failures: int = 0
const KINDS: Array[String] = ["apothecary","tool-shop","outfit-shop","craft-workshop","village-teahouse"]

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, title: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",title)

func blocked(game: Node, point: Vector2) -> bool:
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	query.shape = shape
	query.transform = Transform2D(0,game.area.to_global(point))
	query.collision_mask = 1
	return not game.area.get_world_2d().direct_space_state.intersect_shape(query).is_empty()

func run() -> void:
	create_timer(30.0).timeout.connect(func(): print("FAIL building watchdog"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/village-buildings/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok,"isolated game starts")
	await physics_frame
	var props: Array = game.area.coastal_map.layout.props
	for kind in KINDS:
		var building: Dictionary = {}
		for prop in props:
			if prop.kind == kind:
				building = prop
		check(not building.is_empty(),kind+" exists")
		if building.is_empty():
			continue
		check(blocked(game,building.position+Vector2(0,-25)),kind+" has solid foundation")
		check(not blocked(game,building.position+Vector2(0,45)),kind+" has walkable approach")
		game.player.position = building.position+Vector2(0,45)
		game.player.touch_direction = Vector2.UP
		for frame in 24:
			await physics_frame
		game.player.touch_direction = Vector2.ZERO
		check(game.player.position.y >= building.position.y,kind+" stops actual player at base")
	game.player.get_node("FootstepAudio").stop()
	await create_timer(0.1).timeout
	game.queue_free()
	await process_frame
	print("INK_VILLAGE_BUILDINGS_PASS" if failures == 0 else "BUILDINGS failures=%d" % failures)
	quit(0 if failures == 0 else 1)

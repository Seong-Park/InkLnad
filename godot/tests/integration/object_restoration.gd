extends SceneTree

var failures: int = 0

class FailingStore extends SaveStore:
	func write_snapshot(_snapshot: Dictionary) -> Dictionary:
		return {"ok":false,"reason":"write_failed"}

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",label)

func run() -> void:
	create_timer(60.0).timeout.connect(func(): print("FAIL restoration timeout"); quit(1))
	var game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/object-restoration/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok,"isolated profile")
	check(game.economy.grant_defeat(&"c01",{"enemies":{"c01":{"hp":0,"alive":false}}}).ok,"monster reward funds restoration")
	var restoration = game.area.coastal_map.restoration
	check(restoration.objects.size()>10,"many individual elements")
	var flower: Dictionary = {}
	var tree: Dictionary = {}
	for item in restoration.objects:
		if item.kind == "flowerpots": flower = item
		if item.kind == "pine": tree = item
	check(not flower.is_empty() and not tree.is_empty(),"flowers and trees")
	game.player.position = flower.point
	check(String(game._interaction_context().title).begins_with("색 복원"),"touch interaction")
	game._restore_world_object(flower)
	await create_timer(1.6).timeout
	check(flower.restored,"flower restored")
	check(not tree.restored,"other tree stays faded")
	check(float(flower.material.get_shader_parameter("restored"))>0.99,"wash completed")
	var saved: Dictionary = game.store.read_snapshot()
	check(saved.ok and saved.snapshot.tutorial_flags.get(flower.id,false),"saved element")
	var id: String = flower.id
	game._build_area()
	var found: bool = false
	for item in game.area.coastal_map.restoration.objects:
		if item.id == id: found = item.restored
	check(found,"survives map rebuild")
	var pending: Dictionary = {}
	for item in game.area.coastal_map.restoration.objects:
		if item.kind == "pine" and pending.is_empty(): pending = item
	var before: Dictionary = game.state.capture()
	game.economy.configure(game.state,FailingStore.new(),game.rules)
	var failed: Dictionary = game._restore_world_object(pending)
	check(not failed.ok and not pending.restored,"failed save does not reveal tree")
	check(game.state.capture()==before and not game.tutorial_flags.get(pending.id,false),"failed save rolls back progress")
	game.economy.configure(game.state,game.store,game.rules)
	game.pause(false)
	game.ui.hide_modal()
	game.player.position = pending.point
	game._interact()
	await create_timer(1.6).timeout
	check(pending.restored,"real interaction restores green tree")
	check(game.store.read_snapshot().snapshot.tutorial_flags.get(pending.id,false),"tree separately saved")
	game.queue_free()
	await process_frame
	print("INK_OBJECT_RESTORATION_PASS" if failures==0 else "FAIL restoration")
	quit(0 if failures==0 else 1)

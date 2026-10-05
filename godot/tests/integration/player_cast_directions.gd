extends SceneTree

var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",label)

func run() -> void:
	create_timer(20.0).timeout.connect(func(): print("FAIL cast watchdog"); quit(1))
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var player: PlayerController = load("res://scenes/gameplay/Player.tscn").instantiate()
	root.add_child(player)
	player.set_enabled(true)
	await process_frame
	await process_frame
	for direction in player.FACINGS:
		player.facing = direction
		player.actual_velocity = Vector2.ZERO
		player._update_portrait()
		player.start_cast()
		var expected := StringName("cast_"+String(direction))
		check(player.portrait.animation==expected,"cast preserves facing "+String(direction))
		check(player.portrait.flip_h==(direction in [&"w",&"sw",&"nw"]),"cast mirror "+String(direction))
		check(not player.portrait.sprite_frames.get_animation_loop(player.portrait.animation),"cast is one-shot")
		check(player.portrait.sprite_frames.get_frame_count(player.portrait.animation)==8,"cast has eight authored poses")
		player._process(0.01)
		check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"cast has no duplicate deformation")
		await create_timer(0.9).timeout
		check(not player.casting and player.portrait.animation==StringName("idle_"+String(direction)),"cast returns to matching idle "+String(direction))
	player.facing = &"s"
	player.start_cast(Vector2(-1,-1))
	check(player.facing==&"nw" and player.portrait.animation==&"cast_nw" and player.portrait.flip_h,"cast turns toward aim before playback")
	player.set_enabled(false)
	player.set_enabled(true)
	player.facing = &"nw"
	player.start_cast()
	player.set_enabled(false)
	check(not player.casting and player.portrait.animation==&"idle_nw","disable cancels directional cast")
	print("CAST_DIRECTION failures=",failures)
	if failures==0:
		print("INK_PLAYER_CAST_DIRECTIONS_PASS")
	quit(0 if failures==0 else 1)

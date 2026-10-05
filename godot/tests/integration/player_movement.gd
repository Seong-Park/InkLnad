extends SceneTree

var failures: int = 0
var contacts: Array[int] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	if not ok:
		failures += 1
		print("FAIL ",label)

func ticks(count: int) -> void:
	for i in range(count):
		await physics_frame
	await process_frame

func run() -> void:
	create_timer(15.0).timeout.connect(func(): print("FAIL movement watchdog"); quit(1))
	for action in ["move_left","move_right","move_up","move_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	var player = load("res://scenes/gameplay/Player.tscn").instantiate()
	root.add_child(player)
	player.position = Vector2(100,100)
	player.set_enabled(true)
	player.footstep_contact.connect(func(frame: int): contacts.append(frame))
	await ticks(2)
	# process_frame resumes before node _process callbacks; allow one completed frame.
	await process_frame
	check(player.portrait is AnimatedSprite2D,"real frame animation")
	check(player.is_idle(),"stopped idle")
	check(player.portrait.is_playing() and player.portrait.sprite_frames.get_frame_count(player.portrait.animation)==36,"enabled idle plays authored motion")
	check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"authored idle avoids duplicate secondary motion")
	check(player.portrait.sprite_frames.get_frame_count(&"idle")==16,"fox idle sixteen frames")
	check(player.portrait.sprite_frames.get_frame_count(&"walk")==16,"fox walk sixteen frames")
	check(player.portrait.sprite_frames.has_animation(&"cast"),"fox has cast animation")
	Input.action_press("move_right")
	var start: Vector2 = player.position
	await ticks(30)
	var horizontal: float = player.position.distance_to(start)
	check(absf(horizontal-90.0)<=4.0,"horizontal180/sec")
	check(player.is_walking() and player.portrait.is_playing(),"walking playback")
	check(is_zero_approx(float(player.secondary_material.get_shader_parameter("cloth_tail_weight"))),"native walk clothing and tail do not receive duplicate deformation")
	check(not player.portrait.flip_h,"right facing")
	check(contacts.size() >= 2 and contacts[0] == 0 and contacts[1] == 9,"alternating foot contacts follow native gait")
	await ticks(53)
	check(contacts.size() >= 4 and contacts.size() <= 6,"native gait retains previous step cadence")
	var first_frame: int = player.portrait.frame
	await ticks(14)
	check(player.portrait.frame!=first_frame,"walk frame advances")
	Input.action_release("move_right")
	await ticks(2)
	check(player.is_idle(),"release enters idle")
	check(not player.footstep_audio.playing,"release stops sound")
	start = player.position
	Input.action_press("move_right")
	Input.action_press("move_down")
	await ticks(30)
	check(absf(player.position.distance_to(start)-90.0)<=4.0,"diagonal normalized180/sec")
	Input.action_release("move_right")
	Input.action_release("move_down")
	Input.action_press("move_left")
	await ticks(3)
	check(player.facing == &"w" and not player.portrait.flip_h,"native left facing")
	Input.action_release("move_left")
	Input.action_press("move_up")
	await ticks(3)
	check(player.facing == &"n" and not player.portrait.flip_h and player.is_walking(),"up shows back view")
	Input.action_release("move_up")
	for sector in 8:
		var expected: StringName = player.FACINGS[sector]
		player.touch_direction = Vector2.RIGHT.rotated(sector*PI/4.0)
		start = player.position
		await ticks(5)
		check(player.facing == expected and player.portrait.animation == StringName("walk_"+String(expected)),"eight-direction walk selection "+String(expected))
		check(player.position.distance_to(start) > 8.0,"direction moves physically "+String(expected))
		check(player.portrait.sprite_frames.get_frame_count(player.portrait.animation) == 36,"thirty-six native walk poses "+String(expected))
		player.touch_direction = Vector2.ZERO
		await ticks(2)
		check(player.portrait.animation == StringName("idle_"+String(expected)),"idle retains direction "+String(expected))
	player.actual_velocity = Vector2.RIGHT*180.0
	player._update_portrait()
	player.portrait.set_frame_and_progress(1,0.4)
	player.last_contact_frame = 9
	var contact_count: int = contacts.size()
	player.actual_velocity = Vector2.UP*180.0
	player._update_portrait()
	check(player.portrait.frame == 1 and is_equal_approx(player.portrait.frame_progress,0.4),"turn preserves gait phase")
	check(contacts.size() == contact_count,"turn does not invent a footstep")
	player.actual_velocity = Vector2.RIGHT.rotated(deg_to_rad(24.0))*180.0
	player.facing = &"e"
	player._update_portrait()
	check(player.facing == &"e","direction boundary jitter stays in current sector")
	player.actual_velocity = Vector2.RIGHT.rotated(deg_to_rad(32.0))*180.0
	player._update_portrait()
	check(player.facing == &"se","deliberate turn crosses hysteresis margin")
	player.actual_velocity = Vector2.RIGHT*90.0
	player._update_portrait()
	check(is_equal_approx(player.portrait.speed_scale,0.5),"half speed uses half cadence")
	player.set_enabled(false)
	check(player.is_idle() and player.actual_velocity==Vector2.ZERO,"disable immediately idle")
	Input.action_release("move_up")
	var wall := StaticBody2D.new()
	wall.position = Vector2(500,0)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(40,2000)
	collision.shape = shape
	wall.add_child(collision)
	root.add_child(wall)
	player.position = Vector2(450,100)
	player.set_enabled(true)
	Input.action_press("move_right")
	await ticks(30)
	check(player.position.x<=468.1,"wall prevents penetration")
	check(player.actual_velocity.length()<1.0 and player.is_idle(),"blocked input does not walk in place")
	check(not player.footstep_audio.playing,"blocked movement stops sound")
	check(is_zero_approx(player.portrait.rotation),"no whole-body wobble")
	for animation in player.portrait.sprite_frames.get_animation_names():
		player.portrait.animation = animation
		for frame in range(player.portrait.sprite_frames.get_frame_count(animation)):
			player.portrait.frame = frame
			player._align_portrait_frame()
			var entry: Dictionary = player.portrait_frames[String(animation)][frame]
			var texture: Texture2D = player.portrait.sprite_frames.get_frame_texture(animation,frame)
			var foot: Array = entry.foot_anchor
			var point: Vector2 = Vector2(float(foot[0])-texture.get_width()*0.5,float(foot[1])-texture.get_height()*0.5)*player.portrait.scale
			point.x *= -1.0 if player.portrait.flip_h else 1.0
			check((player.portrait.position+point).length()<0.01,"common foot anchor "+String(animation)+str(frame))
	Input.action_release("move_right")
	await ticks(2)
	player.facing = &"s"
	player.actual_velocity = Vector2.ZERO
	player._update_portrait()
	player._process(0.1)
	check(player.portrait.sprite_frames.get_frame_count(&"idle_s")==36,"frontal idle has authored blink and breathing frames")
	check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"native idle avoids duplicate shader deformation")
	var idle_scale: float = float(player.portrait_frames.idle_s[0].scale)
	for entry in player.portrait_frames.idle_s:
		check(is_equal_approx(float(entry.scale),idle_scale),"native idle never rescales individual breathing frames")
	check(player.portrait.material == null,"LUDO artwork bypasses old head and cloth deformation")
	for direction in [&"ne",&"nw",&"n"]:
		player.facing = direction
		player._update_portrait()
		player._process(0.1)
		check(player.portrait.sprite_frames.get_frame_count(player.portrait.animation)==36,"rear native idle frames "+String(direction))
		check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"rear native idle avoids duplicate deformation")
		check(not player.portrait.flip_h,"rear native idle mirrors correctly")
	for direction in [&"e",&"w",&"se",&"sw"]:
		player.facing = direction
		player.actual_velocity = Vector2.ZERO
		player._update_portrait()
		await ticks(2)
		check(player.portrait.sprite_frames.get_frame_count(player.portrait.animation)==36,"side native idle frames "+String(direction))
		check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"side native idle avoids duplicate deformation")
		check(not player.portrait.flip_h,"side native idle mirrors correctly")
	player.call("start_cast")
	check(player.portrait.animation==StringName("cast_"+String(player.facing)),"directional cast takes animation priority")
	player._process(0.01)
	check(is_zero_approx(float(player.secondary_material.get_shader_parameter("motion_weight"))),"cast preserves authored pose without walk deformation")
	await ticks(55)
	check(player.is_idle(),"one shot returns to idle")
	player.call("start_cast")
	player.set_enabled(false)
	check(player.is_idle(),"disable cancels casting")
	player.queue_free()
	wall.queue_free()
	await process_frame
	print("MOVEMENT failures=",failures)
	if failures==0: print("INK_PLAYER_MOVEMENT_PASS")
	quit(0 if failures==0 else 1)

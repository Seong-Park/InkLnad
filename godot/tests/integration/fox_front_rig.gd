extends SceneTree

var failures := 0

func check(condition: bool,message: String) -> void:
	if not condition:
		failures += 1
		print("FAIL ",message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	create_timer(25.0).timeout.connect(func(): print("FAIL rig watchdog"); quit(1))
	var rig: FoxFrontRig = load("res://scenes/characters/FoxFrontRig.tscn").instantiate()
	root.add_child(rig)
	await process_frame
	check(rig.bones.size() == 22,"all articulated bones")
	check(rig.meshes.size() >= 18,"separate textured parts")
	for mesh in rig.meshes.values():
		check(mesh.texture == rig.MASTER,"shared original texture")
		check(mesh.get_bone_count() == 22,"bound skeleton")
	for state in [&"idle",&"walk",&"attack"]:
		rig.play_state(state)
		rig.animator.advance(0.36)
		check(rig.scale == Vector2.ONE,"no state scale correction")
		check(rig.bones.head.scale == Vector2.ONE,"rigid head scale")
		check(rig.animator.has_animation(state),"authored animation")
	rig.neutral()
	for bone in rig.bones.values():
		check(bone.position == bone.rest.origin and is_zero_approx(bone.rotation),"neutral rest reconstruction")
	rig.play_state(&"attack")
	await create_timer(0.95).timeout
	check(rig.current_state == &"idle","attack returns to idle")
	print("RIG_CHECK failures=",failures)
	print("INK_FOX_FRONT_RIG_PASS" if failures == 0 else "INK_FOX_FRONT_RIG_FAIL")
	quit(0 if failures == 0 else 1)

extends SceneTree

var failures: int = 0
var game: JourneyController

func check(value: bool, label: String) -> void:
	if not value:
		failures += 1
		print("FAIL ",label)

func _initialize() -> void:
	call_deferred("run")

func enemy(point: Vector2) -> EnemyController:
	var result: EnemyController = game.area.enemy_scene.instantiate()
	result.rules = game.rules
	result.player = game.player
	result.area = game.area
	game.area.add_child(result)
	result.configure(StringName("skill-test-%d" % result.get_instance_id()),&"blot",100.0)
	result.position = point
	result.protection = 0.0
	result.set_physics_process(false)
	game.area.enemies.append(result)
	return result

func ready_skill() -> void:
	game.spells.reset()
	game.player.casting = false
	game.draw_controller.skill_locked = false
	game.draw_controller.cancel()
	game.draw_controller.ink.configure(100.0,100.0/3.5,0.5)

func run() -> void:
	create_timer(40.0).timeout.connect(func(): print("FAIL skill watchdog"); quit(1))
	game = load("res://scenes/gameplay/Main.tscn").instantiate()
	game.save_path_override = "user://tests/player-skills/profile.json"
	root.add_child(game)
	await process_frame
	check(game.start_new_game().ok,"isolated new game")
	game.set_physics_process(false)
	game.player.set_physics_process(false)
	for existing in game.area.enemies:
		existing.free()
	game.area.enemies.clear()
	game.player.position = Vector2(1050,950)
	var close: EnemyController = enemy(Vector2(1090,950))
	var second: EnemyController = enemy(Vector2(1140,950))
	var far: EnemyController = enemy(Vector2(1370,950))
	var origin: Vector2 = game.player.global_position
	await physics_frame
	for id in ["paint","flower","spring"]:
		check(game.ui._views.hud.get_node_or_null({"paint":"PaintSkill","flower":"FlowerSkill","spring":"SpringSkill"}[id]) != null,id+" HUD button exists")
	ready_skill()
	game._cast_skill("flower")
	check(is_equal_approx(game.draw_controller.ink.current,80.0),"flower exact ink cost")
	check(game.player.casting and game.spells.auras[0].id == "flower","flower caster effect and animation")
	game.spells.tick(0.2,game.area.enemies)
	check(close.hp == 100.0,"windup deals no damage")
	game.spells.tick(0.5,game.area.enemies)
	check(close.hp == 76.0 and second.hp == 76.0 and far.hp == 100.0,"flower multi target range")
	game.spells.tick(0.1,game.area.enemies)
	check(close.hp == 76.0,"flower hits each enemy once")
	check(game.spells.impacts.size() == 2 and game.spells.impacts[0].id == "flower","flower victim effects")
	game.player.casting = false
	game._cast_skill("flower")
	check(game.draw_controller.ink.current == 80.0,"cooldown rejects without spending ink")
	game._update_ui()
	check(game.ui._flower_skill.disabled and "초" in game.ui._flower_skill.get_child(0).text,"cooldown on HUD")
	ready_skill()
	close.hp = 100.0
	second.hp = 100.0
	game._cast_skill("paint")
	game.spells.tick(0.55,game.area.enemies)
	check(close.hp == 72.0 and second.hp == 100.0,"projectile hits nearest enemy only")
	check(game.spells.bullet.is_empty() and game.spells.impacts[0].id == "paint","paint consumed with victim splash")
	ready_skill()
	close.hp = 100.0
	second.hp = 100.0
	game._cast_skill("spring")
	for delta in [0.31,0.5,0.5,1.0]:
		game.spells.tick(delta,game.area.enemies)
	check(close.hp == 70.0 and second.hp == 70.0 and far.hp == 100.0,"spring three spaced pulses in range")
	check(game.spells.impacts[-1].id == "spring","spring victim ripple")
	ready_skill()
	game.draw_controller.ink.current = 5.0
	game._cast_skill("spring")
	check(game.draw_controller.ink.current == 5.0 and not game.player.casting and game.spells.auras.is_empty(),"insufficient ink rejects whole cast")
	ready_skill()
	game.pause(true)
	game._cast_skill("paint")
	check(game.spells.auras.is_empty(),"paused cast rejected")
	game.pause(false)
	ready_skill()
	game._update_ui()
	var button: Control = game.ui._flower_skill
	var touch := InputEventScreenTouch.new()
	touch.index = 4
	touch.position = button.get_global_rect().get_center()
	touch.pressed = true
	root.push_input(touch,true)
	check(game.draw_controller.ink.current == 80.0 and game.draw_controller.skill_locked,"touch button starts actual skill")
	touch.pressed = false
	root.push_input(touch,true)
	game.draw_controller.handle_pointer({"phase":&"press","screen":Vector2(600,400)})
	check(not game.draw_controller.ink.holding,"skill windup blocks brush press")
	game.player.casting = false
	game.draw_controller.tick(0.01)
	check(not game.draw_controller.skill_locked,"cast completion releases input lock")
	ready_skill()
	# A local wall lies between the caster and both near enemies.
	game.area._wall(Rect2(1070,920,8,60))
	await physics_frame
	close.hp = 100.0
	game.spells.begin("flower",origin,close.global_position)
	game.spells.tick(0.8,game.area.enemies)
	check(close.hp == 100.0,"flower cannot damage through wall")
	game.spells.reset()
	game.spells.begin("paint",origin,close.global_position)
	game.spells.tick(0.6,game.area.enemies)
	check(close.hp == 100.0 and game.spells.bullet.is_empty(),"projectile stops at wall")
	game.spells.reset()
	game.spells.begin("spring",origin,close.global_position)
	game.spells.tick(0.4,game.area.enemies)
	check(close.hp == 100.0,"spring cannot be placed through wall for damage")
	game.spells.cancel()
	check(game.spells.spring.is_empty() and game.spells.impacts.is_empty() and game.spells.wave.age < 0.0,"area cancellation removes effects")
	if "--visual" in OS.get_cmdline_user_args():
		for body in game.area.bodies:
			body.free()
		game.area.bodies.clear()
		game.player.position = Vector2(1050,950)
		game.camera.follow(1.0)
		DirAccess.make_dir_recursive_absolute("C:/workspace/Ink-Land/docs/verification/player-skills/captures")
		for id in ["paint","flower","spring"]:
			ready_skill()
			close.hp = 100.0
			game._cast_skill(id)
			game.spells.tick(0.4 if id == "paint" else 0.5,game.area.enemies)
			game._update_ui()
			await process_frame
			await RenderingServer.frame_post_draw
			check(root.get_texture().get_image().save_png("C:/workspace/Ink-Land/docs/verification/player-skills/captures/"+id+".png") == OK,"save visual "+id)
	game.free()
	if failures == 0:
		print("INK_PLAYER_SKILLS_PASS")
	quit(0 if failures == 0 else 1)

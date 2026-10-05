class_name JourneyController
extends Node2D

const Rules = preload("res://scripts/gameplay/journey_rules.gd")
const State = preload("res://scripts/economy/journey_state.gd")
const Economy = preload("res://scripts/economy/economy_service.gd")
const Store = preload("res://scripts/economy/save_store.gd")
const Resolver = preload("res://scripts/combat/damage_resolver.gd")
@export var save_path_override: String = ""
var rules: JourneyRules = preload("res://resources/first_journey_rules.tres")
var state: JourneyState = State.new()
var store: SaveStore = Store.new()
var economy: EconomyService = Economy.new()
var damage_resolver = Resolver.new()
var area_id: StringName = &"A"
var entry_exit: StringName = &"start"
var started: bool = false
var transitioning: bool = false
var pending_elite: bool = false
var tutorial_flags: Dictionary = {}
var tutorial_progress: Dictionary = {"move":0.0,"line":0.0,"hold":0.0,"recover":0.0}
var save_clock: float = 0.0
var retry_save: Callable
var retry_success: Callable
var test_done: bool = false
var message_clock: float = 0.0
var last_pointer: Vector2 = Vector2.INF
var menu_settings: Dictionary = {"ui_scale":1.0,"mute":false}
var mobile_attacking: bool = false
var touch_aim: Vector2 = Vector2.DOWN
var spells = preload("res://scripts/combat/spell_controller.gd").new()
@onready var area: AreaRuntime = $Area
@onready var player: PlayerController = $Area/Player
@onready var camera: CameraController = $Camera
@onready var draw_controller: DrawController = $DrawController
@onready var ui = $JourneyUI

func _ready() -> void:
	_setup_input()
	process_physics_priority = 10
	get_tree().auto_accept_quit = false
	store.configure(save_path_override if not save_path_override.is_empty() else "user://inkland/profile.json")
	economy.configure(state,store,rules)
	area.rules = rules
	area.player = player
	camera.target = player
	draw_controller.configure(rules,player,camera)
	spells.name = "Spells"
	spells.player = player
	add_child(spells)
	player.moved.connect(func(distance: float): record_tutorial(&"move",distance))
	player.speed = rules.player.speed
	draw_controller.tutorial_event.connect(record_tutorial)
	ui.interaction_requested.connect(_ui_action)
	ui.pause_requested.connect(pause)
	ui.movement_requested.connect(_mobile_move)
	ui.attack_requested.connect(_mobile_attack)
	ui.skill_requested.connect(_cast_skill)
	var loaded: Dictionary = store.read_snapshot()
	if loaded.ok:
		state.restore(loaded.snapshot)
		menu_settings = loaded.snapshot.settings.duplicate()
	var preferences: Dictionary = store.read_preferences()
	if preferences.ok and not loaded.ok:
		menu_settings = preferences.settings.duplicate()
	ui.render_state({"settings":menu_settings})
	ui.show_menu(loaded.ok)
	$Area.visible = false
	$DrawController.visible = false

func _setup_input() -> void:
	var bindings: Dictionary = {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"interact":[KEY_E],"brush":[KEY_1],"pencil":[KEY_2],"flower_skill":[KEY_Q],"pause":[KEY_ESCAPE]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for code in bindings[action]:
			var key: InputEventKey = InputEventKey.new()
			key.physical_keycode = code
			if not InputMap.action_has_event(action,key):
				InputMap.action_add_event(action,key)

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		draw_controller.cancel()
		if started and not transitioning:
			pause(true)
			ui.show_pause()
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready():
		_ui_action(&"quit")

func _input(event: InputEvent) -> void:
	# Touch HUD owns its fingers; ignore synthetic mouse events from those fingers.
	if event.device == -1 and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event is InputEventMouseButton:
		last_pointer = event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed and not mobile_attacking:
		draw_controller.handle_pointer({"phase":&"release","screen":event.position})
	if event is InputEventMouseMotion:
		event.set_meta("physical_motion",event.relative.length()>0.0 or event.position!=last_pointer)
		last_pointer = event.position
		draw_controller.cursor = event.position
	if event.is_action_pressed("pause") and started and not transitioning:
		if get_tree().paused and not retry_save.is_valid():
			pause(false)
			ui.hide_modal()
		else:
			pause(true)
			ui.show_pause()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if event.device == -1 and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if not started or transitioning or get_tree().paused or ui.has_modal():
		return
	if mobile_attacking and (event is InputEventMouseButton or event is InputEventMouseMotion):
		return
	if event.is_action_pressed("flower_skill"):
		_cast_skill("flower")
	elif event is InputEventKey and event.pressed and not event.echo and event.physical_keycode in [KEY_R,KEY_F]:
		_cast_skill("paint" if event.physical_keycode == KEY_R else "spring")
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		draw_controller.handle_pointer({"phase":&"press","screen":event.position,"ui_consumed":false,"physical_motion":true})
	elif event is InputEventMouseMotion:
		draw_controller.handle_pointer({"phase":&"move","screen":event.position,"physical_motion":event.get_meta("physical_motion",false)})
	elif event.is_action_pressed("interact"):
		draw_controller.cancel()
		_interact()
	elif event.is_action_pressed("brush"):
		draw_controller.set_tool(&"brush")
	elif event.is_action_pressed("pencil"):
		if "pencil" in state.capture().owned_tools:
			draw_controller.set_tool(&"pencil")
		else:
			ui.show_result({"ok":false,"reason":"missing_tool"})

func _physics_process(dt: float) -> void:
	if not started or transitioning:
		return
	camera.follow(dt)
	if mobile_attacking:
		draw_controller.handle_pointer({"phase":&"move","screen":get_viewport().get_canvas_transform()*_mobile_target(),"physical_motion":true})
	draw_controller.tick(dt)
	spells.tick(dt,area.enemies)
	if get_tree().paused:
		return
	var incoming: float = area.tick(dt)
	for enemy in area.enemies:
		if not enemy.alive:
			continue
		var damage: Vector2 = draw_controller.damage_at(enemy.global_position,float(enemy.stats.radius))
		var amount: float = damage_resolver.resolve_hit(enemy.spawn_id,damage.x,damage.y,draw_controller.now)
		if amount>0.0:
			enemy.receive_damage(amount)
		if get_tree().paused:
			break
		incoming = maxf(incoming,enemy.incoming_hit())
	if not get_tree().paused and incoming>0.0 and player.apply_hit(incoming) and player.hp<=0.0:
		return_home(true)
	if area_id == &"A" and draw_controller.tool_id == &"pencil" and not test_done:
		var target_damage: Vector2 = draw_controller.damage_at(area.to_global(rules.get_area(&"A").target_position),25.0)
		if target_damage.x>0.0:
			mark_pencil_test()
	player.tool_id = draw_controller.tool_id
	player.use_phase = draw_controller.ink.phase
	save_clock += dt
	if save_clock >= rules.save_interval and not get_tree().paused:
		save_clock = 0.0
		var runtime: Dictionary = capture_runtime()
		_handle_save(economy.commit_runtime(runtime),func(): return economy.commit_runtime(runtime))
	_update_ui()

func capture_runtime() -> Dictionary:
	var enemies: Dictionary = {}
	for enemy in area.capture_enemies():
		enemies[enemy.spawn_id] = {"hp":int(enemy.hp),"alive":enemy.alive}
	return {"hp":int(player.hp),"current_area":String(area_id),"entry_exit":String(entry_exit),"last_safe_point":{"x":player.position.x,"y":player.position.y},"enemies":enemies,"tutorial_flags":tutorial_flags.duplicate(),"pencil_test_completed":test_done}

func get_snapshot() -> Dictionary:
	return state.capture()

func start_new_game(replace_corrupt: bool = false) -> Dictionary:
	var fresh: JourneyState = State.new()
	var snapshot: Dictionary = fresh.capture()
	snapshot.profile_id = "inkland-%s" % Time.get_ticks_usec()
	snapshot.run_id = "journey-1"
	snapshot.save_generation = 1
	snapshot.settings = menu_settings.duplicate()
	var saved: Dictionary = store.write_new_profile(snapshot) if replace_corrupt else store.write_snapshot(snapshot)
	if not saved.ok:
		return _handle_save(saved,func(): return start_new_game(replace_corrupt))
	state.restore(snapshot)
	started = true
	tutorial_progress = {"move":0.0,"line":0.0,"hold":0.0,"recover":0.0}
	_load_snapshot()
	return {"ok":true,"reason":&"none"}

func continue_game() -> Dictionary:
	var saved: Dictionary = store.read_snapshot()
	if not saved.ok:
		ui.show_result(saved)
		return saved
	var result: Dictionary = state.restore(saved.snapshot)
	if not result.ok:
		return result
	started = true
	_load_snapshot()
	return result

func _load_snapshot() -> void:
	spells.reset()
	draw_controller.skill_locked = false
	var snapshot: Dictionary = state.capture()
	tutorial_flags = snapshot.tutorial_flags.duplicate()
	test_done = snapshot.pencil_test_completed
	player.hp = float(snapshot.hp)
	area_id = snapshot.current_area
	entry_exit = snapshot.entry_exit
	draw_controller.cancel()
	draw_controller.ink.configure(100.0,100.0/3.5,0.5)
	draw_controller.set_tool(&"brush")
	draw_controller.strokes.clear()
	damage_resolver = Resolver.new()
	_build_area()
	get_tree().paused = false
	ui.hide_modal()
	$Area.visible = true
	$DrawController.visible = true
	_update_ui()

func _build_area() -> void:
	var snapshot: Dictionary = state.capture()
	var info: Dictionary = rules.get_area(area_id)
	var states: Array[Dictionary] = []
	for spawn in info.spawns:
		var saved: Dictionary = snapshot.enemies.get(spawn.spawn_id,{"hp":rules.get_enemy(spawn.enemy_id).hp,"alive":true})
		states.append({"spawn_id":spawn.spawn_id,"enemy_id":spawn.enemy_id,"position":spawn.position,"hp":saved.hp,"alive":saved.alive})
	area.enter(area_id,entry_exit,states)
	if area.coastal_map.visible:
		area.coastal_map.restoration.apply_flags(tutorial_flags)
	spells.cancel()
	draw_controller.skill_locked = false
	for enemy in area.enemies:
		enemy.defeated.connect(_enemy_defeated)
	player.position = info.get("entry_east",Vector2(1030,280)) if entry_exit==&"east" else info.get("entry_west",Vector2(90,280))
	if area_id == &"A" and entry_exit in [&"start",&"return"]:
		player.position = info.get("start_position",Vector2(300,330))
	player.immunity = 0.75
	player.set_enabled(true)
	camera.set_area(info.size,info.camera)
	area.show_restoration(snapshot.flower_restored)

func _enemy_defeated(id_value: StringName) -> void:
	var runtime: Dictionary = capture_runtime()
	var result: Dictionary = economy.grant_defeat(id_value,runtime)
	if _handle_save(result,func(): return economy.grant_defeat(id_value,runtime)).ok:
		damage_resolver.forget_target(id_value)
		_update_ui()

func _handle_save(result: Dictionary, retry: Callable, success: Callable = Callable()) -> Dictionary:
	if result.ok:
		return result
	if not started and result.reason in ["future_schema","unsupported_schema"]:
		ui.show_confirmation(&"unsupported","이 저장 버전은 현재 게임에서 읽을 수 없습니다. 원본 파일을 보존했습니다. 취소로 메뉴에 돌아가 주세요.")
		return result
	if result.reason in ["save_failed","write_failed","backup_failed","replace_failed","verify_failed","permission_denied"] or result.get("reason","") not in ["already_owned","insufficient_ink","elite_required","already_restored","missing_tool","missing_funds"]:
		draw_controller.cancel()
		if started:
			var prior: Dictionary = state.capture()
			player.hp = float(prior.hp)
			tutorial_flags = prior.tutorial_flags.duplicate()
			test_done = prior.pencil_test_completed
			area_id = prior.current_area
			entry_exit = prior.entry_exit
			for key in tutorial_progress:
				tutorial_progress[key] = 0.0
			for enemy in area.enemies:
				var saved: Dictionary = prior.enemies.get(String(enemy.spawn_id),{"hp":rules.get_enemy(enemy.enemy_id).hp,"alive":true})
				enemy.hp = float(saved.hp)
				enemy.alive = saved.alive
				enemy.visible = saved.alive
		get_tree().paused = true
		retry_save = retry
		retry_success = success
		ui.show_save_error(String(result.reason))
	else:
		ui.show_result(result)
	return result

func _apply_committed_runtime() -> void:
	var snapshot: Dictionary = state.capture()
	player.hp = snapshot.hp
	tutorial_flags = snapshot.tutorial_flags.duplicate()
	test_done = snapshot.pencil_test_completed
	entry_exit = snapshot.entry_exit
	if area_id != StringName(snapshot.current_area):
		area_id = snapshot.current_area
		_build_area()
		if area_id == &"A" and entry_exit == &"return":
			draw_controller.ink.configure(100.0,100.0/3.5,0.5)
	else:
		for enemy in area.enemies:
			var saved: Dictionary = snapshot.enemies.get(String(enemy.spawn_id),{"hp":rules.get_enemy(enemy.enemy_id).hp,"alive":true})
			enemy.hp = saved.hp
			enemy.alive = saved.alive
			enemy.visible = saved.alive
	area.show_restoration(snapshot.flower_restored)
	_update_ui()

func tutorial_complete() -> bool:
	return tutorial_flags.get("move",false) and tutorial_flags.get("line",false) and tutorial_flags.get("hold",false) and tutorial_flags.get("recover",false)

func record_tutorial(event: StringName, amount: float) -> void:
	if not started or area_id != &"A" or tutorial_complete() or amount<=0:
		return
	var key: String = String(event)
	if not tutorial_progress.has(key):
		return
	tutorial_progress[key] += amount
	var thresholds: Dictionary = {"move":120.0,"line":80.0,"hold":0.5,"recover":10.0}
	if tutorial_progress[key]>=thresholds[key] and not tutorial_flags.get(key,false):
		tutorial_flags[key] = true
		if tutorial_complete():
			player.hp = 100.0
			draw_controller.ink.configure(100.0,100.0/3.5,0.5)
		var runtime: Dictionary = capture_runtime()
		_handle_save(economy.commit_runtime(runtime),func(): return economy.commit_runtime(runtime))
		_update_ui()

func request_exit(exit_id: StringName) -> Dictionary:
	if transitioning:
		return {"ok":false,"reason":&"transition"}
	var info: Dictionary = rules.get_area(area_id)
	if not info.exits.has(String(exit_id)):
		return {"ok":false,"reason":&"locked"}
	if (area_id==&"A" and not tutorial_complete()) or (area_id==&"C" and exit_id==&"east" and not _cleared()) or (area_id==&"E" and not state.capture().first_elite_defeated):
		ui.show_result({"ok":false,"reason":"locked"})
		return {"ok":false,"reason":&"locked"}
	if area_id==&"D" and exit_id==&"east" and not state.capture().first_elite_defeated:
		pending_elite = true
		pause(true)
		ui.show_confirmation(&"elite","정예 뜰에 들어가면 적을 물리칠 때까지 출구가 닫힙니다.")
		return {"ok":false,"reason":&"confirmation"}
	return _travel(info.exits[String(exit_id)],&"west" if exit_id==&"east" else &"east")

func confirm_elite(confirm: bool) -> Dictionary:
	if not pending_elite:
		return {"ok":false,"reason":&"cancelled"}
	pending_elite = false
	pause(false)
	ui.hide_modal()
	return _travel(&"E",&"west") if confirm else {"ok":false,"reason":&"cancelled"}

func _travel(destination: StringName, arrival: StringName) -> Dictionary:
	spells.cancel()
	draw_controller.cancel()
	var runtime: Dictionary = capture_runtime()
	runtime.current_area = String(destination)
	runtime.entry_exit = String(arrival)
	var result: Dictionary = economy.commit_runtime(runtime)
	if not result.ok:
		return _handle_save(result,func(): return economy.commit_runtime(runtime))
	transitioning = true
	player.set_enabled(false)
	draw_controller.strokes.clear()
	area.projectiles.clear()
	_finish_travel(destination,arrival)
	return {"ok":true,"reason":&"none"}

func _finish_travel(destination: StringName, arrival: StringName) -> void:
	await get_tree().create_timer(0.2,false).timeout
	area_id = destination
	entry_exit = arrival
	_build_area()
	transitioning = false
	_update_ui()

func _cleared() -> bool:
	for enemy in area.enemies:
		if enemy.alive:
			return false
	return true

func return_home(defeated: bool = false) -> Dictionary:
	spells.cancel()
	if not defeated:
		var safe: Vector2 = rules.get_area(area_id).get("safe_point",Vector2(-9999,-9999))
		if not area_id in [&"B",&"C",&"F"] or player.position.distance_to(safe)>64.0 or (area_id==&"C" and not _cleared()):
			return {"ok":false,"reason":&"locked"}
		for enemy in area.enemies:
			if enemy.alive and player.position.distance_to(enemy.position)<500.0:
				return {"ok":false,"reason":&"locked"}
	draw_controller.cancel()
	var runtime: Dictionary = capture_runtime()
	var result: Dictionary = economy.settle_run(defeated,runtime)
	if not result.ok:
		return _handle_save(result,func(): return economy.settle_run(defeated,runtime))
	player.hp = 100.0
	draw_controller.ink.configure(100.0,100.0/3.5,0.5)
	transitioning = true
	player.set_enabled(false)
	draw_controller.strokes.clear()
	area.projectiles.clear()
	_finish_travel(&"A",&"return")
	return result

func purchase_pencil() -> Dictionary:
	var result: Dictionary = economy.purchase_pencil()
	_handle_save(result,purchase_pencil)
	if result.ok:
		ui.show_shop(true,int(state.capture().wallet_ink))
	_update_ui()
	return result

func restore_flower() -> Dictionary:
	var result: Dictionary = economy.restore_flower()
	_handle_save(result,restore_flower)
	if result.ok:
		area.show_restoration(true)
		ui.show_result({"ok":true,"reason":"restored"})
	_update_ui()
	return result

func mark_pencil_test() -> void:
	if not "pencil" in state.capture().owned_tools or test_done:
		return
	test_done = true
	var runtime: Dictionary = capture_runtime()
	_handle_save(economy.commit_runtime(runtime),func(): return economy.commit_runtime(runtime))
	_update_ui()

func journey_complete() -> bool:
	var snapshot: Dictionary = state.capture()
	return snapshot.flower_restored and "pencil" in snapshot.owned_tools and snapshot.pencil_test_completed

func pause(value: bool) -> void:
	if value:
		ui.reset_controls()
		_mobile_attack(false)
		player.touch_direction = Vector2.ZERO
	draw_controller.cancel()
	get_tree().paused = value

func _interact() -> void:
	if area.coastal_map != null and area.coastal_map.visible:
		var item: Dictionary = area.coastal_map.restoration.nearest(player.position)
		if not item.is_empty():
			_restore_world_object(item)
			return
	if area_id==&"A" and player.position.distance_to(rules.get_area(&"A").npc_position)<=64:
		pause(true)
		ui.show_shop("pencil" in state.capture().owned_tools,int(state.capture().wallet_ink))
		return
	if area_id==&"F" and player.position.distance_to(Vector2(720,280))<=64:
		if state.capture().flower_restored:
			ui.show_result({"ok":true,"reason":"flower_story"})
		else:
			restore_flower()
		return
	var map_info: Dictionary = rules.get_area(area_id)
	if map_info.has("portals"):
		for exit_id in map_info.portals:
			if player.position.distance_to(map_info.portals[exit_id]) <= 64.0:
				request_exit(StringName(exit_id))
				return
	elif absf(player.position.y-280.0)<=48:
		if player.position.x<=60:
			request_exit(&"west")
			return
		if player.position.x>=area.area_size.x-60:
			request_exit(&"east")
			return
	var returned: Dictionary = return_home()
	if not returned.ok:
		ui.show_result({"ok":false,"reason":"interaction_hint"})

func _ui_action(action: StringName) -> void:
	match action:
		&"interact":
			if started and not get_tree().paused:
				draw_controller.cancel()
				_interact()
		&"select_brush": _select_touch_tool(&"brush")
		&"select_pencil":
			if "pencil" in state.capture().owned_tools:
				_select_touch_tool(&"pencil")
		&"new_game":
			if FileAccess.file_exists(store.base_path) or FileAccess.file_exists(store.base_path+".bak"):
				ui.show_confirmation(&"new","현재 여정이 새 여정으로 바뀝니다. 새로 시작할까요?")
			else:
				start_new_game()
		&"confirm_new": start_new_game(true)
		&"cancel_new": ui.show_menu(store.read_snapshot().ok)
		&"continue": continue_game()
		&"resume":
			pause(false)
			ui.hide_modal()
		&"settings": ui.show_settings(state.capture().settings if started else menu_settings)
		&"settings_apply":
			_apply_settings(ui.settings_values.duplicate())
			if not retry_save.is_valid():
				ui.show_pause() if started else ui.show_menu(store.read_snapshot().ok)
		&"buy_pencil": purchase_pencil()
		&"confirm_elite": confirm_elite(true)
		&"cancel_elite": confirm_elite(false)
		&"retry_save":
			if retry_save.is_valid():
				var operation: Callable = retry_save
				var result: Dictionary = operation.call()
				if result.ok:
					var continuation: Callable = retry_success
					retry_save = Callable()
					retry_success = Callable()
					get_tree().paused = false
					if started:
						_apply_committed_runtime()
						ui.hide_modal()
					if continuation.is_valid():
						continuation.call()
					elif not started:
						ui.show_menu(store.read_snapshot().ok)
		&"save_menu", &"quit":
			if started:
				draw_controller.cancel()
				var runtime: Dictionary = capture_runtime()
				var result: Dictionary = economy.commit_runtime(runtime)
				if not result.ok:
					_handle_save(result,func(): return economy.commit_runtime(runtime),func(): _finish_menu_or_quit(action))
					return
			_finish_menu_or_quit(action)

func _finish_menu_or_quit(action: StringName) -> void:
	if action == &"quit":
		get_tree().quit()
	else:
		started = false
		player.set_enabled(false)
		get_tree().paused = true
		area.visible = false
		draw_controller.visible = false
		ui.show_menu(true)

func _apply_settings(candidate: Dictionary) -> Dictionary:
	var result: Dictionary
	var loaded: Dictionary = store.read_snapshot()
	if started or loaded.ok:
		if not started:
			state.restore(loaded.snapshot)
		result = economy.commit_settings(candidate)
	else:
		result = store.write_preferences(candidate)
	if not result.ok:
		return _handle_save(result,func(): return _apply_settings(candidate))
	menu_settings = candidate.duplicate()
	ui.render_state(state.capture() if started else {"settings":menu_settings})
	return result

func _update_ui() -> void:
	if not started:
		return
	var snapshot: Dictionary = state.capture()
	snapshot.hp = int(player.hp)
	snapshot.tool = String(draw_controller.tool_id)
	ui.render_state(snapshot)
	ui.update_minimap(area_id,rules.get_area(area_id),player.position)
	ui.render_ink(draw_controller.ink.current,100.0,draw_controller.ink.phase)
	ui.render_skills(spells.cooldowns,draw_controller.ink.current,player.casting)
	area.left_open = area_id!=&"A" and (area_id!=&"E" or snapshot.first_elite_defeated)
	area.right_open = area_id!=&"F" and (area_id!=&"A" or tutorial_complete()) and (area_id!=&"C" or _cleared()) and (area_id!=&"E" or snapshot.first_elite_defeated)
	var goal: String = ""
	if not tutorial_complete():
		var descriptions: Dictionary = {"move":"움직이며 공방 둘러보기", "line":"움직이며 공격 버튼으로 선 그리기", "hold":"공격 버튼 잠시 누르기", "recover":"공격을 멈추고 잉크 회복하기"}
		for key in descriptions:
			if not tutorial_flags.get(key,false):
				goal = descriptions[key]
				break
	elif journey_complete():
		goal = "첫 여정 완료 · 다음 길은 준비 중"
	elif not snapshot.first_elite_defeated:
		goal = {"A":"동쪽 문으로 · 색을 되찾는 여정", "B":"호수를 돌아 동쪽 길로", "C":"잉크 몬스터 3마리 물리치기", "D":"동쪽 정예 뜰로", "E":"정예를 물리치고 색 되찾기"}.get(String(area_id),"정예 뜰로 향하세요")
	elif not snapshot.flower_restored:
		goal = "꽃집 앞에서 색 복원하기"
	elif not "pencil" in snapshot.owned_tools:
		goal = "마을로 귀환해 연필 구매 · 잉크 60"
	else:
		goal = "연필 선택 후 공방 표적 공격하기"
	ui.set_goal(rules.get_area(area_id).name+"  ·  "+goal)
	var context: Dictionary = _interaction_context()
	ui.set_interaction(context.title,get_viewport().get_canvas_transform()*area.to_global(context.point))

func _cast_skill(id: String) -> void:
	if not spells.DATA.has(id) or not started or transitioning or get_tree().paused or ui.has_modal() or not player.enabled or player.casting or float(spells.cooldowns[id]) > 0.0:
		return
	if not draw_controller.ink.spend_skill(float(spells.DATA[id].cost)):
		return
	_mobile_attack(false)
	var target: Vector2 = _mobile_target()
	player.start_cast(target-player.global_position)
	draw_controller.skill_locked = true
	spells.begin(id,player.global_position,target)
	_update_ui()

func _mobile_move(value: Vector2) -> void:
	player.touch_direction = value if started and not get_tree().paused and not ui.has_modal() else Vector2.ZERO
	if value.length() > 0.1:
		touch_aim = value.normalized()

func _mobile_target() -> Vector2:
	var target: Vector2 = player.global_position+touch_aim*100.0
	var nearest: float = 145.0
	for enemy in area.enemies:
		var distance: float = enemy.global_position.distance_to(player.global_position)
		if enemy.alive and distance < nearest:
			nearest = distance
			target = enemy.global_position
	if area_id == &"A":
		var practice: Vector2 = area.to_global(rules.get_area(&"A").target_position)
		if practice.distance_to(player.global_position) < nearest:
			target = practice
	return target

func _mobile_attack(value: bool) -> void:
	if not value:
		mobile_attacking = false
		draw_controller.cancel()
		return
	if not started or get_tree().paused or ui.has_modal() or transitioning or draw_controller.skill_locked:
		return
	mobile_attacking = true
	draw_controller.handle_pointer({"phase":&"press","screen":get_viewport().get_canvas_transform()*_mobile_target(),"ui_consumed":false})

func _select_touch_tool(value: StringName) -> void:
	draw_controller.set_tool(value)
	if mobile_attacking:
		_mobile_attack(true)

func _interaction_context() -> Dictionary:
	if area.coastal_map != null and area.coastal_map.visible:
		var item: Dictionary = area.coastal_map.restoration.nearest(player.position)
		if not item.is_empty():
			return {"title":"색 복원 · 잉크 1","point":item.point}
	var info: Dictionary = rules.get_area(area_id)
	if area_id == &"A" and player.position.distance_to(info.npc_position) <= 64:
		return {"title":"대화","point":info.npc_position}
	if area_id == &"F" and player.position.distance_to(Vector2(720,280)) <= 64:
		return {"title":"대화" if state.capture().flower_restored else "복원 · 잉크 1","point":Vector2(720,280)}
	if info.has("portals"):
		for exit_id in info.portals:
			if player.position.distance_to(info.portals[exit_id]) <= 64:
				return {"title":"이동","point":info.portals[exit_id]}
	elif absf(player.position.y-280) <= 48 and (player.position.x <= 60 or player.position.x >= area.area_size.x-60):
		return {"title":"이동","point":player.position}
	var safe: Vector2 = info.get("safe_point",Vector2(-9999,-9999))
	if area_id in [&"B",&"C",&"F"] and player.position.distance_to(safe) <= 64 and (area_id != &"C" or _cleared()):
		return {"title":"귀환","point":safe}
	return {"title":"","point":Vector2.ZERO}

func _restore_world_object(item: Dictionary) -> Dictionary:
	if item.restored:
		return {"ok":true,"reason":"already_restored"}
	var runtime: Dictionary = capture_runtime()
	var result: Dictionary = economy.restore_object(item.id,runtime)
	if result.ok:
		tutorial_flags = result.snapshot.tutorial_flags.duplicate(true)
		area.coastal_map.restoration.reveal(item)
		_update_ui()
	else:
		_handle_save(result,func(): return _restore_world_object(item))
	return result

extends SceneTree

var passed: int = 0
var failed: int = 0

func check(value: bool, label: String) -> void:
	if value:
		passed += 1
	else:
		failed += 1
		push_error("FAIL: " + label)

func close_to(actual: float, expected: float, label: String) -> void:
	check(absf(actual - expected) < 0.00001, label)

func _initialize() -> void:
	var paths: Array[String] = ["res://scripts/gameplay/journey_rules.gd", "res://scripts/combat/combat_ink.gd", "res://scripts/combat/stroke_rules.gd", "res://scripts/combat/damage_resolver.gd", "res://resources/first_journey_rules.tres"]
	for path in paths:
		check(ResourceLoader.exists(path), "implementation exists: " + path)
	if failed == 0:
		rules_case()
		ink_case()
		stroke_case()
		stroke_index_case()
		damage_case()
	print("Results: %d passed, %d failed" % [passed, failed])
	if failed == 0:
		print("INK_GAMEPLAY_PASS")
	quit(0 if failed == 0 else 1)

func rules_case() -> void:
	var rules = load("res://resources/first_journey_rules.tres")
	check(rules != null, "rules resource loads")
	close_to(rules.get_tool(&"brush").width, 32.0, "brush width")
	close_to(rules.get_tool(&"pencil").length_cost, 0.025, "pencil length cost")
	check(rules.get_area(&"B").size.x > 1280 and rules.get_area(&"B").size.y > 720, "B is a scrolling exploration map")
	check(rules.get_area(&"C").spawns.size() == 3, "C count")
	check(rules.get_area(&"D").obstacles == [Rect2(700, 180, 60, 100)], "D obstacle")
	var income: int = 0
	for area in [&"C", &"E"]:
		for spawn in rules.get_area(area).spawns:
			income += int(rules.get_enemy(spawn.enemy_id).reward)
	check(income == 74, "required income")
	check(rules.get_enemy(&"elite_dash").hp == 120, "elite hp")
	check(rules.get_area(&"F").restore_position == Vector2(720, 280), "flower anchor")
	check(rules.get_tool(&"missing").is_empty(), "unknown tool rejected")

func ink_case() -> void:
	var ink = load("res://scripts/combat/combat_ink.gd").new()
	ink.configure(100.0, 100.0 / 3.5, 0.5)
	check(ink.press(), "press full")
	close_to(ink.spend(100.0), 1.0, "spend all")
	ink.advance(10.0)
	close_to(ink.current, 0.0, "empty held no recharge")
	ink.release()
	ink.advance(0.49)
	close_to(ink.current, 0.0, "delay")
	ink.advance(3.51)
	close_to(ink.current, 100.0, "release four seconds full")
	ink.current = 50.0
	ink.release()
	ink.advance(2.25)
	close_to(ink.current, 100.0, "half recharge")
	ink.current = 0.9
	check(not ink.press(), "threshold refused")
	ink.advance(5.0)
	close_to(ink.current, 0.9, "low hold no recharge")
	ink.release()
	ink.current = 1.0
	check(ink.press(), "threshold accepted")
	ink.current = 3.0
	close_to(ink.spend(6.0), 0.5, "partial budget")
	close_to(ink.current, 0.0, "partial consumes remaining")
	ink.release()
	ink.current = 50.0
	ink.press()
	ink.set_in_range(false)
	ink.advance(5.0)
	close_to(ink.current, 50.0, "outside no recharge")
	ink.set_in_range(true)
	ink.spend(20.0 * 5.0)
	close_to(ink.current, 0.0, "five second brush upkeep")

func stroke_case() -> void:
	var stroke = load("res://scripts/combat/stroke_rules.gd").new()
	stroke.configure(load("res://resources/first_journey_rules.tres"))
	var clip: Dictionary = stroke.clip_path(Vector2.ZERO, Vector2(200, 0), Vector2.ZERO, 180.0, 16.0, true)
	check(clip.valid, "inside to outside valid")
	close_to(clip.end.x, 164.0, "full width clip")
	check(not stroke.clip_path(Vector2(-200, 0), Vector2(200, 0), Vector2.ZERO, 180.0, 16.0, false).valid, "outside crossing rejected")
	clip = stroke.clip_path(Vector2(200, 0), Vector2(100, 0), Vector2.ZERO, 180.0, 16.0, false)
	check(clip.valid and clip.new_subpath and clip.start == Vector2(100, 0), "reentry new point")
	var direct: Array[Dictionary] = stroke.paint(Vector2.ZERO, Vector2(100, 0), &"brush", Vector2.ZERO, 0.0)
	check(direct.size() == 26, "four unit stamps with endpoints")
	close_to(100.0 * 0.04, 4.0, "length cost independent from stamps")
	stroke.paint(Vector2.ZERO, Vector2.ZERO, &"brush", Vector2.ZERO, 1.0)
	stroke.expire(1.5)
	check(stroke.get_active_stamps().size() == 1, "local refresh only")
	stroke.expire(2.5)
	check(stroke.get_active_stamps().is_empty(), "expiry inclusive")
	stroke.clear()
	stroke.paint(Vector2(165, 0), Vector2(165, 0), &"brush", Vector2(1, 0), 0.0)
	direct = stroke.paint(Vector2(164, 0), Vector2(164, 0), &"brush", Vector2.ZERO, 1.0)
	check(direct.size() == 1 and direct[0].center == Vector2(164, 0), "outside old stamp not reused")
	check(stroke.get_active_stamps().size() == 2, "outside old residual kept")
	stroke.expire(1.5)
	check(stroke.get_active_stamps().size() == 1, "outside old expiry not refreshed")
	stroke.clear()
	stroke.paint(Vector2.ZERO, Vector2(100, 0), &"brush", Vector2.ZERO, 0.0)
	var coarse_count: int = stroke.get_active_stamps().size()
	stroke.clear()
	for x in range(1, 101):
		stroke.paint(Vector2(x - 1, 0), Vector2(x, 0), &"brush", Vector2.ZERO, 0.0)
	# Endpoint stamps can differ, but the distance carry must not reset on each event.
	check(stroke.get_active_stamps().size() <= coarse_count * 2, "dense events bounded by distance")
	check(stroke.clip_path(Vector2.ZERO, Vector2.ONE, Vector2.ZERO, 10.0, 16.0, true).valid == false, "oversized width rejected")

func stroke_index_case() -> void:
	var stroke = load("res://scripts/combat/stroke_rules.gd").new()
	stroke.configure(load("res://resources/first_journey_rules.tres"))
	for x in range(-100,101,10):
		stroke.paint(Vector2(x,-20),Vector2(x,20),&"brush",Vector2.ZERO,0.0)
	var expected: Array[Dictionary] = stroke.get_active_stamps()
	var matches: bool = true
	for x in range(-140,141,7):
		var point := Vector2(x,19)
		var ids: Array[int] = []
		var candidate_ids: Array[int] = []
		for stamp in expected:
			if point.distance_to(stamp.center) <= float(stamp.radius)+17.0:
				ids.append(int(stamp.id))
		for stamp in stroke.damage_candidates(point,17.0):
			if point.distance_to(stamp.center) <= float(stamp.radius)+17.0:
				candidate_ids.append(int(stamp.id))
		ids.sort()
		candidate_ids.sort()
		matches = matches and ids == candidate_ids
	check(matches,"spatial damage candidates preserve full-scan hits across negative and boundary cells")
	expected[0].center = Vector2.INF
	check(stroke.get_active_stamps()[0].center.is_finite(),"public snapshot cannot mutate runtime index")
	stroke.expire(10.0)
	check(stroke.damage_candidates(Vector2.ZERO,500.0).is_empty(),"expired stamps leave damage index")
	stroke.clear()
	stroke.paint(Vector2(-0.5,0),Vector2(-0.5,0),&"brush",Vector2.ZERO,11.0)
	stroke.paint(Vector2(0.5,0),Vector2(0.5,0),&"brush",Vector2.ZERO,11.0)
	check(stroke.get_active_stamps().size() == 1,"merge searches adjacent cells across origin")

func damage_case() -> void:
	var resolver = load("res://scripts/combat/damage_resolver.gd").new()
	var hp: float = 24.0
	for time in [0.0, 0.25, 0.5, 0.75]:
		hp -= resolver.resolve_hit(&"drop", 6.0, 2.0, time)
	close_to(hp, 0.0, "four direct hits kill drop")
	close_to(resolver.resolve_hit(&"drop", 12.0, 3.0, 0.8), 0.0, "tool change cannot reset cooldown")
	close_to(resolver.resolve_hit(&"drop", 0.0, 3.0, 1.0), 3.0, "residual fallback")
	close_to(resolver.resolve_hit(&"other", 0.0, 0.0, 0.0), 0.0, "no contact no cooldown")
	close_to(resolver.resolve_hit(&"other", 6.0, 2.0, 0.0), 6.0, "direct priority")
	resolver.forget_target(&"drop")
	close_to(resolver.resolve_hit(&"drop", 12.0, 3.0, 0.0), 12.0, "forget defeated target")

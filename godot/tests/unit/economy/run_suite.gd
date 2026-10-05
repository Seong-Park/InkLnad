extends SceneTree
const State = preload("res://scripts/economy/journey_state.gd")
const Store = preload("res://scripts/economy/save_store.gd")
const Service = preload("res://scripts/economy/economy_service.gd")
const Rules = preload("res://scripts/gameplay/journey_rules.gd")
var failures = 0

class FailingStore extends Store:
	func write_snapshot(_snapshot: Dictionary) -> Dictionary:
		return {"ok":false, "reason":"injected_failure"}

func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr("ECONOMY FAIL: ", name)

func make_service(label: String, state: JourneyState, fail: bool = false) -> EconomyService:
	var store = FailingStore.new() if fail else Store.new()
	var path = "user://tests/first_journey/economy/" + label + "/profile.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	store.configure(path)
	var service = Service.new()
	service.configure(state, store, Rules.new())
	return service

func kill(service: EconomyService, spawn: String) -> Dictionary:
	return service.grant_defeat(spawn, {"enemies":{spawn:{"alive":false, "hp":0}}})

func _initialize() -> void:
	create_timer(5.0).timeout.connect(func(): printerr("ECONOMY FAIL timeout"); quit(1))
	_run.call_deferred()

func _run() -> void:
	var state = State.new()
	var service = make_service("required", state)
	check(not service.purchase_pencil().ok and not service.restore_flower().ok, "early actions rejected")
	for spawn in ["c01", "c02", "c03", "e01"]:
		check(kill(service, spawn).ok, "kill " + spawn)
	check(state.capture().run_ink == 74, "required income")
	check(kill(service, "e01").ok and state.capture().run_ink == 74, "duplicate reward")
	check(service.restore_flower().ok and not service.restore_flower().ok, "paid restoration once")
	check(service.commit_runtime({"hp":12}).ok, "injured before return")
	check(service.settle_run(false, {}).ok and service.settle_run(false, {}).ok, "return retry")
	check(state.capture().hp == 100, "normal return heals")
	check(state.capture().wallet_ink == 73 and state.capture().run_ink == 0, "settlement once")
	check(service.purchase_pencil().ok and not service.purchase_pencil().ok and state.capture().wallet_ink == 13, "pencil once balance13")
	check(service.commit_runtime({"tutorial_flags":{"move":true}, "pencil_test_completed":true}).ok, "tutorial pencil persist")
	check(service.has_method("commit_settings"), "settings API exists")
	if service.has_method("commit_settings"):
		check(service.commit_settings({"ui_scale":1.25,"mute":true}).ok and state.capture().settings.mute, "settings transaction")
		var settings_before = state.capture()
		check(not service.commit_settings({"ui_scale":1.1,"mute":true}).ok and state.capture() == settings_before, "invalid settings unchanged")
	var before = state.capture()
	var failed = make_service("fail", state, true)
	check(not failed.commit_runtime({"hp":20}).ok and state.capture() == before, "runtime failure rollback")
	check(not failed.settle_run(true, {"hp":0}).ok and state.capture() == before, "settlement failure rollback")
	check(not service.commit_runtime({"enemies":{"c01":{"alive":true,"hp":24}}}).ok and state.capture() == before, "no respawn")
	var all_state = State.new()
	var all_service = make_service("all", all_state)
	for spawn in State.SPAWNS:
		check(kill(all_service, spawn).ok, "all kill " + spawn)
	check(all_state.capture().run_ink == 110, "all income110")
	check(all_service.settle_run(true, {"hp":0}).ok and all_state.capture().hp == 100 and all_state.capture().wallet_ink == 110, "defeat no loss")
	var all_before = all_state.capture()
	var all_failed = make_service("allfail", all_state, true)
	check(not all_failed.purchase_pencil().ok and all_state.capture() == all_before, "funded purchase save failure")
	check(not all_failed.restore_flower().ok and all_state.capture() == all_before, "eligible restoration save failure")
	check(not all_failed.commit_settings({"ui_scale":1.5,"mute":true}).ok and all_state.capture() == all_before, "settings save failure")
	check(all_service.purchase_pencil().ok and all_state.capture().wallet_ink == 50, "all balance50")
	var merged_state = State.new()
	var merged = make_service("merge", merged_state)
	check(merged.commit_runtime({"current_area":"D", "enemies":{"d02":{"alive":true,"hp":30}}}).ok, "damaged room")
	check(merged.commit_runtime({"current_area":"E", "enemies":{"e01":{"alive":true,"hp":100}}}).ok, "next room")
	check(merged_state.capture().enemies.d02.hp == 30, "unloaded room preserved")
	var old = merged_state.capture()
	var fail_merge = make_service("deathfail", merged_state, true)
	var result = fail_merge.grant_defeat("d02", {"enemies":{"d02":{"alive":false,"hp":0}}})
	check(not result.ok and result.snapshot == old and merged_state.capture() == old, "death ledger hp atomic rollback")
	check(not fail_merge.purchase_pencil().ok, "purchase failure")
	var simultaneous = {"c01":{"alive":false,"hp":0}, "c02":{"alive":false,"hp":0}}
	check(merged.grant_defeat("c01", {"enemies":simultaneous}).ok and merged_state.capture().run_ink == 16, "same tick multi-death capture")
	var funded_run = merged_state.capture()
	check(not fail_merge.settle_run(false, {}).ok and merged_state.capture() == funded_run, "funded settlement save failure")
	check(not merged.commit_runtime({"pencil_test_completed":true}).ok and merged_state.capture() == funded_run, "unowned pencil fact rejected")
	check(not merged.commit_runtime({"hp":1.5}).ok and merged_state.capture() == funded_run, "fractional hp rejected")
	check(not merged.commit_runtime({"enemies":{"d02":{"alive":false,"hp":0}}}).ok and merged_state.capture() == funded_run, "death requires reward transaction")
	var precise_state = State.new()
	var precise_service = make_service("fractional", precise_state)
	var coordinate = Vector2(12.0042877197266,12.0664978027344)
	check(precise_service.commit_runtime({"last_safe_point":{"x":coordinate.x,"y":coordinate.y}}).ok, "fractional service commit")
	var precise_store = Store.new()
	precise_store.configure("user://tests/first_journey/economy/fractional/profile.json")
	var disk = precise_store.read_snapshot()
	check(disk.ok and precise_state.capture() == disk.get("snapshot"), "memory uses committed disk canonical snapshot")
	var color_state = State.new()
	var color_service = make_service("colors",color_state)
	check(not color_service.restore_object("color_C_flowerpots_10_10",{}).ok,"restoration requires earned currency")
	check(kill(color_service,"c01").ok,"restoration earns monster ink")
	check(color_service.restore_object("color_C_flowerpots_10_10",{}).ok and color_state.capture().run_ink==7,"restoration spends expedition ink")
	var color_before = color_state.capture()
	check(not color_service.restore_object("color_C_flowerpots_10_10",{}).ok and color_state.capture()==color_before,"restoration cannot double charge")
	var color_fail = make_service("colors-fail",color_state,true)
	check(not color_fail.restore_object("color_D_pine_20_20",{}).ok and color_state.capture()==color_before,"restoration save failure preserves balance and color")
	check(color_service.settle_run(false,{}).ok,"bank remaining monster ink")
	check(color_service.restore_object("color_D_pine_20_20",{}).ok and color_state.capture().wallet_ink==6,"restoration can spend banked monster ink")
	print("ECONOMY PASS" if failures == 0 else "ECONOMY FAILED", " checks complete failures=", failures)
	if failures == 0:
		print("INK_ECONOMY_PASS")
	quit(0 if failures == 0 else 1)

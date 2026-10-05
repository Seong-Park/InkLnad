class_name EconomyService
extends RefCounted

const State = preload("res://scripts/economy/journey_state.gd")
const Store = preload("res://scripts/economy/save_store.gd")
const Rules = preload("res://scripts/gameplay/journey_rules.gd")
signal changed(snapshot: Dictionary)
var _state: JourneyState
var _store: SaveStore
var _rules: JourneyRules

func configure(state: JourneyState, store: SaveStore, rules: JourneyRules) -> void:
	_state = state
	_store = store
	_rules = rules

func _failure(reason: String) -> Dictionary:
	return {"ok":false, "reason":reason, "snapshot":_state.capture()}

func _commit(candidate: Dictionary) -> Dictionary:
	candidate.save_generation += 1
	var valid = State.validate_snapshot(candidate)
	if not valid.ok:
		return _failure(valid.reason)
	var saved = _store.write_snapshot(candidate)
	if not saved.ok:
		return _failure(saved.reason)
	_state.restore(saved.snapshot)
	var snapshot = _state.capture()
	changed.emit(snapshot.duplicate(true))
	return {"ok":true, "reason":"committed", "snapshot":snapshot}

func _runtime(candidate: Dictionary, runtime: Dictionary) -> Dictionary:
	for key in ["hp", "current_area", "entry_exit", "last_safe_point", "tutorial_flags", "pencil_test_completed"]:
		if runtime.has(key):
			candidate[key] = runtime[key]
	if candidate.last_safe_point is Vector2:
		candidate.last_safe_point = {"x":candidate.last_safe_point.x, "y":candidate.last_safe_point.y}
	if runtime.has("enemies"):
		if not runtime.enemies is Dictionary:
			return {"ok":false, "reason":"invalid_enemy"}
		for spawn in runtime.enemies:
			var incoming = runtime.enemies[spawn]
			if not incoming is Dictionary:
				return {"ok":false, "reason":"invalid_enemy"}
			if candidate.enemies.has(spawn) and not candidate.enemies[spawn].alive and incoming.get("alive", true):
				return {"ok":false, "reason":"enemy_respawn"}
			candidate.enemies[spawn] = incoming.duplicate(true)
	if not candidate.current_area in candidate.visited_areas:
		candidate.visited_areas.append(candidate.current_area)
	return State.validate_snapshot(candidate)

func commit_runtime(runtime: Dictionary) -> Dictionary:
	var candidate = _state.capture()
	var captured = _runtime(candidate, runtime)
	if not captured.ok:
		return _failure(captured.reason)
	# A death and its reward must enter the same generation via grant_defeat.
	for spawn in candidate.enemies:
		if not candidate.enemies[spawn].alive and not candidate.granted_reward_keys.has(_reward_key(spawn)):
			return _failure("uncommitted_defeat")
	return _commit(candidate)

func _reward_key(spawn: String) -> String:
	return _state.capture().profile_id + ":" + spawn + ":first_defeat"

func _reward(spawn: String) -> int:
	for area in State.AREAS:
		for entry in _rules.get_area(area).get("spawns", []):
			if entry.spawn_id == spawn:
				return int(_rules.get_enemy(entry.enemy_id).reward)
	return -1

func grant_defeat(spawn_id: StringName, runtime: Dictionary) -> Dictionary:
	var spawn = String(spawn_id)
	if _reward(spawn) < 0:
		return _failure("unknown_spawn")
	var candidate = _state.capture()
	var captured = _runtime(candidate, runtime)
	if not captured.ok:
		return _failure(captured.reason)
	if not candidate.enemies.has(spawn) or candidate.enemies[spawn].get("alive", true) or candidate.enemies[spawn].get("hp", -1) != 0:
		return _failure("defeat_not_captured")
	# One physics capture can contain several deaths: award each exactly once.
	for dead_spawn in candidate.enemies:
		var enemy = candidate.enemies[dead_spawn]
		if not enemy.get("alive", true) and enemy.get("hp", -1) == 0:
			var key = _reward_key(dead_spawn)
			var amount = _reward(dead_spawn)
			if amount < 0:
				return _failure("unknown_spawn")
			if not candidate.granted_reward_keys.has(key):
				candidate.granted_reward_keys.append(key)
				candidate.run_ink += amount
				if dead_spawn == "e01":
					candidate.first_elite_defeated = true
	return _commit(candidate)

func settle_run(_defeated: bool, runtime: Dictionary) -> Dictionary:
	var candidate = _state.capture()
	var captured = _runtime(candidate, runtime)
	if not captured.ok:
		return _failure(captured.reason)
	for spawn in candidate.enemies:
		if not candidate.enemies[spawn].get("alive", true) and not candidate.granted_reward_keys.has(_reward_key(spawn)):
			return _failure("uncommitted_defeat")
	candidate.wallet_ink += candidate.run_ink
	candidate.run_ink = 0
	candidate.current_area = "A"
	candidate.entry_exit = "return"
	candidate.last_safe_point = {"x":180, "y":450}
	candidate.hp = 100
	return _commit(candidate)

func commit_settings(settings: Dictionary) -> Dictionary:
	var candidate = _state.capture()
	candidate.settings = settings.duplicate(true)
	return _commit(candidate)

func purchase_pencil() -> Dictionary:
	var candidate = _state.capture()
	if "pencil" in candidate.owned_tools:
		return _failure("already_owned")
	if candidate.wallet_ink < _rules.pencil_price:
		return _failure("insufficient_ink")
	candidate.wallet_ink -= _rules.pencil_price
	candidate.owned_tools.append("pencil")
	return _commit(candidate)

func restore_flower() -> Dictionary:
	var candidate = _state.capture()
	if candidate.flower_restored:
		return _failure("already_restored")
	if not candidate.first_elite_defeated:
		return _failure("elite_required")
	if candidate.run_ink+candidate.wallet_ink < 1:
		return _failure("insufficient_ink")
	if candidate.run_ink > 0:
		candidate.run_ink -= 1
	else:
		candidate.wallet_ink -= 1
	candidate.flower_restored = true
	return _commit(candidate)

func restore_object(id: String, runtime: Dictionary) -> Dictionary:
	if not id.begins_with("color_"):
		return _failure("invalid_object")
	var candidate: Dictionary = _state.capture()
	var captured: Dictionary = _runtime(candidate,runtime)
	if not captured.ok:
		return _failure(captured.reason)
	if candidate.tutorial_flags.get(id,false):
		return _failure("already_restored")
	if candidate.run_ink+candidate.wallet_ink < 1:
		return _failure("insufficient_ink")
	for spawn in candidate.enemies:
		if not candidate.enemies[spawn].alive and not candidate.granted_reward_keys.has(_reward_key(spawn)):
			return _failure("uncommitted_defeat")
	if candidate.run_ink > 0:
		candidate.run_ink -= 1
	else:
		candidate.wallet_ink -= 1
	candidate.tutorial_flags[id] = true
	return _commit(candidate)

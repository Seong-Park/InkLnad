class_name JourneyState
extends RefCounted

const AREAS = ["A", "B", "C", "D", "E", "F"]
const SPAWNS = {"c01":24, "c02":24, "c03":24, "d01":24, "d02":48, "d03":36, "e01":120}
var _snapshot: Dictionary

func _init() -> void:
	_snapshot = {"schema_version":1, "profile_id":"local", "run_id":"first", "save_generation":0,
		"tutorial_flags":{}, "hp":100, "wallet_ink":0, "run_ink":0, "owned_tools":["brush"],
		"first_elite_defeated":false, "flower_restored":false, "pencil_test_completed":false,
		"visited_areas":["A"], "enemies":{}, "granted_reward_keys":[], "current_area":"A",
		"entry_exit":"start", "last_safe_point":{"x":0, "y":0}, "settings":{"ui_scale":1, "mute":false}}

func capture() -> Dictionary:
	return _snapshot.duplicate(true)

func restore(snapshot: Dictionary) -> Dictionary:
	var result = validate_snapshot(snapshot)
	if result.ok:
		_snapshot = normalize_numbers(snapshot)
	return {"ok":result.ok, "reason":result.reason, "snapshot":capture()}

static func whole_number(value: Variant, maximum: float = 9007199254740991.0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) >= 0 and float(value) <= maximum and floor(float(value)) == float(value)

static func normalize_numbers(value: Variant) -> Variant:
	if value is Dictionary:
		var result = {}
		for key in value:
			result[key] = normalize_numbers(value[key])
		return result
	if value is Array:
		var result = []
		for item in value:
			result.append(normalize_numbers(item))
		return result
	if value is float and is_finite(value) and abs(value) <= 9007199254740991.0 and floor(value) == value:
		return int(value)
	return value

static func validate_snapshot(s: Dictionary) -> Dictionary:
	if not s.has("schema_version") or not whole_number(s.schema_version):
		return {"ok":false, "reason":"invalid_schema"}
	if s.schema_version != 1:
		return {"ok":false, "reason":"future_schema" if s.schema_version > 1 else "unsupported_schema"}
	for key in ["profile_id", "run_id", "entry_exit", "current_area"]:
		if not s.get(key) is String or s[key].is_empty():
			return {"ok":false, "reason":"invalid_structure"}
	for key in ["tutorial_flags", "enemies", "last_safe_point", "settings"]:
		if not s.get(key) is Dictionary:
			return {"ok":false, "reason":"invalid_structure"}
	for key in ["owned_tools", "visited_areas", "granted_reward_keys"]:
		if not s.get(key) is Array:
			return {"ok":false, "reason":"invalid_structure"}
	for key in ["first_elite_defeated", "flower_restored", "pencil_test_completed"]:
		if not s.get(key) is bool:
			return {"ok":false, "reason":"invalid_structure"}
	for key in ["save_generation", "hp", "wallet_ink", "run_ink"]:
		if not whole_number(s.get(key), 100 if key == "hp" else 9007199254740991.0):
			return {"ok":false, "reason":"invalid_number"}
	for key in ["x", "y"]:
		var coordinate = s.last_safe_point.get(key)
		if not (coordinate is int or coordinate is float) or not is_finite(float(coordinate)):
			return {"ok":false, "reason":"invalid_number"}
	for flag in s.tutorial_flags.values():
		if not flag is bool:
			return {"ok":false, "reason":"invalid_tutorial"}
	var scale = s.settings.get("ui_scale")
	if not (scale is int or scale is float) or not float(scale) in [1.0, 1.25, 1.5] or not s.settings.get("mute") is bool:
		return {"ok":false, "reason":"invalid_settings"}
	if not s.current_area in AREAS or not "brush" in s.owned_tools:
		return {"ok":false, "reason":"invalid_reference"}
	for tool in s.owned_tools:
		if not tool in ["brush", "pencil"]:
			return {"ok":false, "reason":"invalid_reference"}
	for area in s.visited_areas:
		if not area in AREAS:
			return {"ok":false, "reason":"invalid_reference"}
	for spawn in s.enemies:
		var enemy = s.enemies[spawn]
		if not spawn in SPAWNS or not enemy is Dictionary or not enemy.get("alive") is bool or not whole_number(enemy.get("hp"), SPAWNS.get(spawn, 0)):
			return {"ok":false, "reason":"invalid_enemy"}
		if enemy.alive != (enemy.hp > 0):
			return {"ok":false, "reason":"invalid_enemy"}
	var seen = {}
	for reward in s.granted_reward_keys:
		if not reward is String or seen.has(reward):
			return {"ok":false, "reason":"invalid_reward"}
		seen[reward] = true
		var found = false
		for spawn in s.enemies:
			if reward == s.profile_id + ":" + spawn + ":first_defeat" and not s.enemies[spawn].alive:
				found = true
		if not found:
			return {"ok":false, "reason":"invalid_reward"}
	if s.first_elite_defeated != s.granted_reward_keys.has(s.profile_id + ":e01:first_defeat") or (s.flower_restored and not s.first_elite_defeated) or (s.pencil_test_completed and not "pencil" in s.owned_tools):
		return {"ok":false, "reason":"invalid_progress"}
	return {"ok":true, "reason":"valid"}

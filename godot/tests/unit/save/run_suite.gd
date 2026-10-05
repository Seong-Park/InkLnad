extends SceneTree
const State = preload("res://scripts/economy/journey_state.gd")
const Store = preload("res://scripts/economy/save_store.gd")
var failures = 0

class MismatchStore extends Store:
	var primary_reads = 0
	func _read(path: String) -> Dictionary:
		var result = super._read(path)
		if path == ProjectSettings.globalize_path(base_path):
			primary_reads += 1
			if primary_reads == 2 and result.ok:
				result.snapshot.hp = 1
		return result

class PreferencesMismatchStore extends Store:
	var primary_reads = 0
	func _read_preferences(path: String) -> Dictionary:
		var result = super._read_preferences(path)
		if path == ProjectSettings.globalize_path(_preferences_path()):
			primary_reads += 1
			if primary_reads == 2 and result.ok:
				result.settings.mute = not result.settings.mute
		return result

func check(value: bool, name: String) -> void:
	if not value:
		failures += 1
		printerr("SAVE FAIL: ", name)

func _initialize() -> void:
	create_timer(5.0).timeout.connect(func(): printerr("SAVE FAIL timeout"); quit(1))
	_run.call_deferred()

func _run() -> void:
	var path = "user://tests/first_journey/save/profile.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))
	var state = State.new()
	var store = Store.new()
	store.configure(path)
	var initial = state.capture()
	check(store.write_snapshot(initial).ok, "initial write")
	var next = initial.duplicate(true)
	next.save_generation = 1
	next.hp = 82
	check(store.write_snapshot(next).ok, "replace existing")
	var moving = next.duplicate(true)
	var real_position = Vector2(280.091796875,260.908233642578)
	moving.last_safe_point = {"x":real_position.x,"y":real_position.y}
	var precision_store = Store.new()
	var precision_path = "user://tests/first_journey/save/precision.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(precision_path + suffix))
	precision_store.configure(precision_path)
	check(precision_store.write_snapshot(moving).ok, "real fractional movement coordinate commit")
	check(precision_store.read_snapshot().get("snapshot", {}).get("last_safe_point") == moving.last_safe_point, "fractional coordinate exact readback")
	for coordinate in [Vector2(12.0042877197266,12.0664978027344), Vector2(1279.123413085938,719.987670898438)]:
		var fractional = next.duplicate(true)
		fractional.last_safe_point = {"x":coordinate.x,"y":coordinate.y}
		var stored = precision_store.write_snapshot(fractional)
		check(stored.ok, "fractional twelve and viewport positions commit")
		if stored.ok:
			check(stored.snapshot == precision_store.read_snapshot().get("snapshot"), "returned state equals serialized disk state")
	var reloaded = Store.new()
	reloaded.configure(path)
	check(JSON.stringify(reloaded.read_snapshot().snapshot) == JSON.stringify(next), "fresh instance semantic equal")
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	var recovered = store.read_snapshot()
	check(recovered.ok and recovered.reason == "recovered_backup" and JSON.stringify(recovered.snapshot) == JSON.stringify(initial), "backup recovery")
	check(store.write_snapshot(next).ok, "commit after recovered backup")
	var nonfinite = next.duplicate(true)
	nonfinite.hp = INF
	check(not State.validate_snapshot(nonfinite).ok, "nonfinite rejected before JSON")
	for mutation in [{"schema_version":2}, {"wallet_ink":-1}, {"save_generation":1.5}, {"schema_version":0}]:
		var bad = next.duplicate(true)
		bad.merge(mutation, true)
		check(not State.validate_snapshot(bad).ok, "reject invalid number/version")
		file = FileAccess.open(path, FileAccess.WRITE)
		var original = JSON.stringify(bad)
		file.store_string(original)
		file.close()
		check(not store.read_snapshot().ok, "invalid primary does not silently downgrade")
		check(FileAccess.get_file_as_string(path) == original, "invalid file preserved")
	check(state.capture() == initial, "validation does not mutate state")
	var mismatch_path = "user://tests/first_journey/save/mismatch.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(mismatch_path + suffix))
	var seed = Store.new()
	seed.configure(mismatch_path)
	check(seed.write_snapshot(initial).ok, "seed verification failure")
	var mismatch = MismatchStore.new()
	mismatch.configure(mismatch_path)
	check(not mismatch.write_snapshot(next).ok, "mismatched readback rejects commit")
	check(seed.read_snapshot().snapshot == initial, "verification failure restores previous generation")
	var reset_path = "user://tests/first_journey/save/reset/profile.json"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(reset_path.get_base_dir()))
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(reset_path + suffix))
	file = FileAccess.open(reset_path, FileAccess.WRITE)
	file.store_string("original corrupt bytes")
	file.close()
	var reset_store = Store.new()
	reset_store.configure(reset_path)
	check(not reset_store.write_snapshot(initial).ok, "default corrupt reset refused")
	check(reset_store.has_method("write_new_profile"), "explicit reset API")
	if reset_store.has_method("write_new_profile"):
		var reset = reset_store.write_new_profile(initial)
		check(reset.ok and FileAccess.get_file_as_string(reset.get("archive_path", "")) == "original corrupt bytes", "explicit reset archives original")
		check(reset_store.read_snapshot().ok, "explicit fresh profile readable")
		var future = initial.duplicate(true)
		future.schema_version = 2
		file = FileAccess.open(reset_path, FileAccess.WRITE)
		file.store_string(JSON.stringify(future))
		file.close()
		check(not reset_store.write_new_profile(initial).ok and FileAccess.get_file_as_string(reset_path) == JSON.stringify(future), "explicit reset future preserved")
		file = FileAccess.open(reset_path, FileAccess.WRITE)
		file.store_string("reset failure original")
		file.close()
		var reset_mismatch = MismatchStore.new()
		reset_mismatch.configure(reset_path)
		check(not reset_mismatch.write_new_profile(initial).ok and FileAccess.get_file_as_string(reset_path) == "reset failure original", "reset verification failure restores original")
	check(reset_store.has_method("write_preferences"), "preferences API")
	if reset_store.has_method("write_preferences"):
		var settings = {"ui_scale":1.5,"mute":true}
		check(reset_store.write_preferences(settings).ok, "preferences write")
		check(reset_store.read_preferences().get("settings") == settings, "preferences fresh read")
		check(not reset_store.write_preferences({"ui_scale":1.1,"mute":true}).ok, "preferences invalid refused")
		check(reset_store.read_preferences().get("settings") == settings, "preferences failed write unchanged")
		var prefs_only_path = "user://tests/first_journey/save/preferences_only/profile.json"
		for suffix in ["", ".bak", ".tmp"]:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(prefs_only_path + suffix))
		var prefs_only = Store.new()
		prefs_only.configure(prefs_only_path)
		check(prefs_only.write_preferences(settings).ok and not FileAccess.file_exists(prefs_only_path), "preferences creates no profile")
		check(prefs_only.read_preferences().get("settings") == settings, "independent preference reload")
		check(prefs_only.write_preferences({"ui_scale":1.25,"mute":false}).ok, "preferences replacement")
		file = FileAccess.open(prefs_only_path.get_base_dir().path_join("preferences.json"), FileAccess.WRITE)
		file.store_string("bad")
		file.close()
		check(prefs_only.read_preferences().get("settings") == settings, "preferences backup recovery")
		var preferences_mismatch = PreferencesMismatchStore.new()
		preferences_mismatch.configure(prefs_only_path)
		check(not preferences_mismatch.write_preferences({"ui_scale":1,"mute":false}).ok, "preferences verification mismatch rejected")
		check(prefs_only.read_preferences().get("settings") == settings, "preferences verification rollback")
		var initial_mismatch_path = "user://tests/first_journey/save/initial_mismatch.json"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(initial_mismatch_path))
		var initial_mismatch = MismatchStore.new()
		initial_mismatch.configure(initial_mismatch_path)
		initial_mismatch.primary_reads = 1
		check(not initial_mismatch.write_snapshot(initial).ok and not FileAccess.file_exists(initial_mismatch_path), "failed initial verification leaves no committed profile")
	print("SAVE PASS" if failures == 0 else "SAVE FAILED", " checks complete failures=", failures)
	if failures == 0:
		print("INK_SAVE_PASS")
	quit(0 if failures == 0 else 1)

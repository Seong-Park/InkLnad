class_name SaveStore
extends RefCounted

const State = preload("res://scripts/economy/journey_state.gd")
var base_path = "user://inkland/profile.json"

func configure(path: String) -> void:
	base_path = path

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok":false, "reason":"missing_save"}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok":false, "reason":"read_failed"}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not parser.data is Dictionary:
		return {"ok":false, "reason":"corrupt_save"}
	var result = State.validate_snapshot(parser.data)
	if result.ok:
		result["snapshot"] = State.normalize_numbers(parser.data)
	return result

func read_snapshot() -> Dictionary:
	var primary = _read(base_path)
	if primary.ok or primary.reason in ["future_schema", "unsupported_schema", "invalid_number", "invalid_reference", "invalid_progress", "invalid_enemy", "invalid_reward", "invalid_tutorial", "invalid_settings"]:
		return primary
	var backup = _read(base_path + ".bak")
	if backup.ok:
		backup.reason = "recovered_backup"
		return backup
	return primary

func write_snapshot(snapshot: Dictionary) -> Dictionary:
	return _write_snapshot(snapshot)

# Caller must have obtained explicit new-profile confirmation first.
func write_new_profile(snapshot: Dictionary) -> Dictionary:
	var valid = State.validate_snapshot(snapshot)
	if not valid.ok:
		return valid
	var existing = _read(base_path)
	if existing.ok or existing.reason == "missing_save":
		return write_snapshot(snapshot)
	if not existing.reason in ["corrupt_save", "invalid_structure"]:
		return existing
	var archive = ProjectSettings.globalize_path(base_path) + ".corrupt-" + str(Time.get_unix_time_from_system()).replace(".", "-") + "-" + str(Time.get_ticks_usec())
	if DirAccess.copy_absolute(ProjectSettings.globalize_path(base_path), archive) != OK:
		return {"ok":false, "reason":"archive_failed"}
	var result = _write_snapshot(snapshot, archive)
	result["archive_path"] = archive
	return result

func _write_snapshot(snapshot: Dictionary, recovery_path: String = "") -> Dictionary:
	var valid = State.validate_snapshot(snapshot)
	if not valid.ok:
		return valid
	var absolute = ProjectSettings.globalize_path(base_path)
	if DirAccess.make_dir_recursive_absolute(absolute.get_base_dir()) != OK:
		return {"ok":false, "reason":"directory_failed"}
	var temporary = absolute + ".tmp"
	var payload = JSON.stringify(snapshot, "", true, true)
	var serialized = JSON.parse_string(payload)
	if not serialized is Dictionary or not State.validate_snapshot(serialized).ok:
		return {"ok":false, "reason":"serialization_failed"}
	var expected = State.normalize_numbers(serialized)
	var file = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return {"ok":false, "reason":"write_failed"}
	file.store_string(payload)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK or not _read(temporary).ok:
		return {"ok":false, "reason":"write_failed"}
	var had_primary = FileAccess.file_exists(absolute)
	if had_primary:
		var existing = _read(absolute)
		if not existing.ok:
			if recovery_path.is_empty() and (not existing.reason in ["corrupt_save", "invalid_structure", "missing_save"] or not _read(absolute + ".bak").ok):
				return existing
		elif DirAccess.copy_absolute(absolute, absolute + ".bak") != OK:
			return {"ok":false, "reason":"backup_failed"}
	# Same-directory rename is the commit point. Never delete the primary first.
	if DirAccess.rename_absolute(temporary, absolute) != OK:
		return {"ok":false, "reason":"replace_failed"}
	var committed = _read(absolute)
	if not committed.ok or committed.snapshot != expected:
		if had_primary:
			DirAccess.copy_absolute(absolute + ".bak" if recovery_path.is_empty() else recovery_path, absolute)
		else:
			DirAccess.remove_absolute(absolute)
		return {"ok":false, "reason":"verify_failed"}
	return {"ok":true, "reason":"committed", "snapshot":committed.snapshot}

func _preferences_path() -> String:
	return base_path.get_base_dir().path_join("preferences.json")

func _valid_preferences(settings: Variant) -> bool:
	if not settings is Dictionary or settings.size() != 2 or not settings.get("mute") is bool:
		return false
	var scale = settings.get("ui_scale")
	return (scale is int or scale is float) and float(scale) in [1.0, 1.25, 1.5]

func _read_preferences(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok":false, "reason":"missing_preferences"}
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok":false, "reason":"read_failed"}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK or not _valid_preferences(parser.data):
		return {"ok":false, "reason":"invalid_settings"}
	return {"ok":true, "reason":"valid", "settings":State.normalize_numbers(parser.data)}

func read_preferences() -> Dictionary:
	var result = _read_preferences(_preferences_path())
	if not result.ok:
		var backup = _read_preferences(_preferences_path() + ".bak")
		if backup.ok:
			backup.reason = "recovered_backup"
			return backup
	return result

func write_preferences(settings: Dictionary) -> Dictionary:
	if not _valid_preferences(settings):
		return {"ok":false, "reason":"invalid_settings"}
	var path = ProjectSettings.globalize_path(_preferences_path())
	if DirAccess.make_dir_recursive_absolute(path.get_base_dir()) != OK:
		return {"ok":false, "reason":"directory_failed"}
	var file = FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		return {"ok":false, "reason":"write_failed"}
	file.store_string(JSON.stringify(settings, "", true, true))
	file.flush()
	var error = file.get_error()
	file.close()
	if error != OK or not _read_preferences(path + ".tmp").ok:
		return {"ok":false, "reason":"write_failed"}
	var had_primary = FileAccess.file_exists(path)
	if had_primary and (_read_preferences(path).ok or not _read_preferences(path + ".bak").ok):
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			return {"ok":false, "reason":"backup_failed"}
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		return {"ok":false, "reason":"replace_failed"}
	var committed = _read_preferences(path)
	if not committed.ok or committed.settings != State.normalize_numbers(settings):
		if had_primary and FileAccess.file_exists(path + ".bak"):
			DirAccess.copy_absolute(path + ".bak", path)
		elif not had_primary:
			DirAccess.remove_absolute(path)
		return {"ok":false, "reason":"verify_failed"}
	return {"ok":true, "reason":"committed", "settings":committed.settings}

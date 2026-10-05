class_name StrokeRules
extends RefCounted

var _rules: JourneyRules
var _stamps: Array[Dictionary] = []
var _next_id: int = 1
var _last_end: Vector2 = Vector2.INF
var _last_tool: StringName = &""
var _distance_to_next: float = 4.0
var _buckets: Dictionary = {}
var _damage_buckets: Dictionary = {}
var _max_radius: float = 0.0
var _expired_at: float = -INF

func _cell(point: Vector2) -> Vector2i:
	var size: float = maxf(_rules.stamp_merge_distance,1.0)
	return Vector2i(floori(point.x/size),floori(point.y/size))

func _index_stamp(stamp: Dictionary) -> void:
	var cell: Vector2i = _cell(stamp.center)
	if not _buckets.has(cell):
		_buckets[cell] = []
	_buckets[cell].append(stamp)
	var damage_cell := Vector2i(floori(stamp.center.x/64.0),floori(stamp.center.y/64.0))
	if not _damage_buckets.has(damage_cell):
		_damage_buckets[damage_cell] = []
	_damage_buckets[damage_cell].append(stamp)
	_max_radius = maxf(_max_radius,float(stamp.radius))

func configure(rules: JourneyRules) -> void:
	_rules = rules
	clear()

func clip_path(from_world: Vector2, to_world: Vector2, center: Vector2, radius: float, half_width: float, was_inside: bool) -> Dictionary:
	var result: Dictionary = {"valid": false, "start": to_world, "end": to_world, "new_subpath": true}
	var limit: float = radius - half_width
	if limit <= 0.0 or half_width < 0.0 or not from_world.is_finite() or not to_world.is_finite():
		return result
	var from_inside: bool = was_inside and from_world.distance_to(center) <= limit + 0.000001
	var to_inside: bool = to_world.distance_to(center) <= limit + 0.000001
	if not from_inside:
		if to_inside:
			result.valid = true
		return result
	result.start = from_world
	result.new_subpath = false
	if to_inside:
		result.valid = true
		return result
	var offset: Vector2 = from_world - center
	var delta: Vector2 = to_world - from_world
	var a: float = delta.length_squared()
	if a <= 0.0:
		return result
	var b: float = 2.0 * offset.dot(delta)
	var c: float = offset.length_squared() - limit * limit
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return result
	var fraction: float = clampf((-b + sqrt(discriminant)) / (2.0 * a), 0.0, 1.0)
	result.end = from_world + delta * fraction
	result.valid = true
	return result

func paint(path_start: Vector2, path_end: Vector2, tool_id: StringName, center: Vector2, now: float) -> Array[Dictionary]:
	var direct: Array[Dictionary] = []
	if _rules == null or not is_finite(now):
		return direct
	var tool: Dictionary = _rules.get_tool(tool_id)
	if tool.is_empty():
		return direct
	expire(now)
	var half_width: float = float(tool.width) * 0.5
	var limit: float = float(_rules.player.attack_radius) - half_width
	if path_start.distance_to(center) > limit + 0.000001 or path_end.distance_to(center) > limit + 0.000001:
		return direct
	var new_path: bool = _last_tool != tool_id or not _last_end.is_equal_approx(path_start)
	if new_path:
		_distance_to_next = _rules.stamp_spacing
	_touch_stamp(path_start, tool_id, half_width, float(tool.lifetime), center, now, direct)
	var length: float = path_start.distance_to(path_end)
	if length > 0.0:
		var direction: Vector2 = (path_end - path_start) / length
		var distance: float = _distance_to_next
		while distance <= length + 0.000001:
			_touch_stamp(path_start + direction * minf(distance, length), tool_id, half_width, float(tool.lifetime), center, now, direct)
			distance += _rules.stamp_spacing
		_distance_to_next = distance - length
		_touch_stamp(path_end, tool_id, half_width, float(tool.lifetime), center, now, direct)
	_last_end = path_end
	_last_tool = tool_id
	return direct

func _touch_stamp(point: Vector2, tool_id: StringName, radius: float, lifetime: float, center: Vector2, now: float, direct: Array[Dictionary]) -> void:
	var closest: Dictionary = {}
	var closest_distance: float = INF
	var cell: Vector2i = _cell(point)
	var merge_squared: float = _rules.stamp_merge_distance*_rules.stamp_merge_distance
	for x in range(-1,2):
		for y in range(-1,2):
			for stamp in _buckets.get(cell+Vector2i(x,y),[]):
				if stamp.tool_id != tool_id or stamp.center.distance_to(center)+stamp.radius > float(_rules.player.attack_radius)+0.000001:
					continue
				var distance: float = stamp.center.distance_squared_to(point)
				if distance <= merge_squared and (distance < closest_distance or (distance == closest_distance and int(stamp.id) < int(closest.get("id",2147483647)))):
					closest = stamp
					closest_distance = distance
	var touched: Dictionary
	if not closest.is_empty():
		touched = closest
		touched.refreshed_at = now
		touched.expires_at = now + lifetime
	else:
		touched = {"id": _next_id, "tool_id": tool_id, "center": point, "radius": radius, "refreshed_at": now, "expires_at": now + lifetime}
		_next_id += 1
		_stamps.append(touched)
		_index_stamp(touched)
	for existing in direct:
		if existing.id == touched.id:
			return
	direct.append(touched.duplicate(true))

func expire(now: float) -> void:
	if now == _expired_at:
		return
	_expired_at = now
	var removed: bool = false
	for index in range(_stamps.size() - 1, -1, -1):
		if float(_stamps[index].expires_at) <= now:
			_stamps.remove_at(index)
			removed = true
	if removed:
		_buckets.clear()
		_damage_buckets.clear()
		_max_radius = 0.0
		for stamp in _stamps:
			_index_stamp(stamp)

func clear() -> void:
	_stamps.clear()
	_buckets.clear()
	_damage_buckets.clear()
	_max_radius = 0.0
	_expired_at = -INF
	_last_end = Vector2.INF
	_last_tool = &""
	_distance_to_next = 4.0

func get_active_stamps() -> Array[Dictionary]:
	return _stamps.duplicate(true)

# Borrowed read-only runtime view; snapshot consumers use get_active_stamps.
func active_stamps_view() -> Array[Dictionary]:
	return _stamps

func damage_candidates(point: Vector2, target_radius: float) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var reach: float = target_radius+_max_radius
	for x in range(floori((point.x-reach)/64.0),floori((point.x+reach)/64.0)+1):
		for y in range(floori((point.y-reach)/64.0),floori((point.y+reach)/64.0)+1):
			result.append_array(_damage_buckets.get(Vector2i(x,y),[]))
	return result

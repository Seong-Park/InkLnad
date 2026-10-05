extends RefCounted

# Authored coastal layouts were made for 80px people; the player is now 160px.
const SCALE: float = 2.0

static func expand(value: Variant, key: String = "") -> Variant:
	if value is Vector2:
		return value * SCALE
	if value is Rect2:
		return Rect2(value.position * SCALE, value.size * SCALE)
	if value is PackedVector2Array:
		var points := PackedVector2Array()
		for point in value:
			points.append(point * SCALE)
		return points
	if value is Dictionary:
		var result: Dictionary = {}
		for field in value:
			result[field] = expand(value[field], String(field))
		return result
	if value is Array:
		var result: Array = []
		for item in value:
			result.append(expand(item))
		return result
	if key == "height" and (value is float or value is int):
		return float(value) * SCALE
	return value

class_name DamageResolver
extends RefCounted

var damage_interval: float = 0.25
var _next_hit: Dictionary = {}

# Caller aggregates all same-tick contacts per target before this single call.
func resolve_hit(target_id: StringName, direct_damage: float, residual_damage: float, now: float) -> float:
	if not is_finite(now) or now < float(_next_hit.get(target_id, -INF)):
		return 0.0
	var amount: float = direct_damage if direct_damage > 0.0 else residual_damage
	if not is_finite(amount) or amount <= 0.0:
		return 0.0
	_next_hit[target_id] = now + damage_interval
	return amount

func forget_target(target_id: StringName) -> void:
	_next_hit.erase(target_id)

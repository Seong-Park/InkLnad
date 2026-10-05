class_name CombatInk
extends RefCounted

signal changed(current: float, maximum: float, phase: StringName)

var current: float = 100.0
var maximum: float = 100.0
var holding: bool = false
var depleted: bool = false
var phase: StringName = &"ready"
var _recharge_rate: float = 100.0 / 3.5
var _delay: float = 0.5
var _waiting: float = 0.0
var _in_range: bool = true
var _blocked: bool = false

func configure(maximum_value: float, recharge_rate: float, delay: float) -> void:
	maximum = maxf(maximum_value, 0.0)
	current = maximum
	_recharge_rate = maxf(recharge_rate, 0.0)
	_delay = maxf(delay, 0.0)
	holding = false
	depleted = false
	_blocked = false
	_waiting = 0.0
	_notify()

func press() -> bool:
	if holding:
		return not _blocked and not depleted
	holding = true
	_waiting = 0.0
	_blocked = current < 1.0
	depleted = current <= 0.0
	_notify()
	return not _blocked

func spend_skill(cost: float) -> bool:
	if not is_finite(cost) or cost < 0.0 or current < cost:
		return false
	current -= cost
	_waiting = _delay
	depleted = current <= 0.0
	_notify()
	return true

func release() -> void:
	holding = false
	_blocked = false
	_waiting = _delay
	_notify()

func set_in_range(value: bool) -> void:
	_in_range = value
	_notify()

func spend(cost: float) -> float:
	if not holding or _blocked or depleted or not _in_range or not is_finite(cost) or cost < 0.0:
		return 0.0
	if cost == 0.0:
		return 1.0
	var fraction: float = minf(1.0, current / cost)
	current = maxf(0.0, current - cost * fraction)
	if current <= 0.00000001:
		current = 0.0
		depleted = true
		_blocked = true
	_notify()
	return fraction

# Upkeep/length are supplied by DrawController once per approved interval.
func advance(dt: float) -> void:
	if not is_finite(dt) or dt <= 0.0 or holding:
		return
	var available: float = dt
	if _waiting > 0.0:
		var waiting_step: float = minf(_waiting, available)
		_waiting -= waiting_step
		available -= waiting_step
	if available > 0.0:
		current = minf(maximum, current + _recharge_rate * available)
		depleted = current <= 0.0
	_notify()

func _notify() -> void:
	if holding:
		phase = &"held_empty" if (_blocked or depleted) else (&"attacking" if _in_range else &"held_outside")
	elif current >= maximum:
		phase = &"ready"
	elif _waiting > 0.0:
		phase = &"waiting"
	else:
		phase = &"recharging"
	changed.emit(current, maximum, phase)

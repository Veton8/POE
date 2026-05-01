extends Node

# Cross-card modifier registry. Cards that buff OTHER autocasts (CD
# reduction during a state, single-shot empower windows, periodic
# doublings via per-card counters) register their effects here so any
# AutocastTicker can query the live modifier state.

@warning_ignore("unused_signal")
signal cd_modifier_changed
@warning_ignore("unused_signal")
signal empower_queued(multiplier: float, window_seconds: float)

# Each entry: { id: StringName, multiplier: float, expires_msec: int }
var _cd_modifiers: Array[Dictionary] = []

var _empower_value: float = 1.0
var _empower_expires_msec: int = 0


func add_cd_modifier(id: StringName, multiplier: float, duration_seconds: float) -> void:
	var expiry: int = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	for i: int in _cd_modifiers.size():
		var m: Dictionary = _cd_modifiers[i]
		if StringName(m["id"]) == id:
			_cd_modifiers[i] = {"id": id, "multiplier": multiplier, "expires_msec": expiry}
			cd_modifier_changed.emit()
			return
	_cd_modifiers.append({"id": id, "multiplier": multiplier, "expires_msec": expiry})
	cd_modifier_changed.emit()


func remove_cd_modifier(id: StringName) -> void:
	var alive: Array[Dictionary] = []
	for m: Dictionary in _cd_modifiers:
		if StringName(m["id"]) != id:
			alive.append(m)
	if alive.size() != _cd_modifiers.size():
		_cd_modifiers = alive
		cd_modifier_changed.emit()


func get_cd_multiplier() -> float:
	_prune_expired()
	var product: float = 1.0
	for m: Dictionary in _cd_modifiers:
		product *= float(m["multiplier"])
	return maxf(product, 0.1)


func queue_empower(multiplier: float, window_seconds: float) -> void:
	_empower_value = multiplier
	_empower_expires_msec = Time.get_ticks_msec() + int(window_seconds * 1000.0)
	empower_queued.emit(multiplier, window_seconds)


func consume_empower() -> float:
	if Time.get_ticks_msec() > _empower_expires_msec:
		_empower_value = 1.0
		return 1.0
	var v: float = _empower_value
	_empower_value = 1.0
	_empower_expires_msec = 0
	return v


func reset_all() -> void:
	_cd_modifiers.clear()
	_empower_value = 1.0
	_empower_expires_msec = 0


func _prune_expired() -> void:
	var now: int = Time.get_ticks_msec()
	var alive: Array[Dictionary] = []
	var changed: bool = false
	for m: Dictionary in _cd_modifiers:
		if int(m["expires_msec"]) > now:
			alive.append(m)
		else:
			changed = true
	if changed:
		_cd_modifiers = alive
		cd_modifier_changed.emit()

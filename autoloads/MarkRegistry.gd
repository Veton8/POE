extends Node

# Per-enemy transient marks/hexes/curses. Cards apply marks via
# apply_mark() and inspect/clear via has_mark() / clear_mark(). Keyed
# on enemy.get_instance_id() so freed enemies don't leak Node refs.
# Lazy cleanup: expired entries dropped on next access; tree_exiting
# is the only proactive cleanup hook.

@warning_ignore("unused_signal")
signal mark_applied(enemy: Node, mark_id: StringName, applier: Node)
@warning_ignore("unused_signal")
signal mark_expired(enemy: Node, mark_id: StringName)
@warning_ignore("unused_signal")
signal mark_cleared(enemy: Node, mark_id: StringName)

var _marks: Dictionary = {}  # int (instance_id) -> Dictionary[StringName -> int (expiry msec)]


func apply_mark(enemy: Node, mark_id: StringName, duration_seconds: float, applier: Node = null) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	var iid: int = enemy.get_instance_id()
	var first_time: bool = not _marks.has(iid)
	if first_time:
		_marks[iid] = {}
		if enemy.has_signal("tree_exiting"):
			enemy.tree_exiting.connect(_on_enemy_freed.bind(iid), CONNECT_ONE_SHOT)
	var expiry: int = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	(_marks[iid] as Dictionary)[mark_id] = expiry
	mark_applied.emit(enemy, mark_id, applier)


func has_mark(enemy: Node, mark_id: StringName) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	var iid: int = enemy.get_instance_id()
	if not _marks.has(iid):
		return false
	var marks: Dictionary = _marks[iid]
	if not marks.has(mark_id):
		return false
	var expiry: int = int(marks[mark_id])
	if Time.get_ticks_msec() >= expiry:
		marks.erase(mark_id)
		mark_expired.emit(enemy, mark_id)
		return false
	return true


func clear_mark(enemy: Node, mark_id: StringName) -> void:
	if enemy == null:
		return
	var iid: int = enemy.get_instance_id()
	if not _marks.has(iid):
		return
	var marks: Dictionary = _marks[iid]
	if marks.has(mark_id):
		marks.erase(mark_id)
		if is_instance_valid(enemy):
			mark_cleared.emit(enemy, mark_id)


func get_mark_count(enemy: Node) -> int:
	if enemy == null or not is_instance_valid(enemy):
		return 0
	var iid: int = enemy.get_instance_id()
	if not _marks.has(iid):
		return 0
	var marks: Dictionary = _marks[iid]
	var now: int = Time.get_ticks_msec()
	var expired: Array[StringName] = []
	var alive_count: int = 0
	for mid_v: Variant in marks.keys():
		var mid: StringName = mid_v as StringName
		if int(marks[mid]) <= now:
			expired.append(mid)
		else:
			alive_count += 1
	for mid: StringName in expired:
		marks.erase(mid)
		mark_expired.emit(enemy, mid)
	return alive_count


func get_marks(enemy: Node) -> Array[StringName]:
	var out: Array[StringName] = []
	if enemy == null or not is_instance_valid(enemy):
		return out
	var iid: int = enemy.get_instance_id()
	if not _marks.has(iid):
		return out
	var marks: Dictionary = _marks[iid]
	var now: int = Time.get_ticks_msec()
	for mid_v: Variant in marks.keys():
		var mid: StringName = mid_v as StringName
		if int(marks[mid]) > now:
			out.append(mid)
	return out


func reset_all() -> void:
	_marks.clear()


func _on_enemy_freed(iid: int) -> void:
	_marks.erase(iid)

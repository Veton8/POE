extends Node

var _active: Node = null

func register(j: Node) -> void:
	_active = j

func unregister(j: Node) -> void:
	if _active == j:
		_active = null

func get_vector() -> Vector2:
	if _active != null and _active.has_method("get_vector"):
		return _active.call("get_vector") as Vector2
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")

func is_pressed() -> bool:
	if _active != null:
		var v: Variant = _active.get("is_pressed")
		if typeof(v) == TYPE_BOOL:
			return v
	return false

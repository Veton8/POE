class_name HealthComponent
extends Node

signal health_changed(current: int, max_hp: int)
signal damaged(amount: int, source: Node)
signal died

@export var max_hp: int = 3
@export var invuln_seconds: float = 0.0

var current: int
var _invuln_until: float = 0.0
var _dead: bool = false

func _ready() -> void:
	current = max_hp
	health_changed.emit(current, max_hp)

func take_damage(amount: int, source: Node = null) -> bool:
	if _dead:
		return false
	if invuln_seconds > 0.0 and Time.get_ticks_msec() / 1000.0 < _invuln_until:
		return false
	current = max(current - amount, 0)
	damaged.emit(amount, source)
	health_changed.emit(current, max_hp)
	if invuln_seconds > 0.0:
		_invuln_until = Time.get_ticks_msec() / 1000.0 + invuln_seconds
	if current == 0:
		_dead = true
		died.emit()
	return true

func heal(amount: int) -> void:
	if _dead:
		return
	current = min(current + amount, max_hp)
	health_changed.emit(current, max_hp)

func is_dead() -> bool:
	return _dead

func reset(new_max: int = -1) -> void:
	if new_max > 0:
		max_hp = new_max
	current = max_hp
	_dead = false
	health_changed.emit(current, max_hp)

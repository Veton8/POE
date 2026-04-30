class_name Ability
extends Node

signal cooldown_started(duration: float)
signal cooldown_ended

@export var cooldown_seconds: float = 3.0
@export var ability_name: String = ""
@export var icon: Texture2D

var _on_cd: bool = false
var _t: Timer

func _ready() -> void:
	_t = Timer.new()
	_t.one_shot = true
	add_child(_t)
	_t.timeout.connect(_on_timeout)

func try_activate() -> bool:
	if _on_cd:
		return false
	if not _can_activate():
		return false
	_activate()
	_on_cd = true
	_t.start(cooldown_seconds)
	cooldown_started.emit(cooldown_seconds)
	return true

func _can_activate() -> bool:
	return true

func _activate() -> void:
	pass

func _on_timeout() -> void:
	_on_cd = false
	cooldown_ended.emit()

func get_player() -> Player:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	return p as Player

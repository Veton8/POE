class_name HollowMaskHandler
extends Node

# Ichigo-style "Hollow Mask" — when player drops below `threshold_pct` HP,
# damage scales by `bonus_mul` for the rest of the room. Restores on full
# heal. Outlines the player in white while active.

@export var threshold_pct: float = 0.4
@export var bonus_mul: float = 1.6

var _player: Player = null
var _active: bool = false
var _base_damage: int = 1


func _ready() -> void:
	_player = get_parent() as Player
	if _player == null or _player.health == null or _player.stats == null:
		queue_free()
		return
	_base_damage = _player.stats.damage
	_player.health.health_changed.connect(_on_hp_changed)


func _on_hp_changed(current: int, max_hp: int) -> void:
	if max_hp <= 0:
		return
	var pct: float = float(current) / float(max_hp)
	if pct <= threshold_pct and not _active:
		_engage()
	elif pct >= 0.99 and _active:
		_disengage()


func _engage() -> void:
	if _player == null:
		return
	_active = true
	_player.stats.damage = int(round(float(_base_damage) * bonus_mul))
	_player.modulate = Color(1.6, 1.6, 1.6, 1.0)


func _disengage() -> void:
	if _player == null:
		return
	_active = false
	_player.stats.damage = _base_damage
	_player.modulate = Color.WHITE

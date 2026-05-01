class_name EvolutionWatcher
extends Node

# Generic evolution effect — when attached, grants permanent passive
# bonuses (damage / max_hp boost) to the player via direct stat
# mutation. Specific signature effects (domain freezes, instakill
# chances, etc.) are layered on top by per-evolution subclasses.

@export var damage_bonus_mult: float = 1.30
@export var max_hp_bonus_mult: float = 1.25
@export var fire_rate_bonus_mult: float = 1.10

var _player: Player = null


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
		_apply()


func _ready() -> void:
	if _player == null:
		_resolve()
	if _player != null:
		_apply()


func _resolve() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _apply() -> void:
	if _player == null or _player.stats == null:
		return
	_player.stats.damage = int(round(float(_player.stats.damage) * damage_bonus_mult))
	_player.stats.max_hp = int(round(float(_player.stats.max_hp) * max_hp_bonus_mult))
	_player.stats.fire_rate *= fire_rate_bonus_mult
	if _player.fire_timer != null:
		_player.fire_timer.wait_time = 1.0 / _player.stats.fire_rate
	if _player.health != null:
		_player.health.max_hp = _player.stats.max_hp
		_player.health.heal(int(round(float(_player.stats.max_hp) * 0.25)))

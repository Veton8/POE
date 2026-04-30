class_name SpiritBombStacker
extends Node

# Goku's "Spirit Bomb" — every kill grants +`per_kill_pct` damage (additive),
# capped at `max_pct`. Resets on player damage. Visualized with a yellow
# modulate as stacks climb.

@export var per_kill_pct: float = 0.05
@export var max_pct: float = 2.0

var _player: Player = null
var _base_damage: int = 1
var _stacks: int = 0
var _max_stacks: int = 0


func _ready() -> void:
	_player = get_parent() as Player
	if _player == null or _player.stats == null:
		queue_free()
		return
	_base_damage = _player.stats.damage
	_max_stacks = int(round(max_pct / per_kill_pct))
	if has_node("/root/Events"):
		Events.enemy_died.connect(_on_enemy_died)
	if _player.health != null:
		_player.health.damaged.connect(_on_damaged)


func _on_enemy_died(_enemy: Node, _pos: Vector2) -> void:
	_stacks = mini(_max_stacks, _stacks + 1)
	_apply()


func _on_damaged(_amount: int, _src: Node) -> void:
	_stacks = 0
	_apply()


func _apply() -> void:
	if _player == null or _player.stats == null:
		return
	var mul: float = 1.0 + per_kill_pct * float(_stacks)
	_player.stats.damage = int(round(float(_base_damage) * mul))
	var blend: float = float(_stacks) / float(_max_stacks)
	_player.modulate = Color(1.0 + blend * 0.6, 1.0 + blend * 0.4, 1.0 - blend * 0.4, 1.0)

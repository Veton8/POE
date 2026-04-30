class_name GearRampHandler
extends Node

# Luffy's "Gear Ramp" — every consecutive bullet_hit ramps fire_rate by 4%
# up to +60%. Resets on player damage. Visual cue: player modulate toward
# red as ramp grows.

@export var max_stacks: int = 15
@export var per_stack_ratemul: float = 0.04
@export var decay_seconds: float = 1.5

var _stacks: int = 0
var _decay_t: float = 0.0
var _player: Player = null
var _base_rate: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	if _player == null:
		queue_free()
		return
	_base_rate = _player.stats.fire_rate
	if _player.has_signal("bullet_hit"):
		_player.connect("bullet_hit", _on_bullet_hit)
	if _player.health != null:
		_player.health.damaged.connect(_on_damaged)


func _on_bullet_hit(_target: Node) -> void:
	_stacks = mini(max_stacks, _stacks + 1)
	_decay_t = decay_seconds
	_apply()


func _on_damaged(_amount: int, _src: Node) -> void:
	_stacks = 0
	_apply()


func _process(delta: float) -> void:
	if _stacks <= 0:
		return
	_decay_t -= delta
	if _decay_t <= 0.0:
		_stacks = max(0, _stacks - 1)
		_decay_t = decay_seconds
		_apply()


func _apply() -> void:
	if _player == null or _player.stats == null:
		return
	var mul: float = 1.0 + per_stack_ratemul * float(_stacks)
	_player.stats.fire_rate = _base_rate * mul
	if _player.fire_timer != null:
		_player.fire_timer.wait_time = 1.0 / _player.stats.fire_rate
	var blend: float = float(_stacks) / float(max_stacks)
	_player.modulate = Color(1.0 + blend * 0.4, 1.0 - blend * 0.2, 1.0 - blend * 0.4, 1.0)

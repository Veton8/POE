class_name BuffComponent
extends Node

# Temporary stat buff attached to an enemy. Duplicates the enemy's stats
# resource on attach so the buffed copy doesn't leak to other instances of
# the same enemy type. Restores the original move_speed on expiry.

@export var duration: float = 0.7
@export var speed_mul: float = 1.5

var _t: float = 0.0
var _enemy: EnemyBase = null
var _orig_speed: float = 0.0


func _ready() -> void:
	var p: Node = get_parent()
	if not (p is EnemyBase):
		queue_free()
		return
	_enemy = p as EnemyBase
	if _enemy.stats == null:
		queue_free()
		return
	_enemy.stats = _enemy.stats.duplicate() as EnemyStats
	_orig_speed = _enemy.stats.move_speed
	_enemy.stats.move_speed = _orig_speed * speed_mul
	_enemy.modulate = Color(1.4, 1.4, 0.6, 1)


func _process(delta: float) -> void:
	if _enemy == null or not is_instance_valid(_enemy):
		queue_free()
		return
	_t += delta
	if _t >= duration:
		_expire()


func refresh(new_duration: float, new_speed_mul: float) -> void:
	_t = 0.0
	duration = new_duration
	speed_mul = new_speed_mul
	if _enemy != null and _enemy.stats != null:
		_enemy.stats.move_speed = _orig_speed * new_speed_mul


func _expire() -> void:
	if _enemy != null and _enemy.stats != null:
		_enemy.stats.move_speed = _orig_speed
		_enemy.modulate = Color.WHITE
	queue_free()

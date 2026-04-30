class_name Drowner
extends EnemyBase

# Fast melee enemy. When close, lunges with a brief speed burst, then falls
# back to chase speed during the cooldown. Sprite tints magenta during the
# lunge windup so the player can read the burst.

@export var lunge_distance: float = 70.0
@export var lunge_speed_multiplier: float = 2.4
@export var lunge_duration: float = 0.35
@export var lunge_cooldown: float = 1.5

var _lunge_t: float = 0.0
var _cooldown_t: float = 0.0


func _ai_step() -> void:
	if player == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	var dist: float = global_position.distance_to(player.global_position)
	var dt: float = get_physics_process_delta_time()
	_cooldown_t = max(0.0, _cooldown_t - dt)
	if _lunge_t > 0.0:
		_lunge_t -= dt
		velocity = dir * stats.move_speed * lunge_speed_multiplier
		if _lunge_t <= 0.0:
			sprite.modulate = Color.WHITE
	elif dist < lunge_distance and _cooldown_t <= 0.0:
		_lunge_t = lunge_duration
		_cooldown_t = lunge_cooldown
		sprite.modulate = Color(1.4, 0.7, 1.4, 1)
		velocity = dir * stats.move_speed * lunge_speed_multiplier
	else:
		velocity = dir * stats.move_speed

class_name PewPhantom
extends EnemyBase

# Stationary-by-default phantom that periodically blinks to a random spot
# around the player and fires one aimed bullet at them. Can't be safely
# kited by holding a corner — has to be focus-killed before it pops up
# behind the player's blind side.

@export var teleport_interval: float = 3.5
@export var teleport_distance: float = 80.0

var _teleport_t: float = 0.0
var _teleporting: bool = false


func _ai_step() -> void:
	if player == null or _teleporting:
		velocity = Vector2.ZERO
		return
	_teleport_t += get_physics_process_delta_time()
	if _teleport_t >= teleport_interval:
		_teleport_t = 0.0
		_blink_and_fire()
	velocity = Vector2.ZERO


func _blink_and_fire() -> void:
	_teleporting = true
	var orig_modulate: Color = sprite.modulate
	sprite.modulate = Color(2.0, 0.5, 2.0, 0.4)
	await get_tree().create_timer(0.18).timeout
	if not is_instance_valid(self) or player == null or not is_instance_valid(player):
		_teleporting = false
		return
	var angle: float = randf_range(0.0, TAU)
	var p2: Node2D = player as Node2D
	global_position = p2.global_position + Vector2.RIGHT.rotated(angle) * teleport_distance
	sprite.modulate = orig_modulate
	if bullet_scene == null:
		_teleporting = false
		return
	var dir: Vector2 = (p2.global_position - global_position).normalized()
	var b: Node = BulletPool.acquire(bullet_scene)
	if b.has_method("spawn"):
		b.call("spawn", global_position, dir, stats.bullet_speed, stats.bullet_damage, "enemy")
	_teleporting = false

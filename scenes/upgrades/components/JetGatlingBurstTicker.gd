class_name JetGatlingBurstTicker
extends AutocastTicker

# Luffy "Jet Gatling Burst" — Epic, UNIQUE.
# Every 9s, fires 16 fast bullets in a 45° forward cone over 0.6s.

const RUBBER_BULLET: PackedScene = preload("res://scenes/projectiles/PlayerBulletRubber.tscn")

@export var bullet_count: int = 16
@export var burst_duration: float = 0.6
@export var bullet_speed: float = 240.0
@export var pierce: int = 1
@export var damage_mult: float = 0.6
@export var spread_degrees: float = 45.0


func _ready() -> void:
	tick_interval = 9.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	_burst(p, dir)


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO


func _burst(p: Player, dir: Vector2) -> void:
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	var spread_rad: float = deg_to_rad(spread_degrees)
	var per_shot: float = burst_duration / float(bullet_count)
	for i: int in bullet_count:
		if not is_instance_valid(p):
			return
		var t: float = (randf() - 0.5) * spread_rad
		var shot_dir: Vector2 = dir.rotated(t)
		var b: Node = BulletPool.acquire(RUBBER_BULLET)
		if b != null and b.has_method("spawn"):
			var origin: Vector2 = p.muzzle.global_position if p.muzzle != null else p.global_position
			b.call("spawn", origin, shot_dir, bullet_speed, dmg, "player", pierce)
		# Audio rate-limited every 2nd bullet
		if i % 2 == 0:
			Audio.play("shoot", 0.3, -6.0)
		await get_tree().create_timer(per_shot).timeout

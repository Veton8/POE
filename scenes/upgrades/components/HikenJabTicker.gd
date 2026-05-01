class_name HikenJabTicker
extends AutocastTicker

# Ace "Hiken Jab" — Uncommon, LINEAR cap 4 (+1 fist per stack).
# Every 3s, fires N flame fists toward current_target. Each pierces 2,
# applies a 2s burn DoT to enemies hit.

const BURN_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")
const FIRE_BULLET: PackedScene = preload("res://scenes/projectiles/PlayerBulletFire.tscn")
const MAX_FISTS: int = 4

@export var fist_speed: float = 220.0
@export var pierce: int = 2
@export var damage_mult: float = 1.4
@export var burn_dps_mult: float = 0.3
@export var burn_duration: float = 2.0
@export var fan_degrees: float = 8.0

var fist_count: int = 1


func _ready() -> void:
	tick_interval = 3.0
	super._ready()


func bump() -> void:
	if fist_count < MAX_FISTS:
		fist_count += 1


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	var spread_rad: float = deg_to_rad(fan_degrees)
	for i: int in fist_count:
		var t: float = 0.0
		if fist_count > 1:
			t = (float(i) - float(fist_count - 1) * 0.5) / (float(fist_count - 1) * 0.5)
		var ang: float = t * spread_rad
		var shot_dir: Vector2 = dir.rotated(ang)
		var b: Node = BulletPool.acquire(FIRE_BULLET)
		if b == null or not b.has_method("spawn"):
			continue
		b.call("spawn", p.muzzle.global_position if p.muzzle != null else p.global_position,
			shot_dir, fist_speed, dmg, "player", pierce)
		if b is Bullet:
			(b as Bullet).burn_dps = float(p.stats.damage) * burn_dps_mult
			(b as Bullet).burn_duration = burn_duration
	Audio.play("shoot", 0.2, -2.0)


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO

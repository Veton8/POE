class_name HikenAbility
extends Ability

# Ace's W (Fire Fist). Pierces a long flame column forward; refreshes burn
# stacks on every enemy hit. Uses Ace's normal fire-bullet scene with
# extreme pierce + damage to read like a beam.

@export var damage_mult: float = 3.5
@export var pierce: int = 14
@export var speed_mult: float = 1.6


func _ready() -> void:
	super._ready()
	ability_name = "Hiken"
	cooldown_seconds = 10.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	Events.screen_shake.emit(8.0, 0.25)

	var aim: Vector2 = _aim_dir(p)
	var b: Node = BulletPool.acquire(p.bullet_scene)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		b.call("spawn", p.muzzle.global_position, aim, p.stats.bullet_speed * speed_mult, dmg, "player", pierce)
	VFX.spawn_muzzle_flash(p.muzzle.global_position, aim)
	VFX.spawn_death_particles(p.muzzle.global_position + aim * 10.0)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

class_name HinokamiSlashAbility
extends Ability

# Tanjiro Q. Wide flame-crescent slash projectile representing Hinokami
# Kagura's signature horizontal cut. Mid pierce, mid damage multiplier,
# short cooldown so it weaves into the basic-attack rhythm.

@export var damage_mult: float = 2.2
@export var pierce: int = 5
@export var speed_mult: float = 1.4


func _ready() -> void:
	super._ready()
	ability_name = "Hinokami Slash"
	cooldown_seconds = 5.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	Events.screen_shake.emit(4.0, 0.15)
	var aim: Vector2 = _aim_dir(p)
	var b: Node = BulletPool.acquire(p.bullet_scene)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		b.call("spawn", p.muzzle.global_position, aim, p.stats.bullet_speed * speed_mult, dmg, "player", pierce)
	VFX.spawn_muzzle_flash(p.muzzle.global_position, aim)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

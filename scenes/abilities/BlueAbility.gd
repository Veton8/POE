class_name BlueAbility
extends Ability

# Gojo's Q (Cursed Technique Lapse: Blue). Fires a large slow blue orb of
# attractive cursed energy. On hit, yanks enemies a substantial distance
# toward the impact point. Pierces — passes through enemies, dragging
# each one along the line.

const BLUE_ORB_SCENE: PackedScene = preload("res://scenes/projectiles/PlayerBulletBlueOrb.tscn")

@export var damage_mult: float = 2.0
@export var orb_speed: float = 90.0
@export var pierce: int = 12


func _ready() -> void:
	super._ready()
	ability_name = "Blue"
	cooldown_seconds = 12.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, -2.0)
	Events.screen_shake.emit(6.0, 0.2)

	var aim: Vector2 = _aim_dir(p)
	var b: Node = BulletPool.acquire(BLUE_ORB_SCENE)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		b.call("spawn", p.muzzle.global_position, aim, orb_speed, dmg, "player", pierce)
	VFX.spawn_muzzle_flash(p.muzzle.global_position, aim)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

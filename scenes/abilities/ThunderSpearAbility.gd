class_name ThunderSpearAbility
extends Ability

# Eren W. Fires a fast spear projectile, then 0.5s later detonates an AoE
# at the projectile's flight position dealing radius damage to nearby
# enemies. Two-stage payoff: the projectile chunks the first thing it hits,
# then the explosion finishes the cluster around it.

@export var spear_damage_mult: float = 2.5
@export var spear_speed_mult: float = 1.6
@export var explosion_delay: float = 0.5
@export var explosion_radius: float = 56.0
@export var explosion_damage: int = 5


func _ready() -> void:
	super._ready()
	ability_name = "Thunder Spear"
	cooldown_seconds = 9.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	var aim: Vector2 = _aim_dir(p)

	var b: Node = BulletPool.acquire(p.bullet_scene)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * spear_damage_mult)))
		b.call("spawn", p.muzzle.global_position, aim, p.stats.bullet_speed * spear_speed_mult, dmg, "player")
	VFX.spawn_muzzle_flash(p.muzzle.global_position, aim)

	var origin: Vector2 = p.muzzle.global_position
	var velocity: Vector2 = aim * p.stats.bullet_speed * spear_speed_mult
	await p.get_tree().create_timer(explosion_delay).timeout
	if not is_instance_valid(p):
		return
	var explosion_pos: Vector2 = origin + velocity * explosion_delay
	Events.screen_shake.emit(10.0, 0.3)
	VFX.spawn_death_particles(explosion_pos)

	for enemy: Node in p.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var e2d: Node2D = enemy as Node2D
		if explosion_pos.distance_to(e2d.global_position) > explosion_radius:
			continue
		var hb: HurtboxComponent = enemy.get_node_or_null("Hurtbox") as HurtboxComponent
		if hb != null:
			hb.receive_hit(explosion_damage, p, e2d.global_position)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

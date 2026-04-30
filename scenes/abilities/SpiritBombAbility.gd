class_name SpiritBombAbility
extends Ability

# Goku's Q (replaces Instant Transmission). Charge-up — Goku raises hands
# overhead and gathers blue-white energy — then hurls a massive slow-moving
# Spirit Bomb that pierces through everything in a wide path.

const SPIRIT_BOMB_SCENE: PackedScene = preload("res://scenes/projectiles/PlayerBulletSpiritBomb.tscn")

@export var damage_mult: float = 6.0
@export var charge_seconds: float = 1.2
@export var bomb_speed: float = 70.0
@export var pierce: int = 30


func _ready() -> void:
	super._ready()
	ability_name = "Spirit Bomb"
	cooldown_seconds = 18.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, -2.0)

	var orig_modulate: Color = p.sprite.modulate
	var tw: Tween = p.create_tween()
	tw.tween_property(p.sprite, "modulate", Color(0.7, 0.95, 1.8), charge_seconds)

	# Gather particles around Goku during charge
	var gather_steps: int = 6
	for i: int in gather_steps:
		if not is_instance_valid(p):
			return
		await p.get_tree().create_timer(charge_seconds / float(gather_steps)).timeout
		if is_instance_valid(p):
			var off: Vector2 = Vector2(randf_range(-14, 14), randf_range(-14, 14))
			VFX.spawn_hit_particles(p.global_position + off, Vector2.UP)

	if not is_instance_valid(p):
		return
	p.sprite.modulate = orig_modulate

	Events.screen_shake.emit(18.0, 0.5)
	var aim: Vector2 = _aim_dir(p)
	var b: Node = BulletPool.acquire(SPIRIT_BOMB_SCENE)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		b.call("spawn", p.muzzle.global_position, aim, bomb_speed, dmg, "player", pierce)
	for i: int in 3:
		VFX.spawn_muzzle_flash(p.muzzle.global_position + aim * float(i * 5), aim)
	VFX.spawn_death_particles(p.muzzle.global_position + aim * 12.0)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

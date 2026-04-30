class_name ElephantGunAbility
extends Ability

# Luffy's E (Gear 3 Elephant Gun). Wind-up — Luffy's body swells with a
# bright red-pink flush — then he hurls a HUGE rubber fist (visibly larger
# than any other projectile) that pierces a line of enemies for massive damage.

const GIANT_FIST_SCENE: PackedScene = preload("res://scenes/projectiles/PlayerBulletGiantFist.tscn")

@export var damage_mult: float = 3.5
@export var windup_seconds: float = 0.6
@export var slow_factor: float = 0.7
@export var range_mult: float = 1.5
@export var pierce: int = 8
@export var fist_scale_mult: float = 1.8
@export var giant_fist_speed_mult: float = 1.0
@export var min_fist_lifetime: float = 1.2


func _ready() -> void:
	super._ready()
	ability_name = "Elephant Gun"
	cooldown_seconds = 13.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, -2.0)
	# Wind-up: slow + Luffy swells with a deep red-pink tint (canon Gear 3 inflate)
	var orig_speed: float = p.stats.move_speed
	var orig_scale: Vector2 = p.sprite.scale
	var orig_modulate: Color = p.sprite.modulate
	p.stats.move_speed = orig_speed * slow_factor
	var tw: Tween = p.create_tween().set_parallel(true)
	tw.tween_property(p.sprite, "scale", orig_scale * fist_scale_mult, windup_seconds).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(p.sprite, "modulate", Color(1.6, 0.55, 0.45), windup_seconds)
	# Charge particles during windup
	for i: int in 4:
		if not is_instance_valid(p):
			return
		await p.get_tree().create_timer(windup_seconds * 0.25).timeout
		if is_instance_valid(p):
			VFX.spawn_hit_particles(p.global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10)), Vector2.UP)
	if not is_instance_valid(p):
		return
	p.stats.move_speed = orig_speed
	# Snap-back fist throw — sprite springs back to normal scale
	var spring: Tween = p.create_tween().set_parallel(true)
	spring.tween_property(p.sprite, "scale", orig_scale, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spring.tween_property(p.sprite, "modulate", orig_modulate, 0.15)
	# Heavy release VFX
	var aim: Vector2 = _aim_dir(p)
	for i: int in 3:
		VFX.spawn_muzzle_flash(p.muzzle.global_position + aim * float(i * 4), aim)
	VFX.spawn_hit_particles(p.muzzle.global_position + aim * 12.0, aim)
	VFX.spawn_death_particles(p.muzzle.global_position)
	Events.screen_shake.emit(14.0, 0.35)
	# Hurl the giant fist
	var b: Node = BulletPool.acquire(GIANT_FIST_SCENE)
	if b != null and b.has_method("spawn"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		var speed: float = p.stats.bullet_speed * giant_fist_speed_mult
		b.call("spawn", p.muzzle.global_position, aim, speed, dmg, "player", pierce)
		if "lifetime" in b:
			# Lifetime governs how far the fist flies — keep it long enough to
			# read visually even when fired without a nearby target.
			var computed: float = (p.stats.detection_radius * range_mult) / speed
			b.set("lifetime", maxf(computed, min_fist_lifetime))


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

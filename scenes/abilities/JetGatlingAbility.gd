class_name JetGatlingAbility
extends Ability

# Luffy's W. 1.5s flurry of rubber fists in a tight forward cone. Luffy
# flushes pink at activation and visibly slides forward as he commits to
# the attack lane.

@export var fist_count: int = 12
@export var burst_duration: float = 1.5
@export var damage_mult: float = 0.8
@export var spread_degrees: float = 60.0
@export var slide_per_volley: float = 8.0
@export var burst_modulate: Color = Color(1.6, 0.5, 0.6)


func _ready() -> void:
	super._ready()
	ability_name = "Jet Gatling"
	cooldown_seconds = 9.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, -2.0)
	Events.screen_shake.emit(6.0, burst_duration)

	# Activation flash — Luffy goes bright pink for the whole burst
	var orig_modulate: Color = p.sprite.modulate
	var fade_tw: Tween = p.create_tween()
	fade_tw.tween_property(p.sprite, "modulate", burst_modulate, 0.08)

	var aim: Vector2 = _aim_dir(p)
	var interval: float = burst_duration / float(fist_count)
	var half_spread: float = deg_to_rad(spread_degrees * 0.5)
	for i: int in fist_count:
		if not is_instance_valid(p):
			return
		var dir: Vector2 = aim.rotated(randf_range(-half_spread, half_spread))
		var b: Node = BulletPool.acquire(p.bullet_scene)
		if b != null and b.has_method("spawn"):
			var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
			b.call("spawn", p.muzzle.global_position, dir, p.stats.bullet_speed, dmg, "player")
		VFX.spawn_muzzle_flash(p.muzzle.global_position, dir)
		# Steam puff every other fist for the rapid-fire feel
		if i % 2 == 0:
			VFX.spawn_hit_particles(p.global_position + Vector2(randf_range(-4, 4), randf_range(-2, 4)), Vector2.UP)
		Audio.play("shoot", 0.10, -8.0)
		p.global_position += aim * slide_per_volley
		await p.get_tree().create_timer(interval).timeout

	if is_instance_valid(p):
		var fade_back: Tween = p.create_tween()
		fade_back.tween_property(p.sprite, "modulate", orig_modulate, 0.15)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

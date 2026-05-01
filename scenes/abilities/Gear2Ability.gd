class_name Gear2Ability
extends Ability

# Luffy's Q. Floods the sprite bright pink with a pulsing shimmer + a
# periodic shader flash, vents steam particles, +50% move_speed,
# +30% fire_rate for 4s. 0.3s i-frame at activation for the burst-step.

@export var move_speed_mult: float = 1.5
@export var fire_rate_mult: float = 1.3
@export var duration: float = 4.0
@export var iframe_seconds: float = 0.3
@export var pink_bright: Color = Color(1.8, 0.4, 0.6)
@export var pink_dim: Color = Color(1.4, 0.55, 0.7)
@export var steam_interval: float = 0.18
@export var shimmer_interval: float = 0.35
@export var shimmer_duration: float = 0.07
@export var shimmer_color: Vector3 = Vector3(1.0, 0.55, 0.72)


func _ready() -> void:
	super._ready()
	ability_name = "Gear 2"
	cooldown_seconds = 10.0
	target_strategy = TargetStrategy.SELF_AOE


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_dash", 0.05, 0.0)

	var orig_speed: float = p.stats.move_speed
	var orig_rate: float = p.stats.fire_rate
	var orig_modulate: Color = p.sprite.modulate
	p.stats.move_speed = orig_speed * move_speed_mult
	p.stats.fire_rate = orig_rate * fire_rate_mult
	p.fire_timer.wait_time = 1.0 / p.stats.fire_rate

	# Pulsing pink shimmer on the sprite
	var pulse_tw: Tween = p.create_tween().set_loops()
	pulse_tw.tween_property(p.sprite, "modulate", pink_bright, 0.22).set_trans(Tween.TRANS_SINE)
	pulse_tw.tween_property(p.sprite, "modulate", pink_dim, 0.22).set_trans(Tween.TRANS_SINE)

	# Periodic steam puffs while Gear 2 is active
	var steam_timer: Timer = Timer.new()
	steam_timer.wait_time = steam_interval
	steam_timer.autostart = true
	p.add_child(steam_timer)
	var steam_tick: Callable = func() -> void:
		if is_instance_valid(p):
			var off: Vector2 = Vector2(randf_range(-6.0, 6.0), randf_range(-2.0, 6.0))
			VFX.spawn_hit_particles(p.global_position + off, Vector2.UP)
	steam_timer.timeout.connect(steam_tick)

	# Shimmer: briefly flash the entire sprite pink via the hit_flash shader
	var mat: ShaderMaterial = p.sprite.material as ShaderMaterial
	var shimmer_timer: Timer = null
	if mat != null:
		mat.set_shader_parameter("flash_color", shimmer_color)
		shimmer_timer = Timer.new()
		shimmer_timer.wait_time = shimmer_interval
		shimmer_timer.autostart = true
		p.add_child(shimmer_timer)
		var shimmer_tick: Callable = func() -> void:
			if not is_instance_valid(p) or mat == null:
				return
			mat.set_shader_parameter("active", true)
			await p.get_tree().create_timer(shimmer_duration).timeout
			if is_instance_valid(p) and mat != null:
				mat.set_shader_parameter("active", false)
		shimmer_timer.timeout.connect(shimmer_tick)

	# I-frames at activation
	p.set_collision_mask_value(3, false)
	if p.hurtbox != null:
		p.hurtbox.set_deferred("monitorable", false)
	await p.get_tree().create_timer(iframe_seconds).timeout
	if is_instance_valid(p):
		p.set_collision_mask_value(3, true)
		if p.hurtbox != null:
			p.hurtbox.set_deferred("monitorable", true)

	# Hold the buff for the rest of the duration
	var remaining: float = maxf(duration - iframe_seconds, 0.0)
	if remaining > 0.0 and is_instance_valid(p):
		await p.get_tree().create_timer(remaining).timeout

	if is_instance_valid(p):
		p.stats.move_speed = orig_speed
		p.stats.fire_rate = orig_rate
		p.fire_timer.wait_time = 1.0 / orig_rate
		if pulse_tw != null and pulse_tw.is_valid():
			pulse_tw.kill()
		p.sprite.modulate = orig_modulate
		if mat != null:
			mat.set_shader_parameter("active", false)
	if is_instance_valid(steam_timer):
		steam_timer.queue_free()
	if shimmer_timer != null and is_instance_valid(shimmer_timer):
		shimmer_timer.queue_free()

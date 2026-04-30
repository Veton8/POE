class_name KaiokenAbility
extends Ability

# Goku's E. Crimson aura: +60% damage, +25% fire-rate, +20% move-speed for
# 5s. Costs 1 HP per second — canon body strain. Cannot be cast at 1 HP.

@export var damage_mult: float = 1.6
@export var fire_rate_mult: float = 1.25
@export var move_speed_mult: float = 1.2
@export var duration: float = 5.0
@export var aura_color: Color = Color(1.6, 0.4, 0.4)


func _ready() -> void:
	super._ready()
	ability_name = "Kaio-ken"
	cooldown_seconds = 14.0


func _can_activate() -> bool:
	var p: Player = get_player()
	return p != null and p.health.current > 1


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_dash", 0.05, 0.0)

	var orig_damage: int = p.stats.damage
	var orig_rate: float = p.stats.fire_rate
	var orig_speed: float = p.stats.move_speed
	var orig_modulate: Color = p.sprite.modulate

	p.stats.damage = max(1, int(round(float(orig_damage) * damage_mult)))
	p.stats.fire_rate = orig_rate * fire_rate_mult
	p.stats.move_speed = orig_speed * move_speed_mult
	p.fire_timer.wait_time = 1.0 / p.stats.fire_rate
	p.sprite.modulate = aura_color

	# HP drain — 1 HP per second while active, won't kill the player
	var hp_timer: Timer = Timer.new()
	hp_timer.wait_time = 1.0
	hp_timer.autostart = true
	p.add_child(hp_timer)
	var drain_tick: Callable = func() -> void:
		if is_instance_valid(p) and p.health.current > 1:
			p.health.take_damage(1, self)
	hp_timer.timeout.connect(drain_tick)

	# Aura particle puffs
	var puff_timer: Timer = Timer.new()
	puff_timer.wait_time = 0.18
	puff_timer.autostart = true
	p.add_child(puff_timer)
	var puff_tick: Callable = func() -> void:
		if is_instance_valid(p):
			var off: Vector2 = Vector2(randf_range(-8, 8), randf_range(-8, 8))
			VFX.spawn_hit_particles(p.global_position + off, Vector2.UP)
	puff_timer.timeout.connect(puff_tick)

	await p.get_tree().create_timer(duration).timeout

	if is_instance_valid(p):
		p.stats.damage = orig_damage
		p.stats.fire_rate = orig_rate
		p.stats.move_speed = orig_speed
		p.fire_timer.wait_time = 1.0 / orig_rate
		p.sprite.modulate = orig_modulate
	if is_instance_valid(hp_timer):
		hp_timer.queue_free()
	if is_instance_valid(puff_timer):
		puff_timer.queue_free()

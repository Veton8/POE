class_name SpinAttackAbility
extends Ability

# Levi E. 1.2-second invulnerable rotation in place that ticks 2 damage
# every 0.1s to anything within `spin_radius`. Up to 24 dmg total to a
# single target standing in the radius for the full duration. Visual is a
# fast sprite rotation with a slight glow tint.

@export var spin_duration: float = 1.2
@export var spin_radius: float = 50.0
@export var damage_per_tick: int = 2
@export var tick_interval: float = 0.1


func _ready() -> void:
	super._ready()
	ability_name = "Levi's Spin"
	target_strategy = TargetStrategy.SELF_AOE
	cooldown_seconds = 11.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	Events.screen_shake.emit(6.0, spin_duration)

	if p.hurtbox != null:
		p.hurtbox.set_deferred("monitorable", false)

	var orig_modulate: Color = p.sprite.modulate
	p.sprite.modulate = Color(1.4, 1.4, 1.6, 1)
	var spin_tw: Tween = p.create_tween()
	spin_tw.tween_property(p.sprite, "rotation", TAU * 4.0, spin_duration)

	var elapsed: float = 0.0
	while elapsed < spin_duration:
		if not is_instance_valid(p):
			return
		for enemy: Node in p.get_tree().get_nodes_in_group("enemies"):
			if not (enemy is Node2D):
				continue
			var e2d: Node2D = enemy as Node2D
			if p.global_position.distance_to(e2d.global_position) > spin_radius:
				continue
			var hb: HurtboxComponent = enemy.get_node_or_null("Hurtbox") as HurtboxComponent
			if hb != null:
				hb.receive_hit(damage_per_tick, p, e2d.global_position)
		await p.get_tree().create_timer(tick_interval).timeout
		elapsed += tick_interval

	if is_instance_valid(p):
		p.sprite.rotation = 0.0
		p.sprite.modulate = orig_modulate
		if p.hurtbox != null:
			p.hurtbox.set_deferred("monitorable", true)

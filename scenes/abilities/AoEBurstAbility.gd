class_name AoEBurstAbility
extends Ability

@export var radius: float = 64.0
@export var damage: int = 3
@export var knockback_strength: float = 200.0

func _ready() -> void:
	super._ready()
	ability_name = "AoE Burst"
	target_strategy = TargetStrategy.SELF_AOE

func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	Events.screen_shake.emit(10.0, 0.25)
	VFX.spawn_death_particles(p.global_position)
	var space: PhysicsDirectSpaceState2D = p.get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0.0, p.global_position)
	query.collision_mask = 1 << 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits: Array[Dictionary] = space.intersect_shape(query, 64)
	for h in hits:
		var hb: HurtboxComponent = h["collider"] as HurtboxComponent
		if hb == null:
			continue
		hb.receive_hit(damage, p, hb.global_position)
		var enemy: CharacterBody2D = hb.get_parent() as CharacterBody2D
		if enemy:
			var dir: Vector2 = (enemy.global_position - p.global_position).normalized()
			enemy.velocity = dir * knockback_strength

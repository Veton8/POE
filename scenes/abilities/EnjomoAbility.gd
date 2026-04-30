class_name EnjomoAbility
extends Ability

# Ace's E. Detonates a fire ring around Ace — instant AoE damage and
# applies max-stack burn DoT to every enemy caught in it.

const BURN_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")

@export var radius: float = 80.0
@export var damage: int = 4
@export var burn_dps: float = 1.0
@export var burn_duration: float = 4.0


func _ready() -> void:
	super._ready()
	ability_name = "Enjomo"
	cooldown_seconds = 16.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	Events.screen_shake.emit(12.0, 0.3)
	VFX.spawn_death_particles(p.global_position)

	var space: PhysicsDirectSpaceState2D = p.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0.0, p.global_position)
	query.collision_mask = 1 << 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits: Array[Dictionary] = space.intersect_shape(query, 64)

	for h: Dictionary in hits:
		var hb: HurtboxComponent = h["collider"] as HurtboxComponent
		if hb == null:
			continue
		hb.receive_hit(damage, p, hb.global_position)
		var enemy_parent: Node = hb.get_parent()
		if enemy_parent != null:
			_apply_burn(enemy_parent)
		var dir: Vector2 = (hb.global_position - p.global_position).normalized()
		VFX.spawn_hit_particles(hb.global_position, dir)


func _apply_burn(target: Node) -> void:
	var existing: Node = target.get_node_or_null("BurnComponent")
	if existing != null and existing is BurnComponent:
		(existing as BurnComponent).refresh(burn_dps, burn_duration)
	else:
		var burn: BurnComponent = BurnComponent.new()
		burn.name = "BurnComponent"
		burn.set_script(BURN_COMPONENT_SCRIPT)
		burn.damage_per_second = burn_dps
		burn.duration = burn_duration
		target.add_child(burn)

class_name BreakablePillar
extends HurtboxComponent

# Destructible cover pillar used by Drowned Curator's R10 arena. Joins the
# `breakable_pillars` group on spawn so the boss can poll how many remain;
# when destroyed, removes itself with a hit-particle puff.

const PILLAR_HP: int = 8

@onready var pillar_health: HealthComponent = $HealthComponent


func _ready() -> void:
	super._ready()
	add_to_group("breakable_pillars")
	if pillar_health != null:
		pillar_health.died.connect(_on_died)


func _on_died() -> void:
	VFX.spawn_death_particles(global_position)
	Events.screen_shake.emit(4.0, 0.15)
	queue_free()

class_name HealingTotem
extends HurtboxComponent

# Bone Choir final-boss adjunct. Joins the `healing_totems` group on spawn
# so Cantor Eternal can poll how many remain. The boss reads that count
# once per heal tick — this script just holds HP and dies cleanly.

@onready var totem_health: HealthComponent = $HealthComponent


func _ready() -> void:
	super._ready()
	add_to_group("healing_totems")
	if totem_health != null:
		totem_health.died.connect(_on_died)


func _on_died() -> void:
	VFX.spawn_death_particles(global_position)
	Events.screen_shake.emit(5.0, 0.2)
	queue_free()

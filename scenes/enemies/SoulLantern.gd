class_name SoulLantern
extends EnemyBase

# Slow drifting healer. Every `heal_interval` seconds, restores 1 HP to every
# other enemy inside `heal_radius` (skipping any already at full). Pulses a
# brief green tint when it heals at least one ally.

@export var heal_radius: float = 80.0
@export var heal_amount: int = 1
@export var heal_interval: float = 2.0

var _heal_t: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_heal_t += delta
	if _heal_t >= heal_interval:
		_heal_t = 0.0
		_heal_nearby()


func _heal_nearby() -> void:
	var healed_any: bool = false
	for n in get_tree().get_nodes_in_group("enemies"):
		if n == self or not (n is Node2D):
			continue
		if global_position.distance_to((n as Node2D).global_position) > heal_radius:
			continue
		var hp_node: HealthComponent = n.get_node_or_null("HealthComponent") as HealthComponent
		if hp_node == null:
			continue
		if hp_node.current >= hp_node.max_hp:
			continue
		hp_node.heal(heal_amount)
		healed_any = true
	if healed_any:
		sprite.modulate = Color(0.6, 1.5, 0.7, 1)
		var tw: Tween = create_tween()
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)

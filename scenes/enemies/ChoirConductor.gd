class_name ChoirConductor
extends EnemyBase

# Bone Choir support unit. Periodically pulses a speed buff onto every other
# enemy inside `buff_radius`, attaching/refreshing a BuffComponent on each.
# Doesn't shoot; relies on the swarm it's amplifying. Priority kill target.

const BUFF_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BuffComponent.gd")

@export var buff_radius: float = 96.0
@export var buff_speed_mul: float = 1.55
@export var pulse_interval: float = 0.45

var _pulse_t: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_pulse_t += delta
	if _pulse_t >= pulse_interval:
		_pulse_t = 0.0
		_pulse_buff()


func _pulse_buff() -> void:
	var any: bool = false
	for n in get_tree().get_nodes_in_group("enemies"):
		if n == self or not (n is EnemyBase):
			continue
		var e: EnemyBase = n as EnemyBase
		if global_position.distance_to(e.global_position) > buff_radius:
			continue
		var existing: Node = e.get_node_or_null("BuffComponent")
		if existing != null and existing.has_method("refresh"):
			existing.call("refresh", 0.7, buff_speed_mul)
		else:
			var buff: Node = BUFF_COMPONENT_SCRIPT.new()
			buff.name = "BuffComponent"
			e.add_child(buff)
		any = true
	if any:
		sprite.modulate = Color(1.5, 1.5, 0.6, 1)
	else:
		sprite.modulate = Color.WHITE

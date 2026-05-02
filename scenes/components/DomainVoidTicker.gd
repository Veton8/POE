class_name DomainVoidTicker
extends Node

# Gojo's "Domain Expansion: Void" — every `interval`, every enemy in the
# active scene loses `freeze_seconds` of action time (BuffComponent at 0.0
# move_speed_mul + cancellation of attacks via group call). Visual: white
# screen flash + dark vignette via VFX.

@export var interval: float = 18.0
@export var freeze_seconds: float = 2.0

var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t < interval:
		return
	_t = 0.0
	_unleash()


func _unleash() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is EnemyBase):
			continue
		var existing: Node = n.get_node_or_null("BuffComponent")
		if existing is BuffComponent:
			(existing as BuffComponent).refresh(freeze_seconds, 0.0)
			continue
		var buff: BuffComponent = BuffComponent.new()
		buff.name = "BuffComponent"
		buff.duration = freeze_seconds
		buff.speed_mul = 0.0
		n.add_child(buff)
	if has_node("/root/Events"):
		Events.screen_shake.emit(8.0, 0.3)
	Audio.play("ability_burst", 0.05, 4.0)

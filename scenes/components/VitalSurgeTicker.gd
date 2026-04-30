class_name VitalSurgeTicker
extends Node

# Heals the player 1 HP every `interval`. Stacks: each call to bump() shaves
# the interval down (faster regen at higher stacks).

@export var interval: float = 6.0
@export var min_interval: float = 2.0
var _t: float = 0.0


func bump() -> void:
	interval = maxf(min_interval, interval - 1.0)


func _process(delta: float) -> void:
	var p: Player = get_parent() as Player
	if p == null or p.health == null or p.health.is_dead():
		queue_free()
		return
	if p.health.current >= p.health.max_hp:
		_t = 0.0
		return
	_t += delta
	if _t >= interval:
		_t = 0.0
		p.health.heal(1)

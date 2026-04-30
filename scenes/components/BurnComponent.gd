class_name BurnComponent
extends Node

# Attached dynamically to an enemy when a burning bullet hits.
# Ticks damage on the parent's HealthComponent every second.

const TICK_INTERVAL: float = 1.0

@export var damage_per_second: float = 1.0
@export var duration: float = 3.0

var _health: HealthComponent = null
var _elapsed: float = 0.0
var _next_tick: float = TICK_INTERVAL


func _ready() -> void:
	var parent: Node = get_parent()
	if parent != null:
		_health = parent.get_node_or_null("HealthComponent") as HealthComponent
	if _health == null:
		queue_free()


func refresh(new_dps: float, new_duration: float) -> void:
	# Refresh-on-hit: keep stronger DPS, reset timer
	damage_per_second = max(damage_per_second, new_dps)
	duration = new_duration
	_elapsed = 0.0


func _process(delta: float) -> void:
	if _health == null or _health.is_dead():
		queue_free()
		return
	_elapsed += delta
	_next_tick -= delta
	if _next_tick <= 0.0:
		var amt: int = max(1, int(round(damage_per_second)))
		_health.take_damage(amt, self)
		_next_tick = TICK_INTERVAL
	if _elapsed >= duration:
		queue_free()

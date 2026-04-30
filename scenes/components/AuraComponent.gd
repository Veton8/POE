class_name AuraComponent
extends Node2D

# Attached to the player via UpgradeData.component_to_attach.
# Pulses damage to enemies inside `radius` every `tick_interval`.
# Drawn as a faint translucent ring so the player can see it.

@export var radius: float = 36.0
@export var damage_per_tick: int = 1
@export var tick_interval: float = 0.6
@export var color: Color = Color(1.0, 0.6, 0.2, 0.18)

var _t: float = 0.0
var _player: Node2D = null


func _ready() -> void:
	z_index = -1
	_player = get_parent() as Node2D


func attach_to(host: Node) -> void:
	_player = host as Node2D


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	global_position = _player.global_position
	_t -= delta
	if _t <= 0.0:
		_t = tick_interval
		_pulse()
	queue_redraw()


func _pulse() -> void:
	var center: Vector2 = global_position
	var r2: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		var n2d: Node2D = n as Node2D
		if center.distance_squared_to(n2d.global_position) > r2:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb == null:
			# Fallback: try direct HealthComponent damage
			var hp: Node = n.get_node_or_null("HealthComponent")
			if hp != null and hp is HealthComponent:
				(hp as HealthComponent).take_damage(damage_per_tick, self)
			continue
		var hbc: HurtboxComponent = hb as HurtboxComponent
		if hbc != null:
			hbc.receive_hit(damage_per_tick, self, n2d.global_position)


func _draw() -> void:
	# A pulse-fade ring centered on the player. Phase tracks the next-tick timer.
	var phase: float = 1.0 - clampf(_t / tick_interval, 0.0, 1.0)
	var r: float = radius * (0.6 + 0.4 * phase)
	var col: Color = color
	col.a = color.a * (1.0 - phase * 0.6)
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, col, 2.0)

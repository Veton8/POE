extends Node2D

# Telegraphed slam — pulses an outline circle at fixed world pos for
# telegraph_seconds, then deals AoE damage + applies BuffComponent
# stun (speed_mul = 0) to non-boss enemies in radius.

var _damage: int = 1
var _radius: float = 80.0
var _telegraph: float = 0.7
var _stun: float = 1.2
var _t: float = 0.0
var _impacted: bool = false


func configure(dmg: int, radius: float, telegraph: float, stun: float) -> void:
	_damage = dmg
	_radius = radius
	_telegraph = telegraph
	_stun = stun


func _ready() -> void:
	z_index = 5
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	if not _impacted and _t >= _telegraph:
		_impacted = true
		_impact()
	if _t >= _telegraph + 0.3:
		queue_free()
		return
	queue_redraw()


func _impact() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(global_position) > _radius * _radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)
		# Stun via BuffComponent (skip bosses)
		if not n.is_in_group("boss"):
			var existing: Node = n.get_node_or_null("BuffComponent")
			if existing is BuffComponent:
				(existing as BuffComponent).refresh(_stun, 0.0)
			else:
				var buff: BuffComponent = BuffComponent.new()
				buff.name = "BuffComponent"
				buff.duration = _stun
				buff.speed_mul = 0.0
				n.add_child(buff)
	Audio.play("ability_burst", -0.4, 4.0)
	Events.screen_shake.emit(5.0, 0.3)


func _draw() -> void:
	if not _impacted:
		# Telegraph circle — pulsing ring (sin-driven on _t)
		var col: Color = Color(1.0, 0.55, 0.40, 0.50 + 0.45 * sin(_t * 12.0))
		draw_arc(Vector2.ZERO, _radius, 0.0, TAU, 48, col, 2.0)
	else:
		# Impact shockwave fading out
		var phase: float = (_t - _telegraph) / 0.3
		var alpha: float = clampf(1.0 - phase, 0.0, 1.0)
		draw_circle(Vector2.ZERO, _radius * (1.0 + phase * 0.4), Color(1.0, 0.85, 0.55, 0.4 * alpha))

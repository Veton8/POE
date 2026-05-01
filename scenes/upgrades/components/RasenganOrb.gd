extends Node2D

# Homing Rasengan orb — pursues target, explodes on contact for AoE.
# Self-frees after 4s if target is gone.

var _target: Node2D = null
var _damage: int = 1
var _aoe: float = 40.0
var _speed: float = 180.0
var _t_alive: float = 0.0
var _spin: float = 0.0


func configure(target: Node2D, dmg: int, aoe: float, speed: float) -> void:
	_target = target
	_damage = dmg
	_aoe = aoe
	_speed = speed


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_t_alive += delta
	_spin += delta * 8.0
	if _t_alive > 4.0:
		queue_free()
		return
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	var dir: Vector2 = (_target.global_position - global_position).normalized()
	global_position += dir * _speed * delta
	if global_position.distance_to(_target.global_position) < 8.0:
		_explode()
		return
	queue_redraw()


func _explode() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(global_position) > _aoe * _aoe:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)
	VFX.spawn_hit_particles(global_position, Vector2.ZERO)
	Audio.play("ability_burst", 0.4, -2.0)
	queue_free()


func _draw() -> void:
	# Cyan-white swirl — outer ring + inner core, both rotated by _spin
	var ang: float = _spin
	for i: int in 4:
		var a: float = ang + i * (TAU / 4.0)
		var p: Vector2 = Vector2(cos(a), sin(a)) * 4.0
		draw_circle(p, 2.0, Color(0.7, 0.95, 1.0, 0.85))
	draw_circle(Vector2.ZERO, 4.0, Color(1.0, 1.0, 1.0, 0.95))
	draw_circle(Vector2.ZERO, 2.0, Color(1.0, 1.0, 1.0, 1.0))

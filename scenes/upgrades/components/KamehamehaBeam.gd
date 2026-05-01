extends Node2D

# One-shot Kamehameha beam. Lives for `_duration`, ticks damage every
# `_tick_interval` to enemies inside its rectangle (length × width
# extending forward from origin in `rotation` direction). Free on end.

var _damage: int = 1
var _length: float = 320.0
var _width: float = 16.0
var _duration: float = 0.5
var _tick_interval: float = 0.1

var _t_alive: float = 0.0
var _t_tick: float = 0.0
var _hit_this_tick: Array[Node] = []


func configure(dmg: int, length: float, width: float, duration: float, tick: float) -> void:
	_damage = dmg
	_length = length
	_width = width
	_duration = duration
	_tick_interval = tick


func _ready() -> void:
	z_index = 4
	queue_redraw()


func _process(delta: float) -> void:
	_t_alive += delta
	if _t_alive >= _duration:
		queue_free()
		return
	_t_tick -= delta
	if _t_tick <= 0.0:
		_t_tick = _tick_interval
		_tick_damage()
	queue_redraw()


func _tick_damage() -> void:
	_hit_this_tick.clear()
	# Build query rectangle: in local space the beam goes from x=0..length,
	# y=-width/2..+width/2. Convert each enemy to local space to test.
	var inv: Transform2D = global_transform.affine_inverse()
	var half_w: float = _width * 0.5
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		var n2d: Node2D = n as Node2D
		var local: Vector2 = inv * n2d.global_position
		if local.x < 0.0 or local.x > _length:
			continue
		if absf(local.y) > half_w:
			continue
		if _hit_this_tick.has(n):
			continue
		_hit_this_tick.append(n)
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, n2d.global_position)


func _draw() -> void:
	# Lifetime-driven alpha pulse (fade-in 0..0.1, hold, fade-out last 0.1)
	var alpha: float = 1.0
	if _t_alive < 0.08:
		alpha = _t_alive / 0.08
	elif _t_alive > _duration - 0.12:
		alpha = clampf((_duration - _t_alive) / 0.12, 0.0, 1.0)
	# Beam halo
	var halo: Color = Color(0.65, 0.95, 1.0, 0.35 * alpha)
	draw_rect(Rect2(Vector2(0, -_width * 0.6), Vector2(_length, _width * 1.2)), halo, true)
	# Core
	var core: Color = Color(0.95, 1.0, 1.0, 0.95 * alpha)
	draw_rect(Rect2(Vector2(0, -_width * 0.5), Vector2(_length, _width)), core, true)
	# White hot center stripe
	var hot: Color = Color(1.0, 1.0, 1.0, 1.0 * alpha)
	draw_rect(Rect2(Vector2(0, -_width * 0.18), Vector2(_length, _width * 0.36)), hot, true)

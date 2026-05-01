extends Node2D

# World-anchored fire wall — ticks damage to enemies overlapping its
# rectangle every tick_seconds. Visual is a flickering animated strip.

var _damage: int = 1
var _length: float = 120.0
var _height: float = 24.0
var _duration: float = 4.0
var _tick_seconds: float = 0.3

var _t_alive: float = 0.0
var _t_tick: float = 0.0


func configure(dmg: int, length: float, height: float, duration: float, tick: float) -> void:
	_damage = dmg
	_length = length
	_height = height
	_duration = duration
	_tick_seconds = tick


func _ready() -> void:
	z_index = 3
	queue_redraw()


func _process(delta: float) -> void:
	_t_alive += delta
	if _t_alive >= _duration:
		queue_free()
		return
	_t_tick -= delta
	if _t_tick <= 0.0:
		_t_tick = _tick_seconds
		_apply_damage()
	queue_redraw()


func _apply_damage() -> void:
	var inv: Transform2D = global_transform.affine_inverse()
	var hh: float = _height * 0.5
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		var local: Vector2 = inv * (n as Node2D).global_position
		# Curtain extends -length/2..+length/2 along x in local space
		if absf(local.x) > _length * 0.5:
			continue
		if absf(local.y) > hh:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)


func _draw() -> void:
	var alpha: float = 1.0
	if _t_alive > _duration - 0.4:
		alpha = clampf((_duration - _t_alive) / 0.4, 0.0, 1.0)
	var flicker: float = (sin(_t_alive * 18.0) + 1.0) * 0.5
	var w: float = _length * 0.5
	var h: float = _height * 0.5
	# Outer red glow
	draw_rect(Rect2(Vector2(-w, -h * 1.4), Vector2(_length, _height * 1.4)), Color(0.95, 0.20, 0.10, 0.30 * alpha), true)
	# Mid orange
	draw_rect(Rect2(Vector2(-w, -h), Vector2(_length, _height)), Color(1.0, 0.45, 0.10, 0.85 * alpha), true)
	# Inner yellow stripe (flickers)
	draw_rect(Rect2(Vector2(-w, -h * 0.4), Vector2(_length, _height * 0.4)), Color(1.0, 0.85, 0.30, (0.4 + flicker * 0.5) * alpha), true)

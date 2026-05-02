extends Node2D

# One-shot Hollow Purple beam — purple-magenta with red-blue lattice
# halo. Single hit per enemy (full pierce, no per-tick reapply).

var _damage: int = 1
var _length: float = 240.0
var _width: float = 12.0
var _duration: float = 0.35

var _t_alive: float = 0.0
var _hit: Array[Node] = []


func configure(dmg: int, length: float, width: float, duration: float) -> void:
	_damage = dmg
	_length = length
	_width = width
	_duration = duration


func _ready() -> void:
	z_index = 4
	queue_redraw()
	_apply_damage()


func _apply_damage() -> void:
	var inv: Transform2D = global_transform.affine_inverse()
	var half_w: float = _width * 0.5
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var local: Vector2 = inv * (n as Node2D).global_position
		if local.x < 0.0 or local.x > _length:
			continue
		if absf(local.y) > half_w:
			continue
		if _hit.has(n):
			continue
		_hit.append(n)
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)


func _process(delta: float) -> void:
	_t_alive += delta
	if _t_alive >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha: float = 1.0
	if _t_alive < 0.05:
		alpha = _t_alive / 0.05
	elif _t_alive > _duration - 0.10:
		alpha = clampf((_duration - _t_alive) / 0.10, 0.0, 1.0)
	# Outer red+blue lattice halo
	draw_rect(Rect2(Vector2(0, -_width * 0.7), Vector2(_length, _width * 1.4)), Color(0.95, 0.25, 0.25, 0.20 * alpha), true)
	draw_rect(Rect2(Vector2(0, -_width * 0.55), Vector2(_length, _width * 1.1)), Color(0.30, 0.45, 0.95, 0.30 * alpha), true)
	# Purple core
	draw_rect(Rect2(Vector2(0, -_width * 0.5), Vector2(_length, _width)), Color(0.65, 0.20, 0.85, 0.95 * alpha), true)
	# White-magenta hot stripe
	draw_rect(Rect2(Vector2(0, -_width * 0.18), Vector2(_length, _width * 0.36)), Color(1.0, 0.85, 1.0, 1.0 * alpha), true)

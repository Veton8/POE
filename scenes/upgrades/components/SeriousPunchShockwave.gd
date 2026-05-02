extends Node2D

# White-hot shockwave rectangle for Saitama's Serious Punch. Single
# damage application at spawn; visual fades over 0.4s.

var _damage: int = 1
var _boss_damage: int = 1
var _length: float = 240.0
var _width: float = 60.0
var _execute_threshold: float = 0.40
var _execute_overkill: int = 99999

var _t: float = 0.0
var _duration: float = 0.4


func configure(dmg: int, boss_dmg: int, length: float, width: float, threshold: float, overkill: int) -> void:
	_damage = dmg
	_boss_damage = boss_dmg
	_length = length
	_width = width
	_execute_threshold = threshold
	_execute_overkill = overkill


func _ready() -> void:
	z_index = 6
	_apply()
	queue_redraw()


func _apply() -> void:
	var inv: Transform2D = global_transform.affine_inverse()
	var hh: float = _width * 0.5
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var local: Vector2 = inv * (n as Node2D).global_position
		if local.x < 0.0 or local.x > _length:
			continue
		if absf(local.y) > hh:
			continue
		var hp: HealthComponent = n.get_node_or_null("HealthComponent") as HealthComponent
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		var is_boss: bool = n.is_in_group("boss")
		if is_boss:
			if hb is HurtboxComponent:
				(hb as HurtboxComponent).receive_hit(_boss_damage, self, (n as Node2D).global_position)
			continue
		# Execute below threshold
		if hp != null and float(hp.current) / float(max(1, hp.max_hp)) <= _execute_threshold:
			hp.take_damage(_execute_overkill, self)
			continue
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)


func _process(delta: float) -> void:
	_t += delta
	if _t >= _duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var alpha: float = clampf(1.0 - _t / _duration, 0.0, 1.0)
	# Outer glow
	draw_rect(Rect2(Vector2(0, -_width * 0.65), Vector2(_length, _width * 1.3)), Color(1.0, 0.95, 0.85, 0.4 * alpha), true)
	# Mid white
	draw_rect(Rect2(Vector2(0, -_width * 0.5), Vector2(_length, _width)), Color(1.0, 1.0, 1.0, 0.85 * alpha), true)
	# Hot core
	draw_rect(Rect2(Vector2(0, -_width * 0.20), Vector2(_length, _width * 0.40)), Color(1.0, 1.0, 1.0, 1.0 * alpha), true)

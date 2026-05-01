extends Node2D

# Stationary crystal spike — damages any enemy that overlaps every
# hit_delay seconds. Despawns after duration.

var _damage: int = 1
var _duration: float = 3.0
var _hit_delay: float = 0.4

var _t_alive: float = 0.0
var _hit_cooldowns: Dictionary = {}  # iid -> next-hit time (seconds)


func configure(dmg: int, duration: float, hit_delay: float) -> void:
	_damage = dmg
	_duration = duration
	_hit_delay = hit_delay


func _ready() -> void:
	z_index = 2
	queue_redraw()


func _process(delta: float) -> void:
	_t_alive += delta
	if _t_alive >= _duration:
		queue_free()
		return
	_apply()
	queue_redraw()


func _apply() -> void:
	var hit_radius_sq: float = 10.0 * 10.0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(global_position) > hit_radius_sq:
			continue
		var iid: int = n.get_instance_id()
		var next: float = float(_hit_cooldowns.get(iid, 0.0))
		if _t_alive < next:
			continue
		_hit_cooldowns[iid] = _t_alive + _hit_delay
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_damage, self, (n as Node2D).global_position)


func _draw() -> void:
	var alpha: float = 1.0
	if _t_alive < 0.1:
		alpha = _t_alive / 0.1
	elif _t_alive > _duration - 0.3:
		alpha = clampf((_duration - _t_alive) / 0.3, 0.0, 1.0)
	# 8x16 jagged crystal in local space, jaggedness via 4 small triangles
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(0, -8),
		Vector2(3, -3),
		Vector2(2, 4),
		Vector2(0, 8),
		Vector2(-2, 4),
		Vector2(-3, -3),
	])
	var col: Color = Color(0.55, 0.65, 0.85, 0.95 * alpha)
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(0.85, 0.92, 1.0, alpha), 1.0, true)

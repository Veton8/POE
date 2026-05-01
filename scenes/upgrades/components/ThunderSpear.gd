extends Node2D

# Piercing thunder spear — travels until impact (or distance limit),
# then detonates an AoE.

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 280.0
var _max_distance: float = 200.0
var _pierce: int = 3
var _travel_damage: int = 1
var _aoe_damage: int = 1
var _aoe_radius: float = 40.0

var _traveled: float = 0.0
var _hit: Array[Node] = []
var _detonated: bool = false


func configure(dir: Vector2, speed: float, max_distance: float, pierce: int, travel_dmg: int, aoe_dmg: int, aoe_radius: float) -> void:
	_dir = dir
	_speed = speed
	_max_distance = max_distance
	_pierce = pierce
	_travel_damage = travel_dmg
	_aoe_damage = aoe_dmg
	_aoe_radius = aoe_radius


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	if _detonated:
		return
	var step: float = _speed * delta
	global_position += _dir * step
	_traveled += step
	# Hit-check
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if _hit.has(n):
			continue
		if (n as Node2D).global_position.distance_to(global_position) > 8.0:
			continue
		_hit.append(n)
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_travel_damage, self, (n as Node2D).global_position)
		if _hit.size() >= _pierce:
			_detonate()
			return
	if _traveled >= _max_distance:
		_detonate()
	queue_redraw()


func _detonate() -> void:
	_detonated = true
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(global_position) > _aoe_radius * _aoe_radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_aoe_damage, self, (n as Node2D).global_position)
	Audio.play("ability_burst", 0.4, -3.0)
	VFX.spawn_hit_particles(global_position, Vector2.ZERO)
	queue_free()


func _draw() -> void:
	# Spear shape: 12x4 yellow with white core, electric particle trail dots
	draw_rect(Rect2(Vector2(-6, -2), Vector2(12, 4)), Color(1.0, 0.95, 0.30, 0.95))
	draw_rect(Rect2(Vector2(-6, -1), Vector2(12, 2)), Color(1.0, 1.0, 0.85, 1.0))

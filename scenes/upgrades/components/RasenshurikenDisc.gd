extends Node2D

# Two-phase Rasenshuriken: travel phase fires forward as a disc until
# distance_max, then expansion phase ticks AoE damage in field_radius.

enum Phase { TRAVEL, FIELD }

var _dir: Vector2 = Vector2.RIGHT
var _distance_max: float = 200.0
var _speed: float = 180.0
var _travel_damage: int = 1
var _field_damage: int = 1
var _field_radius: float = 100.0
var _field_duration: float = 1.5
var _field_tick: float = 0.2

var _phase: Phase = Phase.TRAVEL
var _traveled: float = 0.0
var _field_t: float = 0.0
var _tick_t: float = 0.0
var _hit_during_travel: Array[Node] = []
var _spin: float = 0.0


func configure(dir: Vector2, distance_max: float, speed: float, travel_dmg: int, field_dmg: int, field_radius: float, field_duration: float, field_tick: float) -> void:
	_dir = dir
	_distance_max = distance_max
	_speed = speed
	_travel_damage = travel_dmg
	_field_damage = field_dmg
	_field_radius = field_radius
	_field_duration = field_duration
	_field_tick = field_tick


func _ready() -> void:
	z_index = 4


func _process(delta: float) -> void:
	_spin += delta * 12.0
	queue_redraw()
	match _phase:
		Phase.TRAVEL:
			var step: float = _speed * delta
			global_position += _dir * step
			_traveled += step
			# Damage anything we touch during travel
			for n: Node in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(n) or not (n is Node2D):
					continue
				if _hit_during_travel.has(n):
					continue
				if (n as Node2D).global_position.distance_to(global_position) > 12.0:
					continue
				_hit_during_travel.append(n)
				var hb: Node = n.get_node_or_null("HurtboxComponent")
				if hb is HurtboxComponent:
					(hb as HurtboxComponent).receive_hit(_travel_damage, self, (n as Node2D).global_position)
				_phase = Phase.FIELD
				return
			if _traveled >= _distance_max:
				_phase = Phase.FIELD
		Phase.FIELD:
			_field_t += delta
			if _field_t >= _field_duration:
				queue_free()
				return
			_tick_t -= delta
			if _tick_t <= 0.0:
				_tick_t = _field_tick
				_tick_field()


func _tick_field() -> void:
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(global_position) > _field_radius * _field_radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(_field_damage, self, (n as Node2D).global_position)


func _draw() -> void:
	if _phase == Phase.TRAVEL:
		# Spinning disc — three rotated arms
		for i: int in 3:
			var a: float = _spin + i * (TAU / 3.0)
			var p: Vector2 = Vector2(cos(a), sin(a)) * 6.0
			draw_circle(p, 3.0, Color(0.85, 0.95, 1.0, 0.95))
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 1.0, 1.0, 0.95))
	else:
		var phase_t: float = _field_t / _field_duration
		var alpha: float = clampf(1.0 - phase_t, 0.2, 1.0)
		# Field ring
		draw_arc(Vector2.ZERO, _field_radius, 0.0, TAU, 64, Color(0.7, 0.95, 1.0, 0.5 * alpha), 2.0)
		# Inner haze
		draw_circle(Vector2.ZERO, _field_radius * 0.5, Color(0.85, 0.95, 1.0, 0.15 * alpha))

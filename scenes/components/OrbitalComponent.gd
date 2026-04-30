class_name OrbitalComponent
extends Node2D

# Spawns N orbiting damage orbs around the player. Each orb is a child
# Area2D that spins in unison with the others and damages enemy hurtboxes
# it overlaps, on a per-target contact cooldown.

@export var orb_count: int = 2
@export var orbit_radius: float = 24.0
@export var orbit_speed: float = 3.0  # radians/sec
@export var orb_radius: float = 4.0
@export var orb_damage: int = 1
@export var hit_cooldown: float = 0.4
@export var color: Color = Color(0.7, 0.85, 1.0, 1.0)

var _player: Node2D = null
var _orbs: Array[Area2D] = []
var _theta: float = 0.0
var _hit_timers: Dictionary = {}


func _ready() -> void:
	_player = get_parent() as Node2D
	_build_orbs()


func attach_to(host: Node) -> void:
	_player = host as Node2D


func add_orb(extra: int = 1) -> void:
	orb_count += extra
	_rebuild_orbs()


func _build_orbs() -> void:
	for i: int in orb_count:
		var orb: Area2D = Area2D.new()
		orb.collision_layer = 1 << 5
		orb.collision_mask = 1 << 4
		var shape: CollisionShape2D = CollisionShape2D.new()
		var circle: CircleShape2D = CircleShape2D.new()
		circle.radius = orb_radius
		shape.shape = circle
		orb.add_child(shape)
		var visual: _OrbVisual = _OrbVisual.new()
		visual.r = orb_radius
		visual.c = color
		orb.add_child(visual)
		add_child(orb)
		var idx: int = i
		orb.area_entered.connect(func(area: Area2D) -> void: _on_orb_hit(idx, area))
		_orbs.append(orb)


func _rebuild_orbs() -> void:
	for o: Area2D in _orbs:
		o.queue_free()
	_orbs.clear()
	_build_orbs()


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	global_position = _player.global_position
	_theta += orbit_speed * delta
	for i: int in _orbs.size():
		var ang: float = _theta + (TAU / float(_orbs.size())) * float(i)
		var p: Vector2 = Vector2(cos(ang), sin(ang)) * orbit_radius
		_orbs[i].position = p


func _on_orb_hit(orb_idx: int, area: Area2D) -> void:
	var hb: HurtboxComponent = area as HurtboxComponent
	if hb == null:
		return
	var key: String = "%d:%d" % [orb_idx, area.get_instance_id()]
	var now: float = Time.get_ticks_msec() / 1000.0
	var last: float = float(_hit_timers.get(key, -1.0))
	if last >= 0.0 and now - last < hit_cooldown:
		return
	_hit_timers[key] = now
	hb.receive_hit(orb_damage, self, _orbs[orb_idx].global_position)


class _OrbVisual extends Node2D:
	var r: float = 4.0
	var c: Color = Color.WHITE
	func _draw() -> void:
		draw_circle(Vector2.ZERO, r, c)
		draw_circle(-Vector2(r * 0.3, r * 0.3), r * 0.4, Color(1, 1, 1, 0.6))

class_name BlueOrbitalManager
extends Node2D

# Gojo "Cursed Technique Lapse: Blue" autocast variant.
# Spawns 1 orbital per stack (LINEAR cap 4) that orbits the player at
# orbit_radius. Every tick_interval, each orbital pulls enemies within
# pull_radius toward its center and deals contact damage.
#
# attach_to(host) wires the player ref. _apply_blue_orbital on the
# UpgradeManager instantiates this on first stack and calls bump() on
# subsequent stacks (LINEAR mode, +1 orbital per stack).

const MAX_ORBITALS: int = 4

@export var orbit_radius: float = 60.0
@export var pull_radius: float = 90.0
@export var pull_speed: float = 80.0
@export var damage_mult: float = 0.55
@export var tick_interval: float = 0.25
@export var angular_speed: float = 1.4  # radians/sec

var _player: Player = null
var _orbit_count: int = 1
var _t_angle: float = 0.0
var _t_tick: float = 0.0
var _orbitals: Array[Node2D] = []


func _ready() -> void:
	z_index = 2
	if _player == null:
		_resolve_player()
	_rebuild_orbitals()


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player


func bump() -> void:
	if _orbit_count >= MAX_ORBITALS:
		return
	_orbit_count += 1
	_rebuild_orbitals()


func _resolve_player() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _rebuild_orbitals() -> void:
	for o: Node2D in _orbitals:
		if is_instance_valid(o):
			o.queue_free()
	_orbitals.clear()
	for i: int in _orbit_count:
		var orb: Node2D = _make_orbital_visual()
		add_child(orb)
		_orbitals.append(orb)


func _make_orbital_visual() -> Node2D:
	var orb: Node2D = Node2D.new()
	orb.set_script(preload("res://scenes/upgrades/components/BlueOrbitalSprite.gd"))
	return orb


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
		return
	global_position = _player.global_position
	_t_angle += delta * angular_speed
	for i: int in _orbitals.size():
		var ang: float = _t_angle + (TAU / float(_orbit_count)) * float(i)
		_orbitals[i].position = Vector2(cos(ang), sin(ang)) * orbit_radius

	_t_tick -= delta
	if _t_tick <= 0.0:
		_t_tick = tick_interval
		_pulse()


func _pulse() -> void:
	if _player == null:
		return
	var dmg: int = max(1, int(round(float(_player.stats.damage) * damage_mult)))
	var pull_r2: float = pull_radius * pull_radius
	var max_pull_per_tick: float = pull_speed * tick_interval
	for orb: Node2D in _orbitals:
		var center: Vector2 = orb.global_position
		for n: Node in get_tree().get_nodes_in_group("enemies"):
			if not (n is Node2D):
				continue
			var n2d: Node2D = n as Node2D
			if center.distance_squared_to(n2d.global_position) > pull_r2:
				continue
			# Pull toward orbital, capped per-tick so heavies don't snap
			var to_orb: Vector2 = (center - n2d.global_position)
			var step: float = minf(to_orb.length(), max_pull_per_tick)
			n2d.global_position += to_orb.normalized() * step
			# Damage via HurtboxComponent
			var hb: Node = n.get_node_or_null("HurtboxComponent")
			if hb is HurtboxComponent:
				(hb as HurtboxComponent).receive_hit(dmg, self, center)
	# Quiet pull cue — kept low because at 4 orbitals × multiple enemies
	# this would otherwise spam Audio.
	Audio.play("ability_burst", 0.3, -16.0)

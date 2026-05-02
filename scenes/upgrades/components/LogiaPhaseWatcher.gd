class_name LogiaPhaseWatcher
extends Node

# Ace "Logia Phase" — Epic, HYPERBOLIC cap 60%.
# When the player would take damage, % chance to phase: take 0 damage,
# dash 30px in move_input direction, deal 2 × stats.damage in 50px AoE.
# Internal CD 0.5s prevents phase-lock when cornered by many shots.

const MAX_STACKS: int = 6
const PHASE_CD_MS: int = 500

@export var dash_distance: float = 30.0
@export var aoe_radius: float = 50.0
@export var damage_mult: float = 2.0

var stacks: int = 1
var _player: Player = null
var _last_phase_ms: int = -10000


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _ready() -> void:
	if _player == null:
		_resolve_player()
	_connect()


func _resolve_player() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _connect() -> void:
	if _player != null and _player.health != null:
		if not _player.health.damaged.is_connected(_on_damaged):
			_player.health.damaged.connect(_on_damaged)


func _phase_chance() -> float:
	# Hyperbolic: 1 - 1/(1 + 0.25 × stacks). Cap 0.60.
	return minf(0.60, 1.0 - 1.0 / (1.0 + 0.25 * float(stacks)))


func _on_damaged(_amount: int, _source: Node) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if Time.get_ticks_msec() - _last_phase_ms < PHASE_CD_MS:
		return
	if randf() >= _phase_chance():
		return
	_last_phase_ms = Time.get_ticks_msec()
	# Restore the HP that was just deducted
	if _player.health != null:
		_player.health.heal(_amount)
	# Dash
	var dir: Vector2 = _player.move_input.normalized() if _player.move_input.length_squared() > 0.05 else Vector2.RIGHT
	var landing: Vector2 = _player.global_position + dir * dash_distance
	_player.global_position = landing
	# AoE damage at landing
	var dmg: int = max(1, int(round(float(_player.stats.damage) * damage_mult)))
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(landing) > aoe_radius * aoe_radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, (n as Node2D).global_position)
	VFX.spawn_hit_particles(landing, Vector2.ZERO)
	Audio.play("dash", -0.1, 0.0)

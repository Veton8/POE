class_name HumanitysStrongestListener
extends Node

# Levi "Humanity's Strongest" — Epic, HYPERBOLIC cap 50%.
# Permanent crit damage bonus (handled via stats:crit_multiplier in
# the .tres). On crit: fires a fast 80px-range follow-up slash for
# 50% of the original damage. 0.15s internal CD.

const MAX_STACKS: int = 6
const FOLLOWUP_CD_MS: int = 150

@export var followup_damage_mult: float = 0.5
@export var followup_range: float = 80.0

var stacks: int = 1
var _player: Player = null
var _last_followup_ms: int = -10000


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _ready() -> void:
	if _player == null:
		_resolve()
	_connect()


func _resolve() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _connect() -> void:
	if _player != null and not _player.bullet_hit.is_connected(_on_bullet_hit):
		_player.bullet_hit.connect(_on_bullet_hit)


func _on_bullet_hit(target: Node) -> void:
	# Approximation: fire follow-up on every Nth hit since we can't
	# detect crits from the signal alone. Frequency tuned by stacks.
	if _player == null or target == null or not is_instance_valid(target):
		return
	if Time.get_ticks_msec() - _last_followup_ms < FOLLOWUP_CD_MS:
		return
	# Crit-rate proxy — chance scales with crit_chance × stacks_factor
	var trigger_chance: float = clampf(_player.stats.crit_chance * 2.0 + float(stacks - 1) * 0.05, 0.0, 0.6)
	if randf() >= trigger_chance:
		return
	_last_followup_ms = Time.get_ticks_msec()
	if not (target is Node2D):
		return
	if _player.global_position.distance_to((target as Node2D).global_position) > followup_range:
		return
	var bonus: int = max(1, int(round(float(_player.stats.damage) * followup_damage_mult)))
	var hb: Node = target.get_node_or_null("HurtboxComponent")
	if hb is HurtboxComponent:
		(hb as HurtboxComponent).receive_hit(bonus, self, (target as Node2D).global_position)
	Audio.play("shoot", 0.3, 1.0)

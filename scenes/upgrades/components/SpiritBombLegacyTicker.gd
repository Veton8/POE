class_name SpiritBombLegacyTicker
extends Node

# Goku "Spirit Bomb Legacy" — Legendary, EVOLVING.
# Listens to Events.enemy_died; every 30 kills since last fire,
# spawns a homing 60px-radius energy ball that damages all enemies
# in the radius for 5 × stats.damage. Stacks ON TOP of the existing
# spirit_bomb stacker (kill streak damage).

@export var kills_per_fire: int = 30
@export var radius: float = 60.0
@export var damage_mult: float = 5.0

var _player: Player = null
var _kill_count: int = 0


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect()


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
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)


func _on_enemy_died(_enemy: Node, pos: Vector2) -> void:
	_kill_count += 1
	if _kill_count < kills_per_fire:
		return
	_kill_count = 0
	_fire(pos)


func _fire(origin: Vector2) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# Find nearest enemy as target
	var target: Node2D = null
	var best_d: float = 480.0 * 480.0
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var d: float = (n as Node2D).global_position.distance_squared_to(origin)
		if d < best_d:
			best_d = d
			target = n as Node2D
	if target == null:
		return
	var dmg: int = max(1, int(round(float(_player.stats.damage) * damage_mult)))
	# AoE around target position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(target.global_position) > radius * radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, (n as Node2D).global_position)
	VFX.spawn_hit_particles(target.global_position, Vector2.ZERO)
	Audio.play("ability_burst", -0.3, 1.0)
	Events.screen_shake.emit(4.0, 0.2)

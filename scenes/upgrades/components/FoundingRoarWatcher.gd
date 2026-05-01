class_name FoundingRoarWatcher
extends Node

# Eren "Founding Roar" — Legendary, UNIQUE.
# When player drops below 25% HP, triggers a 200px scream: 50% enemy
# slow for 4s, 4.5x AoE damage, restores 15 HP. 60s lockout.

const LOCKOUT_MS: int = 60000

@export var hp_threshold: float = 0.25
@export var radius: float = 200.0
@export var damage_mult: float = 4.5
@export var slow_factor: float = 0.5
@export var slow_duration: float = 4.0
@export var heal_amount: int = 15

var _player: Player = null
var _last_trigger_ms: int = -100000


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect()


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
	if _player != null and _player.health != null:
		if not _player.health.health_changed.is_connected(_on_health_changed):
			_player.health.health_changed.connect(_on_health_changed)


func _on_health_changed(current: int, max_hp: int) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if Time.get_ticks_msec() - _last_trigger_ms < LOCKOUT_MS:
		return
	if max_hp <= 0:
		return
	if float(current) / float(max_hp) > hp_threshold:
		return
	_last_trigger_ms = Time.get_ticks_msec()
	_unleash()


func _unleash() -> void:
	if _player == null:
		return
	var dmg: int = max(1, int(round(float(_player.stats.damage) * damage_mult)))
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(_player.global_position) > radius * radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, (n as Node2D).global_position)
		# Slow via BuffComponent
		var existing: Node = n.get_node_or_null("BuffComponent")
		if existing is BuffComponent:
			(existing as BuffComponent).refresh(slow_duration, slow_factor)
		else:
			var buff: BuffComponent = BuffComponent.new()
			buff.name = "BuffComponent"
			buff.duration = slow_duration
			buff.speed_mul = slow_factor
			n.add_child(buff)
	if _player.health != null:
		_player.health.heal(heal_amount)
	Audio.play("ability_burst", -0.6, 5.0)
	Events.screen_shake.emit(8.0, 0.5)

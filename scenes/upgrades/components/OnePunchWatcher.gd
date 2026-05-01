class_name OnePunchWatcher
extends Node

# Saitama "One Punch" evolution effect.
# 5% chance per Player.bullet_hit to instakill non-boss enemies via
# overkill damage. Bosses immune.

const INSTAKILL_CHANCE: float = 0.05
const OVERKILL: int = 99999

var _player: Player = null


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
	if _player != null and not _player.bullet_hit.is_connected(_on_bullet_hit):
		_player.bullet_hit.connect(_on_bullet_hit)


func _on_bullet_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target):
		return
	if target.is_in_group("boss"):
		return
	if randf() >= INSTAKILL_CHANCE:
		return
	var hp: HealthComponent = target.get_node_or_null("HealthComponent") as HealthComponent
	if hp == null:
		return
	hp.take_damage(OVERKILL, self)
	if target is Node2D:
		VFX.spawn_hit_particles((target as Node2D).global_position, Vector2.ZERO)
	Audio.play("ability_burst", -0.5, 4.0)

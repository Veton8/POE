class_name SeriousSidewaysWatcher
extends Node

# Saitama "Serious Sideways Jumps" — Legendary, UNIQUE.
# Listens to Player.health.damaged. 25% chance to perfect-dodge:
# negate damage, queue a 4x empower for the next autocast within 4s
# (uses AutocastModifierRegistry). Internal CD 1.5s.

const DODGE_CD_MS: int = 1500
const EMPOWER_MULT: float = 4.0
const EMPOWER_WINDOW: float = 4.0

@export var dodge_chance: float = 0.25

var _player: Player = null
var _last_dodge_ms: int = -10000


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
		if not _player.health.damaged.is_connected(_on_damaged):
			_player.health.damaged.connect(_on_damaged)


func _on_damaged(amount: int, _source: Node) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if Time.get_ticks_msec() - _last_dodge_ms < DODGE_CD_MS:
		return
	if randf() >= dodge_chance:
		return
	_last_dodge_ms = Time.get_ticks_msec()
	if _player.health != null:
		_player.health.heal(amount)
	AutocastModifierRegistry.queue_empower(EMPOWER_MULT, EMPOWER_WINDOW)
	# Visual cue
	if _player.sprite != null:
		var orig: Color = _player.sprite.modulate
		var tw: Tween = create_tween()
		tw.tween_property(_player.sprite, "modulate", Color(2.0, 1.8, 0.4), 0.10)
		tw.tween_property(_player.sprite, "modulate", orig, 0.20)
	Audio.play("dash", -0.4, 6.0)
	if _player is Node2D:
		VFX.spawn_hit_particles(_player.global_position, Vector2.ZERO)

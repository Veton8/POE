class_name ReviveComponent
extends Node

# One-shot revive on player death. Hooks the player's HealthComponent.died
# signal; on first fire, undoes the dead state and restores `revive_hp_pct`
# of max HP, then queue_frees so it can't fire twice.

@export var revive_hp_pct: float = 0.5
@export var i_frames_seconds: float = 1.5

var _player: Player = null
var _health: HealthComponent = null
var _used: bool = false


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null:
		_health = _player.health
	if _health != null:
		_health.died.connect(_on_player_died)


func attach_to(host: Node) -> void:
	_player = host as Player
	if _player != null:
		_health = _player.health
		if _health != null and not _health.died.is_connected(_on_player_died):
			_health.died.connect(_on_player_died)


func _on_player_died() -> void:
	if _used or _health == null:
		return
	_used = true
	# Forcibly clear the dead flag and restore HP. HealthComponent.reset()
	# clears _dead and sets current = max_hp; we override with a partial heal.
	var restore: int = max(1, int(round(float(_health.max_hp) * revive_hp_pct)))
	_health.reset(_health.max_hp)
	_health.current = restore
	_health.health_changed.emit(_health.current, _health.max_hp)
	# Re-enable physics on the player (it set physics off in _on_died)
	if _player != null:
		_player.set_physics_process(true)
		_player.visible = true
		# Brief invuln window so the player isn't immediately re-killed
		if _player.hurtbox != null:
			_player.hurtbox.set_deferred("monitorable", false)
			var t: SceneTreeTimer = get_tree().create_timer(i_frames_seconds)
			t.timeout.connect(func() -> void:
				if _player != null and is_instance_valid(_player) and _player.hurtbox != null:
					_player.hurtbox.set_deferred("monitorable", true)
			)
	VFX.spawn_hit_particles(_player.global_position if _player != null else Vector2.ZERO, Vector2.UP)
	Audio.play("ability_heal", 0.05, 0.0)
	queue_free()

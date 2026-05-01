class_name ReaperWave
extends Node

# Spawns Reapers periodically once active. Reapers are tinted-red
# elite enemies with massive HP scaling (×N relative to the spawner's
# current HP curve). Triggered by Endless at the 18:00 mark.

@export var reaper_interval: float = 90.0
@export var reaper_hp_mult: float = 100.0
@export var reaper_speed_mult: float = 1.4
@export var reaper_damage_mult: float = 3.0

var _spawner: EndlessSpawner = null
var _player: Player = null
var _t_to_next: float = 5.0  # first reaper a few seconds after activation
var _active: bool = false


func attach(spawner: EndlessSpawner, player: Player) -> void:
	_spawner = spawner
	_player = player


func activate() -> void:
	if _active:
		return
	_active = true
	_t_to_next = 5.0
	Events.screen_shake.emit(8.0, 0.6)
	Audio.play("ability_burst", -0.8, 0.0)


func _process(delta: float) -> void:
	if not _active or _spawner == null or _player == null:
		return
	if not is_instance_valid(_player) or not is_instance_valid(_spawner):
		return
	_t_to_next -= delta
	if _t_to_next <= 0.0:
		_t_to_next = reaper_interval
		_spawn_reaper()


func _spawn_reaper() -> void:
	if _spawner.boss_pool.is_empty() and _spawner.elite_pool.is_empty():
		return
	# Pick from elite_pool first, fallback to boss_pool
	var pool: Array[PackedScene] = _spawner.elite_pool if not _spawner.elite_pool.is_empty() else _spawner.boss_pool
	var ps: PackedScene = pool[randi() % pool.size()]
	# Spawn at top edge of the visible area
	var pos: Vector2 = _player.global_position + Vector2(randf_range(-100, 100), -300.0)
	var reaper: Node = _spawner._spawn_at(ps, pos)
	if reaper is EnemyBase:
		var eb: EnemyBase = reaper as EnemyBase
		if eb.stats != null:
			eb.stats.max_hp = int(round(float(eb.stats.max_hp) * reaper_hp_mult))
			eb.stats.move_speed *= reaper_speed_mult
			eb.stats.contact_damage = int(round(float(eb.stats.contact_damage) * reaper_damage_mult))
			eb.stats.bullet_damage = int(round(float(eb.stats.bullet_damage) * reaper_damage_mult))
			# Re-apply to the live HealthComponent
			if eb.health != null:
				eb.health.max_hp = eb.stats.max_hp
				eb.health.reset(eb.stats.max_hp)
		# Tint the sprite red
		if eb.sprite != null:
			eb.sprite.modulate = Color(1.6, 0.4, 0.4)
		# Tag as reaper so HUD telegraphs can identify them
		eb.add_to_group("reaper")
	Events.screen_shake.emit(4.0, 0.3)
	Audio.play("ability_burst", -0.6, 2.0)

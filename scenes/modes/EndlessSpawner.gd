class_name EndlessSpawner
extends Node

# Endless-mode enemy spawner. Spawns enemies in a ring at spawn_radius
# from the player using a 35/35/15/15 angular distribution (top/bot/
# left/right) so the tall portrait viewport is meaningfully used.
# Density curve and formation timestamps follow the design doc.
#
# Caller: Endless.gd — calls attach(player, world) once after spawn,
# then this node ticks itself.

@export var enemy_pool: Array[PackedScene] = []
@export var elite_pool: Array[PackedScene] = []
@export var boss_pool: Array[PackedScene] = []
@export var spawn_radius: float = 280.0
@export var despawn_radius: float = 480.0
@export var alive_cap: int = 220

var _player: Player = null
var _world: Node = null
var _t_run_seconds: float = 0.0
var _spawn_accumulator: float = 0.0
var _alive_enemies: Array[Node] = []

# Formation cooldowns (last-trigger time in seconds, -INF means never)
var _last_vertical_sweep: float = -1000.0
var _last_pincer: float = -1000.0
var _last_flank: float = -1000.0
var _last_elite: float = -1000.0
var _last_alive_prune: float = 0.0

# Boss triggers — once each
var _bosses_fired: Array[float] = []
const BOSS_TIMESTAMPS: Array[float] = [300.0, 600.0, 900.0, 1080.0, 1200.0, 1500.0]

# Map events — scripted timestamps (seconds). Once each unless noted.
var _events_fired: Array[float] = []
const CHEST_TIMESTAMPS: Array[float] = [240.0, 540.0, 840.0]  # 4:00, 9:00, 14:00
const HEAL_SHRINE_TIME: float = 420.0  # 7:00 — persistent
const CURSE_PILLAR_TIME: float = 600.0  # 10:00
const STAMPEDE_TIME: float = 780.0  # 13:00
var _last_bomb_minute: int = -1  # rate-limit ~1 bomb per minute past minute 5

const TREASURE_CHEST: PackedScene = preload("res://scenes/modes/events/TreasureChest.tscn")
const MAGNET_PICKUP: PackedScene = preload("res://scenes/modes/events/MagnetPickup.tscn")
const BOMB_PICKUP: PackedScene = preload("res://scenes/modes/events/BombPickup.tscn")
const HEAL_SHRINE: PackedScene = preload("res://scenes/modes/events/HealShrine.tscn")
const CURSE_PILLAR: PackedScene = preload("res://scenes/modes/events/CursePillar.tscn")


func attach(player: Player, world: Node) -> void:
	_player = player
	_world = world


func get_run_time() -> float:
	return _t_run_seconds


func _physics_process(delta: float) -> void:
	if _player == null or _world == null:
		return
	if not is_instance_valid(_player):
		return
	_t_run_seconds += delta

	var rate: float = _spawn_rate(_t_run_seconds / 60.0)
	_spawn_accumulator += rate * delta
	while _spawn_accumulator >= 1.0:
		_spawn_accumulator -= 1.0
		if _alive_count() < alive_cap:
			_spawn_one()

	_check_formations()
	_check_bosses()
	_check_map_events()
	_prune_far_enemies(delta)


func _spawn_rate(t_min: float) -> float:
	if t_min < 1.0:
		return 3.0
	if t_min < 3.0:
		return 5.0 + (t_min - 1.0) * 2.5
	if t_min < 7.0:
		return 10.0 + (t_min - 3.0) * 2.0
	if t_min < 12.0:
		return 18.0 + (t_min - 7.0) * 1.4
	if t_min < 18.0:
		return 25.0 + (t_min - 12.0) * 1.5
	return minf(40.0, 34.0 + (t_min - 18.0) * 1.0)


func _spawn_one() -> void:
	if enemy_pool.is_empty():
		return
	var pos: Vector2 = _pick_spawn_position()
	_spawn_at(enemy_pool[randi() % enemy_pool.size()], pos)


func _spawn_at(ps: PackedScene, pos: Vector2) -> Node:
	if ps == null:
		return null
	var e: Node = ps.instantiate()
	if e == null:
		return null
	# Apply difficulty scaling — duplicate stats Resource before mutating
	# so we don't poison shared baselines across all spawned instances.
	if e is EnemyBase:
		var eb: EnemyBase = e as EnemyBase
		if eb.stats != null:
			var scaled: EnemyStats = eb.stats.duplicate() as EnemyStats
			var t_min: float = _t_run_seconds / 60.0
			var hp_mul: float = _hp_multiplier(t_min)
			var dmg_mul: float = _damage_multiplier(t_min)
			var speed_mul: float = _speed_multiplier(t_min)
			scaled.max_hp = max(1, int(round(float(scaled.max_hp) * hp_mul)))
			scaled.move_speed *= speed_mul
			scaled.contact_damage = max(1, int(round(float(scaled.contact_damage) * dmg_mul)))
			scaled.bullet_damage = max(1, int(round(float(scaled.bullet_damage) * dmg_mul)))
			eb.stats = scaled
	if e is Node2D:
		(e as Node2D).global_position = pos
	_world.add_child(e)
	_alive_enemies.append(e)
	if e.has_signal("tree_exiting"):
		e.tree_exiting.connect(_on_enemy_freed.bind(e), CONNECT_ONE_SHOT)
	return e


# Difficulty curves from the design doc — piecewise multipliers
# applied to scaled.max_hp / .contact_damage / .move_speed.
func _hp_multiplier(t_min: float) -> float:
	if t_min < 2.0: return 1.0
	if t_min < 5.0: return 1.5
	if t_min < 10.0: return 3.0
	if t_min < 15.0: return 6.0
	if t_min < 20.0: return 12.0
	return 24.0


func _damage_multiplier(t_min: float) -> float:
	if t_min < 2.0: return 1.0
	if t_min < 5.0: return 1.2
	if t_min < 10.0: return 1.8
	if t_min < 15.0: return 2.6
	if t_min < 20.0: return 3.6
	return 5.0


func _speed_multiplier(t_min: float) -> float:
	return minf(1.6, 1.0 + t_min * 0.03)


func _pick_spawn_position() -> Vector2:
	# Angular distribution: 35% top, 35% bottom, 15% left, 15% right.
	# Top arc center = -PI/2 (Godot Y is down); bottom = +PI/2.
	var roll: float = randf()
	var arc_center: float = 0.0
	var arc_width: float = deg_to_rad(45.0)
	if roll < 0.35:
		arc_center = -PI * 0.5
		arc_width = deg_to_rad(45.0)
	elif roll < 0.70:
		arc_center = PI * 0.5
		arc_width = deg_to_rad(45.0)
	elif roll < 0.85:
		arc_center = PI
		arc_width = deg_to_rad(30.0)
	else:
		arc_center = 0.0
		arc_width = deg_to_rad(30.0)
	var angle: float = arc_center + (randf() - 0.5) * arc_width
	var dir: Vector2 = Vector2(cos(angle), sin(angle))
	return _player.global_position + dir * spawn_radius


func _check_formations() -> void:
	var t: float = _t_run_seconds
	if t >= 60.0 and t - _last_vertical_sweep >= 60.0:
		_last_vertical_sweep = t
		_vertical_sweep()
	if t >= 90.0 and t - _last_pincer >= 90.0:
		_last_pincer = t
		_pincer()
	if t >= 120.0 and t - _last_flank >= 90.0:
		_last_flank = t
		_flank()
	if t >= 120.0 and t - _last_elite >= 120.0:
		_last_elite = t
		_spawn_elite()


func _vertical_sweep() -> void:
	if enemy_pool.is_empty():
		return
	var ps: PackedScene = enemy_pool[randi() % enemy_pool.size()]
	var center_x: float = _player.global_position.x
	var top_y: float = _player.global_position.y - spawn_radius
	for i: int in 12:
		var ox: float = (float(i) - 5.5) * 24.0
		_spawn_at(ps, Vector2(center_x + ox, top_y))


func _pincer() -> void:
	if enemy_pool.is_empty():
		return
	var ps: PackedScene = enemy_pool[randi() % enemy_pool.size()]
	var px: float = _player.global_position.x
	var py: float = _player.global_position.y
	for i: int in 8:
		var ox: float = (float(i) - 3.5) * 24.0
		_spawn_at(ps, Vector2(px + ox, py - spawn_radius))
		_spawn_at(ps, Vector2(px + ox, py + spawn_radius))


func _flank() -> void:
	if enemy_pool.is_empty():
		return
	var ps: PackedScene = enemy_pool[randi() % enemy_pool.size()]
	var side: int = 1 if randf() < 0.5 else -1
	var px: float = _player.global_position.x + float(side) * spawn_radius
	var py: float = _player.global_position.y
	for i: int in 16:
		var oy: float = (float(i) - 7.5) * 18.0
		_spawn_at(ps, Vector2(px, py + oy))


func _spawn_elite() -> void:
	if elite_pool.is_empty():
		return
	var pos: Vector2 = _pick_spawn_position()
	_spawn_at(elite_pool[randi() % elite_pool.size()], pos)


func _check_bosses() -> void:
	if boss_pool.is_empty():
		return
	for ts: float in BOSS_TIMESTAMPS:
		if _t_run_seconds >= ts and not _bosses_fired.has(ts):
			_bosses_fired.append(ts)
			var pos: Vector2 = _pick_spawn_position()
			_spawn_at(boss_pool[randi() % boss_pool.size()], pos)
			Events.screen_shake.emit(8.0, 0.4)
			break


func _prune_far_enemies(delta: float) -> void:
	# Cheap pass — only every 0.5s, since iterating all enemies is O(N)
	_last_alive_prune += delta
	if _last_alive_prune < 0.5:
		return
	_last_alive_prune = 0.0
	var r2: float = despawn_radius * despawn_radius
	var px: Vector2 = _player.global_position
	var alive: Array[Node] = []
	for e: Node in _alive_enemies:
		if not is_instance_valid(e):
			continue
		if e is Node2D:
			var n2d: Node2D = e as Node2D
			if px.distance_squared_to(n2d.global_position) > r2:
				e.queue_free()
				continue
		alive.append(e)
	_alive_enemies = alive


func _alive_count() -> int:
	var alive: Array[Node] = []
	for e: Node in _alive_enemies:
		if is_instance_valid(e):
			alive.append(e)
	_alive_enemies = alive
	return alive.size()


func _on_enemy_freed(e: Node) -> void:
	_alive_enemies.erase(e)


# ---------- Map events ----------

func _check_map_events() -> void:
	for ts: float in CHEST_TIMESTAMPS:
		if _t_run_seconds >= ts and not _events_fired.has(ts):
			_events_fired.append(ts)
			_spawn_event(TREASURE_CHEST, _player.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40)))
	if _t_run_seconds >= HEAL_SHRINE_TIME and not _events_fired.has(HEAL_SHRINE_TIME):
		_events_fired.append(HEAL_SHRINE_TIME)
		_spawn_event(HEAL_SHRINE, _player.global_position + Vector2(randf_range(-100, 100), -120.0))
	if _t_run_seconds >= CURSE_PILLAR_TIME and not _events_fired.has(CURSE_PILLAR_TIME):
		_events_fired.append(CURSE_PILLAR_TIME)
		_spawn_event(CURSE_PILLAR, _player.global_position + Vector2(0, 100.0))
	if _t_run_seconds >= STAMPEDE_TIME and not _events_fired.has(STAMPEDE_TIME):
		_events_fired.append(STAMPEDE_TIME)
		_vertical_stampede()
	# Bomb pickup ~1/min past minute 5
	var current_minute: int = int(_t_run_seconds) / 60
	if current_minute >= 5 and current_minute != _last_bomb_minute:
		_last_bomb_minute = current_minute
		if randf() < 0.5:  # 50% per minute past 5
			_spawn_event(BOMB_PICKUP, _player.global_position + Vector2(randf_range(-200, 200), randf_range(-200, 200)))


func _spawn_event(scene: PackedScene, pos: Vector2) -> void:
	if scene == null or _world == null:
		return
	var inst: Node = scene.instantiate()
	if inst == null:
		return
	if inst is Node2D:
		(inst as Node2D).global_position = pos
	_world.add_child(inst)


func _vertical_stampede() -> void:
	# 30 fast runners traverse south-to-north along the long axis
	if enemy_pool.is_empty():
		return
	var ps: PackedScene = enemy_pool[randi() % enemy_pool.size()]
	var center_x: float = _player.global_position.x
	var spawn_y: float = _player.global_position.y + 280.0
	for i: int in 30:
		var ox: float = randf_range(-130.0, 130.0)
		var pos: Vector2 = Vector2(center_x + ox, spawn_y + randf_range(-20, 20))
		_spawn_at(ps, pos)
	Events.screen_shake.emit(4.0, 0.4)

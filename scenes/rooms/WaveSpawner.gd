class_name WaveSpawner
extends Node

signal wave_started(idx: int)
signal wave_finished(idx: int)
signal all_waves_finished

var _waves: Array[WaveData] = []
var _spawn_points: Array[Node] = []
var _current: int = -1
var _alive: int = 0
var _force_timer: Timer

func _ready() -> void:
	_force_timer = Timer.new()
	_force_timer.one_shot = true
	add_child(_force_timer)
	_force_timer.timeout.connect(_force_next)

func start(waves: Array[WaveData], spawn_points: Array[Node]) -> void:
	_waves = waves.duplicate()
	_spawn_points = spawn_points
	_current = -1
	_alive = 0
	_next_wave()

func _next_wave() -> void:
	_current += 1
	if _current >= _waves.size():
		all_waves_finished.emit()
		return
	var w: WaveData = _waves[_current]
	wave_started.emit(_current)
	_force_timer.start(w.auto_advance_seconds)
	_spawn_wave(w)

func _spawn_wave(w: WaveData) -> void:
	for entry in w.entries:
		if entry == null or entry.enemy_scene == null:
			continue
		for i in entry.count:
			if _spawn_points.is_empty():
				return
			var sp_any: Node = _spawn_points.pick_random()
			var sp: Node2D = sp_any as Node2D
			var e: Node2D = entry.enemy_scene.instantiate() as Node2D
			if e == null or sp == null:
				continue
			get_tree().current_scene.add_child(e)
			e.global_position = sp.global_position
			_alive += 1
			e.tree_exited.connect(_on_enemy_died)
			await get_tree().create_timer(w.spawn_delay).timeout

func _on_enemy_died() -> void:
	_alive -= 1
	if _alive <= 0:
		_force_timer.stop()
		wave_finished.emit(_current)
		await get_tree().create_timer(0.5).timeout
		_next_wave()

func _force_next() -> void:
	wave_finished.emit(_current)
	_next_wave()

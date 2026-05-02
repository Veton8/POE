extends Node

@export var hit_particles_scene: PackedScene = preload("res://scenes/vfx/HitParticles.tscn")
@export var death_particles_scene: PackedScene = preload("res://scenes/vfx/DeathParticles.tscn")
@export var muzzle_flash_scene: PackedScene = preload("res://scenes/vfx/MuzzleFlash.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/vfx/DamageNumber.tscn")

# Optional override — endless mode (or any SubViewport scene) calls
# set_world_root() so VFX particles parent to the SubViewport's world
# instead of the run scene root. Stale refs auto-clear.
var _world_root: Node = null


func set_world_root(node: Node) -> void:
	_world_root = node


func clear_world_root() -> void:
	_world_root = null


func _host() -> Node:
	if _world_root != null and is_instance_valid(_world_root):
		return _world_root
	_world_root = null
	return get_tree().current_scene


func screen_shake(amount: float, duration: float = 0.15) -> void:
	Events.screen_shake.emit(amount, duration)

func spawn_hit_particles(pos: Vector2, dir: Vector2 = Vector2.ZERO) -> void:
	if hit_particles_scene == null:
		return
	var p: Node2D = hit_particles_scene.instantiate() as Node2D
	if p == null:
		return
	_host().add_child(p)
	p.global_position = pos
	if dir != Vector2.ZERO:
		p.rotation = dir.angle()
	if p.has_method("emit_burst"):
		p.call("emit_burst")

func spawn_death_particles(pos: Vector2) -> void:
	if death_particles_scene == null:
		return
	var p: Node2D = death_particles_scene.instantiate() as Node2D
	if p == null:
		return
	_host().add_child(p)
	p.global_position = pos
	if p.has_method("emit_burst"):
		p.call("emit_burst")

func spawn_muzzle_flash(pos: Vector2, dir: Vector2) -> void:
	if muzzle_flash_scene == null:
		return
	var p: Node2D = muzzle_flash_scene.instantiate() as Node2D
	if p == null:
		return
	_host().add_child(p)
	p.global_position = pos
	p.rotation = dir.angle()
	if p.has_method("emit_burst"):
		p.call("emit_burst")

const DAMAGE_AGG_WINDOW_MS: int = 200
const DAMAGE_AGG_MAX: int = 30
# pos_key (rounded) -> { label: Label, expires_msec: int, total: int, crit: bool, color: Color }
var _agg_active: Dictionary = {}
var _agg_active_count: int = 0
var _agg_prune_t: float = 0.0


func _process(delta: float) -> void:
	_agg_prune_t += delta
	if _agg_prune_t < 0.5:
		return
	_agg_prune_t = 0.0
	var now: int = Time.get_ticks_msec()
	var stale: Array[int] = []
	for k_v: Variant in _agg_active.keys():
		var k: int = int(k_v)
		var entry: Dictionary = _agg_active[k]
		var label_v: Variant = entry.get("label", null)
		if not is_instance_valid(label_v) or not (label_v is Label):
			stale.append(k)
			continue
		if int(entry["expires_msec"]) < now:
			stale.append(k)
	for k: int in stale:
		_agg_active.erase(k)
	_agg_active_count = _agg_active.size()


func spawn_damage_number(pos: Vector2, value: int, crit: bool = false, color: Color = Color(1, 0.3, 0.3)) -> void:
	if damage_number_scene == null:
		return
	# Aggregate within 0.20s window per "near-position" key (8px buckets)
	var key: int = (int(pos.x / 8.0) * 100000) + int(pos.y / 8.0)
	var now: int = Time.get_ticks_msec()
	if _agg_active.has(key):
		var entry: Dictionary = _agg_active[key]
		var raw: Variant = entry["label"]
		if is_instance_valid(raw):
			var label: Label = raw as Label
			entry["total"] = int(entry["total"]) + value
			entry["crit"] = bool(entry["crit"]) or crit
			entry["expires_msec"] = now + DAMAGE_AGG_WINDOW_MS
			_agg_active[key] = entry
			if label.has_method("popup"):
				label.call("popup", int(entry["total"]), bool(entry["crit"]), color)
			return
		_agg_active.erase(key)
		_agg_active_count = maxi(0, _agg_active_count - 1)
	# Cap simultaneous active labels — drop oldest if over limit
	if _agg_active_count >= DAMAGE_AGG_MAX:
		var oldest_key: int = 0
		var oldest_t: int = 1 << 62
		for k_v: Variant in _agg_active.keys():
			var k: int = int(k_v)
			var e: Dictionary = _agg_active[k]
			if int(e["expires_msec"]) < oldest_t:
				oldest_t = int(e["expires_msec"])
				oldest_key = k
		var oldest_entry: Dictionary = _agg_active[oldest_key]
		var oldest_raw: Variant = oldest_entry["label"]
		if is_instance_valid(oldest_raw):
			(oldest_raw as Label).queue_free()
		_agg_active.erase(oldest_key)
		_agg_active_count = maxi(0, _agg_active_count - 1)
	# Spawn fresh label
	var d: Label = damage_number_scene.instantiate() as Label
	if d == null:
		return
	_host().add_child(d)
	d.global_position = pos + Vector2(randf_range(-4, 4), -8)
	if d.has_method("popup"):
		d.call("popup", value, crit, color)
	_agg_active[key] = {
		"label": d,
		"expires_msec": now + DAMAGE_AGG_WINDOW_MS,
		"total": value,
		"crit": crit,
		"color": color,
	}
	_agg_active_count += 1

class_name Bullet
extends Area2D

const BURN_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")

@export var lifetime: float = 2.0

# On-hit effects (set per-bullet-scene, populated from PlayerStats when spawned)
@export var burn_dps: float = 0.0
@export var burn_duration: float = 0.0
@export var pull_distance: float = 0.0
@export var pierce_count: int = 0

# Upgrade-driven extensions (Phase A power-up system).
# Set on spawned bullets by Player after `spawn()` returns, or directly on
# the bullet scene's defaults. Ricochet decrements per wall hit; homing
# turns velocity toward nearest enemy each frame; chain re-targets on
# enemy hit; split spawns N child bullets at despawn.
@export var ricochet_count: int = 0
@export var split_on_death: int = 0
@export var homing_strength: float = 0.0
@export var chain_targets: int = 0
@export var chain_range: float = 48.0

var velocity: Vector2 = Vector2.ZERO
var damage: int = 1
var team: String = "player"
var on_hit_callback: Callable = Callable()
var _t: float = 0.0
var _alive: bool = false
var _pierces_remaining: int = 0
var _ricochet_remaining: int = 0
var _chain_remaining: int = 0
var _hit_targets: Array[Node] = []
var _trail_origin: Vector2 = Vector2.ZERO
var _trail_line: Line2D = null
# Scene-baked baselines captured at _ready. Spawn() restores from these so
# upgrade-driven mods (knockback, burn) add to the original each fire instead
# of accumulating across pool reuses.
var _baseline_pull: float = 0.0
var _baseline_burn_dps: float = 0.0
var _baseline_burn_duration: float = 0.0
var _baseline_scale: Vector2 = Vector2.ONE


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_trail_line = get_node_or_null("TrailLine") as Line2D
	_baseline_pull = pull_distance
	_baseline_burn_dps = burn_dps
	_baseline_burn_duration = burn_duration
	_baseline_scale = scale


func spawn(pos: Vector2, dir: Vector2, speed: float, dmg: int, t: String, pierce_override: int = -1) -> void:
	global_position = pos
	velocity = dir * speed
	rotation = dir.angle()
	damage = dmg
	team = t
	_t = 0.0
	_alive = true
	_pierces_remaining = pierce_override if pierce_override >= 0 else pierce_count
	_ricochet_remaining = ricochet_count
	_chain_remaining = chain_targets
	_hit_targets.clear()
	# Restore scene-baked values so per-spawn upgrade tweaks don't accumulate
	pull_distance = _baseline_pull
	burn_dps = _baseline_burn_dps
	burn_duration = _baseline_burn_duration
	scale = _baseline_scale
	if _trail_line != null:
		_trail_origin = pos
		_trail_line.clear_points()
		_trail_line.add_point(Vector2.ZERO)
		_trail_line.add_point(Vector2.ZERO)
	if t == "player":
		collision_layer = 1 << 5
		collision_mask = (1 << 4) | 1
	else:
		collision_layer = 1 << 6
		collision_mask = (1 << 3) | 1


func _physics_process(delta: float) -> void:
	if not _alive:
		return
	# Homing — turn velocity toward nearest enemy in 80px radius
	if homing_strength > 0.0 and team == "player":
		var target: Node2D = _find_homing_target(80.0)
		if target != null:
			var desired: Vector2 = (target.global_position - global_position).normalized()
			var current: Vector2 = velocity.normalized()
			var max_turn: float = homing_strength * delta
			var ang: float = clampf(current.angle_to(desired), -max_turn, max_turn)
			velocity = current.rotated(ang) * velocity.length()
			rotation = velocity.angle()
	global_position += velocity * delta
	_t += delta
	if _trail_line != null:
		_trail_line.set_point_position(0, to_local(_trail_origin))
		_trail_line.set_point_position(1, Vector2.ZERO)
	if _t >= lifetime:
		_despawn()


func _find_homing_target(radius: float) -> Node2D:
	var best: Node2D = null
	var best_d: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var n2d: Node2D = n as Node2D
		var d: float = global_position.distance_squared_to(n2d.global_position)
		if d < best_d:
			best_d = d
			best = n2d
	return best


func _find_chain_target(from: Vector2, radius: float) -> Node2D:
	var best: Node2D = null
	var best_d: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if _hit_targets.has(n):
			continue
		var n2d: Node2D = n as Node2D
		var d: float = from.distance_squared_to(n2d.global_position)
		if d < best_d:
			best_d = d
			best = n2d
	return best


func _on_body_entered(body: Node) -> void:
	if not _alive:
		return
	if body is TileMapLayer or body is StaticBody2D:
		# Ricochet: reflect velocity off the wall and burn one bounce. We don't
		# have the exact normal cheaply, so flip the dominant velocity axis —
		# good enough for the orthogonal tile walls in this game.
		if _ricochet_remaining > 0:
			_ricochet_remaining -= 1
			if absf(velocity.x) > absf(velocity.y):
				velocity.x = -velocity.x
			else:
				velocity.y = -velocity.y
			rotation = velocity.angle()
			VFX.spawn_hit_particles(global_position, velocity.normalized())
			return
		_impact()


func _on_area_entered(area: Area2D) -> void:
	if not _alive:
		return
	var hb: HurtboxComponent = area as HurtboxComponent
	if hb == null:
		return
	var owner_team: String = "enemy"
	var parent_node: Node = hb.get_parent()
	if parent_node != null and parent_node.is_in_group("player"):
		owner_team = "player"
	if owner_team == team:
		return
	hb.receive_hit(damage, self, global_position)
	_apply_on_hit_effects(parent_node)
	if parent_node != null and not _hit_targets.has(parent_node):
		_hit_targets.append(parent_node)
	if on_hit_callback.is_valid():
		on_hit_callback.call(self, parent_node)
	# Chain lightning — redirect this bullet to the next nearest unhit enemy.
	if _chain_remaining > 0:
		var next: Node2D = _find_chain_target(global_position, chain_range)
		if next != null:
			_chain_remaining -= 1
			var dir: Vector2 = (next.global_position - global_position).normalized()
			velocity = dir * velocity.length()
			rotation = velocity.angle()
			damage = max(1, int(round(float(damage) * 0.6)))
			return
	if _pierces_remaining > 0:
		_pierces_remaining -= 1
		return
	_impact()


func _apply_on_hit_effects(target_parent: Node) -> void:
	if target_parent == null:
		return
	# Burn DoT — attach or refresh a BurnComponent on the target
	if burn_dps > 0.0 and burn_duration > 0.0:
		var existing: Node = target_parent.get_node_or_null("BurnComponent")
		if existing != null and existing is BurnComponent:
			(existing as BurnComponent).refresh(burn_dps, burn_duration)
		else:
			var burn: BurnComponent = BurnComponent.new()
			burn.name = "BurnComponent"
			burn.set_script(BURN_COMPONENT_SCRIPT)
			burn.damage_per_second = burn_dps
			burn.duration = burn_duration
			target_parent.add_child(burn)
	# Pull / push effect on hit. Positive pull_distance yanks target toward
	# the bullet (Blue / attractive force); negative pushes them away (Red /
	# repulsive force / generic knockback).
	if pull_distance != 0.0 and target_parent is Node2D:
		var target_2d: Node2D = target_parent as Node2D
		var dir: Vector2 = (global_position - target_2d.global_position).normalized()
		target_2d.global_position += dir * pull_distance


func _impact() -> void:
	VFX.spawn_hit_particles(global_position, velocity.normalized())
	_despawn()


func _despawn() -> void:
	if _alive and split_on_death > 0 and team == "player":
		_spawn_split_children()
	_alive = false
	BulletPool.release(self)


func _spawn_split_children() -> void:
	var ps: PackedScene = _get_self_packed_scene()
	if ps == null:
		return
	var base_dir: Vector2 = velocity.normalized()
	var speed: float = velocity.length()
	if speed <= 1.0:
		speed = 200.0
		base_dir = Vector2.RIGHT
	var split_dmg: int = max(1, int(round(float(damage) * 0.5)))
	var fan_radius: float = deg_to_rad(20.0)
	for i: int in split_on_death:
		var t: float = 0.0
		if split_on_death > 1:
			t = (float(i) - float(split_on_death - 1) * 0.5) / (float(split_on_death - 1) * 0.5)
		var ang: float = t * fan_radius
		var dir: Vector2 = base_dir.rotated(ang)
		var b: Node = BulletPool.acquire(ps)
		if b is Bullet:
			var bull: Bullet = b as Bullet
			# Children don't recurse-split.
			bull.split_on_death = 0
			bull.ricochet_count = 0
			bull.chain_targets = 0
			bull.spawn(global_position, dir, speed * 0.8, split_dmg, team)


func _get_self_packed_scene() -> PackedScene:
	var path: String = scene_file_path
	if path == "":
		path = "res://scenes/projectiles/PlayerBullet.tscn"
	return ResourceLoader.load(path) as PackedScene

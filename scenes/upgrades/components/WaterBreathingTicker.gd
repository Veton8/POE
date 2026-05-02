class_name WaterBreathingTicker
extends AutocastTicker

# Tanjiro "Water Breathing" — Uncommon, LINEAR cap 5.
# Every 2.5s, executes a slash. Each stack unlocks one more form in
# the cycle (1→5 forms). Cycle index preserved between casts.
# Form variants are simplified for v1: each form has a different
# effect shape (line / arc / 3-strike / long-line / AoE pulse).

const MAX_STACKS: int = 5

@export var damage_mult: float = 1.6
@export var pierce: int = 4
@export var slash_speed: float = 220.0

var stacks: int = 1
var _form_idx: int = 0


func _ready() -> void:
	tick_interval = 2.5
	super._ready()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	var form: int = _form_idx % maxi(1, stacks)
	_form_idx += 1
	match form:
		0: _form_thrust(p, dir)
		1: _form_arc(p, dir)
		2: _form_combo(p, dir)
		3: _form_long(p, dir)
		_: _form_pulse(p)
	Audio.play("shoot", -0.1 + form * 0.05, -2.0)


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO


func _spawn_bullet(p: Player, dir: Vector2, dmg_mult: float) -> void:
	if p.bullet_scene == null:
		return
	var b: Node = BulletPool.acquire(p.bullet_scene)
	if b == null or not b.has_method("spawn"):
		return
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult * dmg_mult)))
	var origin: Vector2 = p.muzzle.global_position if p.muzzle != null else p.global_position
	b.call("spawn", origin, dir, slash_speed, dmg, "player", pierce)


func _form_thrust(p: Player, dir: Vector2) -> void:
	_spawn_bullet(p, dir, 1.0)


func _form_arc(p: Player, dir: Vector2) -> void:
	for ang_deg: float in [-15.0, 0.0, 15.0]:
		_spawn_bullet(p, dir.rotated(deg_to_rad(ang_deg)), 0.8)


func _form_combo(p: Player, dir: Vector2) -> void:
	_spawn_bullet(p, dir, 0.6)
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(p):
		return
	_spawn_bullet(p, dir, 0.6)
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(p):
		return
	_spawn_bullet(p, dir, 0.6)


func _form_long(p: Player, dir: Vector2) -> void:
	# Single fast bullet with extra pierce/damage as pseudo-beam
	if p.bullet_scene == null:
		return
	var b: Node = BulletPool.acquire(p.bullet_scene)
	if b == null or not b.has_method("spawn"):
		return
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult * 1.5)))
	b.call("spawn", p.muzzle.global_position if p.muzzle != null else p.global_position,
		dir, slash_speed * 1.5, dmg, "player", pierce + 6)


func _form_pulse(p: Player) -> void:
	# AoE around player
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(p.global_position) > 60.0 * 60.0:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, (n as Node2D).global_position)

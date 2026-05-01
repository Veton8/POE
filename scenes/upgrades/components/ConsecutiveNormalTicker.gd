class_name ConsecutiveNormalTicker
extends AutocastTicker

# Saitama "Consecutive Normal Punches" — Legendary, UNIQUE.
# Every 9s, performs 12 rapid punches (over 1.2s, 100ms apart). Each
# punch picks a random enemy within 100px, deals damage with a +5%
# per-connect ramp (resets each cast).

@export var punch_count: int = 12
@export var punch_interval: float = 0.1
@export var punch_radius: float = 100.0
@export var damage_mult: float = 1.5
@export var ramp_per_connect: float = 0.05


func _ready() -> void:
	tick_interval = 9.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var ramp: float = 1.0
	for i: int in punch_count:
		if not is_instance_valid(p):
			return
		var target: Node2D = _pick_random_enemy_near(p)
		if target == null:
			await get_tree().create_timer(punch_interval).timeout
			continue
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult * ramp)))
		var hb: Node = target.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, target.global_position)
			ramp += ramp_per_connect
		VFX.spawn_hit_particles(target.global_position, Vector2.ZERO)
		Audio.play("shoot", randf_range(-0.2, 0.2), -4.0)
		await get_tree().create_timer(punch_interval).timeout


func _pick_random_enemy_near(p: Player) -> Node2D:
	var candidates: Array[Node2D] = []
	var r2: float = punch_radius * punch_radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(p.global_position) > r2:
			continue
		candidates.append(n as Node2D)
	if candidates.is_empty():
		return null
	return candidates[randi() % candidates.size()]

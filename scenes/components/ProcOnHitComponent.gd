class_name ProcOnHitComponent
extends Node

# Listens to player.bullet_hit and runs `proc_id` on every Nth hit.
# The Player must emit `bullet_hit(target: Node)` (added in Phase B).
#
# Built-in proc_ids (extendable via duck-typing):
#   "lifesteal"      -> heal the player (amount = heal_amount)
#   "shockwave"      -> small 32px AoE for `damage` damage
#   "freeze"         -> apply a slow buff via BuffComponent at speed_mul = 0.5

@export var proc_id: StringName = &"lifesteal"
@export var trigger_every_n_hits: int = 6
@export var heal_amount: int = 1
@export var damage: int = 2
@export var radius: float = 32.0

var _player: Player = null
var _counter: int = 0


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null and _player.has_signal("bullet_hit"):
		_player.connect("bullet_hit", _on_bullet_hit)


func attach_to(host: Node) -> void:
	_player = host as Player
	if _player != null and _player.has_signal("bullet_hit") and not _player.is_connected("bullet_hit", _on_bullet_hit):
		_player.connect("bullet_hit", _on_bullet_hit)


func _on_bullet_hit(target: Node) -> void:
	_counter += 1
	if _counter < trigger_every_n_hits:
		return
	_counter = 0
	_fire(target)


func _fire(target: Node) -> void:
	match proc_id:
		&"lifesteal":
			if _player != null and _player.health != null:
				_player.health.heal(heal_amount)
		&"shockwave":
			_spawn_shockwave(target)
		&"freeze":
			_freeze_target(target)
		_:
			pass


func _spawn_shockwave(target: Node) -> void:
	if _player == null:
		return
	var origin: Vector2 = _player.global_position
	if target is Node2D:
		origin = (target as Node2D).global_position
	var r2: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if origin.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		var hb: HurtboxComponent = n.get_node_or_null("HurtboxComponent") as HurtboxComponent
		if hb != null:
			hb.receive_hit(damage, self, (n as Node2D).global_position)
	VFX.spawn_hit_particles(origin, Vector2.UP)


func _freeze_target(target: Node) -> void:
	if not (target is EnemyBase):
		return
	var existing: Node = target.get_node_or_null("BuffComponent")
	if existing is BuffComponent:
		(existing as BuffComponent).refresh(1.0, 0.5)
		return
	var buff: BuffComponent = BuffComponent.new()
	buff.name = "BuffComponent"
	buff.duration = 1.0
	buff.speed_mul = 0.5
	target.add_child(buff)

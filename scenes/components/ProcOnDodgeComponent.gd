class_name ProcOnDodgeComponent
extends Node

# Listens to player.dodged and runs `proc_id` once per dodge.
# Player must emit `dodged()` when DashAbility activates.
#
# Built-in proc_ids:
#   "shockwave"    -> 48px AoE for `damage` damage at dodge end
#   "haste_burst"  -> brief +50% move speed buff for 1.5s on player

@export var proc_id: StringName = &"shockwave"
@export var damage: int = 4
@export var radius: float = 48.0
@export var haste_duration: float = 1.5
@export var haste_mul: float = 1.5

var _player: Player = null
var _haste_active: bool = false
var _orig_speed: float = 0.0
var _haste_t: float = 0.0


func _ready() -> void:
	_player = get_parent() as Player
	if _player != null and _player.has_signal("dodged"):
		_player.connect("dodged", _on_dodged)


func attach_to(host: Node) -> void:
	_player = host as Player
	if _player != null and _player.has_signal("dodged") and not _player.is_connected("dodged", _on_dodged):
		_player.connect("dodged", _on_dodged)


func _on_dodged() -> void:
	match proc_id:
		&"shockwave":
			_emit_shockwave()
		&"haste_burst":
			_grant_haste()
		_:
			pass


func _emit_shockwave() -> void:
	if _player == null:
		return
	var origin: Vector2 = _player.global_position
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
	Audio.play("ability_burst", 0.05, -3.0)


func _grant_haste() -> void:
	if _player == null or _player.stats == null:
		return
	if _haste_active:
		_haste_t = haste_duration
		return
	_haste_active = true
	_orig_speed = _player.stats.move_speed
	_player.stats.move_speed = _orig_speed * haste_mul
	_haste_t = haste_duration
	set_process(true)


func _process(delta: float) -> void:
	if not _haste_active:
		return
	_haste_t -= delta
	if _haste_t <= 0.0:
		if _player != null and _player.stats != null:
			_player.stats.move_speed = _orig_speed
		_haste_active = false
		set_process(false)

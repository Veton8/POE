class_name ProcOnKillComponent
extends Node

# Listens to Events.enemy_died and runs `proc_id` on every Nth kill.
#
# Built-in proc_ids:
#   "splinter_burst"  -> spawn 3 short-lived bullets at the kill site
#   "coin_pop"        -> grant `coin_amount` coins (telemetry only)
#   "burn_bloom"      -> 32px AoE burn application

@export var proc_id: StringName = &"splinter_burst"
@export var trigger_every_n_kills: int = 1
@export var coin_amount: int = 1
@export var splinter_count: int = 3
@export var splinter_damage: int = 2
@export var splinter_speed: float = 180.0
@export var radius: float = 32.0
@export var burn_dps: float = 2.0
@export var burn_duration: float = 2.0

const PLAYER_BULLET_SCENE: PackedScene = preload("res://scenes/projectiles/PlayerBullet.tscn")
const BURN_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")

var _player: Player = null
var _counter: int = 0


func _ready() -> void:
	_player = get_parent() as Player
	if has_node("/root/Events"):
		var ev: Node = get_node("/root/Events")
		if ev.has_signal("enemy_died"):
			ev.connect("enemy_died", _on_enemy_died)


func attach_to(host: Node) -> void:
	_player = host as Player


func _on_enemy_died(enemy: Node, pos: Vector2) -> void:
	if enemy != null and enemy.is_in_group("boss"):
		# Bosses don't trigger N-kill counters — would feel cheap.
		pass
	_counter += 1
	if _counter < trigger_every_n_kills:
		return
	_counter = 0
	_fire(pos)


func _fire(pos: Vector2) -> void:
	match proc_id:
		&"splinter_burst":
			_spawn_splinters(pos)
		&"coin_pop":
			GameState.coins += coin_amount
			Events.coins_changed.emit(GameState.coins)
		&"burn_bloom":
			_burn_aoe(pos)
		_:
			pass


func _spawn_splinters(pos: Vector2) -> void:
	for i: int in splinter_count:
		var ang: float = TAU * float(i) / float(splinter_count)
		var dir: Vector2 = Vector2(cos(ang), sin(ang))
		var b: Node = BulletPool.acquire(PLAYER_BULLET_SCENE)
		if b is Bullet:
			var bull: Bullet = b as Bullet
			bull.lifetime = 0.6
			bull.spawn(pos, dir, splinter_speed, splinter_damage, "player")


func _burn_aoe(pos: Vector2) -> void:
	var r2: float = radius * radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if pos.distance_squared_to((n as Node2D).global_position) > r2:
			continue
		var existing: Node = n.get_node_or_null("BurnComponent")
		if existing != null and existing is BurnComponent:
			(existing as BurnComponent).refresh(burn_dps, burn_duration)
			continue
		var burn: BurnComponent = BurnComponent.new()
		burn.name = "BurnComponent"
		burn.set_script(BURN_SCRIPT)
		burn.damage_per_second = burn_dps
		burn.duration = burn_duration
		n.add_child(burn)

class_name XPOrb
extends Node2D

# XP gem dropped by enemies in endless mode. Sits idle until the
# player enters attract_radius, then homes to the player. Despawns
# after sit_lifetime to keep the world clean.
#
# Drawn programmatically — no sprite asset needed for v1.

enum Tier { GREEN, BLUE, YELLOW, RED }

const VALUES: Dictionary = {
	Tier.GREEN: 1,
	Tier.BLUE: 5,
	Tier.YELLOW: 25,
	Tier.RED: 100,
}

const COLORS: Dictionary = {
	Tier.GREEN: Color(0.4, 0.95, 0.4, 1.0),
	Tier.BLUE: Color(0.3, 0.7, 1.0, 1.0),
	Tier.YELLOW: Color(1.0, 0.85, 0.2, 1.0),
	Tier.RED: Color(1.0, 0.3, 0.3, 1.0),
}

@export var tier: Tier = Tier.GREEN
@export var attract_radius: float = 60.0
@export var attract_speed: float = 220.0
@export var pickup_radius: float = 6.0
@export var sit_lifetime: float = 60.0

var _player: Player = null
var _t_alive: float = 0.0
var _attracting: bool = false


func configure(t: Tier) -> void:
	tier = t
	queue_redraw()


func _ready() -> void:
	z_index = 1
	queue_redraw()


func _process(delta: float) -> void:
	_t_alive += delta
	if _t_alive >= sit_lifetime:
		queue_free()
		return
	if _player == null or not is_instance_valid(_player):
		_player = _find_player()
	if _player == null:
		return
	var d: float = global_position.distance_to(_player.global_position)
	if not _attracting and d <= attract_radius:
		_attracting = true
	if _attracting:
		var dir: Vector2 = (_player.global_position - global_position).normalized()
		global_position += dir * attract_speed * delta
		if d <= pickup_radius:
			_consume()


func _find_player() -> Player:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	for n: Node in nodes:
		if n is Player:
			return n as Player
	return null


func _consume() -> void:
	var value: int = int(VALUES[tier])
	Events.xp_collected.emit(value)
	Audio.play("coin_pickup", 0.05, -8.0)
	queue_free()


func _draw() -> void:
	var col: Color = COLORS[tier]
	var radius: float = 3.0 + float(int(tier)) * 0.7
	draw_circle(Vector2.ZERO, radius, col)
	draw_circle(Vector2(-1, -1), radius * 0.4, col.lightened(0.4))

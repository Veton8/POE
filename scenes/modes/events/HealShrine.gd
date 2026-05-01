class_name HealShrine
extends Area2D

# Persistent shrine. Standing on it for 2s restores 20% HP. 60s
# cooldown between heals. Anchored in the slow-zone band per design.

const STAND_TIME: float = 2.0
const COOLDOWN_S: float = 60.0

var _stand_t: float = 0.0
var _player_in: bool = false
var _last_heal_msec: int = -100000


func _ready() -> void:
	z_index = 2
	add_to_group("map_event")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 16.0
	coll.shape = shape
	add_child(coll)


func _process(delta: float) -> void:
	if _player_in and Time.get_ticks_msec() - _last_heal_msec > int(COOLDOWN_S * 1000.0):
		_stand_t += delta
		if _stand_t >= STAND_TIME:
			_stand_t = 0.0
			_heal()
	else:
		_stand_t = 0.0
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if body is Player:
		_player_in = true


func _on_body_exited(body: Node) -> void:
	if body is Player:
		_player_in = false


func _heal() -> void:
	for n: Node in get_tree().get_nodes_in_group("player"):
		if not (n is Player):
			continue
		var p: Player = n as Player
		if p.health == null:
			continue
		var amount: int = max(1, int(round(float(p.health.max_hp) * 0.20)))
		p.health.heal(amount)
		_last_heal_msec = Time.get_ticks_msec()
		Audio.play("door_unlock", 0.2, -4.0)
		break


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 250.0
	var pulse: float = (sin(t) + 1.0) * 0.5
	# Outer ring
	draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 32, Color(0.30, 0.85, 0.45, 0.5 + pulse * 0.4), 2.0)
	# Inner cross
	draw_rect(Rect2(Vector2(-2, -8), Vector2(4, 16)), Color(0.40, 0.95, 0.55, 0.95), true)
	draw_rect(Rect2(Vector2(-8, -2), Vector2(16, 4)), Color(0.40, 0.95, 0.55, 0.95), true)

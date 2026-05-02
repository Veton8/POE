class_name BombPickup
extends Area2D

# On player overlap, kills every non-elite non-boss enemy on screen.

const VIEWPORT_HALF_W: float = 180.0
const VIEWPORT_HALF_H: float = 320.0


func _ready() -> void:
	z_index = 2
	add_to_group("map_event")
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	body_entered.connect(_on_body_entered)
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 8.0
	coll.shape = shape
	add_child(coll)


func _process(_delta: float) -> void:
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	var p: Player = body as Player
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if n.is_in_group("boss") or n.is_in_group("elite"):
			continue
		var d: Vector2 = (n as Node2D).global_position - p.global_position
		if absf(d.x) > VIEWPORT_HALF_W or absf(d.y) > VIEWPORT_HALF_H:
			continue
		var hp: HealthComponent = n.get_node_or_null("HealthComponent") as HealthComponent
		if hp != null:
			hp.take_damage(99999, self)
	Events.screen_shake.emit(8.0, 0.4)
	Audio.play("ability_burst", -0.4, 4.0)
	queue_free()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 150.0
	var pulse: float = (sin(t) + 1.0) * 0.5
	# Bomb body — black with red fuse spark
	draw_circle(Vector2(0, 1), 6.0, Color(0.10, 0.10, 0.10, 1.0))
	draw_circle(Vector2(0, 1), 5.0, Color(0.20, 0.20, 0.22, 1.0))
	# Fuse top
	draw_rect(Rect2(Vector2(-1, -7), Vector2(2, 3)), Color(0.4, 0.3, 0.2, 1.0), true)
	# Spark
	draw_circle(Vector2(0, -8), 1.5 + pulse, Color(1.0, 0.8, 0.2, 0.95))

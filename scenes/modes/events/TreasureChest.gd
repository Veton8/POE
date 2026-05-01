class_name TreasureChest
extends Area2D

# World-anchored treasure chest. On player overlap, triggers a
# bonus 3-card upgrade overlay (counts as a free level-up). Frees
# itself.

func _ready() -> void:
	z_index = 2
	add_to_group("map_event")
	collision_layer = 0
	collision_mask = 2  # player layer
	monitoring = true
	body_entered.connect(_on_body_entered)
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 10.0
	coll.shape = shape
	add_child(coll)


func _process(_delta: float) -> void:
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	if not (body is Player):
		return
	if has_node("/root/UpgradeManager"):
		var um: Node = get_node("/root/UpgradeManager")
		if um.has_method("offer_picks"):
			um.call("offer_picks")
	Audio.play("door_unlock", 0.05, -2.0)
	queue_free()


func _draw() -> void:
	# Brown chest body
	draw_rect(Rect2(Vector2(-8, -6), Vector2(16, 12)), Color(0.55, 0.35, 0.18, 1.0), true)
	# Lid
	draw_rect(Rect2(Vector2(-8, -10), Vector2(16, 5)), Color(0.45, 0.28, 0.12, 1.0), true)
	# Gold trim pulse
	var pulse: float = (sin(Time.get_ticks_msec() / 200.0) + 1.0) * 0.5
	draw_rect(Rect2(Vector2(-8, -1), Vector2(16, 2)), Color(1.0, 0.85, 0.30, 0.4 + pulse * 0.5), true)

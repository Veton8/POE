class_name MagnetPickup
extends Area2D

# On player overlap, vacuums all XP orbs on screen toward player for
# 4 seconds. Stays in world until picked up.

@export var duration: float = 4.0


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
	# Force every orb in the scene to attract immediately
	for n: Node in get_tree().get_nodes_in_group("xp_orb"):
		if n is XPOrb:
			(n as XPOrb).attract_radius = 9999.0
	# Schedule revert after duration
	var revert_t: SceneTreeTimer = get_tree().create_timer(duration)
	revert_t.timeout.connect(_revert_orbs)
	Audio.play("coin_pickup", 0.0, 2.0)
	queue_free()


func _revert_orbs() -> void:
	# Tighten range back; new orbs spawn with the default in their _ready()
	for n: Node in get_tree().get_nodes_in_group("xp_orb"):
		if n is XPOrb:
			(n as XPOrb).attract_radius = 60.0


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 200.0
	var pulse: float = (sin(t) + 1.0) * 0.5
	# Magnet horseshoe
	draw_arc(Vector2.ZERO, 6.0, PI, TAU, 16, Color(0.85, 0.30, 0.30, 0.95), 2.0)
	draw_circle(Vector2(-4, 4), 1.5, Color(0.95, 0.30, 0.30))
	draw_circle(Vector2(4, 4), 1.5, Color(0.95, 0.30, 0.30))
	# Glow
	draw_circle(Vector2.ZERO, 8.0, Color(0.95, 0.65, 0.65, 0.20 * pulse))

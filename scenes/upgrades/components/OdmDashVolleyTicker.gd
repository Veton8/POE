class_name OdmDashVolleyTicker
extends AutocastTicker

# Levi "ODM Dash Volley" — Epic, UNIQUE.
# Every 6s, ghosts forward 60px toward target (no actual displacement —
# spawns a brief afterimage), executes a 60px-radius spin attack at
# landing, then snaps back. Player retains joystick control throughout.

@export var dash_speed: float = 600.0  # afterimage travel
@export var dash_distance: float = 60.0
@export var aoe_radius: float = 60.0
@export var damage_mult: float = 4.0


func _ready() -> void:
	tick_interval = 6.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var target_pos: Vector2 = Vector2.ZERO
	if p.current_target != null and is_instance_valid(p.current_target):
		target_pos = p.current_target.global_position
	elif p.move_input.length_squared() > 0.05:
		target_pos = p.global_position + p.move_input.normalized() * dash_distance
	else:
		return
	# Visual afterimage line — quick fade
	var afterimg: Line2D = Line2D.new()
	afterimg.add_point(p.global_position)
	afterimg.add_point(target_pos)
	afterimg.width = 3.0
	afterimg.default_color = Color(1.0, 1.0, 1.0, 0.6)
	afterimg.z_index = 5
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(afterimg)
	var fade_tw: Tween = afterimg.create_tween()
	fade_tw.tween_property(afterimg, "modulate:a", 0.0, 0.25)
	fade_tw.tween_callback(afterimg.queue_free)
	# Apply spin damage at target_pos
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(target_pos) > aoe_radius * aoe_radius:
			continue
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(dmg, self, (n as Node2D).global_position)
	VFX.spawn_hit_particles(target_pos, Vector2.ZERO)
	Audio.play("dash", 0.0, -2.0)
	Audio.play("ability_burst", 0.3, -4.0)

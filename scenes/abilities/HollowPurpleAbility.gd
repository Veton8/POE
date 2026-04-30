class_name HollowPurpleAbility
extends Ability

# Gojo's W (Hollow Technique: Purple). Canon: combines Cursed Technique
# Lapse: Blue (attractive) and Cursed Technique Reversal: Red (repulsive)
# into "imaginary mass." Implementation: Gojo flickers red+blue while
# charging, then a Blue orb shoots from his right side and a Red orb from
# his left side. They converge to a point ahead of him and detonate into
# a small purple Unlimited-Void-style sphere that deals AoE true damage.

const VOID_BUBBLE_TEX: Texture2D = preload("res://art/vfx/void_bubble.svg")
const BLUE_TEX: Texture2D = preload("res://art/projectiles/bullet_blue_orb.svg")
const RED_TEX: Texture2D = preload("res://art/projectiles/bullet_red.svg")

@export var damage_mult: float = 6.0
@export var explosion_radius: float = 70.0
@export var charge_seconds: float = 0.5
@export var orb_separation: float = 16.0
@export var orb_travel_distance: float = 90.0
@export var orb_travel_duration: float = 0.35
@export var orb_scale: float = 1.4
@export var purple_color: Color = Color(1.4, 0.5, 1.8)


func _ready() -> void:
	super._ready()
	ability_name = "Hollow Purple"
	cooldown_seconds = 15.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, -1.0)

	# Charge phase: sprite flickers between red and blue tints
	var orig_modulate: Color = p.sprite.modulate
	var charge_tw: Tween = p.create_tween().set_loops()
	charge_tw.tween_property(p.sprite, "modulate", Color(0.5, 0.7, 1.8), 0.12)
	charge_tw.tween_property(p.sprite, "modulate", Color(1.7, 0.4, 0.5), 0.12)
	await p.get_tree().create_timer(charge_seconds).timeout
	if not is_instance_valid(p):
		return
	if charge_tw != null and charge_tw.is_valid():
		charge_tw.kill()
	p.sprite.modulate = orig_modulate

	# Compute Blue (right) + Red (left) trajectories that converge ahead of Gojo
	var aim: Vector2 = _aim_dir(p)
	var right_perp: Vector2 = aim.rotated(PI / 2.0)
	var muzzle_pos: Vector2 = p.muzzle.global_position
	var blue_start: Vector2 = muzzle_pos + right_perp * orb_separation
	var red_start: Vector2 = muzzle_pos - right_perp * orb_separation
	var collision_point: Vector2 = muzzle_pos + aim * orb_travel_distance

	# Launch the two converging orbs (visual-only — collision happens at the meeting point)
	Audio.play("shoot", 0.05, -2.0)
	var blue_orb: Sprite2D = _spawn_orb(BLUE_TEX, blue_start, collision_point, orb_travel_duration)
	var red_orb: Sprite2D = _spawn_orb(RED_TEX, red_start, collision_point, orb_travel_duration)

	# Wait for the orbs to meet, then detonate the Hollow Purple
	await p.get_tree().create_timer(orb_travel_duration).timeout
	_detonate(p, collision_point)

	if is_instance_valid(blue_orb):
		blue_orb.queue_free()
	if is_instance_valid(red_orb):
		red_orb.queue_free()


func _spawn_orb(tex: Texture2D, start_pos: Vector2, end_pos: Vector2, duration: float) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.scale = Vector2(orb_scale, orb_scale)
	s.z_index = 6
	s.global_position = start_pos
	get_tree().current_scene.add_child(s)
	var tw: Tween = s.create_tween()
	tw.tween_property(s, "global_position", end_pos, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return s


func _detonate(p: Player, pos: Vector2) -> void:
	Events.screen_shake.emit(20.0, 0.5)
	Audio.play("ability_burst", 0.05, 1.5)

	# Mini Unlimited Void — purple-tinted, scales up, spins, then fades
	var explosion: Sprite2D = Sprite2D.new()
	explosion.texture = VOID_BUBBLE_TEX
	explosion.modulate = purple_color
	explosion.z_index = 7
	explosion.global_position = pos
	explosion.scale = Vector2.ZERO
	get_tree().current_scene.add_child(explosion)
	var target_scale: float = (explosion_radius * 2.0) / 64.0

	var open_tw: Tween = explosion.create_tween()
	open_tw.tween_property(explosion, "scale", Vector2(target_scale, target_scale), 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var spin_tw: Tween = explosion.create_tween().set_loops()
	spin_tw.tween_property(explosion, "rotation", TAU, 0.8)

	var fade_tw: Tween = explosion.create_tween()
	fade_tw.tween_interval(0.32)
	fade_tw.tween_property(explosion, "modulate", Color(purple_color.r, purple_color.g, purple_color.b, 0), 0.28)
	fade_tw.tween_callback(explosion.queue_free)

	# AoE damage — every enemy hurtbox in radius takes a flat hit
	var space: PhysicsDirectSpaceState2D = p.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = explosion_radius
	query.shape = shape
	query.transform = Transform2D(0.0, pos)
	query.collision_mask = 1 << 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits: Array[Dictionary] = space.intersect_shape(query, 64)
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	for h: Dictionary in hits:
		var hb: HurtboxComponent = h["collider"] as HurtboxComponent
		if hb == null:
			continue
		hb.receive_hit(dmg, p, hb.global_position)
		var dir: Vector2 = (hb.global_position - pos).normalized()
		VFX.spawn_hit_particles(hb.global_position, dir)
	VFX.spawn_death_particles(pos)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

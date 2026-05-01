class_name LogiaFlameDashAbility
extends Ability

# Ace's Q. Logia phase-step: Ace dissolves into flame, dashes forward with
# i-frames, leaves a short fire trail along the path.

@export var dash_distance: float = 90.0
@export var dash_duration: float = 0.22
@export var iframe_seconds: float = 0.45
@export var trail_steps: int = 6


func _ready() -> void:
	super._ready()
	ability_name = "Flame Body"
	cooldown_seconds = 8.0
	target_strategy = TargetStrategy.MOVE_INPUT_DIR


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_dash", 0.05, 0.0)

	var dir: Vector2 = p.move_input if p.move_input.length() > 0.05 else Vector2.RIGHT
	dir = dir.normalized()
	var start: Vector2 = p.global_position
	var target: Vector2 = start + dir * dash_distance

	var orig_modulate: Color = p.sprite.modulate
	p.sprite.modulate = Color(1.6, 0.6, 0.3)
	p.set_collision_mask_value(3, false)
	if p.hurtbox != null:
		p.hurtbox.set_deferred("monitorable", false)

	var tw: Tween = p.create_tween()
	tw.tween_property(p, "global_position", target, dash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Spawn flame puffs along the path
	for i: int in trail_steps:
		var t: float = float(i) / float(maxi(trail_steps - 1, 1))
		var pos: Vector2 = start.lerp(target, t)
		VFX.spawn_hit_particles(pos, dir)

	await tw.finished
	if is_instance_valid(p):
		p.sprite.modulate = orig_modulate
		var rest: float = maxf(iframe_seconds - dash_duration, 0.0)
		if rest > 0.0:
			await p.get_tree().create_timer(rest).timeout
	if is_instance_valid(p):
		p.set_collision_mask_value(3, true)
		if p.hurtbox != null:
			p.hurtbox.set_deferred("monitorable", true)

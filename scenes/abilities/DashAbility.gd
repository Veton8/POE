class_name DashAbility
extends Ability

@export var dash_distance: float = 80.0
@export var dash_duration: float = 0.18
@export var i_frames_seconds: float = 0.3

func _ready() -> void:
	super._ready()
	ability_name = "Dash"
	target_strategy = TargetStrategy.MOVE_INPUT_DIR

func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_dash", 0.05, 0.0)
	if p.has_signal("dodged"):
		p.emit_signal("dodged")
	var dir: Vector2 = p.move_input if p.move_input.length() > 0.05 else Vector2.RIGHT
	dir = dir.normalized()
	var target: Vector2 = p.global_position + dir * dash_distance
	var tw: Tween = p.create_tween()
	tw.tween_property(p, "global_position", target, dash_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	p.set_collision_mask_value(3, false)
	if p.hurtbox != null:
		p.hurtbox.set_deferred("monitorable", false)
	await tw.finished
	if is_instance_valid(p):
		await p.get_tree().create_timer(maxf(i_frames_seconds - dash_duration, 0.0)).timeout
	if is_instance_valid(p):
		p.set_collision_mask_value(3, true)
		if p.hurtbox != null:
			p.hurtbox.set_deferred("monitorable", true)

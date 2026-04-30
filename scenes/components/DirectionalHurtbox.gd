class_name DirectionalHurtbox
extends HurtboxComponent

# Subclass that blocks damage coming from a chosen forward arc when the
# shield is active. Used by Page-Turner: while shielded, hits whose origin
# falls inside `shield_arc_degrees` of `shield_facing` are nullified.

var shield_facing: Vector2 = Vector2.RIGHT
var shield_arc_degrees: float = 110.0
var shield_active: bool = true


func receive_hit(amount: int, source: Node = null, hit_pos: Vector2 = Vector2.ZERO) -> void:
	if shield_active and hit_pos != Vector2.ZERO and shield_facing.length_squared() > 0.001:
		var dir: Vector2 = (hit_pos - global_position).normalized()
		var angle_diff: float = rad_to_deg(absf(dir.angle_to(shield_facing)))
		if angle_diff <= shield_arc_degrees * 0.5:
			VFX.spawn_hit_particles(hit_pos)
			Audio.play("hit", 0.05, 4.0)
			return
	super.receive_hit(amount, source, hit_pos)

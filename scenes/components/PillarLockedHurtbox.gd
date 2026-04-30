class_name PillarLockedHurtbox
extends HurtboxComponent

# Boss hurtbox that ignores damage while `vulnerable` is false. Drowned
# Curator toggles this from `false` to `true` when all breakable pillars
# in the arena have been destroyed.

var vulnerable: bool = false


func receive_hit(amount: int, source: Node = null, hit_pos: Vector2 = Vector2.ZERO) -> void:
	if not vulnerable:
		var pos: Vector2 = hit_pos if hit_pos != Vector2.ZERO else global_position
		VFX.spawn_hit_particles(pos)
		Audio.play("hit", 0.05, 4.0)
		return
	super.receive_hit(amount, source, hit_pos)

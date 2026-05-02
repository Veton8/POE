class_name HurtboxComponent
extends Area2D

signal hit_taken(amount: int, source: Node)

@export var health: HealthComponent
@export var sprite_to_flash: CanvasItem

func _ready() -> void:
	# Bosses get add_child'd from _start_boss, which itself runs from a signal
	# during a physics flush. Direct writes to monitoring/monitorable in that
	# context are blocked by Godot 4 — defer the meaningful change and drop
	# the redundant monitorable assignment (true is the Area2D default).
	set_deferred("monitoring", false)
	if sprite_to_flash and sprite_to_flash.material is ShaderMaterial:
		(sprite_to_flash.material as ShaderMaterial).resource_local_to_scene = true

func receive_hit(amount: int, source: Node = null, hit_pos: Vector2 = Vector2.ZERO) -> void:
	if health == null:
		return
	if health.take_damage(amount, source):
		hit_taken.emit(amount, source)
		var pos := hit_pos if hit_pos != Vector2.ZERO else global_position
		VFX.spawn_hit_particles(pos)
		VFX.spawn_damage_number(pos, amount)
		Audio.play("hit", 0.1, -2.0)
		if get_parent().is_in_group("player"):
			Audio.play("player_hurt", 0.05, 0.0)
		if sprite_to_flash:
			HitFlashHelper.flash(sprite_to_flash, 0.06)

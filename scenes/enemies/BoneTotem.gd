class_name BoneTotem
extends EnemyBase

# Immobile necromancer totem. Cannot move, takes the fire-timer ticks as
# minion-spawn ticks instead. Each tick spawns one Bone Wraith near the
# totem; the totem caps how many living wraiths it has summoned at once
# so it can't flood the room while the player is preoccupied.

const BONE_WRAITH_SCENE: PackedScene = preload("res://scenes/enemies/BoneWraith.tscn")

@export var max_active_wraiths: int = 3

var _summoned: Array[Node] = []


func _on_fire_timer_timeout() -> void:
	_summoned = _summoned.filter(func(n): return is_instance_valid(n))
	if _summoned.size() >= max_active_wraiths:
		return
	var wraith: Node2D = BONE_WRAITH_SCENE.instantiate() as Node2D
	if wraith == null:
		return
	get_tree().current_scene.add_child(wraith)
	var offset: Vector2 = Vector2(randf_range(-12.0, 12.0), randf_range(-12.0, 12.0))
	wraith.global_position = global_position + offset
	_summoned.append(wraith)
	sprite.modulate = Color(1.4, 1.4, 2.0, 1)
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.25)

class_name InkBlob
extends Node2D

# Lobbed ink projectile fired by InkSpitter. Arcs from the spitter to a
# target point, then transforms into an InkPuddle DoT area and frees itself.

const INK_PUDDLE_SCENE: PackedScene = preload("res://scenes/hazards/InkPuddle.tscn")

@export var flight_time: float = 0.55
@export var arc_height: float = 22.0

@onready var sprite: Sprite2D = $Sprite2D


func launch(target: Vector2) -> void:
	var start: Vector2 = global_position
	var mid: Vector2 = (start + target) * 0.5 + Vector2(0, -arc_height)
	var tw: Tween = create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "global_position", mid, flight_time * 0.5).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", target, flight_time * 0.5).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(sprite, "rotation", TAU, flight_time)
	tw.tween_callback(_explode)


func _explode() -> void:
	var puddle: Node2D = INK_PUDDLE_SCENE.instantiate() as Node2D
	if puddle != null:
		get_tree().current_scene.add_child(puddle)
		puddle.global_position = global_position
	queue_free()

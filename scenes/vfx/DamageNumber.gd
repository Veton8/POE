class_name DamageNumber
extends Label

func popup(value: int, crit: bool = false, color: Color = Color(1, 0.3, 0.3)) -> void:
	text = str(value)
	modulate = color
	if crit:
		modulate = Color(1.2, 0.9, 0.2)
		scale = Vector2(1.3, 1.3)
	z_index = 100
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", position.y - 24, 0.6)
	tw.tween_property(self, "modulate:a", 0.0, 0.6).set_delay(0.1)
	await tw.finished
	queue_free()

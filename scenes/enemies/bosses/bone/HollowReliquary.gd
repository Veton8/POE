class_name HollowReliquary
extends Boss

# Stationary projectile boss. FAN + custom SOUL_BURST (3-4 timed rings of
# 8 slow bullets each, slightly rotated each wave so the gaps shift).
# Forces the player to thread between rings instead of just orbiting.


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	if randi() % 2 == 0:
		_projectile_fan()
	else:
		_soul_burst()


func _soul_burst() -> void:
	attacking = true
	var orig_modulate: Color = sprite.modulate
	sprite.modulate = Color(1.8, 0.8, 1.8, 1)
	await get_tree().create_timer(0.5).timeout
	sprite.modulate = orig_modulate
	if bullet_scene == null:
		attacking = false
		return
	var waves: int = 4 if phase == 2 else 3
	for w in waves:
		var rotation_offset: float = float(w) * TAU / 16.0
		for i in 8:
			var angle: float = rotation_offset + TAU * float(i) / 8.0
			var dir: Vector2 = Vector2.RIGHT.rotated(angle)
			var b: Node = BulletPool.acquire(bullet_scene)
			if b.has_method("spawn"):
				b.call("spawn", global_position, dir, stats.bullet_speed * 0.7, stats.bullet_damage, "enemy")
		await get_tree().create_timer(0.35).timeout
	attacking = false

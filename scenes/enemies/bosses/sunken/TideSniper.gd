class_name TideSniper
extends Boss

# Stationary ranged boss. Cycles between FAN, a 4-shot rapid TIDE_VOLLEY
# (fast aimed bullets at the player), and a telegraphed AIM_SHOT (single
# very-fast double-damage bullet). Punishes standing still in any sightline.


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var pick: int = randi() % 3
	match pick:
		0: _projectile_fan()
		1: _tide_volley()
		_: _aim_shot()


func _tide_volley() -> void:
	attacking = true
	if bullet_scene == null:
		attacking = false
		return
	var shots: int = 6 if phase == 2 else 4
	for i in shots:
		if player == null or not is_instance_valid(player):
			break
		var dir: Vector2 = (player.global_position - global_position).normalized()
		var b: Node = BulletPool.acquire(bullet_scene)
		if b.has_method("spawn"):
			b.call("spawn", global_position, dir, stats.bullet_speed * 1.4, stats.bullet_damage, "enemy")
		await get_tree().create_timer(0.16).timeout
	attacking = false


func _aim_shot() -> void:
	attacking = true
	var orig_modulate: Color = sprite.modulate
	sprite.modulate = Color(1.5, 1.5, 0.5, 1)
	await get_tree().create_timer(0.7).timeout
	sprite.modulate = orig_modulate
	if player != null and is_instance_valid(player) and bullet_scene != null:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		var b: Node = BulletPool.acquire(bullet_scene)
		if b.has_method("spawn"):
			b.call("spawn", global_position, dir, stats.bullet_speed * 2.0, stats.bullet_damage * 2, "enemy")
	await get_tree().create_timer(0.5).timeout
	attacking = false

class_name Inkmaw
extends Boss

# First Sunken boss. Slow blob that alternates between a radial PROJECTILE_FAN
# and a custom INK_SPRAY (3-5 lobbed InkBlobs aimed at the player). No CHARGE
# or SLAM — the threat comes from puddle-area denial.

const INK_BLOB_SCENE: PackedScene = preload("res://scenes/projectiles/InkBlob.tscn")


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	if randi() % 2 == 0:
		_projectile_fan()
	else:
		_ink_spray()


func _ink_spray() -> void:
	attacking = true
	var orig_modulate: Color = sprite.modulate
	sprite.modulate = Color(2.0, 1.5, 2.0, 1)
	await get_tree().create_timer(0.5).timeout
	sprite.modulate = orig_modulate
	if player == null or not is_instance_valid(player):
		attacking = false
		return
	var target: Vector2 = player.global_position
	var spread_count: int = 5 if phase == 2 else 3
	var spread: float = 36.0
	for i in spread_count:
		var t: float = float(i) / float(max(spread_count - 1, 1))
		var offset: Vector2 = Vector2((t - 0.5) * 2.0 * spread, 0)
		var blob: Node2D = INK_BLOB_SCENE.instantiate() as Node2D
		if blob == null:
			continue
		get_tree().current_scene.add_child(blob)
		blob.global_position = global_position
		if blob.has_method("launch"):
			blob.call("launch", target + offset)
	await get_tree().create_timer(0.6).timeout
	attacking = false

class_name InkSpitter
extends EnemyBase

# Stationary spitter that lobs ink blobs at the player. Each blob arcs to
# the player's current position, then becomes an InkPuddle DoT area.

const INK_BLOB_SCENE: PackedScene = preload("res://scenes/projectiles/InkBlob.tscn")


func _on_fire_timer_timeout() -> void:
	if player == null or not is_instance_valid(player):
		return
	var blob: Node2D = INK_BLOB_SCENE.instantiate() as Node2D
	if blob == null:
		return
	get_tree().current_scene.add_child(blob)
	blob.global_position = global_position + Vector2(0, -4)
	if blob.has_method("launch"):
		blob.call("launch", player.global_position)

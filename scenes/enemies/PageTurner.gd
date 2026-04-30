class_name PageTurner
extends EnemyBase

# Slow-moving ranged enemy with a forward-facing shield. The DirectionalHurtbox
# blocks any hit whose origin lies inside the front arc relative to the player
# direction, so the player must flank to deal damage.

var dir_hurtbox: DirectionalHurtbox = null


func _ready() -> void:
	super._ready()
	dir_hurtbox = $Hurtbox as DirectionalHurtbox


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dir_hurtbox == null or player == null or not is_instance_valid(player):
		return
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length_squared() > 0.001:
		dir_hurtbox.shield_facing = to_player.normalized()

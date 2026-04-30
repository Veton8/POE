class_name BoundTome
extends Boss

# Slow ranged boss with a forward-facing 90° shield. Player must dash around
# to hit the back. Uses FAN + CHARGE — the charge briefly disables shield
# tracking while attacking, opening a damage window.


var dir_hurtbox: DirectionalHurtbox = null


func _ready() -> void:
	super._ready()
	dir_hurtbox = $Hurtbox as DirectionalHurtbox
	if dir_hurtbox != null:
		dir_hurtbox.shield_arc_degrees = 90.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if dir_hurtbox == null or player == null or not is_instance_valid(player):
		return
	# While charging, drop the shield so the player can punish a missed lunge.
	dir_hurtbox.shield_active = not attacking
	var to_player: Vector2 = player.global_position - global_position
	if to_player.length_squared() > 0.001:
		dir_hurtbox.shield_facing = to_player.normalized()


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	if randi() % 2 == 0:
		_projectile_fan()
	else:
		_charge()

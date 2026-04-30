class_name ChoirAcolyte
extends Boss

# First Bone Choir boss. Slow caster that alternates radial PROJECTILE_FAN
# with SUMMON (Bone Wraiths). Pattern interval is faster than Verdant's
# first boss to make the summons feel like a steady tax on the player's
# attention.


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	if randi() % 2 == 0:
		_projectile_fan()
	else:
		_summon()

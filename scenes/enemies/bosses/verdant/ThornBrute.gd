class_name ThornBruteBoss
extends Boss

# Verdant Crypt R3 mini-boss. Pure melee bruiser — only uses CHARGE + SLAM.

func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var pick: int = [Pattern.CHARGE, Pattern.SLAM].pick_random()
	match pick:
		Pattern.CHARGE: _charge()
		Pattern.SLAM: _slam()

class_name MarrowSentinel
extends Boss

# Aggressive melee-leaning boss. Cycles between CHARGE, SLAM, and FAN.
# Differentiated by stats (high contact dmg, faster move) — patterns are
# all from the Boss.gd base set so this is the most "vanilla" of the four.


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var pick: int = randi() % 3
	match pick:
		0: _charge()
		1: _slam()
		_: _projectile_fan()

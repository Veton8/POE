class_name WraithWardenBoss
extends Boss

# Verdant Crypt R7 mini-boss. Mixed melee + ranged — alternates CHARGE
# (close gap) and PROJECTILE_FAN (zone the arena). Faster pattern interval
# than the earlier minis to feel meaningfully more aggressive.

func _ready() -> void:
	super._ready()
	pattern_timer.wait_time = 1.8


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var pick: int = [Pattern.CHARGE, Pattern.PROJECTILE_FAN, Pattern.CHARGE].pick_random()
	match pick:
		Pattern.CHARGE: _charge()
		Pattern.PROJECTILE_FAN: _projectile_fan()

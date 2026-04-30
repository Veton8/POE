class_name PoisonBloomBoss
extends Boss

# Verdant Crypt R5 mini-boss. Stationary (move_speed=0 in stats), only fires
# projectile fans. Faster pattern interval than usual since it can't move.

func _ready() -> void:
	super._ready()
	pattern_timer.wait_time = 1.6


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	_projectile_fan()

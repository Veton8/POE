class_name HeartOfOvergrowthBoss
extends Boss

# Verdant Crypt R10 floor boss. Multi-phase. Stationary heart of the
# dungeon — pulses out projectile fans and slams while summoning waves of
# Root-Bombers in phase 2. The desperation phase (≤25% HP) accelerates
# everything rather than introducing new patterns.

@export var phase3_pattern_interval: float = 1.0
var _phase3_active: bool = false


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var options: Array = [Pattern.PROJECTILE_FAN, Pattern.SLAM]
	if phase >= 2:
		options.append(Pattern.SUMMON)
		options.append(Pattern.PROJECTILE_FAN)
	var pick: int = options.pick_random()
	match pick:
		Pattern.PROJECTILE_FAN: _projectile_fan()
		Pattern.SLAM: _slam()
		Pattern.SUMMON: _summon()


func _on_health_changed(current: int, _max_hp: int) -> void:
	super._on_health_changed(current, _max_hp)
	# Desperation phase — accelerate pattern cadence at 25% HP
	if not _phase3_active and float(current) / float(stats.max_hp) <= 0.25:
		_phase3_active = true
		pattern_timer.wait_time = phase3_pattern_interval
		Events.screen_shake.emit(16.0, 0.7)
		sprite.modulate = Color(1.6, 0.4, 0.4, 1)

extends Node

# Global signal bus. Signals are declared here and emitted from other scripts
# via `Events.<signal>.emit(...)`. The "unused signal" warnings the parser
# would otherwise raise are suppressed below — they ARE used, just not
# inside this file.

# Cap framerate at 60 — game logic (250-entity endless mode) is balanced
# around 60 Hz physics ticks. ProMotion 120 Hz iPhones would otherwise
# double per-frame CPU cost. 60fps lock applied at startup.
func _ready() -> void:
	Engine.max_fps = 60

@warning_ignore("unused_signal")
signal screen_shake(amount: float, duration: float)

@warning_ignore("unused_signal")
signal room_cleared(room: Node)

@warning_ignore("unused_signal")
signal room_entered(room: Node)

@warning_ignore("unused_signal")
signal player_died

@warning_ignore("unused_signal")
signal enemy_died(enemy: Node, position: Vector2)

@warning_ignore("unused_signal")
signal boss_phase_changed(phase: int)

@warning_ignore("unused_signal")
signal coins_changed(amount: int)

@warning_ignore("unused_signal")
signal gems_changed(amount: int)

@warning_ignore("unused_signal")
signal skill_points_changed(amount: int)

@warning_ignore("unused_signal")
signal item_acquired(item: Dictionary)

@warning_ignore("unused_signal")
signal character_upgraded(char_name: String, new_level: int)

@warning_ignore("unused_signal")
signal run_completed(victory: bool, stats: Dictionary)

# Per-run telemetry — emitted from gameplay so RunManager can tally rewards
@warning_ignore("unused_signal")
signal coin_pickup(amount: int)

# Endless mode — XP orb pickup. Endless run scene listens to update level.
@warning_ignore("unused_signal")
signal xp_collected(amount: int)

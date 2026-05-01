class_name ElephantGunSlamTicker
extends AutocastTicker

# Luffy "Elephant Gun Slam" — Legendary, UNIQUE.
# Every 14s, telegraphs (0.7s) on current_target's position, then a
# giant fist slams down for 6x AoE damage in 80px radius. Stuns 1.2s.

const SLAM_SCRIPT: Script = preload("res://scenes/upgrades/components/ElephantGunSlam.gd")

@export var telegraph_seconds: float = 0.7
@export var aoe_radius: float = 80.0
@export var damage_mult: float = 6.0
@export var stun_duration: float = 1.2


func _ready() -> void:
	tick_interval = 14.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var target_pos: Vector2 = Vector2.ZERO
	if p.current_target != null and is_instance_valid(p.current_target):
		target_pos = p.current_target.global_position
	elif p.move_input.length_squared() > 0.05:
		target_pos = p.global_position + p.move_input.normalized() * 80.0
	else:
		return
	_spawn_slam(p, target_pos)


func _spawn_slam(p: Player, pos: Vector2) -> void:
	var slam: Node2D = Node2D.new()
	slam.set_script(SLAM_SCRIPT)
	if slam.has_method("configure"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		slam.call("configure", dmg, aoe_radius, telegraph_seconds, stun_duration)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(slam)
	slam.global_position = pos

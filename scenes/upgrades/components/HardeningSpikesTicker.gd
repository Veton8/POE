class_name HardeningSpikesTicker
extends AutocastTicker

# Eren "Hardening Spikes" — Rare, LINEAR cap 3.
# Every 5s, when an enemy is within proximity, spawns N stationary
# crystal spikes around player at equal angles. Each spike persists
# 3s, deals contact damage on touch.

const SPIKE_SCRIPT: Script = preload("res://scenes/upgrades/components/HardeningSpike.gd")
const MAX_STACKS: int = 3

@export var proximity_radius: float = 50.0
@export var spike_distance: float = 50.0
@export var spike_duration: float = 3.0
@export var damage_mult: float = 1.0
@export var hit_delay: float = 0.4

var stacks: int = 1


func _ready() -> void:
	tick_interval = 5.0
	super._ready()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	if not _enemy_within(p):
		return
	var spike_count: int = 4 * stacks
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	for i: int in spike_count:
		var ang: float = (TAU / float(spike_count)) * float(i)
		var spike: Node2D = Node2D.new()
		spike.set_script(SPIKE_SCRIPT)
		if spike.has_method("configure"):
			spike.call("configure", dmg, spike_duration, hit_delay)
		var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
		host.add_child(spike)
		spike.global_position = p.global_position + Vector2(cos(ang), sin(ang)) * spike_distance
		spike.rotation = ang + PI * 0.5
	Audio.play("ability_burst", -0.5, -4.0)


func _enemy_within(p: Player) -> bool:
	var r2: float = proximity_radius * proximity_radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if (n as Node2D).global_position.distance_squared_to(p.global_position) <= r2:
			return true
	return false

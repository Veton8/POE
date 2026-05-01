class_name RasenshurikenTicker
extends AutocastTicker

# Naruto "Rasenshuriken Finisher" — Legendary, UNIQUE.
# Every 16s, spawns a wind disc traveling 200px in current_target dir.
# On impact OR after 2s travel, expands into a 100px-radius cutting
# field for 1.5s, ticking damage every 0.2s.

const DISC_SCRIPT: Script = preload("res://scenes/upgrades/components/RasenshurikenDisc.gd")

@export var travel_distance: float = 200.0
@export var disc_speed: float = 180.0
@export var travel_damage_mult: float = 1.2
@export var field_radius: float = 100.0
@export var field_duration: float = 1.5
@export var field_tick: float = 0.2
@export var field_damage_mult: float = 0.8


func _ready() -> void:
	tick_interval = 16.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	var disc: Node2D = Node2D.new()
	disc.set_script(DISC_SCRIPT)
	if disc.has_method("configure"):
		var travel_dmg: int = max(1, int(round(float(p.stats.damage) * travel_damage_mult)))
		var field_dmg: int = max(1, int(round(float(p.stats.damage) * field_damage_mult)))
		disc.call("configure", dir, travel_distance, disc_speed, travel_dmg, field_dmg, field_radius, field_duration, field_tick)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(disc)
	disc.global_position = p.muzzle.global_position if p.muzzle != null else p.global_position
	Audio.play("ability_burst", -0.1, 2.0)


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO

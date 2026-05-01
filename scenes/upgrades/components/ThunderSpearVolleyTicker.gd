class_name ThunderSpearVolleyTicker
extends AutocastTicker

# Levi "Thunder Spear Volley" — Rare, LINEAR cap 3 (+1 spear per stack).
# Every 5s, fires N piercing spears that detonate (40px AoE) on hit
# OR end-of-travel.

const SPEAR_SCRIPT: Script = preload("res://scenes/upgrades/components/ThunderSpear.gd")
const MAX_STACKS: int = 3

@export var spear_speed: float = 280.0
@export var travel_distance: float = 200.0
@export var pierce: int = 3
@export var spear_damage_mult: float = 1.0
@export var aoe_damage_mult: float = 2.5
@export var aoe_radius: float = 40.0

var spear_count: int = 1


func _ready() -> void:
	tick_interval = 5.0
	super._ready()


func bump() -> void:
	if spear_count < MAX_STACKS:
		spear_count += 1


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	var spread: float = deg_to_rad(8.0)
	for i: int in spear_count:
		var t: float = 0.0
		if spear_count > 1:
			t = (float(i) - float(spear_count - 1) * 0.5) / (float(spear_count - 1) * 0.5)
		var shot_dir: Vector2 = dir.rotated(t * spread)
		_spawn(p, shot_dir)


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO


func _spawn(p: Player, dir: Vector2) -> void:
	var spear: Node2D = Node2D.new()
	spear.set_script(SPEAR_SCRIPT)
	spear.rotation = dir.angle()
	if spear.has_method("configure"):
		var travel_dmg: int = max(1, int(round(float(p.stats.damage) * spear_damage_mult)))
		var aoe_dmg: int = max(1, int(round(float(p.stats.damage) * aoe_damage_mult)))
		spear.call("configure", dir, spear_speed, travel_distance, pierce, travel_dmg, aoe_dmg, aoe_radius)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(spear)
	spear.global_position = p.muzzle.global_position if p.muzzle != null else p.global_position
	Audio.play("shoot", 0.1, 0.0)

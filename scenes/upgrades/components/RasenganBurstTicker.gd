class_name RasenganBurstTicker
extends AutocastTicker

# Naruto "Rasengan Burst" — Epic, UNIQUE.
# Every 7s, the player (or each shadow clone, if present) generates a
# Rasengan orb that homes the closest enemy and explodes for 40px AoE.

const ORB_SCRIPT: Script = preload("res://scenes/upgrades/components/RasenganOrb.gd")

@export var damage_mult: float = 3.5
@export var aoe_radius: float = 40.0
@export var orb_speed: float = 180.0
@export var search_radius: float = 200.0


func _ready() -> void:
	tick_interval = 7.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var origins: Array[Vector2] = [p.global_position]
	# Synergy: if shadow clones present, fire from their positions too
	for c: Node in p.get_children():
		if c.name.begins_with("ShadowClone") and c is Node2D:
			origins.append((c as Node2D).global_position)
	var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
	for origin: Vector2 in origins:
		var target: Node2D = _nearest_enemy(origin)
		if target == null:
			continue
		_spawn_orb(p, origin, target, dmg)


func _nearest_enemy(from: Vector2) -> Node2D:
	var best: Node2D = null
	var best_d: float = search_radius * search_radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		var d: float = (n as Node2D).global_position.distance_squared_to(from)
		if d < best_d:
			best_d = d
			best = n as Node2D
	return best


func _spawn_orb(p: Player, origin: Vector2, target: Node2D, dmg: int) -> void:
	var orb: Node2D = Node2D.new()
	orb.set_script(ORB_SCRIPT)
	if orb.has_method("configure"):
		orb.call("configure", target, dmg, aoe_radius, orb_speed)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(orb)
	orb.global_position = origin
	Audio.play("ability_burst", 0.2, -2.0)

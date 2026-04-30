class_name DrownedCurator
extends Boss

# Final Sunken boss. Spawns 4 BreakablePillars at room SpawnPoints B-E on
# entry; the boss is invulnerable while any pillar remains alive. Player
# must destroy all pillars to enter the damage phase. P2 (50% HP) opens
# SUMMON pattern — Drowner adds spawn from the boss.

const PILLAR_SCENE: PackedScene = preload("res://scenes/hazards/BreakablePillar.tscn")

var locked_hurtbox: PillarLockedHurtbox = null
var _pillars_initialized: bool = false


func _ready() -> void:
	super._ready()
	locked_hurtbox = $Hurtbox as PillarLockedHurtbox


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _pillars_initialized:
		_spawn_initial_pillars()
		_pillars_initialized = true
	if locked_hurtbox == null:
		return
	var pillars_alive: int = get_tree().get_nodes_in_group("breakable_pillars").size()
	locked_hurtbox.vulnerable = pillars_alive == 0
	if pillars_alive > 0:
		sprite.modulate = Color(0.55, 0.55, 0.85, 1)
	elif phase == 1:
		sprite.modulate = Color.WHITE


func _spawn_initial_pillars() -> void:
	var room: Node = get_parent()
	if room == null:
		return
	var sp_node: Node = room.get_node_or_null("SpawnPoints")
	if sp_node == null:
		return
	var children: Array = sp_node.get_children()
	for i in range(1, children.size()):
		var sp: Node2D = children[i] as Node2D
		if sp == null:
			continue
		var p: Node2D = PILLAR_SCENE.instantiate() as Node2D
		if p == null:
			continue
		room.add_child(p)
		p.global_position = sp.global_position


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var options: Array = [Pattern.PROJECTILE_FAN, Pattern.CHARGE]
	if phase == 2:
		options.append(Pattern.SUMMON)
	var pick: int = options.pick_random()
	match pick:
		Pattern.PROJECTILE_FAN: _projectile_fan()
		Pattern.CHARGE: _charge()
		Pattern.SUMMON: _summon()

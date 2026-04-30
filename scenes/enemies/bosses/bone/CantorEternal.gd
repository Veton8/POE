class_name CantorEternal
extends Boss

# Final Bone Choir boss. Spawns 3 HealingTotems at room SpawnPoints B-D on
# entry; while any totem is alive the boss self-heals 1 HP per living totem
# every `heal_interval` seconds. Boss is never invulnerable — it's just a
# damage race. Phase 2 (50% HP) opens CHARGE in addition to FAN + SUMMON.

const HEALING_TOTEM_SCENE: PackedScene = preload("res://scenes/hazards/HealingTotem.tscn")

@export var heal_interval: float = 1.5

var _totems_initialized: bool = false
var _heal_t: float = 0.0


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not _totems_initialized:
		_spawn_totems()
		_totems_initialized = true
	_heal_t += delta
	if _heal_t < heal_interval:
		return
	_heal_t = 0.0
	if health == null or health.current >= health.max_hp:
		return
	var totems_alive: int = get_tree().get_nodes_in_group("healing_totems").size()
	if totems_alive <= 0:
		return
	health.heal(totems_alive)
	sprite.modulate = Color(0.7, 1.5, 0.7, 1)
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.4)


func _spawn_totems() -> void:
	var room: Node = get_parent()
	if room == null:
		return
	var sp_node: Node = room.get_node_or_null("SpawnPoints")
	if sp_node == null:
		return
	var children: Array = sp_node.get_children()
	var max_totems: int = min(3, children.size() - 1)
	for i in range(1, max_totems + 1):
		var sp: Node2D = children[i] as Node2D
		if sp == null:
			continue
		var t: Node2D = HEALING_TOTEM_SCENE.instantiate() as Node2D
		if t == null:
			continue
		room.add_child(t)
		t.global_position = sp.global_position


func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var options: Array = [Pattern.PROJECTILE_FAN, Pattern.SUMMON]
	if phase == 2:
		options.append(Pattern.CHARGE)
	var pick: int = options.pick_random()
	match pick:
		Pattern.PROJECTILE_FAN: _projectile_fan()
		Pattern.SUMMON: _summon()
		Pattern.CHARGE: _charge()

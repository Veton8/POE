class_name NameInscribedListener
extends Node

# Light "Name Inscribed" autocast variant.
# Each time Player.bullet_hit fires, roll chance_per_stack × stacks to
# apply the "inscribed" mark via MarkRegistry. Mark detonates after
# detonation_delay for damage_mult × cached stats.damage. If the
# marked enemy dies first, mark transfers to nearest unmarked enemy
# within transfer_radius (Vixen's-Entrapment style).
#
# bump() is called by UpgradeManager._attach_name_inscribed when the
# card is picked again (LINEAR cap 5).

const MAX_STACKS: int = 5
const MARK_ID: StringName = &"inscribed"

@export var chance_per_stack: float = 0.08
@export var detonation_delay: float = 1.5
@export var damage_mult: float = 2.0
@export var transfer_radius: float = 60.0

var _player: Player = null
var stacks: int = 1

# Pending detonations: { iid: int (enemy instance id), enemy_ref: Node,
#                        damage: int, expires_msec: int, glyph: Node2D }
var _pending: Array[Dictionary] = []


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect_signals()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _ready() -> void:
	if _player == null:
		_resolve_player()
	_connect_signals()


func _resolve_player() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _connect_signals() -> void:
	if _player != null and not _player.bullet_hit.is_connected(_on_bullet_hit):
		_player.bullet_hit.connect(_on_bullet_hit)
	if not Events.enemy_died.is_connected(_on_enemy_died):
		Events.enemy_died.connect(_on_enemy_died)


func _on_bullet_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target) or _player == null:
		return
	var roll_chance: float = chance_per_stack * float(stacks)
	if randf() >= roll_chance:
		return
	if MarkRegistry.has_mark(target, MARK_ID):
		return
	_apply_mark(target, _player.stats.damage)


func _apply_mark(enemy: Node, trigger_damage: int) -> void:
	MarkRegistry.apply_mark(enemy, MARK_ID, detonation_delay, self)
	var glyph: Node2D = _spawn_glyph(enemy)
	_pending.append({
		"iid": enemy.get_instance_id(),
		"enemy_ref": enemy,
		"damage": int(round(float(trigger_damage) * damage_mult)),
		"expires_msec": Time.get_ticks_msec() + int(detonation_delay * 1000.0),
		"glyph": glyph,
	})
	Audio.play("ability_burst", 0.5, -10.0)


func _spawn_glyph(enemy: Node) -> Node2D:
	if not (enemy is Node2D):
		return null
	var glyph: Node2D = Node2D.new()
	glyph.set_script(preload("res://scenes/upgrades/components/InscribedGlyph.gd"))
	glyph.position = Vector2(0, -16)
	(enemy as Node2D).add_child(glyph)
	return glyph


func _process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var still_pending: Array[Dictionary] = []
	for entry: Dictionary in _pending:
		var enemy: Node = entry["enemy_ref"] as Node
		if not is_instance_valid(enemy):
			continue  # mark transferred or enemy gone
		if int(entry["expires_msec"]) <= now:
			_detonate(entry)
			continue
		still_pending.append(entry)
	_pending = still_pending


func _detonate(entry: Dictionary) -> void:
	var enemy: Node = entry["enemy_ref"] as Node
	if enemy == null or not is_instance_valid(enemy):
		return
	var dmg: int = int(entry["damage"])
	var hb: Node = enemy.get_node_or_null("HurtboxComponent")
	if hb is HurtboxComponent and enemy is Node2D:
		(hb as HurtboxComponent).receive_hit(dmg, self, (enemy as Node2D).global_position)
	MarkRegistry.clear_mark(enemy, MARK_ID)
	var glyph: Variant = entry.get("glyph", null)
	if glyph is Node2D and is_instance_valid(glyph):
		(glyph as Node2D).queue_free()
	if enemy is Node2D:
		VFX.spawn_hit_particles((enemy as Node2D).global_position, Vector2.ZERO)
	Audio.play("ability_burst", -0.4, 0.0)


func _on_enemy_died(enemy: Node, pos: Vector2) -> void:
	if enemy == null:
		return
	var iid: int = enemy.get_instance_id()
	var inherited: Array[Dictionary] = []
	var still_pending: Array[Dictionary] = []
	for entry: Dictionary in _pending:
		if int(entry["iid"]) == iid:
			inherited.append(entry)
		else:
			still_pending.append(entry)
	_pending = still_pending
	for entry: Dictionary in inherited:
		_try_transfer(entry, pos)


func _try_transfer(entry: Dictionary, dead_pos: Vector2) -> void:
	# Find nearest unmarked enemy within transfer_radius
	var best: Node = null
	var best_d: float = transfer_radius * transfer_radius
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(n) or not (n is Node2D):
			continue
		if MarkRegistry.has_mark(n, MARK_ID):
			continue
		var d: float = dead_pos.distance_squared_to((n as Node2D).global_position)
		if d < best_d:
			best_d = d
			best = n
	# Drop the old glyph regardless
	var old_glyph: Variant = entry.get("glyph", null)
	if old_glyph is Node2D and is_instance_valid(old_glyph):
		(old_glyph as Node2D).queue_free()
	if best == null:
		return
	# Re-apply mark on the new target with the same damage
	MarkRegistry.apply_mark(best, MARK_ID, detonation_delay, self)
	var glyph: Node2D = _spawn_glyph(best)
	_pending.append({
		"iid": best.get_instance_id(),
		"enemy_ref": best,
		"damage": int(entry["damage"]),
		"expires_msec": Time.get_ticks_msec() + int(detonation_delay * 1000.0),
		"glyph": glyph,
	})

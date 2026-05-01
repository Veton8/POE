class_name NichirinFocusListener
extends Node

# Tanjiro "Nichirin Focus" — Rare, LINEAR cap 4.
# Tracks per-enemy hit counter. Every Nth hit on the same enemy deals
# +250% bonus damage and applies bleed (3s, 0.3 × stats.damage/s).
# N starts at 4 and reduces by 1 per stack (4→3→2→1).

const BURN_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")
const MAX_STACKS: int = 4
const RESET_AFTER_SECONDS: float = 5.0

@export var bonus_damage_mult: float = 2.5
@export var bleed_dps_mult: float = 0.3
@export var bleed_duration: float = 3.0

var stacks: int = 1
var _player: Player = null
# iid -> { count: int, last_hit_msec: int }
var _per_enemy: Dictionary = {}


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player
	_connect()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _ready() -> void:
	if _player == null:
		_resolve()
	_connect()


func _resolve() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _connect() -> void:
	if _player != null and not _player.bullet_hit.is_connected(_on_bullet_hit):
		_player.bullet_hit.connect(_on_bullet_hit)


func _threshold() -> int:
	return maxi(1, 5 - stacks)


func _on_bullet_hit(target: Node) -> void:
	if target == null or not is_instance_valid(target) or _player == null:
		return
	var iid: int = target.get_instance_id()
	var now: int = Time.get_ticks_msec()
	var entry: Dictionary = _per_enemy.get(iid, {"count": 0, "last_hit_msec": 0})
	# Reset if too long since last hit
	if now - int(entry.get("last_hit_msec", 0)) > int(RESET_AFTER_SECONDS * 1000.0):
		entry["count"] = 0
	entry["count"] = int(entry.get("count", 0)) + 1
	entry["last_hit_msec"] = now
	_per_enemy[iid] = entry
	if int(entry["count"]) < _threshold():
		return
	# Trigger
	entry["count"] = 0
	_per_enemy[iid] = entry
	var bonus: int = max(1, int(round(float(_player.stats.damage) * bonus_damage_mult)))
	var hb: Node = target.get_node_or_null("HurtboxComponent")
	if hb is HurtboxComponent and target is Node2D:
		(hb as HurtboxComponent).receive_hit(bonus, self, (target as Node2D).global_position)
	# Apply bleed
	var existing: Node = target.get_node_or_null("BurnComponent")
	var dps: float = float(_player.stats.damage) * bleed_dps_mult
	if existing is BurnComponent:
		(existing as BurnComponent).refresh(dps, bleed_duration)
	else:
		var burn: BurnComponent = BurnComponent.new()
		burn.name = "BurnComponent"
		burn.set_script(BURN_COMPONENT_SCRIPT)
		burn.damage_per_second = dps
		burn.duration = bleed_duration
		target.add_child(burn)
	Audio.play("shoot", 0.3, 2.0)

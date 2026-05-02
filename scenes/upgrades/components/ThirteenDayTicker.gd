class_name ThirteenDayTicker
extends AutocastTicker

# Light "Thirteen Day Curse" — Epic, UNIQUE.
# Every 13s, marks the 3 lowest-HP visible enemies. After 3s, marked
# non-bosses are reduced to 1 HP (effectively executed). Bosses
# instead take 6 × stats.damage.

const MARK_ID: StringName = &"thirteen_day"
const VIEWPORT_HALF_W: float = 180.0
const VIEWPORT_HALF_H: float = 320.0

@export var sentence_delay: float = 3.0
@export var boss_damage_mult: float = 6.0

# pending: { iid: int, enemy_ref: Node, expires_msec: int, glyph: Node2D, is_boss: bool, boss_dmg: int }
var _pending: Array[Dictionary] = []


func _ready() -> void:
	tick_interval = 13.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var visible: Array[Node2D] = _visible_enemies(p)
	if visible.is_empty():
		return
	# Sort by current HP (lowest first), pick 3
	visible.sort_custom(_compare_hp)
	var take: int = mini(3, visible.size())
	var boss_dmg: int = max(1, int(round(float(p.stats.damage) * boss_damage_mult)))
	for i: int in take:
		var e: Node2D = visible[i]
		var is_boss: bool = e.is_in_group("boss")
		MarkRegistry.apply_mark(e, MARK_ID, sentence_delay, self)
		var glyph: Node2D = _spawn_glyph(e)
		_pending.append({
			"iid": e.get_instance_id(),
			"enemy_ref": e,
			"expires_msec": Time.get_ticks_msec() + int(sentence_delay * 1000.0),
			"glyph": glyph,
			"is_boss": is_boss,
			"boss_dmg": boss_dmg,
		})
	Audio.play("ability_burst", -0.2, -4.0)


func _process(_delta: float) -> void:
	if _pending.is_empty():
		return
	var now: int = Time.get_ticks_msec()
	var still: Array[Dictionary] = []
	for entry: Dictionary in _pending:
		if int(entry["expires_msec"]) <= now:
			_execute(entry)
			continue
		still.append(entry)
	_pending = still


func _execute(entry: Dictionary) -> void:
	var enemy: Node = entry["enemy_ref"] as Node
	if enemy == null or not is_instance_valid(enemy):
		return
	var glyph: Variant = entry.get("glyph", null)
	if glyph is Node2D and is_instance_valid(glyph):
		(glyph as Node2D).queue_free()
	var hp: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
	if hp == null:
		return
	if bool(entry["is_boss"]):
		hp.take_damage(int(entry["boss_dmg"]), self)
	else:
		hp.take_damage(99999, self)
	MarkRegistry.clear_mark(enemy, MARK_ID)
	if enemy is Node2D:
		Audio.play("enemy_died", 0.2, 2.0)


func _visible_enemies(p: Player) -> Array[Node2D]:
	var out: Array[Node2D] = []
	var center: Vector2 = p.global_position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		if MarkRegistry.has_mark(n, MARK_ID):
			continue
		var n2d: Node2D = n as Node2D
		var d: Vector2 = n2d.global_position - center
		if absf(d.x) > VIEWPORT_HALF_W or absf(d.y) > VIEWPORT_HALF_H:
			continue
		out.append(n2d)
	return out


func _compare_hp(a: Node2D, b: Node2D) -> bool:
	var ha: HealthComponent = a.get_node_or_null("HealthComponent") as HealthComponent
	var hb: HealthComponent = b.get_node_or_null("HealthComponent") as HealthComponent
	var av: int = ha.current if ha != null else 9999
	var bv: int = hb.current if hb != null else 9999
	return av < bv


func _spawn_glyph(enemy: Node2D) -> Node2D:
	var glyph: Node2D = Node2D.new()
	glyph.set_script(preload("res://scenes/upgrades/components/InscribedGlyph.gd"))
	glyph.position = Vector2(0, -16)
	enemy.add_child(glyph)
	return glyph

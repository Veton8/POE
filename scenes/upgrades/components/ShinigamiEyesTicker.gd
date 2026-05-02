class_name ShinigamiEyesTicker
extends AutocastTicker

# Light "Shinigami Eyes" — Rare, HYPERBOLIC cap 25%.
# Every 1s, each visible enemy has a chance to be marked with
# "visible_doom" for 4s. Marked enemies take an extra DoT tick
# (proxy for "+30% damage from all sources").

const MAX_STACKS: int = 6
const MARK_ID: StringName = &"visible_doom"
const VIEWPORT_HALF_W: float = 180.0
const VIEWPORT_HALF_H: float = 320.0

@export var mark_duration: float = 4.0
@export var bonus_dot_per_tick: float = 0.30  # × stats.damage every tick_dot

var stacks: int = 1


func _ready() -> void:
	tick_interval = 1.0
	super._ready()
	# Inherited _player is populated by AutocastTicker._resolve_player()
	# during super._ready(); no further setup needed.


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _hyperbolic_chance() -> float:
	return minf(0.25, 1.0 - 1.0 / (1.0 + 0.20 * float(stacks)))


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var chance: float = _hyperbolic_chance()
	var bonus: int = max(1, int(round(float(p.stats.damage) * bonus_dot_per_tick)))
	var pos: Vector2 = p.global_position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		var n2d: Node2D = n as Node2D
		var d: Vector2 = n2d.global_position - pos
		if absf(d.x) > VIEWPORT_HALF_W or absf(d.y) > VIEWPORT_HALF_H:
			continue
		# Already marked enemies get DoT tick this second
		if MarkRegistry.has_mark(n, MARK_ID):
			var hb_existing: Node = n.get_node_or_null("HurtboxComponent")
			if hb_existing is HurtboxComponent:
				(hb_existing as HurtboxComponent).receive_hit(bonus, self, n2d.global_position)
			continue
		if randf() >= chance:
			continue
		MarkRegistry.apply_mark(n, MARK_ID, mark_duration, self)

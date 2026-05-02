class_name SixEyesTicker
extends AutocastTicker

# Gojo "Six Eyes" — Rare, LINEAR cap 3.
# Crit chance bonus is provided via stat_modifiers in the .tres
# (handled by UpgradeManager declaratively). This ticker does the
# secondary effect: every 6s, mark all visible enemies with vulnerable
# (DoT proxy — applies a small damage tick over 3s as a stand-in for
# the design-doc "+25% damage taken" until HurtboxComponent supports
# vulnerability multipliers).

const MARK_ID: StringName = &"six_eyes_vulnerable"
const VIEWPORT_HALF_W: float = 180.0
const VIEWPORT_HALF_H: float = 320.0

@export var mark_duration: float = 3.0
@export var bonus_damage_mult: float = 0.25


func _ready() -> void:
	tick_interval = 6.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var bonus: int = max(1, int(round(float(p.stats.damage) * bonus_damage_mult)))
	var center: Vector2 = p.global_position
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		if not (n is Node2D):
			continue
		var n2d: Node2D = n as Node2D
		var d: Vector2 = n2d.global_position - center
		if absf(d.x) > VIEWPORT_HALF_W or absf(d.y) > VIEWPORT_HALF_H:
			continue
		MarkRegistry.apply_mark(n, MARK_ID, mark_duration, self)
		var hb: Node = n.get_node_or_null("HurtboxComponent")
		if hb is HurtboxComponent:
			(hb as HurtboxComponent).receive_hit(bonus, self, n2d.global_position)
	Audio.play("ability_burst", 0.5, -12.0)

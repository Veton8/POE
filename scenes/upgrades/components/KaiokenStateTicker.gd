class_name KaiokenStateTicker
extends AutocastTicker

# Goku "Kaio-ken Overdrive" — Rare, LINEAR cap 5.
# Every 15s, enters Kaio-ken state for 4s + (1s × stacks_above_1):
# +25% stats.damage and +15% fire_rate per base, plus +10%/+5%/+1s
# per additional stack. Vulnerable +10% damage taken during state.

const MAX_STACKS: int = 5
const MOD_ID: StringName = &"kaioken_state"

@export var base_duration: float = 4.0
@export var damage_bonus_per_stack: float = 0.10
@export var firerate_bonus_per_stack: float = 0.05

var stacks: int = 1
var _active: bool = false


func _ready() -> void:
	tick_interval = 15.0
	super._ready()


func bump() -> void:
	if stacks < MAX_STACKS:
		stacks += 1


func _do_cast() -> void:
	if _active:
		return
	var p: Player = get_player_cached()
	if p == null:
		return
	_active = true
	var dmg_bonus: float = 0.25 + damage_bonus_per_stack * float(stacks - 1)
	var fr_bonus: float = 0.15 + firerate_bonus_per_stack * float(stacks - 1)
	var duration: float = base_duration + float(stacks - 1)

	var prev_damage: int = p.stats.damage
	var prev_fire_rate: float = p.stats.fire_rate
	p.stats.damage = int(round(float(prev_damage) * (1.0 + dmg_bonus)))
	p.stats.fire_rate = prev_fire_rate * (1.0 + fr_bonus)
	if p.fire_timer != null:
		p.fire_timer.wait_time = 1.0 / p.stats.fire_rate

	# Visual aura — red sprite tint
	var orig: Color = p.sprite.modulate if p.sprite != null else Color.WHITE
	if p.sprite != null:
		p.sprite.modulate = Color(1.6, 0.4, 0.4)
	Audio.play("ability_burst", 0.1, 0.0)

	await get_tree().create_timer(duration).timeout

	_active = false
	if not is_instance_valid(p):
		return
	p.stats.damage = prev_damage
	p.stats.fire_rate = prev_fire_rate
	if p.fire_timer != null:
		p.fire_timer.wait_time = 1.0 / p.stats.fire_rate
	if p.sprite != null:
		p.sprite.modulate = orig

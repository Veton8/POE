class_name SeriousPunchTicker
extends AutocastTicker

# Saitama "Serious Punch" — Legendary, UNIQUE.
# Every 18s, charge 1.0s then horizontal shockwave: 240×60 rectangle.
# Anything below 40% HP is INSTAKILLED. Above-40% take 8x. Bosses take
# 12x (no instakill).

const SHOCKWAVE_SCRIPT: Script = preload("res://scenes/upgrades/components/SeriousPunchShockwave.gd")
const EXECUTE_THRESHOLD: float = 0.40
const EXECUTE_OVERKILL: int = 99999

@export var charge_seconds: float = 1.0
@export var rect_length: float = 240.0
@export var rect_width: float = 60.0
@export var damage_mult: float = 8.0
@export var boss_damage_mult: float = 12.0


func _ready() -> void:
	tick_interval = 18.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = p.move_input.normalized() if p.move_input.length_squared() > 0.05 else Vector2.RIGHT
	# Charge tell — sprite winds back
	if p.sprite != null:
		var orig: Color = p.sprite.modulate
		var tw: Tween = create_tween()
		tw.tween_property(p.sprite, "modulate", Color(1.6, 1.4, 0.8), charge_seconds)
		tw.tween_callback(func() -> void:
			if is_instance_valid(p) and p.sprite != null:
				p.sprite.modulate = orig
		)
	await get_tree().create_timer(charge_seconds).timeout
	if not is_instance_valid(p):
		return
	_unleash(p, dir)


func _unleash(p: Player, dir: Vector2) -> void:
	var shockwave: Node2D = Node2D.new()
	shockwave.set_script(SHOCKWAVE_SCRIPT)
	shockwave.rotation = dir.angle()
	if shockwave.has_method("configure"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		var boss_dmg: int = max(1, int(round(float(p.stats.damage) * boss_damage_mult)))
		shockwave.call("configure", dmg, boss_dmg, rect_length, rect_width, EXECUTE_THRESHOLD, EXECUTE_OVERKILL)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(shockwave)
	shockwave.global_position = p.global_position
	Audio.play("ability_burst", -0.8, 8.0)
	Events.screen_shake.emit(12.0, 0.6)

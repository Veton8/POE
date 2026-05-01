class_name KamehamehaLanceTicker
extends AutocastTicker

# Goku "Kamehameha" autocast variant.
# Every cooldown_seconds: charge for charge_seconds (player tints cyan
# as a tell), then fire a piercing beam toward Player.current_target
# (or move_input fallback). Beam ticks damage every beam_tick_interval
# for beam_duration. Fall-through behavior on no-target = skip and
# retry next tick (Q4 answer).

const BEAM_SCRIPT: Script = preload("res://scenes/upgrades/components/KamehamehaBeam.gd")

@export var cooldown_seconds: float = 8.0
@export var charge_seconds: float = 0.6
@export var beam_duration: float = 0.5
@export var beam_length: float = 320.0
@export var beam_width: float = 16.0
@export var beam_tick_interval: float = 0.1
@export var damage_mult: float = 1.8

var _charging: bool = false


func _ready() -> void:
	tick_interval = cooldown_seconds
	autostart = true
	super._ready()


func _do_cast() -> void:
	if _charging:
		return
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _resolve_aim(p)
	if dir == Vector2.ZERO:
		return  # no-target = skip & retry next cycle
	_charging = true
	_play_charge_tell(p)
	await get_tree().create_timer(charge_seconds).timeout
	_charging = false
	if not is_instance_valid(p):
		return
	_fire_beam(p, _resolve_aim(p))


func _resolve_aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO


func _play_charge_tell(p: Player) -> void:
	if p.sprite == null:
		return
	var orig: Color = p.sprite.modulate
	var tw: Tween = create_tween()
	tw.tween_property(p.sprite, "modulate", Color(0.7, 1.4, 1.8), charge_seconds * 0.5)
	tw.tween_property(p.sprite, "modulate", orig, charge_seconds * 0.5)


func _fire_beam(p: Player, dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var beam: Node2D = Node2D.new()
	beam.set_script(BEAM_SCRIPT)
	beam.rotation = dir.angle()
	if beam.has_method("configure"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		beam.call("configure", dmg, beam_length, beam_width, beam_duration, beam_tick_interval)
	# Parent to the player's parent (World node in endless / dungeon scene
	# in dungeon mode) so the SubViewport camera transform applies. Setting
	# global_position AFTER add_child so the parent's transform is applied
	# correctly.
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(beam)
	beam.global_position = p.muzzle.global_position if p.muzzle != null else p.global_position
	Audio.play("ability_burst", -0.2, 3.0)
	Events.screen_shake.emit(3.0, 0.15)

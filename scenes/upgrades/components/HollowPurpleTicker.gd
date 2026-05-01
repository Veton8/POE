class_name HollowPurpleTicker
extends AutocastTicker

# Gojo "Hollow Purple" autocast — Legendary, UNIQUE.
# Every cooldown_seconds: brief charge tell, then a wide purple beam
# in current_target direction. 240px, 12px wide, infinite pierce.

const BEAM_SCRIPT: Script = preload("res://scenes/upgrades/components/HollowPurpleBeam.gd")

@export var cooldown_seconds: float = 12.0
@export var charge_seconds: float = 0.5
@export var beam_duration: float = 0.35
@export var beam_length: float = 240.0
@export var beam_width: float = 12.0
@export var damage_mult: float = 4.5

var _charging: bool = false


func _ready() -> void:
	tick_interval = cooldown_seconds
	super._ready()


func _do_cast() -> void:
	if _charging:
		return
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = _aim(p)
	if dir == Vector2.ZERO:
		return
	_charging = true
	var orig: Color = p.sprite.modulate if p.sprite != null else Color.WHITE
	if p.sprite != null:
		p.sprite.modulate = Color(1.4, 0.4, 1.6)
	await get_tree().create_timer(charge_seconds).timeout
	if p.sprite != null and is_instance_valid(p):
		p.sprite.modulate = orig
	_charging = false
	if not is_instance_valid(p):
		return
	_fire(p, _aim(p))


func _aim(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length_squared() > 0.05:
		return p.move_input.normalized()
	return Vector2.ZERO


func _fire(p: Player, dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var beam: Node2D = Node2D.new()
	beam.set_script(BEAM_SCRIPT)
	beam.rotation = dir.angle()
	if beam.has_method("configure"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
		beam.call("configure", dmg, beam_length, beam_width, beam_duration)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(beam)
	beam.global_position = p.muzzle.global_position if p.muzzle != null else p.global_position
	Audio.play("ability_burst", -0.4, 4.0)
	Events.screen_shake.emit(6.0, 0.25)

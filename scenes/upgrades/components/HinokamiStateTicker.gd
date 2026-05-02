class_name HinokamiStateTicker
extends AutocastTicker

# Tanjiro "Hinokami Pulse" — Epic, UNIQUE.
# Every 11s, enters Hinokami stance for 3s: queues a -40% CD modifier
# on all autocasts (via AutocastModifierRegistry). Slashes during
# state ignite enemies (handled here as a 1.5s burn DoT applied to
# any enemy hit by Player.bullet_hit during the window).

const MOD_ID: StringName = &"hinokami_state"
const BURN_COMPONENT_SCRIPT: Script = preload("res://scenes/components/BurnComponent.gd")

@export var state_duration: float = 3.0
@export var cd_multiplier: float = 0.6
@export var burn_dps_mult: float = 0.4
@export var burn_duration: float = 1.5

var _state_active: bool = false


func _ready() -> void:
	tick_interval = 11.0
	super._ready()
	# Inherited _player is populated by AutocastTicker._resolve_player()
	# during super._ready(); connect the bullet_hit listener once.
	if _player != null and not _player.bullet_hit.is_connected(_on_bullet_hit):
		_player.bullet_hit.connect(_on_bullet_hit)


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	if _state_active:
		return
	_state_active = true
	AutocastModifierRegistry.add_cd_modifier(MOD_ID, cd_multiplier, state_duration)
	var orig: Color = p.sprite.modulate if p.sprite != null else Color.WHITE
	if p.sprite != null:
		p.sprite.modulate = Color(1.5, 0.55, 0.30)
	Audio.play("ability_burst", -0.2, 1.0)
	await get_tree().create_timer(state_duration).timeout
	_state_active = false
	if is_instance_valid(p) and p.sprite != null:
		p.sprite.modulate = orig
	AutocastModifierRegistry.remove_cd_modifier(MOD_ID)


func _on_bullet_hit(target: Node) -> void:
	if not _state_active or _player == null or target == null:
		return
	if not is_instance_valid(target):
		return
	# Apply burn via BurnComponent
	var existing: Node = target.get_node_or_null("BurnComponent")
	var dps: float = float(_player.stats.damage) * burn_dps_mult
	if existing != null and existing is BurnComponent:
		(existing as BurnComponent).refresh(dps, burn_duration)
	else:
		var burn: BurnComponent = BurnComponent.new()
		burn.name = "BurnComponent"
		burn.set_script(BURN_COMPONENT_SCRIPT)
		burn.damage_per_second = dps
		burn.duration = burn_duration
		target.add_child(burn)

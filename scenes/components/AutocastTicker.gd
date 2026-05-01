class_name AutocastTicker
extends Node

# Base for upgrade-card autocasts. Owns a Timer; calls _do_cast() on
# every tick. Subclasses override _do_cast() with the card's effect.
# Interval is recomputed each cycle so AutocastModifierRegistry CD
# scaling applies (next cycle picks up the new cooldown).

@export var tick_interval: float = 1.0
@export var autostart: bool = true

var _player: Player
var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.wait_time = effective_interval()
	add_child(_timer)
	_timer.timeout.connect(_on_timer_tick)
	if autostart:
		_timer.start()
	if _player == null:
		_resolve_player()


func attach_to(host: Node) -> void:
	if host is Player:
		_player = host as Player


func effective_interval() -> float:
	var base: float = maxf(0.05, tick_interval)
	if has_node("/root/AutocastModifierRegistry"):
		var reg: Node = get_node("/root/AutocastModifierRegistry")
		if reg.has_method("get_cd_multiplier"):
			base *= float(reg.call("get_cd_multiplier"))
	return maxf(0.05, base)


func get_player_cached() -> Player:
	if _player == null or not is_instance_valid(_player):
		_resolve_player()
	return _player


func _resolve_player() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _on_timer_tick() -> void:
	_timer.wait_time = effective_interval()
	if get_player_cached() == null:
		return
	_do_cast()


# Subclass hook — override with the card's effect.
func _do_cast() -> void:
	pass

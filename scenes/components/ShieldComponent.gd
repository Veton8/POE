class_name ShieldComponent
extends Node2D

# A regenerating hit-absorber. While `current_hp > 0`, intercepts player
# damage by hooking the player's HealthComponent.damaged signal — note
# this REDUCES rather than replaces damage, so the player still takes the
# real hit if shield runs out mid-blow. We can't undo a damage event
# already applied, so the cleaner approach is intercept-via-recipe:
# subscribe to `damaged`, then heal back any portion the shield could
# have soaked. After `regen_delay` of no hits, regen 1 hp every tick.

@export var max_hp: int = 1
@export var regen_delay: float = 4.0
@export var regen_interval: float = 2.5

var current_hp: int = 0
var _player: Player = null
var _health: HealthComponent = null
var _last_hit_time: float = -INF
var _regen_t: float = 0.0

var _ring: _ShieldRing = null


func _ready() -> void:
	current_hp = max_hp
	_player = get_parent() as Player
	if _player != null:
		_health = _player.health
		if _health != null:
			_health.damaged.connect(_on_player_damaged)
	_ring = _ShieldRing.new()
	add_child(_ring)
	_ring.refresh(current_hp, max_hp)


func attach_to(host: Node) -> void:
	_player = host as Player
	if _player != null:
		_health = _player.health


func _on_player_damaged(amount: int, _source: Node) -> void:
	if amount <= 0 or current_hp <= 0:
		return
	var soaked: int = mini(current_hp, amount)
	current_hp -= soaked
	# Heal back the soaked portion — net effect: shield ate `soaked` damage.
	if _health != null and not _health.is_dead():
		_health.heal(soaked)
	_last_hit_time = Time.get_ticks_msec() / 1000.0
	if _ring != null:
		_ring.refresh(current_hp, max_hp)


func _process(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		queue_free()
		return
	if current_hp >= max_hp:
		return
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_hit_time < regen_delay:
		return
	_regen_t += delta
	if _regen_t >= regen_interval:
		_regen_t = 0.0
		current_hp = mini(max_hp, current_hp + 1)
		if _ring != null:
			_ring.refresh(current_hp, max_hp)


class _ShieldRing extends Node2D:
	var hp: int = 0
	var max_hp: int = 1
	func refresh(c: int, m: int) -> void:
		hp = c
		max_hp = m
		queue_redraw()
	func _draw() -> void:
		if hp <= 0 or max_hp <= 0:
			return
		var ratio: float = float(hp) / float(max_hp)
		var col: Color = Color(0.4, 0.8, 1.0, 0.5 + ratio * 0.3)
		draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 24, col, 1.5)

class_name CharacterAbilityAutocastWrapper
extends Node

# Endless-mode wrapper for a character's signature Ability (Q/W/E).
# Polls each physics frame; when the Ability's target_strategy permits
# firing AND its internal cooldown has elapsed, calls try_activate().
# Ability.try_activate() is no-op while on cooldown so this is cheap.
#
# In dungeon mode, abilities are HUD-driven via input — this wrapper
# is NOT installed, the Ability nodes work as before.

var _ability: Ability
var _player: Player


func bind(ability: Ability) -> void:
	_ability = ability
	_resolve_player()


func _ready() -> void:
	_resolve_player()


func _resolve_player() -> void:
	var p: Node = get_parent()
	while p != null and not (p is Player):
		p = p.get_parent()
	if p is Player:
		_player = p as Player


func _physics_process(_delta: float) -> void:
	if _ability == null or _player == null:
		return
	if not is_instance_valid(_ability) or not is_instance_valid(_player):
		return
	if not _can_fire_now():
		return
	_ability.try_activate()


func _can_fire_now() -> bool:
	match _ability.target_strategy:
		Ability.TargetStrategy.NEAREST_ENEMY:
			return _player.current_target != null and is_instance_valid(_player.current_target)
		Ability.TargetStrategy.MOVE_INPUT_DIR:
			return _player.move_input.length_squared() > 0.05
		Ability.TargetStrategy.SELF_AOE:
			return true
	return false

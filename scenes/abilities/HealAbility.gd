class_name HealAbility
extends Ability

@export var heal_amount: int = 1

func _ready() -> void:
	super._ready()
	ability_name = "Heal"
	cooldown_seconds = 12.0
	target_strategy = TargetStrategy.SELF_AOE

func _can_activate() -> bool:
	var p: Player = get_player()
	return p != null and p.health.current < p.health.max_hp

func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_heal", 0.05, 0.0)
	p.health.heal(heal_amount)
	VFX.spawn_damage_number(p.global_position + Vector2(0, -8), heal_amount, false, Color(0.4, 1.0, 0.5))

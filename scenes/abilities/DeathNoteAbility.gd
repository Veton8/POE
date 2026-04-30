class_name DeathNoteAbility
extends Ability

# Light W. Targets Light's currently-locked enemy, freezes its physics for
# `stun_duration` seconds while a "marked" tint is applied, then deals
# fixed `death_damage` (canonical 40s heart-attack rule, scaled to action
# pacing). Bypasses normal projectile shields. Cannot fire without a target.

@export var stun_duration: float = 4.0
@export var death_damage: int = 12


func _ready() -> void:
	super._ready()
	ability_name = "Death Note"
	cooldown_seconds = 10.0


func _can_activate() -> bool:
	var p: Player = get_player()
	return p != null and p.current_target != null and is_instance_valid(p.current_target)


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.current_target == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	var target: Node = p.current_target

	var sprite_node: Node = target.get_node_or_null("Sprite2D")
	var orig_modulate: Color = Color.WHITE
	if sprite_node != null and sprite_node is CanvasItem:
		orig_modulate = (sprite_node as CanvasItem).modulate
		(sprite_node as CanvasItem).modulate = Color(0.4, 0.0, 0.4, 1)
	if target.has_method("set_physics_process"):
		target.set_physics_process(false)

	await p.get_tree().create_timer(stun_duration).timeout

	if not is_instance_valid(target):
		return
	if target.has_method("set_physics_process"):
		target.set_physics_process(true)
	if sprite_node != null and sprite_node is CanvasItem and is_instance_valid(sprite_node):
		(sprite_node as CanvasItem).modulate = orig_modulate

	var hb: HurtboxComponent = target.get_node_or_null("Hurtbox") as HurtboxComponent
	if hb != null:
		hb.receive_hit(death_damage, p, (target as Node2D).global_position if target is Node2D else Vector2.ZERO)
	Events.screen_shake.emit(8.0, 0.3)

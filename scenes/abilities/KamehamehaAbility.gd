class_name KamehamehaAbility
extends Ability

# Goku's W. Brief charge (Goku cups his hands at his hip — sprite flushes
# blue) then fires a sustained beam — 4 fast piercing ki bullets in tight
# succession reading as one continuous wave.

@export var damage_mult: float = 4.5
@export var pierce: int = 18
@export var speed_mult: float = 2.0
@export var charge_seconds: float = 0.65
@export var beam_count: int = 4
@export var beam_interval: float = 0.06


func _ready() -> void:
	super._ready()
	ability_name = "Kamehameha"
	cooldown_seconds = 10.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, -1.0)

	var orig_modulate: Color = p.sprite.modulate
	var tw: Tween = p.create_tween()
	tw.tween_property(p.sprite, "modulate", Color(0.6, 0.85, 1.7), charge_seconds)
	await tw.finished
	if not is_instance_valid(p):
		return

	Events.screen_shake.emit(15.0, 0.4)
	var aim: Vector2 = _aim_dir(p)
	for i: int in beam_count:
		if not is_instance_valid(p):
			return
		var b: Node = BulletPool.acquire(p.bullet_scene)
		if b != null and b.has_method("spawn"):
			var dmg: int = max(1, int(round(float(p.stats.damage) * damage_mult)))
			b.call("spawn", p.muzzle.global_position, aim, p.stats.bullet_speed * speed_mult, dmg, "player", pierce)
		VFX.spawn_muzzle_flash(p.muzzle.global_position, aim)
		await p.get_tree().create_timer(beam_interval).timeout

	if is_instance_valid(p):
		var fade: Tween = p.create_tween()
		fade.tween_property(p.sprite, "modulate", orig_modulate, 0.2)


func _aim_dir(p: Player) -> Vector2:
	if p.current_target != null and is_instance_valid(p.current_target):
		return (p.current_target.global_position - p.global_position).normalized()
	if p.move_input.length() > 0.05:
		return p.move_input.normalized()
	return Vector2.RIGHT

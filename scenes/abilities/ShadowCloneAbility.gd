class_name ShadowCloneAbility
extends Ability

# Naruto Q. Spawns 2 stationary clone-turrets at the player's flanks. Each
# clone auto-fires the player's bullet at the player's current target for
# `clone_duration` seconds, dealing `clone_damage_mult` of normal damage.
# Clones use a tinted-blue copy of the player sprite as their visual.

@export var clone_duration: float = 6.0
@export var clone_fire_rate: float = 2.5
@export var clone_damage_mult: float = 0.5
@export var flank_offset: float = 22.0


func _ready() -> void:
	super._ready()
	ability_name = "Shadow Clone"
	cooldown_seconds = 10.0


func _activate() -> void:
	var p: Player = get_player()
	if p == null or p.bullet_scene == null:
		return
	Audio.play("ability_burst", 0.05, 0.0)
	VFX.spawn_hit_particles(p.global_position, Vector2.UP)
	for offset_x: float in [-flank_offset, flank_offset]:
		_spawn_clone(p, p.global_position + Vector2(offset_x, 0))


func _spawn_clone(p: Player, pos: Vector2) -> void:
	var clone: Node2D = Node2D.new()
	clone.global_position = pos
	clone.z_index = 5
	p.get_tree().current_scene.add_child(clone)

	var sprite_copy: Sprite2D = Sprite2D.new()
	if p.sprite is AnimatedSprite2D:
		var anim: AnimatedSprite2D = p.sprite as AnimatedSprite2D
		if anim.sprite_frames != null and anim.sprite_frames.has_animation(&"idle"):
			var tex: Texture2D = anim.sprite_frames.get_frame_texture(&"idle", 0)
			if tex != null:
				sprite_copy.texture = tex
	sprite_copy.modulate = Color(0.6, 0.85, 1.2, 0.7)
	clone.add_child(sprite_copy)

	var fire_t: Timer = Timer.new()
	fire_t.wait_time = 1.0 / max(clone_fire_rate, 0.01)
	fire_t.autostart = true
	clone.add_child(fire_t)
	var dmg: int = max(1, int(round(float(p.stats.damage) * clone_damage_mult)))
	fire_t.timeout.connect(func() -> void:
		if not is_instance_valid(p) or not is_instance_valid(clone):
			return
		if p.current_target == null or not is_instance_valid(p.current_target):
			return
		var dir: Vector2 = (p.current_target.global_position - clone.global_position).normalized()
		var b: Node = BulletPool.acquire(p.bullet_scene)
		if b != null and b.has_method("spawn"):
			b.call("spawn", clone.global_position, dir, p.stats.bullet_speed, dmg, "player")
	)

	var life_t: Timer = Timer.new()
	life_t.wait_time = clone_duration
	life_t.one_shot = true
	life_t.autostart = true
	clone.add_child(life_t)
	life_t.timeout.connect(func() -> void:
		if is_instance_valid(clone):
			VFX.spawn_hit_particles(clone.global_position, Vector2.UP)
			clone.queue_free()
	)

class_name Player
extends CharacterBody2D

signal health_changed(current: int, max_hp: int)
signal died
# Power-up proc bus — emitted by Player so attached ProcOnXComponent
# nodes can subscribe without each one re-listening to every bullet.
@warning_ignore("unused_signal")
signal bullet_hit(target: Node)
@warning_ignore("unused_signal")
signal dodged

@export var stats: PlayerStats
@export var bullet_scene: PackedScene
@export var hub_mode: bool = false

# Upgrade-driven fire mods (set by UpgradeManager via apply_callback).
# Reset per-run via UpgradeManager.reset_for_new_run().
var extra_projectiles: int = 0       # +N additional bullets per fire, fanned
var bullet_ricochet_count: int = 0   # bullets bounce N times off walls
var bullet_pierce_bonus: int = 0     # added to bullet's pierce_count at spawn
var bullet_homing_strength: float = 0.0
var bullet_chain_targets: int = 0
var bullet_split_on_death: int = 0
var bullet_burn_dps: float = 0.0     # added on top of bullet's baked burn_dps
var bullet_burn_duration: float = 0.0
var bullet_knockback: float = 0.0    # negative pushes target away on hit
var bullet_size_mul: float = 1.0     # visual + radius mul applied at spawn
var bullet_spread_extra: float = 0.0 # extra fan-radians for spread shot

# Per-frame move-speed multiplier (slow zones in endless mode, etc.).
# Read in _physics_process; multiple sources stack multiplicatively via
# enter/exit pairs.
var move_speed_mul: float = 1.0

@onready var detection: Area2D = $DetectionRange
@onready var fire_timer: Timer = $FireTimer
@onready var muzzle: Marker2D = $Muzzle
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox

var current_target: Node2D = null
var move_input: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	if stats == null:
		stats = PlayerStats.new()
	# Per-character bullet override — falls back to scene-baked default
	if stats.bullet_scene != null:
		bullet_scene = stats.bullet_scene
	health.max_hp = stats.max_hp
	health.reset(stats.max_hp)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	fire_timer.wait_time = 1.0 / stats.fire_rate
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	if not hub_mode:
		fire_timer.start()
	var det_shape: CollisionShape2D = detection.get_node("CollisionShape2D")
	var circle: CircleShape2D = det_shape.shape as CircleShape2D
	if circle != null:
		circle.radius = stats.detection_radius
	if bullet_scene != null and not hub_mode:
		BulletPool.warm(bullet_scene, 96)
	_install_abilities_from_stats()
	_setup_sprite_frames()
	if hub_mode:
		# Disable hurtbox and abilities while wandering the hub
		if hurtbox != null:
			hurtbox.set_deferred("monitoring", false)
			hurtbox.set_deferred("monitorable", false)
		var abilities_node: Node = get_node_or_null("Abilities")
		if abilities_node != null:
			abilities_node.process_mode = Node.PROCESS_MODE_DISABLED


func _setup_sprite_frames() -> void:
	# Use the stats-provided SpriteFrames if any. Otherwise build a single-frame
	# fallback from `portrait` so legacy 16x16 characters render unchanged.
	if sprite == null or stats == null:
		return
	if stats.frames != null:
		sprite.sprite_frames = stats.frames
	elif stats.portrait != null:
		var fallback: SpriteFrames = SpriteFrames.new()
		fallback.add_animation(&"idle")
		fallback.add_frame(&"idle", stats.portrait)
		sprite.sprite_frames = fallback
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")
	# Per-character sprite offset — for AI-generated sheets where the
	# character floats in the upper part of the cell with empty space
	# below. Naruto needs ~+12 to drop his feet onto the shadow.
	sprite.offset = stats.sprite_offset
	# Reposition the shadow to sit at the sprite's feet — auto-scales with sprite height
	# so 16x16 portraits and 32x48 hero sprites both get the right shadow placement.
	# The shadow does NOT track sprite_offset — that offset shifts the sprite down to
	# fill empty bottom padding, which is exactly where the shadow already is.
	var shadow: Sprite2D = get_node_or_null("Shadow") as Sprite2D
	if shadow != null and sprite.sprite_frames != null:
		var tex: Texture2D = sprite.sprite_frames.get_frame_texture(&"idle", 0)
		if tex != null:
			shadow.position.y = float(tex.get_height()) * 0.5 - 2.0


func _on_health_changed(current: int, max_hp: int) -> void:
	health_changed.emit(current, max_hp)

func _physics_process(_delta: float) -> void:
	move_input = Joystick.get_vector()
	velocity = move_input * stats.move_speed * move_speed_mul
	move_and_slide()
	if absf(move_input.x) > 0.05:
		sprite.flip_h = move_input.x < 0
	_update_animation()
	if not hub_mode:
		_update_target()


func _update_animation() -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var moving: bool = move_input.length_squared() > 0.01
	var want: StringName = &"walk" if moving else &"idle"
	if want == &"walk" and not sprite.sprite_frames.has_animation(&"walk"):
		want = &"idle"
	if sprite.animation != want and sprite.sprite_frames.has_animation(want):
		sprite.play(want)

func _update_target() -> void:
	var bodies: Array[Node2D] = detection.get_overlapping_bodies()
	var areas: Array[Area2D] = detection.get_overlapping_areas()
	var nearest: Node2D = null
	var best_dist_sq: float = INF
	for b in bodies:
		if not b.is_in_group("enemies"):
			continue
		var d: float = global_position.distance_squared_to(b.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			nearest = b
	for a in areas:
		var parent2d: Node2D = a.get_parent() as Node2D
		if parent2d == null:
			continue
		if not parent2d.is_in_group("enemies"):
			continue
		var d: float = global_position.distance_squared_to(parent2d.global_position)
		if d < best_dist_sq:
			best_dist_sq = d
			nearest = parent2d
	current_target = nearest

func _on_fire_timer_timeout() -> void:
	if hub_mode:
		return
	if bullet_scene == null:
		return
	if current_target == null or not is_instance_valid(current_target):
		return
	var dir: Vector2 = (current_target.global_position - muzzle.global_position).normalized()
	var shots: int = 1 + max(0, extra_projectiles)
	var spread: float = deg_to_rad(8.0) + bullet_spread_extra
	for i: int in shots:
		var t: float = 0.0
		if shots > 1:
			t = (float(i) - float(shots - 1) * 0.5) / (float(shots - 1) * 0.5)
		var ang: float = t * spread
		var shot_dir: Vector2 = dir.rotated(ang)
		var b: Node = BulletPool.acquire(bullet_scene)
		if b == null or not b.has_method("spawn"):
			continue
		var dmg: int = stats.damage
		var crit: bool = randf() < stats.crit_chance
		if crit:
			dmg = roundi(stats.damage * stats.crit_multiplier)
		var pierce_override: int = -1
		if b is Bullet and bullet_pierce_bonus > 0:
			pierce_override = (b as Bullet).pierce_count + bullet_pierce_bonus
		b.call("spawn", muzzle.global_position, shot_dir, stats.bullet_speed, dmg, "player", pierce_override)
		if b is Bullet:
			var bull: Bullet = b as Bullet
			bull.ricochet_count = bullet_ricochet_count
			bull._ricochet_remaining = bullet_ricochet_count
			bull.homing_strength = bullet_homing_strength
			bull.chain_targets = bullet_chain_targets
			bull._chain_remaining = bullet_chain_targets
			bull.split_on_death = bullet_split_on_death
			bull.on_hit_callback = _on_bullet_hit_callback
			if bullet_burn_dps > 0.0:
				bull.burn_dps = max(bull.burn_dps, bullet_burn_dps)
				bull.burn_duration = max(bull.burn_duration, bullet_burn_duration)
			if bullet_knockback != 0.0:
				bull.pull_distance += bullet_knockback
			if bullet_size_mul != 1.0:
				bull.scale = Vector2.ONE * bullet_size_mul
	VFX.spawn_muzzle_flash(muzzle.global_position, dir)
	Audio.play("shoot", 0.08, -4.0)

func _on_bullet_hit_callback(_bullet: Node, target: Node) -> void:
	# Re-emitted as a player-level signal so any attached ProcOnHitComponent
	# can subscribe once, instead of every bullet attaching its own.
	bullet_hit.emit(target)


func _on_died() -> void:
	died.emit()
	Events.player_died.emit()
	Audio.play("player_hurt", 0.0, 0.0)
	set_physics_process(false)
	visible = false


func _install_abilities_from_stats() -> void:
	# Rename baked Q/W/E nodes to slot names so the HUD can find them by slot,
	# then replace any slot the active stats provide an override for.
	var ab_root: Node = get_node_or_null("Abilities")
	if ab_root == null:
		return
	var slot_names: Array[String] = ["AbilityQ", "AbilityW", "AbilityE"]
	var baked: Array[Node] = []
	for c: Node in ab_root.get_children():
		baked.append(c)
	for i: int in mini(baked.size(), slot_names.size()):
		baked[i].name = slot_names[i]
	if stats == null:
		return
	var overrides: Array = [stats.ability_q, stats.ability_w, stats.ability_e]
	for i: int in slot_names.size():
		var packed: PackedScene = overrides[i] as PackedScene
		if packed == null:
			continue
		var existing: Node = ab_root.get_node_or_null(slot_names[i])
		if existing != null:
			ab_root.remove_child(existing)
			existing.queue_free()
		var inst: Node = packed.instantiate()
		if inst == null:
			continue
		inst.name = slot_names[i]
		ab_root.add_child(inst)

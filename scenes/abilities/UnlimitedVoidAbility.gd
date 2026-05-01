class_name UnlimitedVoidAbility
extends Ability

# Gojo's E (Domain Expansion: Unlimited Void). Spawns a black-core / cyan-
# ringed void sphere centered on Gojo, freezes every regular enemy inside
# its radius for stun_duration, and ticks a small DoT from "infinite
# information." Bosses are carved out — they take damage but stay mobile.

const VOID_BUBBLE_TEX: Texture2D = preload("res://art/vfx/void_bubble.svg")

@export var radius: float = 91.0
@export var stun_duration: float = 3.0
@export var damage_per_sec: int = 1
@export var bubble_open_seconds: float = 0.35
@export var bubble_close_seconds: float = 0.45
@export var execute_overkill: int = 99999


func _ready() -> void:
	super._ready()
	ability_name = "Unlimited Void"
	cooldown_seconds = 20.0
	target_strategy = TargetStrategy.SELF_AOE


func _can_activate() -> bool:
	var p: Player = get_player()
	return p != null and p.health.current > 1


func _activate() -> void:
	var p: Player = get_player()
	if p == null:
		return
	Audio.play("ability_burst", 0.05, -1.0)
	Events.screen_shake.emit(16.0, 0.5)

	# Visual telegraph — Gojo flushes purple
	var orig_modulate: Color = p.sprite.modulate
	p.sprite.modulate = Color(0.7, 0.55, 1.6)

	# Spawn the void bubble visual at Gojo's position
	var bubble: Sprite2D = _spawn_bubble(p)

	# Find every enemy hurtbox in radius
	var space: PhysicsDirectSpaceState2D = p.get_world_2d().direct_space_state
	var query: PhysicsShapeQueryParameters2D = PhysicsShapeQueryParameters2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = radius
	query.shape = shape
	query.transform = Transform2D(0.0, p.global_position)
	query.collision_mask = 1 << 4
	query.collide_with_areas = true
	query.collide_with_bodies = false
	var hits: Array[Dictionary] = space.intersect_shape(query, 64)

	var stunned: Array[Node] = []
	for h: Dictionary in hits:
		var hb: HurtboxComponent = h["collider"] as HurtboxComponent
		if hb == null:
			continue
		var enemy: Node = hb.get_parent()
		if enemy == null:
			continue
		var is_boss: bool = enemy.is_in_group("boss")
		if not is_boss:
			# Anything non-boss caught in the void is annihilated immediately.
			var ihp: HealthComponent = enemy.get_node_or_null("HealthComponent") as HealthComponent
			if ihp != null:
				ihp.take_damage(execute_overkill, p)
			continue
		# Bosses stay mobile but get tinted + DoT'd for the duration.
		stunned.append(enemy)
		var sprite_node: Node = enemy.get_node_or_null("Sprite2D")
		if sprite_node == null:
			sprite_node = enemy.get_node_or_null("Sprite")
		if sprite_node is CanvasItem:
			(sprite_node as CanvasItem).modulate = Color(0.55, 0.55, 0.85)

	# DoT during the stun
	var dot_timer: Timer = Timer.new()
	dot_timer.wait_time = 1.0
	dot_timer.autostart = true
	p.add_child(dot_timer)
	var dot_tick: Callable = func() -> void:
		for e: Node in stunned:
			if not is_instance_valid(e):
				continue
			var hp: HealthComponent = e.get_node_or_null("HealthComponent") as HealthComponent
			if hp != null:
				hp.take_damage(damage_per_sec, p)
	dot_timer.timeout.connect(dot_tick)

	await p.get_tree().create_timer(stun_duration).timeout

	# Restore enemies
	for e: Node in stunned:
		if not is_instance_valid(e):
			continue
		e.set_physics_process(true)
		e.set_process(true)
		var sprite_node: Node = e.get_node_or_null("Sprite2D")
		if sprite_node == null:
			sprite_node = e.get_node_or_null("Sprite")
		if sprite_node is CanvasItem:
			(sprite_node as CanvasItem).modulate = Color(1, 1, 1, 1)

	if is_instance_valid(dot_timer):
		dot_timer.queue_free()
	if is_instance_valid(p):
		p.sprite.modulate = orig_modulate

	# Collapse the bubble
	_close_bubble(bubble)


func _spawn_bubble(p: Player) -> Sprite2D:
	var bubble: Sprite2D = Sprite2D.new()
	bubble.texture = VOID_BUBBLE_TEX
	bubble.z_index = 4  # above floor, below player
	bubble.modulate = Color(1, 1, 1, 0)
	bubble.scale = Vector2.ZERO
	bubble.global_position = p.global_position
	# Parent to current scene so it stays put if Gojo moves out of the void
	get_tree().current_scene.add_child(bubble)
	# Sphere texture is 64×64 source → final scale to fit `radius` * 2 in pixels
	var target_scale: float = (radius * 2.0) / 64.0
	var open_tw: Tween = bubble.create_tween().set_parallel(true)
	open_tw.tween_property(bubble, "scale", Vector2(target_scale, target_scale), bubble_open_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	open_tw.tween_property(bubble, "modulate", Color(1, 1, 1, 1), bubble_open_seconds * 0.6)
	# Subtle rotation so the rings feel alive
	var spin_tw: Tween = bubble.create_tween().set_loops()
	spin_tw.tween_property(bubble, "rotation", TAU, 6.0)
	bubble.set_meta("spin_tw", spin_tw)
	return bubble


func _close_bubble(bubble: Sprite2D) -> void:
	if bubble == null or not is_instance_valid(bubble):
		return
	var spin_tw: Variant = bubble.get_meta("spin_tw", null)
	if spin_tw is Tween and (spin_tw as Tween).is_valid():
		(spin_tw as Tween).kill()
	var close_tw: Tween = bubble.create_tween().set_parallel(true)
	close_tw.tween_property(bubble, "scale", Vector2.ZERO, bubble_close_seconds).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	close_tw.tween_property(bubble, "modulate", Color(1, 1, 1, 0), bubble_close_seconds)
	close_tw.chain().tween_callback(bubble.queue_free)

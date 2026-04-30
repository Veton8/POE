class_name Boss
extends CharacterBody2D

signal phase_changed(phase: int)
signal died

enum Pattern { PROJECTILE_FAN, CHARGE, SLAM, SUMMON }

@export var stats: EnemyStats
@export var bullet_scene: PackedScene
@export var minion_scene: PackedScene
@export var charge_speed: float = 240.0
@export var phase2_pattern_interval: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var contact: Area2D = $ContactHitbox
@onready var pattern_timer: Timer = $PatternTimer
@onready var telegraph: CanvasItem = $Telegraph
@onready var slam_area: Area2D = $SlamArea

var player: Node2D = null
var phase: int = 1
var attacking: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	if stats == null:
		stats = EnemyStats.new()
		stats.max_hp = 60
		stats.move_speed = 35.0
		stats.contact_damage = 1
	health.max_hp = stats.max_hp
	health.reset(stats.max_hp)
	health.health_changed.connect(_on_health_changed)
	health.died.connect(_on_died)
	pattern_timer.wait_time = 2.5
	pattern_timer.timeout.connect(_choose_pattern)
	pattern_timer.start()
	contact.body_entered.connect(_on_contact)
	_acquire_player()

func _acquire_player() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		player = nodes[0] as Node2D

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_acquire_player()
		return
	if not attacking:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		velocity = dir * stats.move_speed
	move_and_slide()

func _choose_pattern() -> void:
	if attacking or player == null:
		return
	var options: Array = [Pattern.PROJECTILE_FAN, Pattern.CHARGE, Pattern.SLAM]
	if phase == 2:
		options.append(Pattern.SUMMON)
	var pick: int = options.pick_random()
	match pick:
		Pattern.PROJECTILE_FAN: _projectile_fan()
		Pattern.CHARGE: _charge()
		Pattern.SLAM: _slam()
		Pattern.SUMMON: _summon()

func _projectile_fan() -> void:
	attacking = true
	var orig_modulate: Color = sprite.modulate
	sprite.modulate = Color(2, 2, 0.8, 1)
	await get_tree().create_timer(0.5).timeout
	sprite.modulate = orig_modulate
	if bullet_scene != null:
		var count: int = 12 if phase == 1 else 18
		for i in count:
			var angle: float = TAU * float(i) / float(count)
			var dir: Vector2 = Vector2.RIGHT.rotated(angle)
			var b: Node = BulletPool.acquire(bullet_scene)
			if b.has_method("spawn"):
				b.call("spawn", global_position, dir, stats.bullet_speed, stats.bullet_damage, "enemy")
	attacking = false

func _charge() -> void:
	attacking = true
	var dir: Vector2 = (player.global_position - global_position).normalized()
	telegraph.show()
	if telegraph is Node2D:
		(telegraph as Node2D).rotation = dir.angle()
	elif telegraph is Control:
		(telegraph as Control).rotation = dir.angle()
	await get_tree().create_timer(0.7).timeout
	telegraph.hide()
	velocity = dir * charge_speed
	var t: float = 0.0
	while t < 0.4:
		t += get_physics_process_delta_time()
		move_and_slide()
		await get_tree().physics_frame
	velocity = Vector2.ZERO
	await get_tree().create_timer(0.6).timeout
	attacking = false

func _slam() -> void:
	attacking = true
	var target: Vector2 = player.global_position
	var tw: Tween = create_tween()
	tw.tween_property(self, "global_position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(sprite, "scale", Vector2(1.2, 0.8), 0.4)
	await tw.finished
	var tw2: Tween = create_tween()
	tw2.tween_property(sprite, "scale", Vector2.ONE, 0.15)
	Events.screen_shake.emit(8.0, 0.3)
	VFX.spawn_death_particles(global_position)
	slam_area.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame
	for body in slam_area.get_overlapping_bodies():
		if not body.is_in_group("player"):
			continue
		var hb: HurtboxComponent = body.get_node_or_null("Hurtbox") as HurtboxComponent
		if hb == null:
			continue
		var body2d: Node2D = body as Node2D
		var hit_pos: Vector2 = body2d.global_position if body2d else global_position
		hb.receive_hit(stats.contact_damage + 1, self, hit_pos)
	await get_tree().create_timer(0.1).timeout
	slam_area.monitoring = false
	await get_tree().create_timer(0.5).timeout
	attacking = false

func _summon() -> void:
	if minion_scene == null:
		attacking = false
		return
	attacking = true
	for i in 3:
		var m: Node2D = minion_scene.instantiate() as Node2D
		if m == null:
			continue
		get_parent().add_child(m)
		m.global_position = global_position + Vector2(randf_range(-32, 32), randf_range(-32, 32))
		await get_tree().create_timer(0.1).timeout
	attacking = false

func _on_contact(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var hb: HurtboxComponent = body.get_node_or_null("Hurtbox") as HurtboxComponent
	if hb == null:
		return
	var body2d: Node2D = body as Node2D
	var hit_pos: Vector2 = body2d.global_position if body2d else global_position
	hb.receive_hit(stats.contact_damage, self, hit_pos)

func _on_health_changed(current: int, _max_hp: int) -> void:
	if phase == 1 and float(current) / float(stats.max_hp) <= 0.5:
		phase = 2
		pattern_timer.wait_time = phase2_pattern_interval
		Events.screen_shake.emit(12.0, 0.5)
		Events.boss_phase_changed.emit(2)
		phase_changed.emit(2)
		Audio.play("boss_phase2", 0.0, 0.0)
		sprite.modulate = Color(1.2, 0.7, 0.7, 1)

func _on_died() -> void:
	died.emit()
	Events.enemy_died.emit(self, global_position)
	VFX.spawn_death_particles(global_position)
	Events.screen_shake.emit(20.0, 0.6)
	Audio.play("boss_die", 0.0, 0.0)
	queue_free()

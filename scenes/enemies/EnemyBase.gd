class_name EnemyBase
extends CharacterBody2D

signal died

@export var stats: EnemyStats
@export var bullet_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var health: HealthComponent = $HealthComponent
@onready var hurtbox: HurtboxComponent = $Hurtbox
@onready var hitbox_area: Area2D = $ContactHitbox
@onready var fire_timer: Timer = $FireTimer

var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	if stats == null:
		stats = EnemyStats.new()
	health.max_hp = stats.max_hp
	health.reset(stats.max_hp)
	health.died.connect(_on_died)
	fire_timer.wait_time = 1.0 / max(stats.fire_rate, 0.01)
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	if stats.ranged:
		fire_timer.start()
	hitbox_area.body_entered.connect(_on_body_entered)
	_acquire_player()

func _acquire_player() -> void:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		player = nodes[0] as Node2D

func _physics_process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		_acquire_player()
		return
	_ai_step()
	move_and_slide()
	if absf(velocity.x) > 1.0:
		sprite.flip_h = velocity.x < 0

func _ai_step() -> void:
	var dir: Vector2 = (player.global_position - global_position).normalized()
	if stats.ranged:
		var dist: float = global_position.distance_to(player.global_position)
		var ideal: float = stats.detection_radius * 0.5
		if dist > ideal + 16.0:
			velocity = dir * stats.move_speed
		elif dist < ideal - 16.0:
			velocity = -dir * stats.move_speed
		else:
			velocity = velocity.move_toward(Vector2.ZERO, stats.move_speed * 4.0 * get_physics_process_delta_time())
	else:
		velocity = dir * stats.move_speed

func _on_fire_timer_timeout() -> void:
	if bullet_scene == null or player == null:
		return
	var dir: Vector2 = (player.global_position - global_position).normalized()
	var b: Node = BulletPool.acquire(bullet_scene)
	if b.has_method("spawn"):
		b.call("spawn", global_position, dir, stats.bullet_speed, stats.bullet_damage, "enemy")

func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	var hb: HurtboxComponent = body.get_node_or_null("Hurtbox") as HurtboxComponent
	if hb == null:
		return
	var body2d: Node2D = body as Node2D
	var hit_pos: Vector2 = body2d.global_position if body2d else global_position
	hb.receive_hit(stats.contact_damage, self, hit_pos)
	Events.screen_shake.emit(4.0, 0.1)

func _on_died() -> void:
	died.emit()
	Events.enemy_died.emit(self, global_position)
	VFX.spawn_death_particles(global_position)
	Events.screen_shake.emit(3.0, 0.1)
	Audio.play("enemy_die", 0.1, -2.0)
	queue_free()

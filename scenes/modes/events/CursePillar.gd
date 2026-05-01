class_name CursePillar
extends StaticBody2D

# Destructible 3000-HP pillar. While alive: +20% enemy HP (applied to
# spawner difficulty multiplier via a flag). On death: grants +10%
# permanent XP gain for the rest of the run.

const PILLAR_HP: int = 3000
const ENEMY_HP_BONUS: float = 0.20
const XP_BONUS: float = 0.10

var _hp: int = PILLAR_HP
var _alive: bool = true


func _ready() -> void:
	z_index = 1
	add_to_group("map_event")
	add_to_group("curse_pillar")
	collision_layer = 1  # world (so bullets hit it)
	collision_mask = 0
	# Hurtbox so player bullets damage it
	var hurtbox: HurtboxComponent = HurtboxComponent.new()
	hurtbox.name = "HurtboxComponent"
	add_child(hurtbox)
	hurtbox.hit_taken.connect(_on_hit)
	# Collision shape so it blocks projectiles / bullets register
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = Vector2(20, 32)
	coll.shape = shape
	add_child(coll)


func _process(_delta: float) -> void:
	queue_redraw()


func _on_hit(amount: int, _source: Node) -> void:
	if not _alive:
		return
	_hp -= amount
	if _hp <= 0:
		_die()


func _die() -> void:
	_alive = false
	# Buff XP gain — bumps EndlessSpawner._xp_global_mult or whatever
	# pattern the run scene uses. For v1, store on the run scene meta.
	var run: Node = get_tree().current_scene
	if run != null and run.has_method("apply_xp_bonus"):
		run.call("apply_xp_bonus", XP_BONUS)
	VFX.spawn_hit_particles(global_position, Vector2.ZERO)
	Events.screen_shake.emit(6.0, 0.4)
	Audio.play("ability_burst", -0.5, 2.0)
	queue_free()


func _draw() -> void:
	var t: float = Time.get_ticks_msec() / 300.0
	var pulse: float = (sin(t) + 1.0) * 0.5
	# Pillar shape — dark stone with red glyphs
	draw_rect(Rect2(Vector2(-10, -16), Vector2(20, 32)), Color(0.20, 0.18, 0.22, 1.0), true)
	draw_rect(Rect2(Vector2(-10, -16), Vector2(20, 32)), Color(0.55, 0.05, 0.05, 0.4 + pulse * 0.4), false)
	# HP indicator — small bar on top
	var hp_frac: float = clampf(float(_hp) / float(PILLAR_HP), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-10, -22), Vector2(20, 2)), Color(0.10, 0.10, 0.10, 0.8), true)
	draw_rect(Rect2(Vector2(-10, -22), Vector2(20.0 * hp_frac, 2)), Color(0.95, 0.30, 0.30, 0.95), true)

extends Node

@export var hit_particles_scene: PackedScene = preload("res://scenes/vfx/HitParticles.tscn")
@export var death_particles_scene: PackedScene = preload("res://scenes/vfx/DeathParticles.tscn")
@export var muzzle_flash_scene: PackedScene = preload("res://scenes/vfx/MuzzleFlash.tscn")
@export var damage_number_scene: PackedScene = preload("res://scenes/vfx/DamageNumber.tscn")

func screen_shake(amount: float, duration: float = 0.15) -> void:
	Events.screen_shake.emit(amount, duration)

func spawn_hit_particles(pos: Vector2, dir: Vector2 = Vector2.ZERO) -> void:
	if hit_particles_scene == null:
		return
	var p: Node2D = hit_particles_scene.instantiate() as Node2D
	if p == null:
		return
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	if dir != Vector2.ZERO:
		p.rotation = dir.angle()
	if p.has_method("emit_burst"):
		p.call("emit_burst")

func spawn_death_particles(pos: Vector2) -> void:
	if death_particles_scene == null:
		return
	var p: Node2D = death_particles_scene.instantiate() as Node2D
	if p == null:
		return
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	if p.has_method("emit_burst"):
		p.call("emit_burst")

func spawn_muzzle_flash(pos: Vector2, dir: Vector2) -> void:
	if muzzle_flash_scene == null:
		return
	var p: Node2D = muzzle_flash_scene.instantiate() as Node2D
	if p == null:
		return
	get_tree().current_scene.add_child(p)
	p.global_position = pos
	p.rotation = dir.angle()
	if p.has_method("emit_burst"):
		p.call("emit_burst")

func spawn_damage_number(pos: Vector2, value: int, crit: bool = false, color: Color = Color(1, 0.3, 0.3)) -> void:
	if damage_number_scene == null:
		return
	var d: Label = damage_number_scene.instantiate() as Label
	if d == null:
		return
	get_tree().current_scene.add_child(d)
	d.global_position = pos + Vector2(randf_range(-4, 4), -8)
	if d.has_method("popup"):
		d.call("popup", value, crit, color)

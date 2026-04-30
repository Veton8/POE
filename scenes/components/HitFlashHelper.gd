class_name HitFlashHelper
extends RefCounted

static func flash(sprite: CanvasItem, duration: float = 0.06) -> void:
	if sprite == null:
		return
	var mat := sprite.material as ShaderMaterial
	if mat == null:
		return
	mat.set_shader_parameter("active", true)
	await sprite.get_tree().create_timer(duration).timeout
	if is_instance_valid(sprite) and is_instance_valid(mat):
		mat.set_shader_parameter("active", false)

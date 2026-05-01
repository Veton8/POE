extends Node2D

# 4-px tall status strip along the bottom of the bottom HUD band.
# Shows up to 8 status icons for active marks/buffs from
# AutocastModifierRegistry and MarkRegistry. Cosmetic only.

const MAX_ICONS: int = 8


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	# Pull active CD modifiers + check for queued empower
	if not has_node("/root/AutocastModifierRegistry"):
		return
	var reg: Node = get_node("/root/AutocastModifierRegistry")
	# Drawn icons — small colored squares; bright if active
	var x: float = 4.0
	var icons_drawn: int = 0
	# Check for queued empower (not directly inspectable; show always when present
	# would require a getter — for v1, just draw a placeholder if cd_multiplier < 1.0)
	var cd_mul: float = float(reg.call("get_cd_multiplier"))
	if absf(cd_mul - 1.0) > 0.01 and icons_drawn < MAX_ICONS:
		# CD-mod active — yellow
		draw_rect(Rect2(Vector2(x, 0), Vector2(4, 4)), Color(1.0, 0.85, 0.30, 0.95), true)
		x += 6.0
		icons_drawn += 1

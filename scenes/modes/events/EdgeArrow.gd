extends Control

# Programmatic 12x12 red arrow drawn pointing right by default; the
# parent telegraph manager rotates this control to face the threat.

func _draw() -> void:
	var pulse: float = (sin(Time.get_ticks_msec() / 150.0) + 1.0) * 0.5
	var col: Color = Color(0.95, 0.25, 0.25, 0.55 + pulse * 0.4)
	# Triangle pointing right (in local space — rotation is applied by parent)
	var pts: PackedVector2Array = PackedVector2Array([
		Vector2(12, 6),  # tip
		Vector2(0, 0),   # top-left
		Vector2(0, 12),  # bottom-left
	])
	draw_colored_polygon(pts, col)
	draw_polyline(pts, Color(1.0, 0.5, 0.5, 0.95), 1.0, true)

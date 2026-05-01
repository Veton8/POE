extends Node2D

# Programmatic visual for a Blue orbital — 4×4 navy core + 1px white
# inner highlight + soft 6px additive glow. No sprite asset required.

func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	# Outer additive glow
	var glow: Color = Color(0.30, 0.42, 0.95, 0.22)
	draw_circle(Vector2.ZERO, 6.0, glow)
	# Mid navy
	draw_circle(Vector2.ZERO, 3.0, Color(0.18, 0.32, 0.78, 1.0))
	# White core (1px)
	draw_circle(Vector2(-0.5, -0.5), 1.0, Color(0.95, 0.97, 1.0, 1.0))

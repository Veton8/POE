extends Node2D

# Programmatic visual for the "Inscribed" mark — small black square
# with a faint white inner pulse. Hovers above marked enemies. Freed
# by NameInscribedListener on detonation/transfer.

var _t: float = 0.0


func _ready() -> void:
	z_index = 3
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	# 1px vertical bob to draw the eye
	position.y = -16.0 + sin(_t * 4.0) * 1.0
	queue_redraw()


func _draw() -> void:
	# 8x8 outer black; small inner pulse so the mark reads even on dark enemies
	draw_rect(Rect2(Vector2(-4, -4), Vector2(8, 8)), Color(0.04, 0.04, 0.06, 0.95), true)
	var pulse: float = (sin(_t * 6.0) + 1.0) * 0.5
	var inner: Color = Color(0.95, 0.10, 0.10, 0.40 + pulse * 0.40)
	draw_rect(Rect2(Vector2(-2, -2), Vector2(4, 4)), inner, true)

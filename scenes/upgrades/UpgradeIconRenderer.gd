class_name UpgradeIconRenderer
extends Control

# Programmatic icon factory. configure() with a shape keyword and two colors,
# then the Control draws itself in _draw via primitives. 12 keyword shapes
# for v1: circle, square, diamond, triangle, star, cross, flame, bolt, orb,
# ring, eye, arrow.

var shape: StringName = &"circle"
var primary: Color = Color.WHITE
var accent: Color = Color.BLACK


func configure(s: StringName, p: Color, a: Color) -> void:
	shape = s
	primary = p
	accent = a
	queue_redraw()


func _draw() -> void:
	var sz: Vector2 = size
	var center: Vector2 = sz * 0.5
	var radius: float = minf(sz.x, sz.y) * 0.4
	match shape:
		&"circle":
			draw_circle(center, radius, primary)
			draw_arc(center, radius, 0.0, TAU, 24, accent, 1.5)
		&"square":
			var rect: Rect2 = Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0))
			draw_rect(rect, primary, true)
			draw_rect(rect, accent, false, 1.5)
		&"diamond":
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius, 0),
				center + Vector2(0, radius),
				center + Vector2(-radius, 0),
			])
			draw_colored_polygon(pts, primary)
		&"triangle":
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.866, radius * 0.5),
				center + Vector2(-radius * 0.866, radius * 0.5),
			])
			draw_colored_polygon(pts, primary)
		&"star":
			var pts: PackedVector2Array = PackedVector2Array()
			for i: int in 10:
				var ang: float = -PI / 2.0 + (float(i) * PI / 5.0)
				var r: float = radius if i % 2 == 0 else radius * 0.4
				pts.append(center + Vector2(cos(ang), sin(ang)) * r)
			draw_colored_polygon(pts, primary)
		&"cross":
			var thick: float = radius * 0.4
			draw_rect(Rect2(center - Vector2(thick, radius), Vector2(thick * 2.0, radius * 2.0)), primary)
			draw_rect(Rect2(center - Vector2(radius, thick), Vector2(radius * 2.0, thick * 2.0)), primary)
		&"flame":
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(0, -radius),
				center + Vector2(radius * 0.6, 0),
				center + Vector2(radius * 0.4, radius * 0.7),
				center + Vector2(-radius * 0.4, radius * 0.7),
				center + Vector2(-radius * 0.6, 0),
			])
			draw_colored_polygon(pts, primary)
			draw_circle(center + Vector2(0, radius * 0.2), radius * 0.3, accent)
		&"bolt":
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(-radius * 0.3, -radius),
				center + Vector2(radius * 0.4, -radius * 0.2),
				center + Vector2(radius * 0.1, -radius * 0.2),
				center + Vector2(radius * 0.3, radius),
				center + Vector2(-radius * 0.4, radius * 0.2),
				center + Vector2(-radius * 0.1, radius * 0.2),
			])
			draw_colored_polygon(pts, primary)
		&"orb":
			draw_circle(center, radius, primary)
			draw_circle(center - Vector2(radius * 0.3, radius * 0.3), radius * 0.3, accent)
		&"ring":
			draw_arc(center, radius, 0.0, TAU, 24, primary, 3.0)
		&"eye":
			draw_arc(center, radius, 0.0, TAU, 24, primary, 2.0)
			draw_circle(center, radius * 0.4, accent)
		&"arrow":
			var pts: PackedVector2Array = PackedVector2Array([
				center + Vector2(-radius, -radius * 0.2),
				center + Vector2(radius * 0.4, -radius * 0.2),
				center + Vector2(radius * 0.4, -radius * 0.5),
				center + Vector2(radius, 0),
				center + Vector2(radius * 0.4, radius * 0.5),
				center + Vector2(radius * 0.4, radius * 0.2),
				center + Vector2(-radius, radius * 0.2),
			])
			draw_colored_polygon(pts, primary)
		_:
			draw_circle(center, radius, primary)

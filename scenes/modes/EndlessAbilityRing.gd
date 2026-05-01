extends Node2D

# 16x16 cooldown ring icon for an Ability. Draws a radial wipe
# that fills clockwise as the cooldown progresses. No input — pure
# visual feedback per the design doc.

var _ability: Ability = null


func bind_ability(a: Ability) -> void:
	_ability = a


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _ability == null:
		return
	# Background circle
	draw_circle(Vector2.ZERO, 8.0, Color(0.04, 0.05, 0.08, 0.85))
	# Ring outline
	draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 24, Color(0.55, 0.55, 0.65, 0.95), 1.0)
	# Cooldown wipe
	var t: float = _cd_progress()
	if t < 1.0:
		# t = 0 means just fired (full wipe), t = 1 means ready (no wipe)
		var fill: Color = Color(0.95, 0.85, 0.30, 0.85)
		var sweep: float = TAU * (1.0 - t)
		draw_arc(Vector2.ZERO, 6.0, -PI * 0.5, -PI * 0.5 + sweep, 32, fill, 4.0)
	else:
		# Ready — small green dot center
		draw_circle(Vector2.ZERO, 2.0, Color(0.35, 0.95, 0.40, 0.95))


func _cd_progress() -> float:
	# 0.0 = just-fired, 1.0 = ready. Ability has _on_cd flag and _t Timer
	# but those are private; estimate via _t.time_left vs cooldown_seconds.
	if _ability == null or not is_instance_valid(_ability):
		return 1.0
	var t: Timer = _ability.get_node_or_null("Timer") as Timer
	if t == null:
		# Timer was created in _ready as add_child without a name override —
		# it's the only Timer child. Find it.
		for c: Node in _ability.get_children():
			if c is Timer:
				t = c as Timer
				break
	if t == null:
		return 1.0
	if t.is_stopped():
		return 1.0
	if _ability.cooldown_seconds <= 0.0:
		return 1.0
	return clampf(1.0 - (t.time_left / _ability.cooldown_seconds), 0.0, 1.0)

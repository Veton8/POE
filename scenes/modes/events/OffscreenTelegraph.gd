class_name OffscreenTelegraph
extends CanvasLayer

# Edge-arrow indicator for off-screen bosses, elites, and reapers.
# Positions a 12×12 red triangle at the closest viewport edge,
# pointing toward the threat. atan2-based screen-rect intersection.
# Renders at full screen resolution above the SubViewport content.

const VIEWPORT_W: float = 270.0
const VIEWPORT_H: float = 480.0
const MARGIN: float = 12.0

var _player: Player = null
var _arrows: Array[Control] = []  # pool of reusable arrow controls


func attach_to(player: Player) -> void:
	_player = player


func _ready() -> void:
	layer = 80


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var threats: Array[Node2D] = []
	for n: Node in get_tree().get_nodes_in_group("boss"):
		if n is Node2D:
			threats.append(n as Node2D)
	for n: Node in get_tree().get_nodes_in_group("reaper"):
		if n is Node2D and not threats.has(n):
			threats.append(n as Node2D)
	# Ensure pool has enough arrows
	while _arrows.size() < threats.size():
		var arrow: Control = _make_arrow()
		add_child(arrow)
		_arrows.append(arrow)
	# Position one arrow per threat
	for i: int in _arrows.size():
		var arrow: Control = _arrows[i]
		if i >= threats.size():
			arrow.visible = false
			continue
		var t: Node2D = threats[i]
		if not is_instance_valid(t):
			arrow.visible = false
			continue
		_position_arrow(arrow, t)


func _make_arrow() -> Control:
	var c: Control = Control.new()
	c.size = Vector2(12, 12)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.set_script(preload("res://scenes/modes/events/EdgeArrow.gd"))
	return c


func _position_arrow(arrow: Control, threat: Node2D) -> void:
	# Camera centers on player; world-space delta determines arrow angle.
	var delta: Vector2 = threat.global_position - _player.global_position
	var half_w: float = VIEWPORT_W * 0.5
	var half_h: float = VIEWPORT_H * 0.5
	# Hide if threat is on-screen
	if absf(delta.x) <= half_w and absf(delta.y) <= half_h:
		arrow.visible = false
		return
	arrow.visible = true
	# Project ray to viewport edge using atan2
	var ang: float = atan2(delta.y, delta.x)
	var sx: float = signf(delta.x) if absf(delta.x) > 0.001 else 0.0
	var sy: float = signf(delta.y) if absf(delta.y) > 0.001 else 0.0
	var px: float = half_w - MARGIN
	var py: float = half_h - MARGIN
	# Pick edge by which axis has larger projection
	var pos_in_viewport: Vector2
	if absf(delta.x) * py > absf(delta.y) * px:
		pos_in_viewport = Vector2(sx * px, sx * px * delta.y / delta.x if absf(delta.x) > 0.001 else 0.0)
	else:
		pos_in_viewport = Vector2(sy * py * delta.x / delta.y if absf(delta.y) > 0.001 else 0.0, sy * py)
	# Map viewport-space to OS-window-space (assume centered display)
	var screen_size: Vector2 = Vector2(get_viewport().get_visible_rect().size)
	var scale_factor: float = minf(screen_size.x / VIEWPORT_W, screen_size.y / VIEWPORT_H)
	var center_screen: Vector2 = screen_size * 0.5
	var arrow_screen: Vector2 = center_screen + pos_in_viewport * scale_factor
	arrow.position = arrow_screen - arrow.size * 0.5
	arrow.rotation = ang
	arrow.set_meta("rotation_angle", ang)

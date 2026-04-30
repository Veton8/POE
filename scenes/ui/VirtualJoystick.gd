class_name VirtualJoystick
extends Control

enum Mode { FIXED, DYNAMIC }

@export var mode: Mode = Mode.DYNAMIC
@export var max_radius: float = 64.0
@export var deadzone: float = 0.15
@export var active_zone_x_fraction: float = 0.5

@onready var bg: Control = $Background
@onready var knob: Control = $Background/Knob

var _touch_index: int = -1
var _output: Vector2 = Vector2.ZERO
var _initial_bg_position: Vector2
var is_pressed: bool = false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_initial_bg_position = bg.position
	_recenter_knob()
	if mode == Mode.DYNAMIC:
		bg.hide()
	Joystick.register(self)

func _exit_tree() -> void:
	Joystick.unregister(self)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var touch: InputEventScreenTouch = event
		if touch.pressed and _touch_index == -1 and _is_inside_active_zone(touch.position):
			_touch_index = touch.index
			is_pressed = true
			if mode == Mode.DYNAMIC:
				bg.show()
				bg.global_position = touch.position - bg.size * 0.5
			_update_knob(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var drag: InputEventScreenDrag = event
		if drag.index == _touch_index:
			_update_knob(drag.position)

func _update_knob(touch_pos: Vector2) -> void:
	var center: Vector2 = bg.global_position + bg.size * 0.5
	var delta: Vector2 = touch_pos - center
	if delta.length() > max_radius:
		delta = delta.normalized() * max_radius
	knob.position = bg.size * 0.5 + delta - knob.size * 0.5
	var raw: Vector2 = delta / max_radius
	_output = raw if raw.length() > deadzone else Vector2.ZERO

func _release() -> void:
	_touch_index = -1
	is_pressed = false
	_output = Vector2.ZERO
	_recenter_knob()
	if mode == Mode.DYNAMIC:
		bg.hide()
		bg.position = _initial_bg_position

func _recenter_knob() -> void:
	knob.position = bg.size * 0.5 - knob.size * 0.5

func _is_inside_active_zone(p: Vector2) -> bool:
	return p.x < get_viewport_rect().size.x * active_zone_x_fraction

func get_vector() -> Vector2:
	return _output

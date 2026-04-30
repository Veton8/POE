class_name HubInteractable
extends Area2D

# Pixel-art object the player can walk up to and interact with.
# Emits `interacted` when the player is in range and the "interact"
# input action fires, or when the body itself is clicked/tapped.

signal interacted

@export var label_text: String = "Use"
@export var label_offset: Vector2 = Vector2(0, -28)
@export var bob_height: float = 1.5
@export var bob_speed: float = 2.5
@export var disabled: bool = false

var _player_in_range: bool = false
var _hover_label: Label = null
var _bob_t: float = 0.0
var _sprite: Sprite2D = null
var _sprite_base_y: float = 0.0


func _ready() -> void:
	add_to_group("hub_interactable")
	collision_layer = 0
	collision_mask = 2  # player layer
	monitoring = true
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	input_event.connect(_on_input_event)
	_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _sprite != null:
		_sprite_base_y = _sprite.position.y
	_create_label()


func _create_label() -> void:
	_hover_label = Label.new()
	_hover_label.text = label_text
	_hover_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hover_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hover_label.add_theme_color_override("font_color", Color("#FEF3C7"))
	_hover_label.add_theme_color_override("font_outline_color", Color("#1A1A2E"))
	_hover_label.add_theme_constant_override("outline_size", 4)
	_hover_label.position = label_offset - Vector2(40, 8)
	_hover_label.size = Vector2(80, 14)
	_hover_label.visible = false
	add_child(_hover_label)


func _process(delta: float) -> void:
	if disabled:
		_hover_label.visible = false
		return
	# Subtle bob animation
	_bob_t += delta * bob_speed
	if _sprite != null and _player_in_range:
		_sprite.position.y = _sprite_base_y + sin(_bob_t) * bob_height
	elif _sprite != null:
		_sprite.position.y = _sprite_base_y
	if _player_in_range:
		_hover_label.visible = true
		if Input.is_action_just_pressed("interact"):
			interacted.emit()
	else:
		_hover_label.visible = false


func _on_body_entered(body: Node) -> void:
	if disabled:
		return
	if body.is_in_group("player"):
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if disabled:
		return
	var pressed: bool = false
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			pressed = true
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			pressed = true
	if pressed:
		interacted.emit()


func set_disabled(value: bool) -> void:
	disabled = value
	if disabled:
		_hover_label.visible = false

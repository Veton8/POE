class_name AbilityButton
extends TouchScreenButton

@export var ability_path: NodePath
@export var input_action: String = ""

@onready var fill: TextureProgressBar = $Fill
@onready var label: Label = $Label
@onready var icon_rect: TextureRect = $Icon

var _ability: Ability = null

func _ready() -> void:
	pressed.connect(_on_pressed)
	released.connect(_on_released)
	if ability_path != NodePath(""):
		_bind_ability(get_node_or_null(ability_path) as Ability)

func _process(_dt: float) -> void:
	if _ability == null:
		return
	if input_action != "" and Input.is_action_just_pressed(input_action):
		_ability.try_activate()
	if _ability._t != null and _ability._t.time_left > 0.0:
		label.text = "%.1f" % _ability._t.time_left
		fill.value = _ability._t.time_left

func _bind_ability(a: Ability) -> void:
	if a == null:
		return
	_ability = a
	a.cooldown_started.connect(_on_cd_started)
	a.cooldown_ended.connect(_on_cd_ended)
	if a.icon != null:
		icon_rect.texture = a.icon
	label.hide()

func bind(a: Node) -> void:
	_bind_ability(a as Ability)

func _on_pressed() -> void:
	if _ability != null:
		_ability.try_activate()

func _on_released() -> void:
	pass

func _on_cd_started(duration: float) -> void:
	label.show()
	fill.max_value = duration
	fill.value = duration

func _on_cd_ended() -> void:
	label.hide()
	fill.value = 0.0

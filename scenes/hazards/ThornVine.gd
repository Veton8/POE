class_name ThornVine
extends Area2D

const TEX_ACTIVE: Texture2D = preload("res://art/hazards/thorn_vine.svg")
const TEX_DORMANT: Texture2D = preload("res://art/hazards/thorn_vine_dormant.svg")

@export var damage: int = 1
@export var dormant_seconds: float = 1.5

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var rearm_timer: Timer = $RearmTimer

var _active: bool = true

func _ready() -> void:
	z_index = 1
	rearm_timer.one_shot = true
	rearm_timer.timeout.connect(_on_rearm)
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	if not (area is HurtboxComponent):
		return
	var hb: HurtboxComponent = area as HurtboxComponent
	var owner_node: Node = hb.get_parent()
	if owner_node == null or not owner_node.is_in_group("player"):
		return
	hb.receive_hit(damage, self, global_position)
	_go_dormant()

func _go_dormant() -> void:
	_active = false
	sprite.texture = TEX_DORMANT
	collision.set_deferred("disabled", true)
	rearm_timer.start(dormant_seconds)

func _on_rearm() -> void:
	_active = true
	sprite.texture = TEX_ACTIVE
	collision.set_deferred("disabled", false)

class_name Door
extends Area2D

signal used

@export var locked_color: Color = Color(0.3, 0.3, 0.4, 1)
@export var unlocked_color: Color = Color(1, 0.85, 0.4, 1)

@onready var sprite: Sprite2D = $Sprite2D
@onready var blocker: StaticBody2D = $Blocker

var _locked: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	lock()

func lock() -> void:
	_locked = true
	if blocker:
		blocker.process_mode = Node.PROCESS_MODE_INHERIT
		for c in blocker.get_children():
			if c is CollisionShape2D:
				c.set_deferred("disabled", false)
	if sprite:
		sprite.modulate = locked_color

func unlock() -> void:
	if not _locked:
		return
	_locked = false
	if blocker:
		for c in blocker.get_children():
			if c is CollisionShape2D:
				c.set_deferred("disabled", true)
	if sprite:
		sprite.modulate = unlocked_color
	Audio.play("door_unlock", 0.05, -2.0)

func _on_body_entered(body: Node) -> void:
	if _locked:
		return
	if body.is_in_group("player"):
		used.emit()
		DungeonManager.door_used()

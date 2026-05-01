class_name SlowZone
extends Area2D

# 4-tile margin at each world edge that halves player speed while
# overlapping. Soft-wall — kiting away from the edge always feels
# like the right play. Stacks multiplicatively if zones overlap so
# corners feel slightly stickier than edges.

@export var speed_multiplier: float = 0.5


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	monitoring = true
	monitorable = false


func _on_body_entered(body: Node) -> void:
	if body is Player:
		(body as Player).move_speed_mul *= speed_multiplier


func _on_body_exited(body: Node) -> void:
	if body is Player:
		var p: Player = body as Player
		if absf(speed_multiplier) > 0.001:
			p.move_speed_mul /= speed_multiplier
		else:
			p.move_speed_mul = 1.0

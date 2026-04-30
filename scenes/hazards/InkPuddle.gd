class_name InkPuddle
extends Area2D

# Persistent damaging area left behind by Ink Spitter projectiles. While the
# player overlaps the puddle, deals `damage_per_tick` every `tick_interval`
# seconds. The sprite fades over the puddle's lifetime as a wear-out cue.

@export var damage_per_tick: int = 1
@export var tick_interval: float = 0.7
@export var lifetime: float = 4.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var tick_timer: Timer = $TickTimer

var _player_hurtbox: HurtboxComponent = null


func _ready() -> void:
	z_index = 0
	collision_layer = 0
	collision_mask = 8
	lifetime_timer.one_shot = true
	lifetime_timer.wait_time = lifetime
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()
	tick_timer.wait_time = tick_interval
	tick_timer.timeout.connect(_on_tick)
	tick_timer.start()
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	var tw: Tween = create_tween()
	tw.tween_property(sprite, "modulate:a", 0.35, lifetime).set_ease(Tween.EASE_IN)


func _on_area_entered(area: Area2D) -> void:
	if not (area is HurtboxComponent):
		return
	var hb: HurtboxComponent = area as HurtboxComponent
	var owner_node: Node = hb.get_parent()
	if owner_node != null and owner_node.is_in_group("player"):
		_player_hurtbox = hb


func _on_area_exited(area: Area2D) -> void:
	if area == _player_hurtbox:
		_player_hurtbox = null


func _on_tick() -> void:
	if _player_hurtbox != null and is_instance_valid(_player_hurtbox):
		_player_hurtbox.receive_hit(damage_per_tick, self, global_position)

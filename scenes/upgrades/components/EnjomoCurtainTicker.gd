class_name EnjomoCurtainTicker
extends AutocastTicker

# Ace "Enjomo Curtain" — Rare, UNIQUE.
# Every 10s, spawns a stationary fire wall in player's facing direction
# for 4s. Damages enemies that pass through every 0.3s.

const CURTAIN_SCRIPT: Script = preload("res://scenes/upgrades/components/EnjomoCurtain.gd")

@export var curtain_duration: float = 4.0
@export var curtain_length: float = 120.0
@export var curtain_height: float = 24.0
@export var curtain_offset: float = 40.0
@export var tick_damage_mult: float = 0.7
@export var tick_seconds: float = 0.3


func _ready() -> void:
	tick_interval = 10.0
	super._ready()


func _do_cast() -> void:
	var p: Player = get_player_cached()
	if p == null:
		return
	var dir: Vector2 = p.move_input.normalized() if p.move_input.length_squared() > 0.05 else Vector2.RIGHT
	var curtain: Node2D = Node2D.new()
	curtain.set_script(CURTAIN_SCRIPT)
	curtain.rotation = dir.angle()
	if curtain.has_method("configure"):
		var dmg: int = max(1, int(round(float(p.stats.damage) * tick_damage_mult)))
		curtain.call("configure", dmg, curtain_length, curtain_height, curtain_duration, tick_seconds)
	var host: Node = p.get_parent() if p.get_parent() != null else get_tree().current_scene
	host.add_child(curtain)
	curtain.global_position = p.global_position + dir * curtain_offset
	Audio.play("ability_burst", 0.4, -4.0)

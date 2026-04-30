extends Node

signal run_started
signal run_ended(victory: bool)
signal room_changed(index: int, total: int)

var room_list: Array[PackedScene] = []
var current_index: int = -1
var current_room: Node = null
var player: Node = null
var run_active: bool = false

func start_run(rooms: Array[PackedScene], spawn_player: Node = null) -> void:
	room_list = rooms
	current_index = -1
	player = spawn_player
	run_active = true
	run_started.emit()
	advance_room()

func advance_room() -> void:
	if not run_active:
		return
	current_index += 1
	if current_index >= room_list.size():
		end_run(true)
		return
	_load_room(room_list[current_index])
	room_changed.emit(current_index, room_list.size())

func _load_room(scene: PackedScene) -> void:
	if current_room != null and is_instance_valid(current_room):
		current_room.queue_free()
	current_room = scene.instantiate()
	get_tree().current_scene.add_child(current_room)
	if current_room.has_signal("cleared"):
		current_room.connect("cleared", _on_room_cleared, CONNECT_ONE_SHOT)
	if current_room.has_method("enter_room") and player != null:
		current_room.call("enter_room", player)
	Events.room_entered.emit(current_room)

func _on_room_cleared() -> void:
	Events.room_cleared.emit(current_room)

func door_used() -> void:
	advance_room()

func end_run(victory: bool) -> void:
	run_active = false
	run_ended.emit(victory)

func is_boss_room(index: int) -> bool:
	return (index + 1) % 5 == 0

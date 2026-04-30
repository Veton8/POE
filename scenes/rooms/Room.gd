class_name Room
extends Node2D

signal cleared

const ROOM_TILES_W := 30
const ROOM_TILES_H := 17
const SOURCE_FLOOR_A := 0
const SOURCE_FLOOR_B := 1
const SOURCE_WALL := 2
const TILE_SIZE := 16
const DOOR_GAPS: Array[Vector2i] = [Vector2i(14, 0), Vector2i(15, 0)]
const THORN_VINE_SCENE: PackedScene = preload("res://scenes/hazards/ThornVine.tscn")

@export var room_data: RoomData
@onready var spawner: WaveSpawner = $WaveSpawner
@onready var spawn_points: Node = $SpawnPoints
@onready var doors: Node = $Doors
@onready var player_spawn: Marker2D = $PlayerSpawn

var room_active: bool = false
var _is_boss_room: bool = false
var _boss_instance: Node2D = null

func _ready() -> void:
	_paint_default_tiles()
	if spawner != null:
		spawner.all_waves_finished.connect(_on_all_waves_finished)
	_lock_doors()
	if room_data != null and room_data.is_boss:
		_is_boss_room = true

func _paint_default_tiles() -> void:
	var floor_layer: TileMapLayer = get_node_or_null("Floor") as TileMapLayer
	var wall_layer: TileMapLayer = get_node_or_null("Walls") as TileMapLayer
	if floor_layer == null or wall_layer == null:
		return
	if floor_layer.get_used_cells().size() > 0 or wall_layer.get_used_cells().size() > 0:
		return
	if room_data != null and room_data.layout_text.strip_edges() != "":
		_paint_from_layout(room_data.layout_text, floor_layer, wall_layer)
	else:
		_paint_default_border(floor_layer, wall_layer)
	if room_data != null:
		_spawn_hazards()

func _paint_default_border(floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	for y in ROOM_TILES_H:
		for x in ROOM_TILES_W:
			var pos := Vector2i(x, y)
			var is_wall: bool = x == 0 or x == ROOM_TILES_W - 1 or y == 0 or y == ROOM_TILES_H - 1
			if is_wall and not (pos in DOOR_GAPS):
				wall_layer.set_cell(pos, SOURCE_WALL, Vector2i(0, 0))
			elif not is_wall:
				var src: int = SOURCE_FLOOR_A if (x * 7 + y * 13) % 5 != 0 else SOURCE_FLOOR_B
				floor_layer.set_cell(pos, src, Vector2i(0, 0))

func _paint_from_layout(text: String, floor_layer: TileMapLayer, wall_layer: TileMapLayer) -> void:
	var raw_lines: PackedStringArray = text.split("\n")
	var lines: Array[String] = []
	for l in raw_lines:
		var line: String = l
		if line.length() > 0 and line[line.length() - 1] == "\r":
			line = line.substr(0, line.length() - 1)
		lines.append(line)
	while lines.size() > 0 and lines[0].strip_edges() == "":
		lines.remove_at(0)
	while lines.size() > 0 and lines[lines.size() - 1].strip_edges() == "":
		lines.remove_at(lines.size() - 1)
	for y in lines.size():
		if y >= ROOM_TILES_H:
			break
		var line: String = lines[y]
		for x in line.length():
			if x >= ROOM_TILES_W:
				break
			var pos := Vector2i(x, y)
			var c: String = line.substr(x, 1)
			match c:
				".":
					floor_layer.set_cell(pos, SOURCE_FLOOR_A, Vector2i(0, 0))
				",":
					floor_layer.set_cell(pos, SOURCE_FLOOR_B, Vector2i(0, 0))
				"#":
					wall_layer.set_cell(pos, SOURCE_WALL, Vector2i(0, 0))
				_:
					pass

func _spawn_hazards() -> void:
	for tile in room_data.thorn_vines:
		var v: Node2D = THORN_VINE_SCENE.instantiate() as Node2D
		if v == null:
			continue
		add_child(v)
		v.position = Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2, tile.y * TILE_SIZE + TILE_SIZE / 2)

func enter_room(p: Node) -> void:
	if player_spawn != null and p is Node2D:
		(p as Node2D).global_position = player_spawn.global_position
	room_active = true
	if _is_boss_room:
		_start_boss()
	elif room_data != null and room_data.is_reward:
		_unlock_doors()
		cleared.emit()
	elif spawner != null and room_data != null:
		spawner.start(room_data.waves, spawn_points.get_children())

func _start_boss() -> void:
	if room_data == null or room_data.boss_scene == null:
		_unlock_doors()
		cleared.emit()
		return
	var boss: Node2D = room_data.boss_scene.instantiate() as Node2D
	if boss == null:
		_unlock_doors()
		cleared.emit()
		return
	_boss_instance = boss
	add_child(boss)
	if spawn_points != null and spawn_points.get_child_count() > 0:
		var sp: Node2D = spawn_points.get_child(0) as Node2D
		if sp != null:
			boss.global_position = sp.global_position
	if boss.has_signal("died"):
		boss.connect("died", _on_boss_died)
	var bar: Node = get_tree().get_first_node_in_group("boss_health_bar")
	if bar != null and bar.has_method("bind"):
		bar.call("bind", boss)

func _on_boss_died() -> void:
	_unlock_doors()
	cleared.emit()

func _on_all_waves_finished() -> void:
	_unlock_doors()
	cleared.emit()

func _lock_doors() -> void:
	if doors == null:
		return
	for d in doors.get_children():
		if d.has_method("lock"):
			d.call("lock")

func _unlock_doors() -> void:
	if doors == null:
		return
	for d in doors.get_children():
		if d.has_method("unlock"):
			d.call("unlock")

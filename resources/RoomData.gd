class_name RoomData
extends Resource

@export var waves: Array[WaveData]
@export var is_boss: bool = false
@export var boss_scene: PackedScene
@export var is_reward: bool = false

# Optional 30x17 ASCII grid for hand-authored layouts.
# Characters: '.' = floor, ',' = floor variant, '#' = wall, ' ' = no tile (door gap or void).
# When empty, Room.gd falls back to the procedural rectangular border.
@export_multiline var layout_text: String = ""

# Tile-coordinate positions where ThornVine hazards should be instanced at room load.
@export var thorn_vines: Array[Vector2i] = []

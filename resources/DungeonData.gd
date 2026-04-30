class_name DungeonData
extends Resource

# Per-dungeon manifest. The HubRoom dungeon-select overlay lists every
# DungeonData resource it knows about; the run-scene (Main.gd) reads the
# selected dungeon's `room_scenes` to drive DungeonManager.

@export var dungeon_id: String = ""
@export var display_name: String = "Unnamed Dungeon"
@export_multiline var lore: String = ""
@export var room_scenes: Array[PackedScene] = []
@export var theme_color: Color = Color(0.15, 0.12, 0.18, 1)
@export_range(1, 5) var difficulty_stars: int = 1
@export var recommended_archetype: String = ""
@export var signature_gimmick: String = ""
# How the player gets access to this dungeon. Empty string == unlocked by
# default. "complete:<dungeon_id>" == clearing that dungeon's room 10
# unlocks this one. "gems:<n>" == pay gems to unlock.
@export var unlock_requirement: String = ""
@export var icon: Texture2D

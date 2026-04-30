class_name GearItem
extends Resource

# Static template for a piece of gear. Inventory entries are stored as
# Dictionary snapshots derived from these templates so the save file
# remains plain JSON.

@export var item_id: String = ""
@export var item_name: String = "Unnamed"
@export var type: String = "weapon"  # "weapon", "armor", "trinket", "pet"
@export_range(0, 4) var rarity: int = 0  # 0=common .. 4=legendary
@export var hp_bonus: int = 0
@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var crit_bonus: float = 0.0
@export var icon: Texture2D
@export var description: String = ""

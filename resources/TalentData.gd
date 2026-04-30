class_name TalentData
extends Resource

# Talent card resource. Reserved for the future Talent Grid screen.

@export var talent_id: String = ""
@export var talent_name: String = "Unnamed Talent"
@export var description: String = ""
@export var icon: Texture2D
@export_range(0, 4) var rarity: int = 0
@export var grasp_cost: int = 1  # how many slots of grasp_budget this talent occupies when active
@export var prerequisite_ids: Array[String] = []
@export var hp_bonus: int = 0
@export var damage_bonus: float = 0.0
@export var speed_bonus: float = 0.0
@export var crit_bonus: float = 0.0
@export var fire_rate_bonus: float = 0.0

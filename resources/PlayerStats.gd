class_name PlayerStats
extends Resource

@export var character_name: String = "Knight"
@export var max_hp: int = 6
@export var move_speed: float = 90.0
@export var damage: int = 1
@export var fire_rate: float = 4.0  # shots per second
@export var bullet_speed: float = 220.0
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 1.5
@export var detection_radius: float = 120.0
@export var portrait: Texture2D

# Optional per-character SpriteFrames for the in-world AnimatedSprite2D.
# Expected animations: "idle" (always required) and "walk" (optional).
# When null, Player falls back to building a single-frame "idle" animation
# from `portrait` so unconverted characters keep working unchanged.
@export var frames: SpriteFrames

# Optional per-character bullet override. If null, the Player falls back to its
# scene-baked default bullet. Projectile on-hit effects (burn, pull, pierce)
# live on the bullet scene itself.
@export var bullet_scene: PackedScene

# Optional per-character abilities. Each is a PackedScene whose root is an
# Ability subclass. If null, the Player keeps its baked Dash/Burst/Heal in
# that slot. HUD binds to children named AbilityQ / AbilityW / AbilityE.
@export var ability_q: PackedScene
@export var ability_w: PackedScene
@export var ability_e: PackedScene

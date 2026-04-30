class_name UpgradeData
extends Resource

# The central upgrade definition. Drop a .tres of this type under
# scenes/upgrades/catalog/<bucket>/ and UpgradeRegistry will pick it up.

enum Category { BULLET, AUTOCAST, DEFENSIVE, MOVEMENT, STAT, ANIME, ABILITY_MOD }
enum Rarity { COMMON, UNCOMMON, RARE, EPIC, LEGENDARY }
enum StackMode { LINEAR, HYPERBOLIC, CAPPED, UNIQUE, EVOLVING }

@export var id: StringName = &""
@export var display_name: String = ""
@export_multiline var effect_text: String = ""
@export_multiline var flavor_text: String = ""
@export var category: Category = Category.STAT
@export var rarity: Rarity = Rarity.COMMON
@export var stack_mode: StackMode = StackMode.CAPPED
@export var max_stacks: int = 4
@export var weight: float = 1.0

# Tagging — drives synergy detection AND hero-flavor weighting.
@export var tags: Array[StringName] = []
@export var hero_affinity: Array[StringName] = []

# Mechanical payload — at least ONE of these three is populated.
@export var stat_modifiers: Array[UpgradeStatModifier] = []
@export var component_to_attach: PackedScene = null
@export var apply_callback: StringName = &""

# Synergy & evolution hooks.
@export var requires_tags: Array[StringName] = []
@export var requires_ids: Array[StringName] = []
@export var evolves_into: StringName = &""
@export var consumes_on_evolve: Array[StringName] = []

# Cursed/negative hook (v1 ships with these set false/empty).
@export var tradeoff: bool = false
@export var negative_effects: Array[UpgradeStatModifier] = []

# Visuals — programmatic only.
@export var icon_shape: StringName = &"circle"
@export var icon_color_primary: Color = Color.WHITE
@export var icon_color_accent: Color = Color.BLACK

class_name UpgradeStatModifier
extends Resource

# A single stat delta or callback reference attached to an UpgradeData.
# stat_path is a NodePath relative to the Player (e.g. "stats:damage" — uses
# colon to access the PlayerStats sub-resource property).

enum Op { ADD, MULT, SET, ADD_PER_STACK_LINEAR, ADD_PER_STACK_HYPERBOLIC }

@export var stat_path: NodePath = NodePath("")
@export var op: Op = Op.ADD
@export var value: float = 0.0
@export var hyperbolic_coefficient: float = 0.15

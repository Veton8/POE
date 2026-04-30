class_name BossHealthBar
extends CanvasLayer

@onready var bar: TextureProgressBar = $Bar
@onready var name_label: Label = $NameLabel
@onready var phase_label: Label = $PhaseLabel

var _bound_boss: Boss = null

func _ready() -> void:
	visible = false

func bind(boss_node: Node) -> void:
	var boss: Boss = boss_node as Boss
	if boss == null:
		return
	_bound_boss = boss
	visible = true
	bar.max_value = boss.health.max_hp
	bar.value = boss.health.current
	if boss.stats != null:
		name_label.text = boss.stats.enemy_name
	boss.health.health_changed.connect(_on_health_changed)
	boss.phase_changed.connect(_on_phase_changed)
	boss.died.connect(_on_died)

func _on_health_changed(current: int, _max_hp: int) -> void:
	var tw: Tween = create_tween()
	tw.tween_property(bar, "value", current, 0.2)

func _on_phase_changed(phase: int) -> void:
	phase_label.text = "PHASE %d" % phase
	phase_label.show()
	var tw: Tween = create_tween()
	tw.tween_property(phase_label, "modulate:a", 0.0, 1.5).from(1.0)

func _on_died() -> void:
	visible = false

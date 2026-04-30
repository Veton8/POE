extends Control

# Post-run results card. Reads GameState.run_stats, applies rewards,
# animates a count-up, and offers Continue / Try Again buttons.

const COIN_ICON := preload("res://art/ui/coin_icon.svg")
const GEM_ICON := preload("res://art/ui/gem_icon.svg")
const SP_ICON := preload("res://art/ui/sp_icon.svg")
const STAR_FULL := preload("res://art/ui/star_full.svg")
const STAR_EMPTY := preload("res://art/ui/star_empty.svg")

@onready var bg: ColorRect = $Background
@onready var banner_label: Label = $Panel/BannerLabel
@onready var subtitle_label: Label = $Panel/SubtitleLabel
@onready var stars_row: HBoxContainer = $Panel/StarsRow
@onready var coin_label: Label = $Panel/StatsBox/CoinRow/Value
@onready var sp_label: Label = $Panel/StatsBox/SPRow/Value
@onready var gem_label: Label = $Panel/StatsBox/GemRow/Value
@onready var items_label: Label = $Panel/ItemsHeader
@onready var items_row: HBoxContainer = $Panel/ItemsRow
@onready var continue_button: Button = $Panel/ButtonRow/ContinueButton
@onready var try_again_button: Button = $Panel/ButtonRow/TryAgainButton

var _summary: Dictionary = {}


func _ready() -> void:
	_collect_rewards()
	_setup_banner()
	_animate_counters()
	continue_button.pressed.connect(_on_continue)
	try_again_button.pressed.connect(_on_try_again)


func _collect_rewards() -> void:
	# GameState.grant_run_rewards already credits currency + items + saves
	_summary = GameState.grant_run_rewards(GameState.run_stats)


func _setup_banner() -> void:
	var victory: bool = bool(GameState.run_stats.get("victory", false))
	if victory:
		banner_label.text = "VICTORY!"
		banner_label.add_theme_color_override("font_color", Color("#4CAF50"))
	else:
		banner_label.text = "DEFEATED"
		banner_label.add_theme_color_override("font_color", Color("#DC2626"))
	var rooms: int = int(GameState.run_stats.get("rooms_cleared", 0))
	var elapsed_ms: int = Time.get_ticks_msec() - int(GameState.run_stats.get("start_time_ms", Time.get_ticks_msec()))
	var seconds: int = elapsed_ms / 1000
	subtitle_label.text = "Rooms: %d   Time: %ds" % [rooms, seconds]
	# Performance stars
	var hits: int = int(GameState.run_stats.get("hits_taken", 0))
	var stars: int = 0
	if victory:
		stars = 1
		if hits < 3:
			stars = 2
		if hits == 0:
			stars = 3
	for i: int in 3:
		var tex: TextureRect = stars_row.get_child(i) as TextureRect
		if tex == null:
			continue
		tex.texture = STAR_FULL if i < stars else STAR_EMPTY
	# Items dropped
	var dropped: Array = _summary.get("items_dropped", []) as Array
	if dropped.is_empty():
		items_label.visible = false
		items_row.visible = false
	else:
		items_label.visible = true
		items_row.visible = true
		_populate_items(dropped)


func _populate_items(dropped: Array) -> void:
	for c: Node in items_row.get_children():
		c.queue_free()
	for entry: Variant in dropped:
		if not (entry is Dictionary):
			continue
		var item: Dictionary = entry as Dictionary
		var box: VBoxContainer = VBoxContainer.new()
		box.custom_minimum_size = Vector2(60, 36)
		var bg_panel: ColorRect = ColorRect.new()
		bg_panel.custom_minimum_size = Vector2(20, 20)
		var rarity: int = int(item.get("rarity", 0))
		bg_panel.color = GameState.RARITY_COLORS[clampi(rarity, 0, 4)]
		bg_panel.modulate = Color(1, 1, 1, 0.4)
		box.add_child(bg_panel)
		var icon_path: String = str(item.get("icon_path", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var icon_tex: Texture2D = load(icon_path) as Texture2D
			var ir: TextureRect = TextureRect.new()
			ir.texture = icon_tex
			ir.custom_minimum_size = Vector2(20, 20)
			ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ir.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			ir.position = Vector2(0, 0)
			bg_panel.add_child(ir)
		var name_lbl: Label = Label.new()
		name_lbl.text = str(item.get("name", "?"))
		name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_lbl.add_theme_color_override("font_color", GameState.RARITY_COLORS[clampi(rarity, 0, 4)])
		name_lbl.custom_minimum_size = Vector2(60, 12)
		box.add_child(name_lbl)
		items_row.add_child(box)


func _animate_counters() -> void:
	var coins_target: int = int(_summary.get("coins_earned", 0))
	var sp_target: int = int(_summary.get("skill_points_earned", 0))
	var gems_target: int = int(_summary.get("gems_earned", 0))
	coin_label.text = "0"
	sp_label.text = "0"
	gem_label.text = "0"
	var tween: Tween = create_tween().set_parallel(true)
	tween.tween_method(_set_coin_label, 0, coins_target, 0.8)
	tween.tween_method(_set_sp_label, 0, sp_target, 0.6)
	tween.tween_method(_set_gem_label, 0, gems_target, 0.5)


func _set_coin_label(value: int) -> void:
	coin_label.text = str(value)


func _set_sp_label(value: int) -> void:
	sp_label.text = str(value)


func _set_gem_label(value: int) -> void:
	gem_label.text = str(value)


func _on_continue() -> void:
	# Fade out, then go to hub
	var tween: Tween = create_tween()
	tween.tween_property(bg, "color", Color(0, 0, 0, 1), 0.3)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub/HubRoom.tscn"))


func _on_try_again() -> void:
	GameState.run_stats = {
		"enemies_killed": 0,
		"bosses_killed": 0,
		"rooms_cleared": 0,
		"coins_collected": 0,
		"hits_taken": 0,
		"start_time_ms": Time.get_ticks_msec(),
	}
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

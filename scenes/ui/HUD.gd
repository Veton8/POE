class_name HUD
extends CanvasLayer

const HEART_FULL := preload("res://art/ui/heart_full.svg")
const HEART_EMPTY := preload("res://art/ui/heart_empty.svg")

@onready var hearts: HBoxContainer = $Margin/HeartsRow
@onready var ability_q: AbilityButton = $AbilityQ
@onready var ability_w: AbilityButton = $AbilityW
@onready var ability_e: AbilityButton = $AbilityE
@onready var room_label: Label = $RoomLabel
@onready var pause_button: Button = $PauseButton
@onready var coin_counter: Label = $CoinCounter/Label
@onready var pause_overlay: Control = $PauseOverlay
@onready var resume_button: Button = $PauseOverlay/Panel/ResumeButton
@onready var quit_button: Button = $PauseOverlay/Panel/QuitButton


func _ready() -> void:
	DungeonManager.room_changed.connect(_on_room_changed)
	pause_button.pressed.connect(_toggle_pause)
	resume_button.pressed.connect(_toggle_pause)
	quit_button.pressed.connect(_quit_run)
	pause_overlay.visible = false
	_refresh_run_coin_label()


func bind_player(p: Player) -> void:
	if p == null:
		return
	p.health_changed.connect(_update_hearts)
	_update_hearts(p.health.current, p.health.max_hp)
	var abilities: Node = p.get_node_or_null("Abilities")
	if abilities == null:
		return
	var q: Ability = abilities.get_node_or_null("AbilityQ") as Ability
	var w: Ability = abilities.get_node_or_null("AbilityW") as Ability
	var e: Ability = abilities.get_node_or_null("AbilityE") as Ability
	# Legacy fallback for any save/scene that still uses class-named nodes
	if q == null:
		q = abilities.get_node_or_null("DashAbility") as Ability
	if w == null:
		w = abilities.get_node_or_null("AoEBurstAbility") as Ability
	if e == null:
		e = abilities.get_node_or_null("HealAbility") as Ability
	if q != null: ability_q.bind(q)
	if w != null: ability_w.bind(w)
	if e != null: ability_e.bind(e)


func _on_room_changed(idx: int, total: int) -> void:
	room_label.text = "Room %d / %d" % [idx + 1, total]


func _update_hearts(current: int, max_hp: int) -> void:
	for c in hearts.get_children():
		c.queue_free()
	for i in max_hp:
		var tex_rect := TextureRect.new()
		tex_rect.texture = HEART_FULL if i < current else HEART_EMPTY
		tex_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		tex_rect.custom_minimum_size = Vector2(10, 10)
		hearts.add_child(tex_rect)


func _refresh_run_coin_label() -> void:
	if coin_counter == null:
		return
	# Use enemy/boss/room kills to estimate coins this run (matches reward formula)
	var coins: int = _estimate_run_coins()
	coin_counter.text = "+%d" % coins


func _estimate_run_coins() -> int:
	var enemies: int = int(GameState.run_stats.get("enemies_killed", 0))
	var bosses: int = int(GameState.run_stats.get("bosses_killed", 0))
	var rooms: int = int(GameState.run_stats.get("rooms_cleared", 0))
	return enemies * 10 + bosses * 50 + rooms * 25


func update_kill_label() -> void:
	_refresh_run_coin_label()


func _process(_delta: float) -> void:
	# Cheap polling — totals only update on a few infrequent events but we don't have
	# wired signals everywhere, so refresh once per frame.
	_refresh_run_coin_label()


func _toggle_pause() -> void:
	pause_overlay.visible = not pause_overlay.visible
	get_tree().paused = pause_overlay.visible


func _quit_run() -> void:
	get_tree().paused = false
	pause_overlay.visible = false
	GameState.run_stats["victory"] = false
	get_tree().change_scene_to_file("res://scenes/hub/RewardScreen.tscn")

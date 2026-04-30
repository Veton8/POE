extends CanvasLayer

# 3-card upgrade choice overlay. Pauses the game on present(); on selection
# (or skip), unpauses and queue_frees itself.

signal closed

const UPGRADE_CARD_SCENE: PackedScene = preload("res://scenes/upgrades/UpgradeCard.tscn")

var _picks: Array[UpgradeData] = []
var _cards: Array[UpgradeCard] = []
var _reroll_uses: int = 0
var _hero_id: StringName = &""

var _backdrop: ColorRect = null
var _root_panel: Panel = null
var _header_label: Label = null
var _skip_button: Button = null
var _reroll_button: Button = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	_build_ui()
	get_tree().paused = true


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0, 0, 0, 0.6)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.modulate.a = 0.0
	add_child(_backdrop)
	# Backdrop fade-in 200ms ease-out
	var tw: Tween = create_tween()
	tw.tween_property(_backdrop, "modulate:a", 1.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	_root_panel = Panel.new()
	_root_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: StyleBoxFlat = StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0)
	_root_panel.add_theme_stylebox_override("panel", bg)
	_root_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_panel)

	_header_label = Label.new()
	_header_label.text = "CHOOSE YOUR POWER"
	_header_label.size = Vector2(480, 24)
	_header_label.position = Vector2(0, 24)
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_header_label.add_theme_font_size_override("font_size", 14)
	_root_panel.add_child(_header_label)

	var row: HBoxContainer = HBoxContainer.new()
	row.position = Vector2(24, 60)
	row.size = Vector2(432, 160)
	row.add_theme_constant_override("separation", 24)
	_root_panel.add_child(row)
	for i: int in 3:
		var card: UpgradeCard = UPGRADE_CARD_SCENE.instantiate() as UpgradeCard
		if card == null:
			continue
		card.custom_minimum_size = Vector2(128, 160)
		row.add_child(card)
		var idx: int = i
		card.selected.connect(func() -> void: _on_card_selected(idx))
		card.hovered.connect(func() -> void: _on_card_hovered(idx))
		_cards.append(card)

	var footer: HBoxContainer = HBoxContainer.new()
	footer.position = Vector2(0, 232)
	footer.size = Vector2(480, 22)
	footer.alignment = BoxContainer.ALIGNMENT_CENTER
	footer.add_theme_constant_override("separation", 32)
	_root_panel.add_child(footer)

	_skip_button = Button.new()
	_skip_button.text = "Skip (+25 coins)"
	_skip_button.pressed.connect(_on_skip)
	footer.add_child(_skip_button)

	_reroll_button = Button.new()
	_reroll_button.text = "Reroll (10 gems)"
	_reroll_button.pressed.connect(_on_reroll)
	footer.add_child(_reroll_button)


func present(picks: Array[UpgradeData]) -> void:
	_hero_id = StringName(GameState.selected_character)
	_picks = picks
	_refresh_skip_label()
	_refresh_reroll_label()
	_refresh_cards()
	# Track every offered pick (passive codex unlock — mark seen even if skipped)
	for u: UpgradeData in picks:
		if u != null and u.id != &"":
			GameState.save_codex_seen(u.id)
	# Stagger flip-in 60ms apart
	for i: int in _cards.size():
		var card: UpgradeCard = _cards[i]
		if i < _picks.size() and card.has_method("play_flip_in"):
			card.play_flip_in(float(i) * 0.06)
	if _cards.size() > 0:
		_cards[0].grab_card_focus()
	Audio.play("door_unlock", 0.05, -2.0)


func _refresh_cards() -> void:
	for i: int in _cards.size():
		var card: UpgradeCard = _cards[i]
		if i < _picks.size():
			card.visible = true
			card.bind(_picks[i])
		else:
			card.visible = false


func _refresh_skip_label() -> void:
	if _skip_button == null:
		return
	var reward: int = UpgradeManager.skip_reward()
	_skip_button.text = "Skip (+%d coins)" % reward


func _refresh_reroll_label() -> void:
	if _reroll_button == null:
		return
	var cost: int = UpgradeManager.reroll_cost(_reroll_uses)
	_reroll_button.text = "Reroll (%d gems)" % cost
	_reroll_button.disabled = GameState.gems < cost


func _on_card_selected(index: int) -> void:
	if index < 0 or index >= _picks.size():
		return
	var picked: UpgradeData = _picks[index]
	UpgradeManager.apply(picked)
	Audio.play("ability_burst", 0.05, -2.0)
	_close()


func _on_card_hovered(_index: int) -> void:
	Audio.play("footstep", 0.1, -8.0)


func _on_skip() -> void:
	GameState.coins += UpgradeManager.skip_reward()
	GameState.save()
	_close()


func _on_reroll() -> void:
	var cost: int = UpgradeManager.reroll_cost(_reroll_uses)
	if GameState.gems < cost:
		return
	GameState.gems -= cost
	GameState.save()
	_reroll_uses += 1
	_picks = UpgradeManager.reroll(_reroll_uses, _hero_id)
	_refresh_cards()
	_refresh_reroll_label()
	for u: UpgradeData in _picks:
		if u != null and u.id != &"":
			GameState.save_codex_seen(u.id)
	for i: int in _cards.size():
		var card: UpgradeCard = _cards[i]
		if i < _picks.size() and card.has_method("play_flip_in"):
			card.play_flip_in(float(i) * 0.06)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ability_q") and _picks.size() >= 1:
		_on_card_selected(0)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_w") and _picks.size() >= 2:
		_on_card_selected(1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ability_e") and _picks.size() >= 3:
		_on_card_selected(2)
		get_viewport().set_input_as_handled()


func _close() -> void:
	get_tree().paused = false
	closed.emit()
	queue_free()

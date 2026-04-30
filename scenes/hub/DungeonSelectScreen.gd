extends Control

# Overlay shown when the player interacts with the hub door. Lists every
# DungeonData manifest GameState knows about, locked entries are greyed
# out. Picking one updates GameState.selected_dungeon and emits `chosen`
# so the HubRoom can kick off the run.

signal closed
signal chosen(dungeon_id: String)

const STAR_FULL_TEX: Texture2D = preload("res://art/ui/star_full.svg")
const STAR_EMPTY_TEX: Texture2D = preload("res://art/ui/star_empty.svg")

@onready var bg: ColorRect = $Background
@onready var card_row: HBoxContainer = $Panel/CardRow
@onready var back_button: Button = $Panel/BackButton
@onready var play_button: Button = $Panel/PlayButton
@onready var subtitle: Label = $Panel/Subtitle

var _selected_id: String = ""


func _ready() -> void:
	back_button.pressed.connect(func() -> void: closed.emit())
	play_button.pressed.connect(_on_play)
	_selected_id = GameState.selected_dungeon
	_build_cards()
	_refresh_play_button()


func _build_cards() -> void:
	for c: Node in card_row.get_children():
		c.queue_free()
	for dd: DungeonData in GameState.get_all_dungeons_in_order():
		var card: Button = _make_card(dd)
		card_row.add_child(card)


func _make_card(dd: DungeonData) -> Button:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(132, 168)
	card.toggle_mode = true
	card.flat = true
	card.focus_mode = Control.FOCUS_ALL

	var unlocked: bool = GameState.is_dungeon_unlocked(dd.dungeon_id)

	var bg_rect: ColorRect = ColorRect.new()
	bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = dd.theme_color
	bg_rect.modulate = Color(1, 1, 1, 0.65 if unlocked else 0.25)
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg_rect)

	var border: ColorRect = ColorRect.new()
	border.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	border.color = Color(0.09, 0.13, 0.24, 1)
	border.show_behind_parent = true
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(border)

	var name_lbl: Label = Label.new()
	name_lbl.text = dd.display_name
	name_lbl.position = Vector2(4, 6)
	name_lbl.size = Vector2(124, 14)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_color_override("font_color", Color("#FEF3C7") if unlocked else Color("#64748B"))
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(name_lbl)

	var stars: HBoxContainer = HBoxContainer.new()
	stars.position = Vector2(38, 24)
	stars.size = Vector2(56, 12)
	stars.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i: int in 5:
		var star: TextureRect = TextureRect.new()
		star.texture = STAR_FULL_TEX if i < dd.difficulty_stars else STAR_EMPTY_TEX
		star.custom_minimum_size = Vector2(10, 10)
		star.modulate = Color(1, 1, 1, 1) if unlocked else Color(0.4, 0.4, 0.45, 1)
		stars.add_child(star)
	card.add_child(stars)

	var gimmick: Label = Label.new()
	gimmick.text = dd.signature_gimmick
	gimmick.position = Vector2(6, 42)
	gimmick.size = Vector2(120, 36)
	gimmick.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	gimmick.add_theme_color_override("font_color", Color("#CBD5E1") if unlocked else Color("#475569"))
	gimmick.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(gimmick)

	var rec: Label = Label.new()
	rec.text = "Build: " + dd.recommended_archetype
	rec.position = Vector2(6, 90)
	rec.size = Vector2(120, 12)
	rec.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rec.add_theme_color_override("font_color", Color("#94A3B8") if unlocked else Color("#475569"))
	rec.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(rec)

	var status: Label = Label.new()
	if unlocked:
		status.text = "SELECTED" if dd.dungeon_id == _selected_id else "Available"
		status.add_theme_color_override("font_color", Color("#F4D03F") if dd.dungeon_id == _selected_id else Color("#4CAF50"))
	else:
		status.text = "LOCKED"
		status.add_theme_color_override("font_color", Color("#DC2626"))
	status.position = Vector2(6, 138)
	status.size = Vector2(120, 14)
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(status)

	if unlocked:
		card.pressed.connect(func() -> void: _on_card_picked(dd.dungeon_id))
	else:
		card.disabled = true

	return card


func _on_card_picked(dungeon_id: String) -> void:
	_selected_id = dungeon_id
	GameState.select_dungeon(dungeon_id)
	_build_cards()
	_refresh_play_button()


func _refresh_play_button() -> void:
	var dd: DungeonData = GameState.get_dungeon(_selected_id)
	if dd != null:
		subtitle.text = dd.lore
		play_button.disabled = not GameState.is_dungeon_unlocked(_selected_id)
	else:
		subtitle.text = ""
		play_button.disabled = true


func _on_play() -> void:
	if not GameState.is_dungeon_unlocked(_selected_id):
		return
	chosen.emit(_selected_id)

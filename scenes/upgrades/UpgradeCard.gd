class_name UpgradeCard
extends Panel

# Single upgrade card. Built programmatically — bind() with an UpgradeData
# and the card configures itself. Emits `selected` when clicked.

signal selected
signal hovered

const RARITY_COLORS: Array[Color] = [
	Color("#E8E4D8"),  # COMMON
	Color("#4FCC5A"),  # UNCOMMON
	Color("#3FA9F5"),  # RARE
	Color("#A335EE"),  # EPIC
	Color("#FF9D2B"),  # LEGENDARY
]
const RARITY_NAMES: Array[String] = ["COMMON", "UNCOMMON", "RARE", "EPIC", "LEGENDARY"]
const CARD_BG_COLORS: Array[Color] = [
	Color("#181820"),
	Color("#101810"),
	Color("#0E1420"),
	Color("#1A0E20"),
	Color("#201410"),
]

# 600ms anti-misclick window for legendary cards.
const LEGENDARY_LOCK_MS: int = 600

var upgrade: UpgradeData = null

var _border_panel: Panel = null
var _icon_renderer: UpgradeIconRenderer = null
var _name_label: Label = null
var _rarity_label: Label = null
var _effect_label: Label = null
var _flavor_label: Label = null
var _synergy_label: Label = null
var _hover_button: Button = null
var _bound_at_ms: int = 0
var _legendary_pulse_t: float = 0.0
var _is_legendary: bool = false


func _ready() -> void:
	custom_minimum_size = Vector2(128, 160)
	mouse_filter = Control.MOUSE_FILTER_PASS
	pivot_offset = Vector2(64, 80)  # for flip-in scale tween
	_build_layout()


func _build_layout() -> void:
	_border_panel = Panel.new()
	_border_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_border_panel.show_behind_parent = true
	add_child(_border_panel)
	var border_style: StyleBoxFlat = StyleBoxFlat.new()
	border_style.bg_color = Color("#181820")
	border_style.border_width_top = 4
	border_style.border_width_bottom = 4
	border_style.border_width_left = 4
	border_style.border_width_right = 4
	border_style.border_color = Color.WHITE
	_border_panel.add_theme_stylebox_override("panel", border_style)

	_icon_renderer = UpgradeIconRenderer.new()
	_icon_renderer.size = Vector2(40, 40)
	_icon_renderer.position = Vector2(44, 22)
	_icon_renderer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon_renderer)

	_rarity_label = Label.new()
	_rarity_label.size = Vector2(120, 12)
	_rarity_label.position = Vector2(4, 4)
	_rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_rarity_label.add_theme_font_size_override("font_size", 8)
	_rarity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_rarity_label)

	_synergy_label = Label.new()
	_synergy_label.size = Vector2(20, 12)
	_synergy_label.position = Vector2(4, 4)
	_synergy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_synergy_label.add_theme_font_size_override("font_size", 10)
	_synergy_label.add_theme_color_override("font_color", Color("#4FCC5A"))
	_synergy_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_synergy_label.text = ""
	add_child(_synergy_label)

	_name_label = Label.new()
	_name_label.size = Vector2(120, 14)
	_name_label.position = Vector2(4, 66)
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 10)
	_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_name_label)

	_effect_label = Label.new()
	_effect_label.size = Vector2(120, 44)
	_effect_label.position = Vector2(4, 84)
	_effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_effect_label.add_theme_font_size_override("font_size", 8)
	_effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_effect_label)

	_flavor_label = Label.new()
	_flavor_label.size = Vector2(120, 14)
	_flavor_label.position = Vector2(4, 142)
	_flavor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_flavor_label.add_theme_font_size_override("font_size", 7)
	_flavor_label.modulate = Color(1, 1, 1, 0.6)
	_flavor_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flavor_label)

	_hover_button = Button.new()
	_hover_button.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hover_button.flat = true
	_hover_button.focus_mode = Control.FOCUS_ALL
	_hover_button.pressed.connect(_on_pressed)
	_hover_button.mouse_entered.connect(_on_hover)
	_hover_button.focus_entered.connect(_on_hover)
	add_child(_hover_button)


func bind(u: UpgradeData) -> void:
	upgrade = u
	if not is_node_ready():
		await ready
	_refresh()
	_bound_at_ms = Time.get_ticks_msec()


func play_flip_in(delay_seconds: float) -> void:
	# Card scales from 0->1 on Y after a delay; staggered between cards.
	scale = Vector2(1.0, 0.0)
	modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_interval(delay_seconds)
	tw.parallel().tween_property(self, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 1.0, 0.16)


func _refresh() -> void:
	if upgrade == null:
		return
	var r_idx: int = clampi(int(upgrade.rarity), 0, RARITY_COLORS.size() - 1)
	var border_color: Color = RARITY_COLORS[r_idx]
	var bg_color: Color = CARD_BG_COLORS[r_idx]
	var style: StyleBoxFlat = _border_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style != null:
		style.bg_color = bg_color
		style.border_color = border_color
	_rarity_label.text = RARITY_NAMES[r_idx]
	_rarity_label.modulate = border_color
	_name_label.text = upgrade.display_name
	_effect_label.text = upgrade.effect_text
	_flavor_label.text = upgrade.flavor_text
	if _icon_renderer != null:
		_icon_renderer.configure(upgrade.icon_shape, upgrade.icon_color_primary, upgrade.icon_color_accent)
	_synergy_label.text = "[+]" if _has_synergy() else ""
	_is_legendary = (upgrade.rarity == UpgradeData.Rarity.LEGENDARY)
	_legendary_pulse_t = 0.0


func _process(delta: float) -> void:
	if not _is_legendary:
		return
	# Gold pulse loop on legendary cards — sin oscillates the border alpha.
	_legendary_pulse_t += delta
	var phase: float = sin(_legendary_pulse_t * TAU * 1.25) * 0.5 + 0.5  # ~800ms cycle
	var style: StyleBoxFlat = _border_panel.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var base: Color = RARITY_COLORS[UpgradeData.Rarity.LEGENDARY]
	var glow: Color = base.lightened(0.4)
	style.border_color = base.lerp(glow, phase)


func _has_synergy() -> bool:
	if upgrade == null:
		return false
	if not has_node("/root/UpgradeManager"):
		return false
	var mgr: Node = get_node("/root/UpgradeManager")
	var owned_tags: Variant = mgr.get("owned_tags")
	if not (owned_tags is Dictionary):
		return false
	for tag: StringName in upgrade.tags:
		if (owned_tags as Dictionary).has(tag) and int((owned_tags as Dictionary)[tag]) > 0:
			return true
	return false


func _on_pressed() -> void:
	# Anti-misclick on legendaries: ignore presses within the lock window.
	if _is_legendary and Time.get_ticks_msec() - _bound_at_ms < LEGENDARY_LOCK_MS:
		return
	selected.emit()


func _on_hover() -> void:
	hovered.emit()
	# Subtle bump scale on hover.
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.04, 1.04), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector2.ONE, 0.10).set_trans(Tween.TRANS_SINE)


func grab_card_focus() -> void:
	if _hover_button != null:
		_hover_button.grab_focus()

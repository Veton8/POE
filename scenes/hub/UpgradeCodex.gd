extends Control

# Phase C — bookshelf "Codex" UI. Browse every UpgradeData in the registry.
# Entries the player has been offered (logged via GameState.seen_upgrade_ids)
# render in full color; unseen ones show as silhouettes labeled "???".
# Filter tabs left (one per category + "All"); grid center; detail pane right.

signal closed

const TAB_W: int = 32
const GRID_TILE: Vector2 = Vector2(64, 72)
const GRID_COLS: int = 5
const DETAIL_W: int = 116

const CATEGORY_NAMES: Array[String] = ["All", "Bullet", "Auto", "Defense", "Move", "Stat", "Anime", "Ability"]
const CATEGORY_FILTERS: Array[int] = [-1, 0, 1, 2, 3, 4, 5, 6]

var _bg: ColorRect = null
var _root: Panel = null
var _tabs_container: VBoxContainer = null
var _grid_scroll: ScrollContainer = null
var _grid: GridContainer = null
var _detail_panel: Panel = null
var _detail_name: Label = null
var _detail_rarity: Label = null
var _detail_effect: Label = null
var _detail_flavor: Label = null
var _detail_icon: UpgradeIconRenderer = null
var _close_button: Button = null

var _selected_category: int = -1  # -1 = All
var _all_entries: Array[UpgradeData] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_collect_entries()
	_build_ui()
	_refresh_grid()


func _collect_entries() -> void:
	if not has_node("/root/UpgradeRegistry"):
		return
	var reg: Node = get_node("/root/UpgradeRegistry")
	var all_d: Variant = reg.get("all")
	if not (all_d is Dictionary):
		return
	for k: Variant in (all_d as Dictionary).keys():
		var u: UpgradeData = (all_d as Dictionary)[k] as UpgradeData
		if u != null:
			_all_entries.append(u)
	_all_entries.sort_custom(func(a: UpgradeData, b: UpgradeData) -> bool:
		if a.category != b.category:
			return a.category < b.category
		if a.rarity != b.rarity:
			return a.rarity < b.rarity
		return a.display_name < b.display_name)


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0, 0, 0, 0.85)
	add_child(_bg)

	_root = Panel.new()
	_root.position = Vector2(8, 8)
	_root.size = Vector2(464, 254)
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color("#0E1420")
	st.border_color = Color("#3FA9F5")
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.border_width_left = 2
	st.border_width_right = 2
	_root.add_theme_stylebox_override("panel", st)
	add_child(_root)

	var title: Label = Label.new()
	title.text = "CODEX"
	title.position = Vector2(0, 4)
	title.size = Vector2(464, 16)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	_root.add_child(title)

	# Left tabs
	_tabs_container = VBoxContainer.new()
	_tabs_container.position = Vector2(6, 28)
	_tabs_container.size = Vector2(TAB_W, 220)
	_tabs_container.add_theme_constant_override("separation", 2)
	_root.add_child(_tabs_container)
	for i: int in CATEGORY_NAMES.size():
		var b: Button = Button.new()
		b.text = CATEGORY_NAMES[i]
		b.custom_minimum_size = Vector2(TAB_W, 22)
		b.add_theme_font_size_override("font_size", 7)
		var idx: int = i
		b.pressed.connect(func() -> void: _on_tab_pressed(idx))
		_tabs_container.add_child(b)

	# Center grid
	_grid_scroll = ScrollContainer.new()
	_grid_scroll.position = Vector2(TAB_W + 14, 28)
	_grid_scroll.size = Vector2(GRID_TILE.x * GRID_COLS + 8, 200)
	_root.add_child(_grid_scroll)
	_grid = GridContainer.new()
	_grid.columns = GRID_COLS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	_grid_scroll.add_child(_grid)

	# Right detail
	_detail_panel = Panel.new()
	_detail_panel.position = Vector2(_root.size.x - DETAIL_W - 8, 28)
	_detail_panel.size = Vector2(DETAIL_W, 200)
	var dst: StyleBoxFlat = StyleBoxFlat.new()
	dst.bg_color = Color("#16213E")
	dst.border_color = Color("#3FA9F5")
	dst.border_width_top = 1
	dst.border_width_bottom = 1
	dst.border_width_left = 1
	dst.border_width_right = 1
	_detail_panel.add_theme_stylebox_override("panel", dst)
	_root.add_child(_detail_panel)

	_detail_icon = UpgradeIconRenderer.new()
	_detail_icon.position = Vector2(40, 8)
	_detail_icon.size = Vector2(36, 36)
	_detail_icon.configure(&"circle", Color(0.4, 0.4, 0.5, 1), Color.BLACK)
	_detail_panel.add_child(_detail_icon)

	_detail_name = Label.new()
	_detail_name.text = "Select an entry"
	_detail_name.position = Vector2(4, 50)
	_detail_name.size = Vector2(DETAIL_W - 8, 14)
	_detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_name.add_theme_font_size_override("font_size", 10)
	_detail_panel.add_child(_detail_name)

	_detail_rarity = Label.new()
	_detail_rarity.position = Vector2(4, 66)
	_detail_rarity.size = Vector2(DETAIL_W - 8, 12)
	_detail_rarity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_detail_rarity.add_theme_font_size_override("font_size", 8)
	_detail_panel.add_child(_detail_rarity)

	_detail_effect = Label.new()
	_detail_effect.position = Vector2(6, 82)
	_detail_effect.size = Vector2(DETAIL_W - 12, 80)
	_detail_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_effect.add_theme_font_size_override("font_size", 8)
	_detail_panel.add_child(_detail_effect)

	_detail_flavor = Label.new()
	_detail_flavor.position = Vector2(6, 162)
	_detail_flavor.size = Vector2(DETAIL_W - 12, 32)
	_detail_flavor.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_detail_flavor.modulate = Color(1, 1, 1, 0.55)
	_detail_flavor.add_theme_font_size_override("font_size", 7)
	_detail_panel.add_child(_detail_flavor)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.position = Vector2(_root.size.x - 70, _root.size.y - 26)
	_close_button.size = Vector2(60, 20)
	_close_button.pressed.connect(_on_close)
	_root.add_child(_close_button)

	var seen_count: int = GameState.seen_upgrade_ids.size()
	var counter: Label = Label.new()
	counter.text = "%d / %d discovered" % [seen_count, _all_entries.size()]
	counter.position = Vector2(8, _root.size.y - 22)
	counter.size = Vector2(220, 14)
	counter.add_theme_font_size_override("font_size", 8)
	counter.add_theme_color_override("font_color", Color("#94A3B8"))
	_root.add_child(counter)


func _on_tab_pressed(idx: int) -> void:
	_selected_category = CATEGORY_FILTERS[idx]
	_refresh_grid()


func _refresh_grid() -> void:
	for c: Node in _grid.get_children():
		c.queue_free()
	for u: UpgradeData in _all_entries:
		if _selected_category != -1 and int(u.category) != _selected_category:
			continue
		_grid.add_child(_make_entry_tile(u))


func _make_entry_tile(u: UpgradeData) -> Control:
	var tile: Panel = Panel.new()
	tile.custom_minimum_size = GRID_TILE
	var seen: bool = GameState.is_codex_seen(u.id)
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color("#1A1A2E")
	var rcol: Color = UpgradeCard.RARITY_COLORS[clampi(int(u.rarity), 0, UpgradeCard.RARITY_COLORS.size() - 1)]
	st.border_color = rcol if seen else Color(0.25, 0.25, 0.3, 1)
	st.border_width_top = 1
	st.border_width_bottom = 1
	st.border_width_left = 1
	st.border_width_right = 1
	tile.add_theme_stylebox_override("panel", st)

	var icon: UpgradeIconRenderer = UpgradeIconRenderer.new()
	icon.position = Vector2(16, 4)
	icon.size = Vector2(32, 32)
	if seen:
		icon.configure(u.icon_shape, u.icon_color_primary, u.icon_color_accent)
	else:
		icon.configure(u.icon_shape, Color(0.15, 0.15, 0.2, 1), Color(0.05, 0.05, 0.1, 1))
	tile.add_child(icon)

	var lbl: Label = Label.new()
	lbl.position = Vector2(2, 38)
	lbl.size = Vector2(GRID_TILE.x - 4, 32)
	lbl.text = u.display_name if seen else "???"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 7)
	if not seen:
		lbl.add_theme_color_override("font_color", Color("#525266"))
	tile.add_child(lbl)

	var btn: Button = Button.new()
	btn.set_anchors_preset(Control.PRESET_FULL_RECT)
	btn.flat = true
	btn.pressed.connect(func() -> void: _on_tile_clicked(u, seen))
	tile.add_child(btn)
	return tile


func _on_tile_clicked(u: UpgradeData, seen: bool) -> void:
	if not seen:
		_detail_name.text = "???"
		_detail_rarity.text = "Undiscovered"
		_detail_effect.text = "Found in a future run, perhaps."
		_detail_flavor.text = ""
		_detail_icon.configure(&"circle", Color(0.2, 0.2, 0.25, 1), Color(0.1, 0.1, 0.15, 1))
		return
	_detail_name.text = u.display_name
	var r_idx: int = clampi(int(u.rarity), 0, UpgradeCard.RARITY_NAMES.size() - 1)
	_detail_rarity.text = UpgradeCard.RARITY_NAMES[r_idx]
	_detail_rarity.modulate = UpgradeCard.RARITY_COLORS[r_idx]
	_detail_effect.text = u.effect_text
	_detail_flavor.text = u.flavor_text
	_detail_icon.configure(u.icon_shape, u.icon_color_primary, u.icon_color_accent)


func _on_close() -> void:
	closed.emit()
	queue_free()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()

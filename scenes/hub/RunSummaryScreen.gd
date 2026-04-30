extends Control

# Phase C — post-run "build summary" card. Shown before RewardScreen.
# Lays out the upgrades the player picked up this run as a 12-col grid of
# 32×32 icon tiles with stack counters, a dominant tag readout, and the
# headline run stats (rooms, time, hits). Continue routes to RewardScreen.

const REWARD_SCREEN_PATH := "res://scenes/hub/RewardScreen.tscn"
const TILE_SIZE: int = 32
const GRID_COLS: int = 12
const GRID_ORIGIN: Vector2 = Vector2(40, 80)

var _bg: ColorRect = null
var _panel: Panel = null
var _title: Label = null
var _stats_label: Label = null
var _tags_label: Label = null
var _grid: Control = null
var _continue: Button = null


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_populate()


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0, 0, 0, 0.85)
	add_child(_bg)

	_panel = Panel.new()
	_panel.position = Vector2(20, 20)
	_panel.size = Vector2(440, 230)
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color("#101018")
	st.border_color = Color("#3FA9F5")
	st.border_width_top = 2
	st.border_width_bottom = 2
	st.border_width_left = 2
	st.border_width_right = 2
	_panel.add_theme_stylebox_override("panel", st)
	add_child(_panel)

	_title = Label.new()
	_title.text = "RUN SUMMARY"
	_title.position = Vector2(0, 6)
	_title.size = Vector2(440, 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size", 14)
	_panel.add_child(_title)

	_stats_label = Label.new()
	_stats_label.size = Vector2(440, 16)
	_stats_label.position = Vector2(0, 26)
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 9)
	_panel.add_child(_stats_label)

	var grid_header: Label = Label.new()
	grid_header.text = "BUILD"
	grid_header.position = Vector2(20, 56)
	grid_header.size = Vector2(80, 12)
	grid_header.add_theme_font_size_override("font_size", 8)
	grid_header.add_theme_color_override("font_color", Color("#94A3B8"))
	_panel.add_child(grid_header)

	_grid = Control.new()
	_grid.position = GRID_ORIGIN
	_grid.size = Vector2(GRID_COLS * TILE_SIZE, 96)
	_panel.add_child(_grid)

	_tags_label = Label.new()
	_tags_label.size = Vector2(420, 14)
	_tags_label.position = Vector2(10, 184)
	_tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tags_label.add_theme_font_size_override("font_size", 9)
	_tags_label.add_theme_color_override("font_color", Color("#A335EE"))
	_panel.add_child(_tags_label)

	_continue = Button.new()
	_continue.text = "Continue"
	_continue.size = Vector2(96, 22)
	_continue.position = Vector2(172, 202)
	_continue.pressed.connect(_on_continue)
	_panel.add_child(_continue)


func _populate() -> void:
	var rooms: int = int(GameState.run_stats.get("rooms_cleared", 0))
	var enemies: int = int(GameState.run_stats.get("enemies_killed", 0))
	var bosses: int = int(GameState.run_stats.get("bosses_killed", 0))
	var hits: int = int(GameState.run_stats.get("hits_taken", 0))
	var elapsed_ms: int = Time.get_ticks_msec() - int(GameState.run_stats.get("start_time_ms", Time.get_ticks_msec()))
	var seconds: int = elapsed_ms / 1000
	_stats_label.text = "Rooms %d  ·  Enemies %d  ·  Bosses %d  ·  Hits %d  ·  Time %ds" % [rooms, enemies, bosses, hits, seconds]

	if not has_node("/root/UpgradeManager"):
		return
	var mgr: Node = get_node("/root/UpgradeManager")
	var owned: Variant = mgr.get("owned_stacks")
	if not (owned is Dictionary):
		return
	var ids: Array[StringName] = []
	for k: Variant in (owned as Dictionary).keys():
		ids.append(k as StringName)
	# Sort: rarity desc, then name
	ids.sort_custom(func(a: StringName, b: StringName) -> bool:
		var ua: UpgradeData = UpgradeRegistry.get_upgrade(a)
		var ub: UpgradeData = UpgradeRegistry.get_upgrade(b)
		if ua == null or ub == null:
			return false
		if ua.rarity != ub.rarity:
			return ua.rarity > ub.rarity
		return ua.display_name < ub.display_name)
	for i: int in ids.size():
		var id: StringName = ids[i]
		var u: UpgradeData = UpgradeRegistry.get_upgrade(id)
		if u == null:
			continue
		var stacks: int = int((owned as Dictionary)[id])
		var col: int = i % GRID_COLS
		var row: int = i / GRID_COLS
		_add_tile(u, stacks, col, row)
	_tags_label.text = _format_dominant_tags()


func _add_tile(u: UpgradeData, stacks: int, col: int, row: int) -> void:
	var holder: Control = Control.new()
	holder.position = Vector2(col * TILE_SIZE, row * TILE_SIZE)
	holder.size = Vector2(TILE_SIZE - 2, TILE_SIZE - 2)
	_grid.add_child(holder)
	var bg_panel: Panel = Panel.new()
	bg_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var st: StyleBoxFlat = StyleBoxFlat.new()
	st.bg_color = Color("#1A1A2E")
	var rcol: Color = UpgradeCard.RARITY_COLORS[clampi(int(u.rarity), 0, UpgradeCard.RARITY_COLORS.size() - 1)]
	st.border_color = rcol
	st.border_width_top = 1
	st.border_width_bottom = 1
	st.border_width_left = 1
	st.border_width_right = 1
	bg_panel.add_theme_stylebox_override("panel", st)
	holder.add_child(bg_panel)
	var icon: UpgradeIconRenderer = UpgradeIconRenderer.new()
	icon.size = Vector2(TILE_SIZE - 6, TILE_SIZE - 6)
	icon.position = Vector2(2, 2)
	icon.configure(u.icon_shape, u.icon_color_primary, u.icon_color_accent)
	holder.add_child(icon)
	if stacks > 1:
		var count: Label = Label.new()
		count.text = "x%d" % stacks
		count.position = Vector2(0, TILE_SIZE - 14)
		count.size = Vector2(TILE_SIZE - 4, 12)
		count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count.add_theme_font_size_override("font_size", 8)
		count.add_theme_color_override("font_color", Color("#FEF3C7"))
		count.add_theme_color_override("font_outline_color", Color.BLACK)
		count.add_theme_constant_override("outline_size", 2)
		holder.add_child(count)


func _format_dominant_tags() -> String:
	if not has_node("/root/UpgradeManager"):
		return ""
	var mgr: Node = get_node("/root/UpgradeManager")
	var tags: Variant = mgr.get("owned_tags")
	if not (tags is Dictionary) or (tags as Dictionary).is_empty():
		return "No themed picks"
	var rows: Array = []
	for k: Variant in (tags as Dictionary).keys():
		rows.append([k as StringName, int((tags as Dictionary)[k])])
	rows.sort_custom(func(a: Array, b: Array) -> bool: return int(a[1]) > int(b[1]))
	var top: Array = rows.slice(0, 3)
	var parts: Array[String] = []
	for r: Variant in top:
		var pair: Array = r as Array
		parts.append("%s ×%d" % [String(pair[0]), int(pair[1])])
	return "Theme: " + " · ".join(parts)


func _on_continue() -> void:
	get_tree().change_scene_to_file(REWARD_SCREEN_PATH)

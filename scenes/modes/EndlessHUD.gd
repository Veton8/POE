extends CanvasLayer

# Endless-mode HUD. Renders at full screen resolution (not pixel-snapped
# inside the SubViewport) so text reads cleanly. Layout per the design
# doc:
#   y=0..24    top bar — HP, timer, kills
#   y=24..34   XP strip — bar + level label
#   y=34..end  play field (rendered by the SubViewport / TextureRect
#              on a separate CanvasLayer behind this one)
#
# bind(player, spawner, run) wires the live nodes once the run scene
# has built them.

const TOP_BAR_H: int = 24
const XP_STRIP_H: int = 10

var _player: Player
var _spawner: EndlessSpawner
var _run: Node

var _bg_top: ColorRect
var _hp_label: Label
var _timer_label: Label
var _kills_label: Label

var _xp_bg: ColorRect
var _xp_fill: ColorRect
var _level_label: Label


func _ready() -> void:
	layer = 50
	_build_top_bar()
	_build_xp_strip()


func bind(player: Player, spawner: EndlessSpawner, run: Node) -> void:
	_player = player
	_spawner = spawner
	_run = run
	if _player != null:
		_player.health_changed.connect(_on_health_changed)
		_on_health_changed(_player.health.current, _player.health.max_hp)


func _build_top_bar() -> void:
	_bg_top = ColorRect.new()
	_bg_top.color = Color(0, 0, 0, 0.55)
	_bg_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_bg_top.size = Vector2(0, TOP_BAR_H)
	_bg_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_bg_top)

	_hp_label = _make_label("HP 0/0", Vector2(4, 4), 120, 12, HORIZONTAL_ALIGNMENT_LEFT, 8)
	_bg_top.add_child(_hp_label)

	_timer_label = _make_label("00:00", Vector2(0, 4), 120, 12, HORIZONTAL_ALIGNMENT_CENTER, 8)
	_timer_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_timer_label.position = Vector2(-60, 4)
	_bg_top.add_child(_timer_label)

	_kills_label = _make_label("k:0", Vector2(0, 4), 120, 12, HORIZONTAL_ALIGNMENT_RIGHT, 8)
	_kills_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_kills_label.position = Vector2(-124, 4)
	_bg_top.add_child(_kills_label)


func _build_xp_strip() -> void:
	_xp_bg = ColorRect.new()
	_xp_bg.color = Color(0.04, 0.06, 0.10, 0.70)
	_xp_bg.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_xp_bg.position = Vector2(0, TOP_BAR_H)
	_xp_bg.size = Vector2(0, XP_STRIP_H)
	_xp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_xp_bg)

	_xp_fill = ColorRect.new()
	_xp_fill.color = Color(0.4, 0.85, 1.0, 1.0)
	_xp_fill.position = Vector2(0, 1)
	_xp_fill.size = Vector2(0, XP_STRIP_H - 2)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_bg.add_child(_xp_fill)

	_level_label = _make_label("Lv.1", Vector2(0, 0), 60, XP_STRIP_H, HORIZONTAL_ALIGNMENT_RIGHT, 8)
	_level_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_level_label.position = Vector2(-64, 0)
	_xp_bg.add_child(_level_label)


func _make_label(text: String, pos: Vector2, w: float, h: float, align: HorizontalAlignment, font_size: int) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = Vector2(w, h)
	lbl.horizontal_alignment = align
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return lbl


func _process(_delta: float) -> void:
	if _spawner != null:
		var t: float = _spawner.get_run_time()
		var mins: int = int(t) / 60
		var secs: int = int(t) % 60
		_timer_label.text = "%02d:%02d" % [mins, secs]
	if GameState.run_stats != null:
		_kills_label.text = "k:%d" % int(GameState.run_stats.get("enemies_killed", 0))
	if _run != null and _run.has_method("get_level"):
		var lvl: int = int(_run.call("get_level"))
		_level_label.text = "Lv.%d" % lvl
	if _run != null and _run.has_method("get_xp_progress"):
		var prog: float = float(_run.call("get_xp_progress"))
		var bar_max: float = float(_xp_bg.size.x)
		_xp_fill.size.x = bar_max * prog


func _on_health_changed(current: int, max_hp: int) -> void:
	if _hp_label != null:
		_hp_label.text = "HP %d/%d" % [current, max_hp]

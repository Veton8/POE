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
const BOTTOM_BAND_H: int = 80
const COOLDOWN_RING_SIZE: int = 16
const STATUS_STRIP_H: int = 6
const VIRTUAL_JOYSTICK_SCENE: PackedScene = preload("res://scenes/ui/VirtualJoystick.tscn")

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

var _cooldown_ring_container: Node2D
var _cooldown_rings: Array[Node2D] = []
var _ability_refs: Array[Ability] = []

var _status_strip: Node2D


func _ready() -> void:
	layer = 50
	_build_top_bar()
	_build_xp_strip()
	_build_bottom_band()
	_install_virtual_joystick()


func _install_virtual_joystick() -> void:
	# Touch input source for endless mode. Same VirtualJoystick scene
	# the dungeon HUD uses — registers itself with the Joystick
	# autoload so Player movement reads from touch automatically.
	var joy: Control = VIRTUAL_JOYSTICK_SCENE.instantiate() as Control
	if joy == null:
		return
	joy.name = "VirtualJoystick"
	add_child(joy)


func bind(player: Player, spawner: EndlessSpawner, run: Node) -> void:
	_player = player
	_spawner = spawner
	_run = run
	if _player != null:
		_player.health_changed.connect(_on_health_changed)
		_on_health_changed(_player.health.current, _player.health.max_hp)
		_collect_abilities()


func _collect_abilities() -> void:
	if _player == null:
		return
	var ab_root: Node = _player.get_node_or_null("Abilities")
	if ab_root == null:
		return
	for c: Node in ab_root.get_children():
		if c is Ability:
			_ability_refs.append(c as Ability)
	# Build a ring per ability (max 3)
	if _cooldown_ring_container == null:
		return
	for i: int in mini(3, _ability_refs.size()):
		var ring: Node2D = Node2D.new()
		ring.set_script(preload("res://scenes/modes/EndlessAbilityRing.gd"))
		ring.position = Vector2(264 - 8 - 4, 410 + i * 20)
		_cooldown_ring_container.add_child(ring)
		if ring.has_method("bind_ability"):
			ring.call("bind_ability", _ability_refs[i])
		_cooldown_rings.append(ring)


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


func _build_bottom_band() -> void:
	# Cooldown ring container — positioned at bottom-right of viewport
	_cooldown_ring_container = Node2D.new()
	_cooldown_ring_container.name = "CooldownRings"
	add_child(_cooldown_ring_container)
	# Status strip — bottom of bottom band
	_status_strip = Node2D.new()
	_status_strip.set_script(preload("res://scenes/modes/EndlessStatusStrip.gd"))
	_status_strip.position = Vector2(0, 480 - STATUS_STRIP_H)
	add_child(_status_strip)


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

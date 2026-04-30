extends Node2D

# The diegetic hub. Player spawns here and walks around. Each interactable
# object opens a sub-screen overlay. Walking into the door starts a run.

const ROOM_TILES_W := 30
const ROOM_TILES_H := 17
const SOURCE_FLOOR_A := 0
const SOURCE_FLOOR_B := 1
const SOURCE_WALL := 2

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CAMERA_SCENE := preload("res://scenes/camera/ShakeCamera2D.tscn")
const CHARACTER_SCREEN_SCENE := preload("res://scenes/hub/CharacterScreen.tscn")
const GEAR_SCREEN_SCENE := preload("res://scenes/hub/GearScreen.tscn")
const DUNGEON_SELECT_SCENE := preload("res://scenes/hub/DungeonSelectScreen.tscn")
const UPGRADE_CODEX_SCENE := preload("res://scenes/hub/UpgradeCodex.tscn")

@onready var floor_layer: TileMapLayer = $Floor
@onready var walls_layer: TileMapLayer = $Walls
@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var ui_layer: CanvasLayer = $UILayer
@onready var hero_pedestal: HubInteractable = $Interactables/HeroPedestal
@onready var anvil: HubInteractable = $Interactables/Anvil
@onready var shrine: HubInteractable = $Interactables/Shrine
@onready var bookshelf: HubInteractable = $Interactables/Bookshelf
@onready var mailbox: HubInteractable = $Interactables/Mailbox
@onready var hub_door: HubInteractable = $Interactables/HubDoor
@onready var locked_silhouette: Sprite2D = $LockedSilhouette
@onready var coin_label: Label = $UILayer/TopBar/CoinBox/CoinLabel
@onready var gem_label: Label = $UILayer/TopBar/GemBox/GemLabel
@onready var sp_label: Label = $UILayer/TopBar/SPBox/SPLabel
@onready var play_arrow: Sprite2D = $Interactables/HubDoor/PlayArrow

var player: Node2D = null
var _active_overlay: Control = null
var _arrow_t: float = 0.0


func _ready() -> void:
	randomize()
	_paint_floor()
	_spawn_hub_player()
	_connect_interactables()
	_refresh_currency_labels()
	_refresh_locked_silhouette()
	Events.coins_changed.connect(_on_currency_changed)
	Events.gems_changed.connect(_on_currency_changed)
	Events.skill_points_changed.connect(_on_currency_changed)


func _process(delta: float) -> void:
	# Bouncy "press play" arrow above the door
	_arrow_t += delta * 4.0
	if play_arrow != null:
		play_arrow.position.y = -32.0 + sin(_arrow_t) * 2.0


func _paint_floor() -> void:
	for y: int in ROOM_TILES_H:
		for x: int in ROOM_TILES_W:
			var pos: Vector2i = Vector2i(x, y)
			var is_wall: bool = x == 0 or x == ROOM_TILES_W - 1 or y == 0 or y == ROOM_TILES_H - 1
			if is_wall:
				walls_layer.set_cell(pos, SOURCE_WALL, Vector2i(0, 0))
			else:
				var src: int = SOURCE_FLOOR_A if (x * 7 + y * 13) % 5 != 0 else SOURCE_FLOOR_B
				floor_layer.set_cell(pos, src, Vector2i(0, 0))


func _spawn_hub_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	if player == null:
		return
	var p: Player = player as Player
	p.hub_mode = true
	# Use the selected character's stats so the visual matches
	var stats: PlayerStats = GameState.get_character_base_stats(GameState.selected_character)
	if stats != null:
		p.stats = stats
	add_child(player)
	player.global_position = player_spawn.global_position
	# Swap sprite texture to selected character portrait if available
	if stats != null and stats.portrait != null:
		var sprite_node: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
		if sprite_node != null:
			sprite_node.texture = stats.portrait
	# Camera follow
	var cam: Node2D = CAMERA_SCENE.instantiate() as Node2D
	if cam != null:
		player.add_child(cam)
		if cam.has_method("make_current"):
			cam.call("make_current")


func _connect_interactables() -> void:
	hero_pedestal.interacted.connect(_open_character_screen)
	anvil.interacted.connect(_open_gear_screen)
	shrine.interacted.connect(_open_placeholder.bind("Talents"))
	bookshelf.interacted.connect(_open_codex)
	mailbox.interacted.connect(_open_placeholder.bind("Quests"))
	hub_door.interacted.connect(_open_dungeon_select)


func _open_character_screen() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = CHARACTER_SCREEN_SCENE.instantiate() as Control
	if overlay == null:
		return
	_show_overlay(overlay)


func _open_gear_screen() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = GEAR_SCREEN_SCENE.instantiate() as Control
	if overlay == null:
		return
	_show_overlay(overlay)


func _open_codex() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = UPGRADE_CODEX_SCENE.instantiate() as Control
	if overlay == null:
		return
	_show_overlay(overlay)


func _open_placeholder(title: String) -> void:
	if _active_overlay != null:
		return
	var overlay: Control = _make_placeholder_overlay(title)
	_show_overlay(overlay)


func _make_placeholder_overlay(title: String) -> Control:
	var root: Control = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.7)
	root.add_child(bg)
	var panel: ColorRect = ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.size = Vector2(360, 180)
	panel.position = Vector2(-180, -90)
	panel.color = Color("#1A1A2E")
	root.add_child(panel)
	var border: ColorRect = ColorRect.new()
	border.set_anchors_preset(Control.PRESET_CENTER)
	border.size = Vector2(362, 182)
	border.position = Vector2(-181, -91)
	border.color = Color("#16213E")
	border.show_behind_parent = true
	root.add_child(border)
	var title_lbl: Label = Label.new()
	title_lbl.text = title
	title_lbl.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title_lbl.position = Vector2(-60, -75)
	title_lbl.size = Vector2(120, 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_color_override("font_color", Color("#FEF3C7"))
	root.add_child(title_lbl)
	var coming: Label = Label.new()
	coming.text = "Coming Soon"
	coming.set_anchors_preset(Control.PRESET_CENTER)
	coming.position = Vector2(-60, -10)
	coming.size = Vector2(120, 20)
	coming.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coming.add_theme_color_override("font_color", Color("#94A3B8"))
	root.add_child(coming)
	var close: Button = Button.new()
	close.text = "Close"
	close.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	close.position = Vector2(-40, 40)
	close.size = Vector2(80, 24)
	close.pressed.connect(_close_overlay)
	root.add_child(close)
	return root


func _show_overlay(overlay: Control) -> void:
	_active_overlay = overlay
	ui_layer.add_child(overlay)
	# Disable interactables and freeze player movement while overlay is open
	_set_player_paused(true)
	_set_interactables_disabled(true)
	# If overlay has a `closed` signal, wire it up
	if overlay.has_signal("closed"):
		overlay.connect("closed", _close_overlay, CONNECT_ONE_SHOT)


func _close_overlay() -> void:
	if _active_overlay != null and is_instance_valid(_active_overlay):
		_active_overlay.queue_free()
	_active_overlay = null
	_set_player_paused(false)
	_set_interactables_disabled(false)
	_refresh_currency_labels()
	_refresh_locked_silhouette()
	# Player may have changed character — respawn the hub player to reflect it
	_refresh_hub_player_appearance()


func _set_player_paused(paused: bool) -> void:
	if player != null:
		player.set_physics_process(not paused)
		player.set_process(not paused)


func _set_interactables_disabled(value: bool) -> void:
	for n: Node in get_tree().get_nodes_in_group("hub_interactable"):
		if n is HubInteractable:
			(n as HubInteractable).set_disabled(value)


func _refresh_currency_labels() -> void:
	coin_label.text = str(GameState.coins)
	gem_label.text = str(GameState.gems)
	sp_label.text = str(GameState.skill_points)


func _on_currency_changed(_amount: int) -> void:
	_refresh_currency_labels()


func _refresh_locked_silhouette() -> void:
	# Show a teaser silhouette of the next un-unlocked character behind the pedestal
	var next_locked: String = ""
	for char_id: String in ["luffy", "ace", "goku", "gojo", "rogue", "mage"]:
		if not GameState.unlocked_characters.has(char_id):
			next_locked = char_id
			break
	if next_locked == "" or locked_silhouette == null:
		if locked_silhouette != null:
			locked_silhouette.visible = false
		return
	var stats: PlayerStats = GameState.get_character_base_stats(next_locked)
	if stats != null and stats.portrait != null:
		locked_silhouette.texture = stats.portrait
		locked_silhouette.modulate = Color(0.15, 0.15, 0.2, 0.85)
		locked_silhouette.visible = true


func _refresh_hub_player_appearance() -> void:
	if player == null:
		return
	var stats: PlayerStats = GameState.get_character_base_stats(GameState.selected_character)
	if stats == null:
		return
	(player as Player).stats = stats
	if stats.portrait != null:
		var sprite_node: Sprite2D = player.get_node_or_null("Sprite2D") as Sprite2D
		if sprite_node != null:
			sprite_node.texture = stats.portrait


func _open_dungeon_select() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = DUNGEON_SELECT_SCENE.instantiate() as Control
	if overlay == null:
		return
	overlay.connect("chosen", _on_dungeon_chosen, CONNECT_ONE_SHOT)
	_show_overlay(overlay)


func _on_dungeon_chosen(_dungeon_id: String) -> void:
	# Close the overlay first so the hub doesn't keep it around when the
	# scene changes
	_close_overlay()
	_start_run()


func _start_run() -> void:
	# Reset run telemetry and load the run scene
	GameState.run_stats = {
		"enemies_killed": 0,
		"bosses_killed": 0,
		"rooms_cleared": 0,
		"coins_collected": 0,
		"hits_taken": 0,
		"start_time_ms": Time.get_ticks_msec(),
	}
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

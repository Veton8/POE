extends Node2D

# Portrait hub. Renders a 360x640 portrait view via a SubViewport,
# displays it scaled-with-aspect inside the OS window via a TextureRect.
# Same pattern Endless mode uses (see scenes/modes/Endless.gd).
#
# Three interactables in a horizontal row across the floor:
#   ENDLESS rift (left) - HERO book (centre) - DUNGEON portal (right)

const PORTRAIT_W: int = 720
const PORTRAIT_H: int = 1280

# Layout in SubViewport game-pixel coordinates. SubViewport is 2x what we
# had before so 128px-cell character (Levi at high detail) reads as the
# same proportion of viewport as the 64px version did at 360x640.
const CAMERA_POS := Vector2(360, 640)
const BG_CENTER := Vector2(360, 640)
const PLAYER_SPAWN_POS := Vector2(360, 1080)
const ENDLESS_POS := Vector2(180, 880)
const HEROBOOK_POS := Vector2(360, 880)
const DUNGEON_POS := Vector2(540, 880)

# Walkable rectangle - players move on the floor band beneath the
# interactable row, between the side walls.
const FLOOR_LEFT: int = 100
const FLOOR_RIGHT: int = 620
const FLOOR_TOP: int = 960
const FLOOR_BOTTOM: int = 1220

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CHARACTER_SCREEN_SCENE := preload("res://scenes/hub/CharacterScreen.tscn")
const DUNGEON_SELECT_SCENE := preload("res://scenes/hub/DungeonSelectScreen.tscn")
const VIRTUAL_JOYSTICK_SCENE := preload("res://scenes/ui/VirtualJoystick.tscn")
const HUB_ROOM_TEXTURE := preload("res://art/hub/hub_room_portrait.png")
const HERO_BOOK_TEXTURE := preload("res://art/hub/hero_book_med.png")
const DUNGEON_PORTAL_TEXTURE := preload("res://art/hub/dungeon_portal_med.png")
const ENDLESS_PORTAL_TEXTURE := preload("res://art/hub/endless_portal_med.png")
const ENDLESS_SCENE_PATH := "res://scenes/modes/Endless.tscn"

@onready var ui_layer: CanvasLayer = $UILayer
@onready var coin_label: Label = $UILayer/TopBar/CoinBox/CoinLabel
@onready var gem_label: Label = $UILayer/TopBar/GemBox/GemLabel
@onready var sp_label: Label = $UILayer/TopBar/SPBox/SPLabel

var _viewport: SubViewport
var _display: TextureRect
var _world: Node2D
var _interactables_node: Node2D
var player: Node2D = null
var _active_overlay: Control = null
var _endless_door: HubInteractable = null


func _ready() -> void:
	_build_render_tree()
	_build_world_contents()
	_spawn_hub_player()
	_build_interactables()
	_install_virtual_joystick()
	_refresh_currency_labels()
	Events.coins_changed.connect(_on_currency_changed)
	Events.gems_changed.connect(_on_currency_changed)
	Events.skill_points_changed.connect(_on_currency_changed)


func _build_render_tree() -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(PORTRAIT_W, PORTRAIT_H)
	_viewport.snap_2d_transforms_to_pixel = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = false
	_viewport.handle_input_locally = false
	add_child(_viewport)

	_world = Node2D.new()
	_world.name = "World"
	_viewport.add_child(_world)

	# Display layer behind the UI layer (which is at layer=10).
	var display_layer: CanvasLayer = CanvasLayer.new()
	display_layer.layer = -10
	add_child(display_layer)
	_display = TextureRect.new()
	_display.set_anchors_preset(Control.PRESET_FULL_RECT)
	_display.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_display.texture = _viewport.get_texture()
	_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	display_layer.add_child(_display)


func _build_world_contents() -> void:
	var bg: Sprite2D = Sprite2D.new()
	bg.name = "Background"
	bg.texture = HUB_ROOM_TEXTURE
	bg.position = BG_CENTER
	bg.z_index = -10
	_world.add_child(bg)

	var cam: Camera2D = Camera2D.new()
	cam.name = "Camera2D"
	cam.position = CAMERA_POS
	_world.add_child(cam)
	cam.make_current()

	var walls: Node2D = Node2D.new()
	walls.name = "Walls"
	_world.add_child(walls)
	var t: int = 16
	_add_wall(walls, Vector2((FLOOR_LEFT + FLOOR_RIGHT) * 0.5, FLOOR_TOP - t * 0.5), Vector2(FLOOR_RIGHT - FLOOR_LEFT, t))
	_add_wall(walls, Vector2((FLOOR_LEFT + FLOOR_RIGHT) * 0.5, FLOOR_BOTTOM + t * 0.5), Vector2(FLOOR_RIGHT - FLOOR_LEFT, t))
	_add_wall(walls, Vector2(FLOOR_LEFT - t * 0.5, (FLOOR_TOP + FLOOR_BOTTOM) * 0.5), Vector2(t, FLOOR_BOTTOM - FLOOR_TOP))
	_add_wall(walls, Vector2(FLOOR_RIGHT + t * 0.5, (FLOOR_TOP + FLOOR_BOTTOM) * 0.5), Vector2(t, FLOOR_BOTTOM - FLOOR_TOP))

	_interactables_node = Node2D.new()
	_interactables_node.name = "Interactables"
	_world.add_child(_interactables_node)


func _add_wall(parent: Node, pos: Vector2, size: Vector2) -> void:
	var body: StaticBody2D = StaticBody2D.new()
	body.position = pos
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: RectangleShape2D = RectangleShape2D.new()
	shape.size = size
	coll.shape = shape
	body.add_child(coll)
	parent.add_child(body)


func _install_virtual_joystick() -> void:
	if ui_layer == null:
		return
	var joy: Control = VIRTUAL_JOYSTICK_SCENE.instantiate() as Control
	if joy == null:
		return
	joy.name = "VirtualJoystick"
	ui_layer.add_child(joy)


func _spawn_hub_player() -> void:
	player = PLAYER_SCENE.instantiate() as Node2D
	if player == null:
		return
	var p: Player = player as Player
	p.hub_mode = true
	var stats: PlayerStats = GameState.get_character_base_stats(GameState.selected_character)
	if stats != null:
		p.stats = stats
	_world.add_child(player)
	player.global_position = PLAYER_SPAWN_POS


func _build_interactables() -> void:
	_build_endless_portal()
	_build_hero_book()
	_build_dungeon_portal()


func _build_endless_portal() -> void:
	var door: HubInteractable = _make_sprite_interactable("EndlessPortal", _endless_label_text(), ENDLESS_PORTAL_TEXTURE, ENDLESS_POS)
	door.interacted.connect(_on_endless_portal_interacted)
	_endless_door = door


func _endless_label_text() -> String:
	return "ENDLESS" if GameState.endless_unlocked else "ENDLESS (locked)"


func _build_hero_book() -> void:
	var book: HubInteractable = _make_sprite_interactable("HeroBook", "HERO SELECT", HERO_BOOK_TEXTURE, HEROBOOK_POS)
	book.interacted.connect(_on_hero_book_interacted)


func _build_dungeon_portal() -> void:
	var portal: HubInteractable = _make_sprite_interactable("DungeonPortal", "DUNGEON", DUNGEON_PORTAL_TEXTURE, DUNGEON_POS)
	portal.interacted.connect(_on_dungeon_portal_interacted)


func _make_sprite_interactable(node_name: String, label: String, texture: Texture2D, pos: Vector2) -> HubInteractable:
	var inter: HubInteractable = HubInteractable.new()
	inter.name = node_name
	inter.label_text = label
	inter.label_offset = Vector2(0, -88)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = texture
	inter.add_child(sprite)
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 56.0
	coll.shape = shape
	inter.add_child(coll)
	inter.position = pos
	_interactables_node.add_child(inter)
	return inter


func _on_endless_portal_interacted() -> void:
	if not GameState.endless_unlocked:
		Audio.play("player_hurt", 0.05, -8.0)
		return
	Audio.play("door_unlock", 0.05, -2.0)
	get_tree().change_scene_to_file(ENDLESS_SCENE_PATH)


func _on_hero_book_interacted() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = CHARACTER_SCREEN_SCENE.instantiate() as Control
	if overlay == null:
		return
	_show_overlay(overlay)


func _on_dungeon_portal_interacted() -> void:
	if _active_overlay != null:
		return
	var overlay: Control = DUNGEON_SELECT_SCENE.instantiate() as Control
	if overlay == null:
		return
	overlay.connect("chosen", _on_dungeon_chosen, CONNECT_ONE_SHOT)
	_show_overlay(overlay)


func _on_dungeon_chosen(_dungeon_id: String) -> void:
	_close_overlay()
	_start_run()


func _start_run() -> void:
	GameState.run_stats = {
		"enemies_killed": 0,
		"bosses_killed": 0,
		"rooms_cleared": 0,
		"coins_collected": 0,
		"hits_taken": 0,
		"start_time_ms": Time.get_ticks_msec(),
	}
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func _show_overlay(overlay: Control) -> void:
	_active_overlay = overlay
	ui_layer.add_child(overlay)
	_set_player_paused(true)
	_set_interactables_disabled(true)
	if overlay.has_signal("closed"):
		overlay.connect("closed", _close_overlay, CONNECT_ONE_SHOT)


func _close_overlay() -> void:
	if _active_overlay != null and is_instance_valid(_active_overlay):
		_active_overlay.queue_free()
	_active_overlay = null
	_set_player_paused(false)
	_set_interactables_disabled(false)
	_refresh_currency_labels()
	_refresh_endless_label()
	_respawn_hub_player()


func _set_player_paused(paused: bool) -> void:
	if player != null and is_instance_valid(player):
		player.set_physics_process(not paused)
		player.set_process(not paused)


func _set_interactables_disabled(value: bool) -> void:
	for n: Node in get_tree().get_nodes_in_group("hub_interactable"):
		if not is_instance_valid(n):
			continue
		if n is HubInteractable:
			(n as HubInteractable).set_disabled(value)


func _refresh_currency_labels() -> void:
	coin_label.text = str(GameState.coins)
	gem_label.text = str(GameState.gems)
	sp_label.text = str(GameState.skill_points)


func _on_currency_changed(_amount: int) -> void:
	_refresh_currency_labels()


func _refresh_endless_label() -> void:
	if _endless_door != null and is_instance_valid(_endless_door):
		_endless_door.label_text = _endless_label_text()


func _respawn_hub_player() -> void:
	if player != null and is_instance_valid(player):
		player.queue_free()
	_spawn_hub_player()

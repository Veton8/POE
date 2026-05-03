extends Node2D

# Diegetic hub. Three interactables only:
#   - Endless rift (left)        — programmatic placeholder until art arrives
#   - Hero selection book (mid)  — opens CharacterScreen overlay
#   - Dungeon portal (right)     — opens DungeonSelectScreen, then starts a run
#
# Room is 512x288 game pixels (2x downsample of a 1024x576 Stitch crop).
# Camera is fixed at the room centre — no follow, no scroll.

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const CHARACTER_SCREEN_SCENE := preload("res://scenes/hub/CharacterScreen.tscn")
const DUNGEON_SELECT_SCENE := preload("res://scenes/hub/DungeonSelectScreen.tscn")
const VIRTUAL_JOYSTICK_SCENE := preload("res://scenes/ui/VirtualJoystick.tscn")
const HUB_ROOM_TEXTURE := preload("res://art/hub/hub_room.png")
const HERO_BOOK_TEXTURE := preload("res://art/hub/hero_book.png")
const DUNGEON_PORTAL_TEXTURE := preload("res://art/hub/dungeon_portal.png")
const ENDLESS_PORTAL_TEXTURE := preload("res://art/hub/endless_portal.png")
const ENDLESS_SCENE_PATH := "res://scenes/modes/Endless.tscn"

const ROOM_W := 512
const ROOM_H := 360
# Source was cropped top-aligned to 1024x720 then downsampled 2x to 512x360
# so the room exactly fills the 360-tall viewport vertically (no hidden
# bottom, no black void below the floor).
const BG_CENTER := Vector2(256, 180)
const CAMERA_CENTER := Vector2(256, 180)
# Walkable rectangle — players move on the floor band between the back
# wall (~y=170) and the bottom of the visible floor pattern (~y=345).
const FLOOR_LEFT := 40
const FLOOR_RIGHT := 472
const FLOOR_TOP := 180
const FLOOR_BOTTOM := 345

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var ui_layer: CanvasLayer = $UILayer
@onready var interactables_node: Node2D = $Interactables
@onready var coin_label: Label = $UILayer/TopBar/CoinBox/CoinLabel
@onready var gem_label: Label = $UILayer/TopBar/GemBox/GemLabel
@onready var sp_label: Label = $UILayer/TopBar/SPBox/SPLabel

var player: Node2D = null
var _active_overlay: Control = null
var _endless_door: HubInteractable = null


func _ready() -> void:
	_build_background()
	_build_camera()
	_build_walls()
	_spawn_hub_player()
	_build_interactables()
	_install_virtual_joystick()
	_refresh_currency_labels()
	Events.coins_changed.connect(_on_currency_changed)
	Events.gems_changed.connect(_on_currency_changed)
	Events.skill_points_changed.connect(_on_currency_changed)


func _build_background() -> void:
	var bg: Sprite2D = Sprite2D.new()
	bg.name = "Background"
	bg.texture = HUB_ROOM_TEXTURE
	bg.position = BG_CENTER
	bg.z_index = -10
	add_child(bg)


func _build_camera() -> void:
	var cam: Camera2D = Camera2D.new()
	cam.name = "Camera2D"
	cam.position = CAMERA_CENTER
	add_child(cam)
	cam.make_current()


func _build_walls() -> void:
	# Four invisible walls around the walkable rectangle so the player can't
	# wander off the floor into the back wall art or out past the room edges.
	var walls: Node2D = Node2D.new()
	walls.name = "Walls"
	add_child(walls)
	var thickness: int = 16
	# top
	_add_wall(walls, Vector2((FLOOR_LEFT + FLOOR_RIGHT) * 0.5, FLOOR_TOP - thickness * 0.5), Vector2(FLOOR_RIGHT - FLOOR_LEFT, thickness))
	# bottom
	_add_wall(walls, Vector2((FLOOR_LEFT + FLOOR_RIGHT) * 0.5, FLOOR_BOTTOM + thickness * 0.5), Vector2(FLOOR_RIGHT - FLOOR_LEFT, thickness))
	# left
	_add_wall(walls, Vector2(FLOOR_LEFT - thickness * 0.5, (FLOOR_TOP + FLOOR_BOTTOM) * 0.5), Vector2(thickness, FLOOR_BOTTOM - FLOOR_TOP))
	# right
	_add_wall(walls, Vector2(FLOOR_RIGHT + thickness * 0.5, (FLOOR_TOP + FLOOR_BOTTOM) * 0.5), Vector2(thickness, FLOOR_BOTTOM - FLOOR_TOP))


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
	# Use the selected character's stats so the visual matches selection
	var stats: PlayerStats = GameState.get_character_base_stats(GameState.selected_character)
	if stats != null:
		p.stats = stats
	add_child(player)
	player.global_position = player_spawn.global_position


func _build_interactables() -> void:
	_build_endless_portal()
	_build_hero_book()
	_build_dungeon_portal()


func _build_endless_portal() -> void:
	# y=236 centre means 128px sprite bottom sits at y=300 (on the floor's
	# foreground edge) and top at y=172 (overlaps the back wall, reads as
	# 'mounted on the wall').
	var door: HubInteractable = _make_sprite_interactable("EndlessPortal", _endless_label_text(), ENDLESS_PORTAL_TEXTURE, Vector2(112, 236))
	door.interacted.connect(_on_endless_portal_interacted)
	_endless_door = door


func _endless_label_text() -> String:
	return "ENDLESS" if GameState.endless_unlocked else "ENDLESS (locked)"


func _build_hero_book() -> void:
	var book: HubInteractable = _make_sprite_interactable("HeroBook", "HERO SELECT", HERO_BOOK_TEXTURE, Vector2(256, 236))
	book.interacted.connect(_on_hero_book_interacted)


func _build_dungeon_portal() -> void:
	var portal: HubInteractable = _make_sprite_interactable("DungeonPortal", "DUNGEON", DUNGEON_PORTAL_TEXTURE, Vector2(400, 236))
	portal.interacted.connect(_on_dungeon_portal_interacted)


func _make_sprite_interactable(node_name: String, label: String, texture: Texture2D, pos: Vector2) -> HubInteractable:
	var inter: HubInteractable = HubInteractable.new()
	inter.name = node_name
	inter.label_text = label
	inter.label_offset = Vector2(0, -76)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = texture
	inter.add_child(sprite)
	var coll: CollisionShape2D = CollisionShape2D.new()
	var shape: CircleShape2D = CircleShape2D.new()
	shape.radius = 48.0
	coll.shape = shape
	inter.add_child(coll)
	inter.position = pos
	interactables_node.add_child(inter)
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
	# Selected character may have changed in the overlay — re-instantiate so
	# Player._ready() rebuilds sprite frames from the new stats. Cheaper than
	# reaching into private setup on the existing instance.
	if player != null and is_instance_valid(player):
		player.queue_free()
	_spawn_hub_player()

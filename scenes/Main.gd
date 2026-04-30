extends Node2D

# The "run scene". Spawns a fresh player using the selected character's stats
# (level + gear-applied), runs the dungeon, and transitions to RewardScreen
# when the run ends — victory or defeat.

@export var player_scene: PackedScene = preload("res://scenes/player/Player.tscn")
@export var camera_scene: PackedScene = preload("res://scenes/camera/ShakeCamera2D.tscn")
@export var hud_scene: PackedScene = preload("res://scenes/ui/HUD.tscn")
@export var boss_bar_scene: PackedScene = preload("res://scenes/ui/BossHealthBar.tscn")

# Fallback room pool if no dungeon is selected or its room_scenes is empty.
@export var fallback_room_pool: Array[PackedScene] = [
	preload("res://scenes/rooms/Room_1_1.tscn"),
	preload("res://scenes/rooms/Room_1_2.tscn"),
	preload("res://scenes/rooms/Room_1_3.tscn"),
	preload("res://scenes/rooms/Room_1_4.tscn"),
	preload("res://scenes/rooms/BossRoom.tscn"),
]

var room_pool: Array[PackedScene] = []

const REWARD_SCENE_PATH := "res://scenes/hub/RewardScreen.tscn"
const RUN_SUMMARY_SCENE_PATH := "res://scenes/hub/RunSummaryScreen.tscn"

var player: Player
var camera: ShakeCamera2D
var hud: HUD


func _ready() -> void:
	randomize()
	_ensure_run_stats()
	_resolve_room_pool()
	_spawn_player()
	_spawn_camera()
	_spawn_hud()
	_spawn_boss_bar()
	_connect_telemetry()
	if has_node("/root/UpgradeManager"):
		var um: Node = get_node("/root/UpgradeManager")
		if um.has_method("reset_for_new_run"):
			um.call("reset_for_new_run")
	DungeonManager.start_run(room_pool, player)


func _resolve_room_pool() -> void:
	# Pull the rooms from the player's currently-selected DungeonData; fall
	# back to the legacy hard-coded pool if nothing is wired up yet.
	var dd: DungeonData = GameState.get_dungeon(GameState.selected_dungeon)
	if dd != null and dd.room_scenes.size() > 0:
		room_pool = dd.room_scenes.duplicate()
		GameState.run_stats["dungeon_id"] = dd.dungeon_id
	else:
		room_pool = fallback_room_pool.duplicate()
		GameState.run_stats["dungeon_id"] = "verdant_crypt"


func _ensure_run_stats() -> void:
	# Reset run telemetry if entered without a hub transition (e.g. running Main directly)
	if GameState.run_stats.is_empty():
		GameState.run_stats = {
			"enemies_killed": 0,
			"bosses_killed": 0,
			"rooms_cleared": 0,
			"coins_collected": 0,
			"hits_taken": 0,
			"start_time_ms": Time.get_ticks_msec(),
		}


func _spawn_player() -> void:
	player = player_scene.instantiate() as Player
	if player == null:
		push_error("Main: Player scene didn't instantiate as Player")
		return
	# Apply character stats from GameState (level + gear scaled)
	var stats: PlayerStats = GameState.get_character_stats(GameState.selected_character)
	if stats != null:
		player.stats = stats
	add_child(player)
	# Sprite frames / portrait fallback are applied by Player._setup_sprite_frames()
	# during _ready, which runs as soon as add_child fires above.
	player.died.connect(_on_player_died)


func _spawn_camera() -> void:
	camera = camera_scene.instantiate() as ShakeCamera2D
	if camera == null or player == null:
		return
	player.add_child(camera)
	camera.make_current()


func _spawn_hud() -> void:
	hud = hud_scene.instantiate() as HUD
	if hud == null:
		return
	add_child(hud)
	if player != null:
		hud.bind_player(player)


func _spawn_boss_bar() -> void:
	var bar: Node = boss_bar_scene.instantiate()
	if bar == null:
		return
	bar.add_to_group("boss_health_bar")
	add_child(bar)


func _connect_telemetry() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.room_cleared.connect(_on_room_cleared_signal)
	DungeonManager.run_ended.connect(_on_run_ended)
	if player != null and player.health != null:
		player.health.damaged.connect(_on_player_damaged)


func _on_enemy_died(enemy: Node, _pos: Vector2) -> void:
	if enemy != null and enemy.is_in_group("boss"):
		GameState.run_stats["bosses_killed"] = int(GameState.run_stats.get("bosses_killed", 0)) + 1
	else:
		GameState.run_stats["enemies_killed"] = int(GameState.run_stats.get("enemies_killed", 0)) + 1


func _on_room_cleared_signal(_room: Node) -> void:
	GameState.run_stats["rooms_cleared"] = int(GameState.run_stats.get("rooms_cleared", 0)) + 1
	if hud != null and hud.has_method("update_kill_label"):
		hud.call("update_kill_label")


func _on_player_damaged(_amount: int, _source: Node) -> void:
	GameState.run_stats["hits_taken"] = int(GameState.run_stats.get("hits_taken", 0)) + 1


func _on_player_died() -> void:
	GameState.run_stats["victory"] = false
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(RUN_SUMMARY_SCENE_PATH)


func _on_run_ended(victory: bool) -> void:
	GameState.run_stats["victory"] = victory
	if not victory:
		# Player-died path handles death-to-reward; only handle the victory-finish here
		return
	# Unlock the next dungeon (if its requirement was clearing this one)
	var dungeon_id: String = str(GameState.run_stats.get("dungeon_id", ""))
	if dungeon_id != "":
		GameState.mark_dungeon_cleared(dungeon_id)
	await get_tree().create_timer(1.0).timeout
	get_tree().change_scene_to_file(RUN_SUMMARY_SCENE_PATH)


func quit_to_hub() -> void:
	# Called by the pause menu's "Quit Run" button
	GameState.run_stats["victory"] = false
	get_tree().change_scene_to_file(RUN_SUMMARY_SCENE_PATH)

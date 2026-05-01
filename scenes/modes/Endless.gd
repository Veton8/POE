extends Node2D

# Endless mode run scene. Renders a 270×480 portrait view via a
# SubViewport, displays it scaled-with-aspect inside the OS window
# via a TextureRect. The world is a 960×960 (60×60 tile) bounded
# arena with 4-tile soft slow-zone margins. Player abilities are
# wrapped with CharacterAbilityAutocastWrapper so Q/W/E auto-fire
# (no HUD slots, no input). Spawner spawns enemies in the angular
# distribution from the design doc and ramps density over time.

const PLAYER_SCENE: PackedScene = preload("res://scenes/player/Player.tscn")
const HUD_SCENE: PackedScene = preload("res://scenes/modes/EndlessHUD.tscn")
const RUN_SUMMARY_SCENE_PATH: String = "res://scenes/hub/RunSummaryScreen.tscn"

const PORTRAIT_W: int = 270
const PORTRAIT_H: int = 480
const TILE_SIZE: int = 16
const WORLD_TILES: int = 60
const WORLD_PX: int = WORLD_TILES * TILE_SIZE  # 960
const SLOW_MARGIN_TILES: int = 4
const SLOW_MARGIN_PX: int = SLOW_MARGIN_TILES * TILE_SIZE  # 64

const VIEW_HALF_W: int = PORTRAIT_W / 2  # 135
const VIEW_HALF_H: int = PORTRAIT_H / 2  # 240

var _viewport: SubViewport
var _display: TextureRect
var _world: Node2D
var _player: Player
var _camera: ShakeCamera2D
var _spawner: EndlessSpawner
var _hud: CanvasLayer

# Run-state for XP / level
var _xp_current: int = 0
var _level: int = 1
var _xp_bonus_mult: float = 1.0  # bumped by Curse Pillar destruction


func _ready() -> void:
	randomize()
	_ensure_run_stats()
	_build_render_tree()
	# Bullets and VFX must spawn inside the SubViewport's world so the
	# camera transform applies. These overrides are cleared in _exit_tree
	# (and on death/quit transitions).
	BulletPool.set_world_root(_world)
	VFX.set_world_root(_world)
	_build_world_floor()
	_build_slow_zones()
	_spawn_player()
	_build_camera()
	_wrap_abilities_for_autocast()
	_build_spawner()
	_build_hud()
	_connect_signals()
	if has_node("/root/UpgradeManager"):
		var um: Node = get_node("/root/UpgradeManager")
		if um.has_method("reset_for_new_run"):
			um.call("reset_for_new_run")


func _exit_tree() -> void:
	# Reparent pooled bullets back to the autoload container before our
	# SubViewport disappears, otherwise the pool entries become invalid.
	BulletPool.clear_world_root()
	VFX.clear_world_root()


func _ensure_run_stats() -> void:
	if GameState.run_stats.is_empty():
		GameState.run_stats = {
			"enemies_killed": 0,
			"bosses_killed": 0,
			"rooms_cleared": 0,
			"coins_collected": 0,
			"hits_taken": 0,
			"start_time_ms": Time.get_ticks_msec(),
			"mode": "endless",
		}
	else:
		GameState.run_stats["mode"] = "endless"


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

	# Display layer — scales the SubViewport texture to fit OS window
	# while preserving aspect (letterbox).
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


func _build_world_floor() -> void:
	# Placeholder programmatic floor — replace with a TileMapLayer
	# once the new endless biome tileset is authored.
	var floor: ColorRect = ColorRect.new()
	floor.color = Color(0.10, 0.16, 0.13)
	floor.size = Vector2(WORLD_PX, WORLD_PX)
	floor.position = Vector2.ZERO
	floor.z_index = -10
	floor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_world.add_child(floor)
	# Sprinkle dirt patches for visual variety
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 0x90F7E183
	for i: int in 60:
		var patch: ColorRect = ColorRect.new()
		patch.color = Color(0.07, 0.11, 0.09)
		var w: float = rng.randf_range(20.0, 56.0)
		var h: float = rng.randf_range(16.0, 40.0)
		patch.size = Vector2(w, h)
		patch.position = Vector2(rng.randf_range(0, WORLD_PX - w), rng.randf_range(0, WORLD_PX - h))
		patch.z_index = -9
		patch.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_world.add_child(patch)


func _build_slow_zones() -> void:
	# 4-tile margin slow-zones along each world edge. Soft-wall effect.
	var zones: Array[Dictionary] = [
		{"pos": Vector2(0, 0), "size": Vector2(WORLD_PX, SLOW_MARGIN_PX)},                          # top
		{"pos": Vector2(0, WORLD_PX - SLOW_MARGIN_PX), "size": Vector2(WORLD_PX, SLOW_MARGIN_PX)},  # bottom
		{"pos": Vector2(0, SLOW_MARGIN_PX), "size": Vector2(SLOW_MARGIN_PX, WORLD_PX - 2 * SLOW_MARGIN_PX)},                         # left
		{"pos": Vector2(WORLD_PX - SLOW_MARGIN_PX, SLOW_MARGIN_PX), "size": Vector2(SLOW_MARGIN_PX, WORLD_PX - 2 * SLOW_MARGIN_PX)}, # right
	]
	for z: Dictionary in zones:
		var area: SlowZone = SlowZone.new()
		area.name = "SlowZone"
		area.collision_layer = 0
		area.collision_mask = 1  # Player layer
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = z["size"]
		shape.shape = rect
		shape.position = (z["size"] as Vector2) * 0.5
		area.add_child(shape)
		area.position = z["pos"]
		# Visual tint so the slow-zone is readable at low contrast
		var tint: ColorRect = ColorRect.new()
		tint.size = z["size"]
		tint.color = Color(0, 0, 0, 0.28)
		tint.z_index = -8
		tint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		area.add_child(tint)
		_world.add_child(area)


func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate() as Player
	if _player == null:
		push_error("Endless: Player scene didn't instantiate as Player")
		return
	var stats: PlayerStats = GameState.get_character_stats(GameState.selected_character)
	if stats != null:
		_player.stats = stats
	_player.global_position = Vector2(WORLD_PX, WORLD_PX) * 0.5
	_world.add_child(_player)
	_player.died.connect(_on_player_died)


func _build_camera() -> void:
	# Camera lives as a Player child so it follows automatically.
	# Limits constrain to the world rect minus half the viewport so
	# the camera never reveals beyond the slow-zone outer edge.
	_camera = ShakeCamera2D.new()
	_player.add_child(_camera)
	_camera.make_current()
	# Override _ready()'s landscape-mode defaults
	_camera.limit_left = VIEW_HALF_W
	_camera.limit_top = VIEW_HALF_H
	_camera.limit_right = WORLD_PX - VIEW_HALF_W
	_camera.limit_bottom = WORLD_PX - VIEW_HALF_H
	_camera.offset = Vector2(0, -24)  # bias player ~5% below center
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 8.0


func _wrap_abilities_for_autocast() -> void:
	# Endless mode: every Ability child of the player auto-fires via
	# CharacterAbilityAutocastWrapper. The Q/W/E HUD is not built; the
	# wrappers tick each physics frame and call try_activate() when the
	# ability's target_strategy permits.
	var ab_root: Node = _player.get_node_or_null("Abilities")
	if ab_root == null:
		return
	for c: Node in ab_root.get_children():
		if c is Ability:
			var ability: Ability = c as Ability
			var wrapper: CharacterAbilityAutocastWrapper = CharacterAbilityAutocastWrapper.new()
			wrapper.name = "AutocastWrapper_" + ability.name
			ability.add_child(wrapper)
			wrapper.bind(ability)


func _build_spawner() -> void:
	_spawner = EndlessSpawner.new()
	_spawner.name = "EndlessSpawner"
	# v1 enemy roster — pulled from existing verdant pool plus a few
	# cross-biome flavors so the endless feel isn't tied to one dungeon.
	# Real endless biome enemies will replace these later.
	_spawner.enemy_pool = [
		preload("res://scenes/enemies/Slime.tscn"),
		preload("res://scenes/enemies/Dasher.tscn"),
		preload("res://scenes/enemies/Archer.tscn"),
		preload("res://scenes/enemies/SporePuffer.tscn"),
	]
	_spawner.elite_pool = [
		preload("res://scenes/enemies/MossbackTank.tscn"),
		preload("res://scenes/enemies/RootBomber.tscn"),
	]
	_spawner.boss_pool = [
		preload("res://scenes/enemies/bosses/verdant/ThornBrute.tscn"),
		preload("res://scenes/enemies/bosses/verdant/WraithWarden.tscn"),
		preload("res://scenes/enemies/bosses/verdant/PoisonBloom.tscn"),
	]
	_world.add_child(_spawner)
	_spawner.attach(_player, _world)


func _build_hud() -> void:
	if HUD_SCENE == null:
		return
	_hud = HUD_SCENE.instantiate() as CanvasLayer
	if _hud == null:
		return
	add_child(_hud)
	if _hud.has_method("bind"):
		_hud.call("bind", _player, _spawner, self)


func _connect_signals() -> void:
	Events.enemy_died.connect(_on_enemy_died)
	Events.xp_collected.connect(_on_xp_collected)


func _on_enemy_died(enemy: Node, pos: Vector2) -> void:
	GameState.run_stats["enemies_killed"] = int(GameState.run_stats.get("enemies_killed", 0)) + 1
	_drop_xp_orb(enemy, pos)


func _drop_xp_orb(enemy: Node, pos: Vector2) -> void:
	# Tier picked by enemy-group affiliation as a v1 placeholder.
	# Later: read from EnemyData resource per-type.
	var tier: int = XPOrb.Tier.GREEN
	if enemy != null and enemy.is_in_group("boss"):
		tier = XPOrb.Tier.RED
	elif enemy != null and enemy.is_in_group("elite"):
		tier = XPOrb.Tier.YELLOW
	elif randf() < 0.18:
		tier = XPOrb.Tier.BLUE
	var orb: XPOrb = XPOrb.new()
	orb.global_position = pos
	orb.configure(tier)
	_world.add_child(orb)


func _on_xp_collected(amount: int) -> void:
	_xp_current += int(round(float(amount) * _xp_bonus_mult))
	while _xp_current >= xp_to_next_level(_level):
		_xp_current -= xp_to_next_level(_level)
		_level_up()


func apply_xp_bonus(extra: float) -> void:
	# Called by CursePillar on death — permanent +extra fraction to
	# every XP gain for the rest of the run.
	_xp_bonus_mult += extra


func xp_to_next_level(lvl: int) -> int:
	# Curve from research doc.
	if lvl == 1: return 5
	if lvl == 2: return 12
	if lvl == 3: return 20
	if lvl < 10: return 20 + (lvl - 3) * 8
	if lvl < 20: return 20 + 6 * 8 + (lvl - 9) * 12
	if lvl < 30: return 20 + 6 * 8 + 10 * 12 + (lvl - 19) * 16
	return 20 + 6 * 8 + 10 * 12 + 10 * 16 + (lvl - 29) * 22


func _level_up() -> void:
	_level += 1
	# Levels 1-20: every level. 21+: every odd level.
	var should_offer: bool = _level <= 20 or (_level % 2 == 1)
	if not should_offer:
		return
	if has_node("/root/UpgradeManager"):
		var um: Node = get_node("/root/UpgradeManager")
		if um.has_method("offer_picks"):
			um.call("offer_picks")


func get_level() -> int:
	return _level


func get_xp_progress() -> float:
	var need: int = xp_to_next_level(_level)
	if need <= 0:
		return 0.0
	return clampf(float(_xp_current) / float(need), 0.0, 1.0)


func get_run_seconds() -> float:
	if _spawner == null:
		return 0.0
	return _spawner.get_run_time()


func _on_player_died() -> void:
	GameState.run_stats["victory"] = false
	GameState.run_stats["time_survived_ms"] = Time.get_ticks_msec() - int(GameState.run_stats.get("start_time_ms", Time.get_ticks_msec()))
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file(RUN_SUMMARY_SCENE_PATH)

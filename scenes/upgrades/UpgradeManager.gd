extends Node

# Autoload — holds the active run's build state and applies upgrades to the
# active player. Listens for Events.room_cleared to push the choice screen.

const CHOICE_SCREEN_SCENE: PackedScene = preload("res://scenes/upgrades/UpgradeChoiceScreen.tscn")
const SKIP_BASE_REWARD: int = 25
const SKIP_DEPTH_BONUS: int = 12
const REROLL_BASE_COST: int = 10
const REROLL_PER_USE_COST: int = 5

var owned_stacks: Dictionary = {}      # StringName -> int
var owned_tags: Dictionary = {}        # StringName -> int
var banished_ids: Array[StringName] = []


func _ready() -> void:
	if has_node("/root/Events"):
		var ev: Node = get_node("/root/Events")
		if ev.has_signal("room_cleared"):
			ev.connect("room_cleared", _on_room_cleared_event)


func reset_for_new_run() -> void:
	owned_stacks.clear()
	owned_tags.clear()
	banished_ids.clear()


func apply(upgrade: UpgradeData) -> void:
	if upgrade == null:
		return
	var prev: int = int(owned_stacks.get(upgrade.id, 0))
	owned_stacks[upgrade.id] = prev + 1
	for tag: StringName in upgrade.tags:
		owned_tags[tag] = int(owned_tags.get(tag, 0)) + 1
	_apply_stat_modifiers(upgrade)
	if upgrade.component_to_attach != null:
		_attach_component(upgrade.component_to_attach)
	if upgrade.apply_callback != &"":
		var cb_name: String = String(upgrade.apply_callback)
		if has_method(cb_name):
			call(cb_name, upgrade)
	_save_codex_seen(upgrade.id)


func _apply_stat_modifiers(upgrade: UpgradeData) -> void:
	var player: Node = _get_player()
	if player == null:
		return
	for mod: UpgradeStatModifier in upgrade.stat_modifiers:
		if mod == null:
			continue
		var path: NodePath = mod.stat_path
		if path.is_empty():
			continue
		match mod.op:
			UpgradeStatModifier.Op.ADD:
				var current_a: Variant = player.get_indexed(path)
				if current_a is float:
					player.set_indexed(path, (current_a as float) + mod.value)
				elif current_a is int:
					player.set_indexed(path, int(current_a) + int(round(mod.value)))
			UpgradeStatModifier.Op.MULT:
				var current_m: Variant = player.get_indexed(path)
				if current_m is float:
					player.set_indexed(path, (current_m as float) * mod.value)
				elif current_m is int:
					player.set_indexed(path, int(round(float(int(current_m)) * mod.value)))
			UpgradeStatModifier.Op.SET:
				player.set_indexed(path, mod.value)
			_:
				pass  # PER_STACK ops handled by compute_effective_value (Phase B)


func _attach_component(scene: PackedScene) -> void:
	var player: Node = _get_player()
	if player == null:
		return
	var c: Node = scene.instantiate()
	if c == null:
		return
	player.add_child(c)
	if c.has_method("attach_to"):
		c.call("attach_to", player)


func _get_player() -> Node:
	var nodes: Array[Node] = get_tree().get_nodes_in_group("player")
	if nodes.size() > 0:
		return nodes[0]
	return null


func _on_room_cleared_event(room: Node) -> void:
	if not _should_offer(room):
		return
	offer_picks()


# Public — called by either room-clear (dungeon mode) or level-up (endless).
# Builds picks against the current dungeon's rarity curve and pushes the
# 3-card overlay onto the active scene.
func offer_picks(count: int = 3) -> void:
	var hero_id: StringName = StringName(GameState.selected_character)
	var dungeon_idx: int = _dungeon_index()
	var rarity_curve: Dictionary = _rarity_curve_for_dungeon(dungeon_idx)
	var picks: Array[UpgradeData] = UpgradeRegistry.roll_offer(count, hero_id, owned_stacks, rarity_curve)
	if picks.is_empty():
		return
	var screen: Node = CHOICE_SCREEN_SCENE.instantiate()
	if screen == null:
		return
	get_tree().current_scene.add_child(screen)
	if screen.has_method("present"):
		screen.call_deferred("present", picks)


func _should_offer(_room: Node) -> bool:
	var dungeon_idx: int = _dungeon_index()
	var chance: float = 0.65 + 0.10 * float(dungeon_idx)
	return randf() < chance


func _dungeon_index() -> int:
	var did: String = str(GameState.selected_dungeon)
	match did:
		"verdant_crypt": return 0
		"sunken_archive": return 1
		"bone_choir": return 2
		_: return 0


func _rarity_curve_for_dungeon(idx: int) -> Dictionary:
	match idx:
		0:
			return {
				UpgradeData.Rarity.COMMON: 60.0,
				UpgradeData.Rarity.UNCOMMON: 30.0,
				UpgradeData.Rarity.RARE: 8.0,
				UpgradeData.Rarity.EPIC: 2.0,
				UpgradeData.Rarity.LEGENDARY: 0.0,
			}
		1:
			return {
				UpgradeData.Rarity.COMMON: 35.0,
				UpgradeData.Rarity.UNCOMMON: 35.0,
				UpgradeData.Rarity.RARE: 22.0,
				UpgradeData.Rarity.EPIC: 7.0,
				UpgradeData.Rarity.LEGENDARY: 1.0,
			}
		_:
			return {
				UpgradeData.Rarity.COMMON: 15.0,
				UpgradeData.Rarity.UNCOMMON: 25.0,
				UpgradeData.Rarity.RARE: 30.0,
				UpgradeData.Rarity.EPIC: 25.0,
				UpgradeData.Rarity.LEGENDARY: 5.0,
			}


func skip_reward() -> int:
	return SKIP_BASE_REWARD + SKIP_DEPTH_BONUS * _dungeon_index()


func reroll_cost(times_used_this_room: int) -> int:
	return REROLL_BASE_COST + REROLL_PER_USE_COST * times_used_this_room


func reroll(_times_used_this_room: int, hero_id: StringName) -> Array[UpgradeData]:
	var rarity_curve: Dictionary = _rarity_curve_for_dungeon(_dungeon_index())
	return UpgradeRegistry.roll_offer(3, hero_id, owned_stacks, rarity_curve)


func _save_codex_seen(id: StringName) -> void:
	if has_node("/root/GameState"):
		var gs: Node = get_node("/root/GameState")
		if gs.has_method("save_codex_seen"):
			gs.call("save_codex_seen", id)


# ---------------- apply_callbacks ----------------
# Each callback receives the UpgradeData and pulls the active player on demand.
# Referenced by UpgradeData.apply_callback (StringName matching the function name).

func _apply_iron_skin(_u: UpgradeData) -> void:
	# stat_modifier already bumped stats.max_hp; sync the live HealthComponent
	# so the player's HP bar reflects the new ceiling and gain the bonus HP.
	var p: Player = _get_player() as Player
	if p == null or p.health == null:
		return
	p.health.max_hp = p.stats.max_hp
	p.health.heal(1)


func _apply_burn_coat(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	p.bullet_burn_dps += 2.0
	p.bullet_burn_duration = maxf(p.bullet_burn_duration, 2.0)


func _apply_knockback(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	p.bullet_knockback -= 8.0  # negative = push away on hit


func _apply_big_bullet(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	p.bullet_size_mul *= 1.4
	p.stats.damage += 2
	p.stats.fire_rate *= 0.85
	if p.fire_timer != null:
		p.fire_timer.wait_time = 1.0 / p.stats.fire_rate


func _apply_spread_shot(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	p.extra_projectiles += 1
	p.bullet_spread_extra += deg_to_rad(14.0)


func _apply_dash_plus(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var ab_root: Node = p.get_node_or_null("Abilities")
	if ab_root == null:
		return
	for c: Node in ab_root.get_children():
		if c is DashAbility:
			var d: DashAbility = c as DashAbility
			d.cooldown_seconds = maxf(0.5, d.cooldown_seconds * 0.75)


func _apply_phase_step(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var ab_root: Node = p.get_node_or_null("Abilities")
	if ab_root == null:
		return
	for c: Node in ab_root.get_children():
		if c is DashAbility:
			var d: DashAbility = c as DashAbility
			d.i_frames_seconds += 0.25
			d.dash_distance += 24.0


func _apply_vital_surge(_u: UpgradeData) -> void:
	# Spawns a per-frame regen ticker child on the player.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("VitalSurgeTicker"):
		var t: Node = p.get_node("VitalSurgeTicker")
		if t.has_method("bump"):
			t.call("bump")
		return
	var ticker: VitalSurgeTicker = VitalSurgeTicker.new()
	ticker.name = "VitalSurgeTicker"
	p.add_child(ticker)


func _apply_gear_ramp(_u: UpgradeData) -> void:
	# Anime callback: hooks bullet_hit to ramp fire_rate temporarily.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("GearRampHandler"):
		return
	var handler: GearRampHandler = GearRampHandler.new()
	handler.name = "GearRampHandler"
	p.add_child(handler)


func _apply_hollow_mask(_u: UpgradeData) -> void:
	# Anime callback: bonus damage when below 40% HP. Persists for the run.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("HollowMaskHandler"):
		return
	var handler: HollowMaskHandler = HollowMaskHandler.new()
	handler.name = "HollowMaskHandler"
	p.add_child(handler)


func _apply_domain_void(_u: UpgradeData) -> void:
	# Legendary: every 18s, freeze all enemies on screen for 2s.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("DomainVoidTicker"):
		return
	var t: DomainVoidTicker = DomainVoidTicker.new()
	t.name = "DomainVoidTicker"
	p.add_child(t)


func _apply_spirit_bomb(_u: UpgradeData) -> void:
	# Legendary: +5% damage per kill (capped +200%), resets on hit taken.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("SpiritBombStacker"):
		return
	var s: SpiritBombStacker = SpiritBombStacker.new()
	s.name = "SpiritBombStacker"
	p.add_child(s)

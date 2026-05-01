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


# ---------- Slice 2B autocast cards ----------

func _attach_blue_orbital(_u: UpgradeData) -> void:
	# Gojo orbital pull aura. LINEAR cap 4 — first stack instantiates,
	# subsequent stacks bump orbit_count up to 4.
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("BlueOrbitalManager")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var mgr: BlueOrbitalManager = BlueOrbitalManager.new()
	mgr.name = "BlueOrbitalManager"
	p.add_child(mgr)
	mgr.attach_to(p)


func _attach_kamehameha_lance(_u: UpgradeData) -> void:
	# Goku timed beam. UNIQUE — only ever one ticker.
	var p: Player = _get_player() as Player
	if p == null:
		return
	if p.has_node("KamehamehaLanceTicker"):
		return
	var ticker: KamehamehaLanceTicker = KamehamehaLanceTicker.new()
	ticker.name = "KamehamehaLanceTicker"
	p.add_child(ticker)


func _attach_name_inscribed(_u: UpgradeData) -> void:
	# Light mark+detonate. LINEAR cap 5 — first stack instantiates,
	# subsequent stacks bump per-hit chance.
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("NameInscribedListener")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var lis: NameInscribedListener = NameInscribedListener.new()
	lis.name = "NameInscribedListener"
	p.add_child(lis)
	lis.attach_to(p)


# ---------- Slice 2C: full autocast catalog ----------

func _attach_hollow_purple(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("HollowPurpleTicker"):
		return
	var t: HollowPurpleTicker = HollowPurpleTicker.new()
	t.name = "HollowPurpleTicker"
	p.add_child(t)


func _attach_six_eyes(_u: UpgradeData) -> void:
	# Crit chance bump handled via stat_modifiers in the .tres.
	# Ticker handles the every-6s viewport mark.
	var p: Player = _get_player() as Player
	if p == null or p.has_node("SixEyesTicker"):
		return
	var t: SixEyesTicker = SixEyesTicker.new()
	t.name = "SixEyesTicker"
	p.add_child(t)


func _attach_kaioken_overdrive(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("KaiokenStateTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: KaiokenStateTicker = KaiokenStateTicker.new()
	t.name = "KaiokenStateTicker"
	p.add_child(t)


func _attach_spirit_bomb_legacy(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("SpiritBombLegacyTicker"):
		return
	var t: SpiritBombLegacyTicker = SpiritBombLegacyTicker.new()
	t.name = "SpiritBombLegacyTicker"
	p.add_child(t)
	t.attach_to(p)


func _attach_hiken_jab(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("HikenJabTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: HikenJabTicker = HikenJabTicker.new()
	t.name = "HikenJabTicker"
	p.add_child(t)


func _attach_enjomo_curtain(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("EnjomoCurtainTicker"):
		return
	var t: EnjomoCurtainTicker = EnjomoCurtainTicker.new()
	t.name = "EnjomoCurtainTicker"
	p.add_child(t)


func _attach_logia_phase(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("LogiaPhaseWatcher")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var w: LogiaPhaseWatcher = LogiaPhaseWatcher.new()
	w.name = "LogiaPhaseWatcher"
	p.add_child(w)
	w.attach_to(p)


func _attach_jet_gatling_burst(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("JetGatlingBurstTicker"):
		return
	var t: JetGatlingBurstTicker = JetGatlingBurstTicker.new()
	t.name = "JetGatlingBurstTicker"
	p.add_child(t)


func _attach_elephant_gun_slam(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("ElephantGunSlamTicker"):
		return
	var t: ElephantGunSlamTicker = ElephantGunSlamTicker.new()
	t.name = "ElephantGunSlamTicker"
	p.add_child(t)


func _attach_serious_punch_aura(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("SeriousPunchTicker"):
		return
	var t: SeriousPunchTicker = SeriousPunchTicker.new()
	t.name = "SeriousPunchTicker"
	p.add_child(t)


func _attach_consecutive_normal(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("ConsecutiveNormalTicker"):
		return
	var t: ConsecutiveNormalTicker = ConsecutiveNormalTicker.new()
	t.name = "ConsecutiveNormalTicker"
	p.add_child(t)


func _attach_serious_sideways(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("SeriousSidewaysWatcher"):
		return
	var w: SeriousSidewaysWatcher = SeriousSidewaysWatcher.new()
	w.name = "SeriousSidewaysWatcher"
	p.add_child(w)
	w.attach_to(p)


func _attach_rasengan_burst(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("RasenganBurstTicker"):
		return
	var t: RasenganBurstTicker = RasenganBurstTicker.new()
	t.name = "RasenganBurstTicker"
	p.add_child(t)


func _attach_rasenshuriken_finisher(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("RasenshurikenTicker"):
		return
	var t: RasenshurikenTicker = RasenshurikenTicker.new()
	t.name = "RasenshurikenTicker"
	p.add_child(t)


func _attach_hardening_spikes(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("HardeningSpikesTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: HardeningSpikesTicker = HardeningSpikesTicker.new()
	t.name = "HardeningSpikesTicker"
	p.add_child(t)


func _attach_founding_roar(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("FoundingRoarWatcher"):
		return
	var w: FoundingRoarWatcher = FoundingRoarWatcher.new()
	w.name = "FoundingRoarWatcher"
	p.add_child(w)
	w.attach_to(p)


func _attach_water_breathing(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("WaterBreathingTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: WaterBreathingTicker = WaterBreathingTicker.new()
	t.name = "WaterBreathingTicker"
	p.add_child(t)


func _attach_hinokami_pulse(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("HinokamiStateTicker"):
		return
	var t: HinokamiStateTicker = HinokamiStateTicker.new()
	t.name = "HinokamiStateTicker"
	p.add_child(t)


func _attach_nichirin_focus(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("NichirinFocusListener")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var l: NichirinFocusListener = NichirinFocusListener.new()
	l.name = "NichirinFocusListener"
	p.add_child(l)
	l.attach_to(p)


func _attach_odm_dash_volley(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("OdmDashVolleyTicker"):
		return
	var t: OdmDashVolleyTicker = OdmDashVolleyTicker.new()
	t.name = "OdmDashVolleyTicker"
	p.add_child(t)


func _attach_thunder_spear_volley(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("ThunderSpearVolleyTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: ThunderSpearVolleyTicker = ThunderSpearVolleyTicker.new()
	t.name = "ThunderSpearVolleyTicker"
	p.add_child(t)


func _attach_humanitys_strongest(_u: UpgradeData) -> void:
	# Crit damage bump handled via stat_modifiers; listener handles
	# the on-crit follow-up slash.
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("HumanitysStrongestListener")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var l: HumanitysStrongestListener = HumanitysStrongestListener.new()
	l.name = "HumanitysStrongestListener"
	p.add_child(l)
	l.attach_to(p)


func _attach_shinigami_eyes(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null:
		return
	var existing: Node = p.get_node_or_null("ShinigamiEyesTicker")
	if existing != null and existing.has_method("bump"):
		existing.call("bump")
		return
	var t: ShinigamiEyesTicker = ShinigamiEyesTicker.new()
	t.name = "ShinigamiEyesTicker"
	p.add_child(t)


func _attach_thirteen_day_curse(_u: UpgradeData) -> void:
	var p: Player = _get_player() as Player
	if p == null or p.has_node("ThirteenDayTicker"):
		return
	var t: ThirteenDayTicker = ThirteenDayTicker.new()
	t.name = "ThirteenDayTicker"
	p.add_child(t)

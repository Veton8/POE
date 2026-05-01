extends Node

# Persistent meta-progression singleton. Auto-loaded as "GameState".
# Saves/loads to user://save.dat as JSON.

const SAVE_PATH := "user://save.dat"
const GEAR_DIR := "res://resources/data/gear/"
const SAVE_VERSION: int = 2  # bump on schema change; read path tolerates older

const RARITY_NAMES: Array[String] = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
const RARITY_COLORS: Array[Color] = [
	Color("#FFFFFF"),
	Color("#4CAF50"),
	Color("#2196F3"),
	Color("#9C27B0"),
	Color("#FF9800"),
]
const RARITY_SALVAGE: Array[int] = [10, 25, 50, 100, 250]

# Currencies
var coins: int = 0
var gems: int = 0
var skill_points: int = 0

# Characters
var unlocked_characters: Array[String] = ["luffy"]
var selected_character: String = "luffy"
var character_levels: Dictionary = {"luffy": 1}

# Gear
var equipped_gear: Dictionary = {"weapon": "", "armor": "", "trinket": "", "pet": ""}
var inventory: Array[Dictionary] = []

# Talents (placeholder for future)
var talents_unlocked: Array[String] = []
var talents_active: Array[String] = []
var grasp_budget: int = 3

# Dungeons
var unlocked_dungeons: Array[String] = ["verdant_crypt"]
var selected_dungeon: String = "verdant_crypt"
var cleared_dungeons: Array[String] = []
# Endless mode unlocks after first dungeon clear (any hero, any dungeon).
var endless_unlocked: bool = false

# Upgrade codex (Phase A power-up persistence). Stored in save.dat as String
# arrays for forward-compat. Used as a Set via membership checks.
var seen_upgrade_ids: Array[String] = []
var evolved_upgrade_ids: Array[String] = []

# Last-run telemetry — populated by RunManager / Main.gd, consumed by RewardScreen
var run_stats: Dictionary = {}

# Gear template registry, loaded from disk at startup
var _gear_templates: Dictionary = {}

# Dungeon manifests, loaded from disk at startup
const DUNGEON_DIR: String = "res://resources/data/dungeons/"
const DUNGEON_ORDER: Array[String] = ["verdant_crypt", "sunken_archive", "bone_choir"]
var _dungeons: Dictionary = {}

# Character unlock costs. Each entry: {"currency": "coins"|"gems", "amount": int}.
const CHARACTER_UNLOCK_COSTS: Dictionary = {
	"luffy": {"currency": "coins", "amount": 0},
	"ace": {"currency": "gems", "amount": 600},
	"goku": {"currency": "gems", "amount": 1200},
	"gojo": {"currency": "gems", "amount": 1500},
	"saitama": {"currency": "gems", "amount": 800},
	"naruto_uzumaki": {"currency": "coins", "amount": 1500},
	"eren_yeager": {"currency": "coins", "amount": 500},
	"tanjiro_kamado": {"currency": "coins", "amount": 500},
	"levi_ackerman": {"currency": "coins", "amount": 1500},
	"light_yagami": {"currency": "coins", "amount": 1500},
}

# Character stats resource paths
const CHARACTER_STATS_PATHS: Dictionary = {
	"luffy": "res://resources/data/luffy_stats.tres",
	"ace": "res://resources/data/ace_stats.tres",
	"goku": "res://resources/data/goku_stats.tres",
	"gojo": "res://resources/data/gojo_stats.tres",
	"saitama": "res://resources/data/saitama_stats.tres",
	"naruto_uzumaki": "res://resources/data/naruto_stats.tres",
	"eren_yeager": "res://resources/data/eren_stats.tres",
	"tanjiro_kamado": "res://resources/data/tanjiro_stats.tres",
	"levi_ackerman": "res://resources/data/levi_stats.tres",
	"light_yagami": "res://resources/data/light_stats.tres",
}


func _ready() -> void:
	_load_gear_templates()
	_load_dungeons()
	if FileAccess.file_exists(SAVE_PATH):
		load_save()
	else:
		_seed_starter_inventory()
		save()


# ---------- Persistence ----------

func save() -> void:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"coins": coins,
		"gems": gems,
		"skill_points": skill_points,
		"unlocked_characters": unlocked_characters,
		"selected_character": selected_character,
		"character_levels": character_levels,
		"equipped_gear": equipped_gear,
		"inventory": inventory,
		"talents_unlocked": talents_unlocked,
		"talents_active": talents_active,
		"grasp_budget": grasp_budget,
		"unlocked_dungeons": unlocked_dungeons,
		"selected_dungeon": selected_dungeon,
		"cleared_dungeons": cleared_dungeons,
		"endless_unlocked": endless_unlocked,
		"seen_upgrade_ids": seen_upgrade_ids,
		"evolved_upgrade_ids": evolved_upgrade_ids,
	}
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_error("GameState: failed to open save file for writing")
		return
	f.store_string(JSON.stringify(data))
	f.close()


func load_save() -> void:
	var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var raw: String = f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: save file is not a Dictionary, ignoring")
		return
	var data: Dictionary = parsed as Dictionary
	# Save schema is forward-tolerant: any missing key falls back to a default,
	# so v1 saves load fine into v2. We only check `version` to log surprises.
	var ver: int = int(data.get("version", 1))
	if ver > SAVE_VERSION:
		push_warning("GameState: save version %d is newer than client %d — fields may be ignored" % [ver, SAVE_VERSION])
	coins = int(data.get("coins", 0))
	gems = int(data.get("gems", 0))
	skill_points = int(data.get("skill_points", 0))
	var uc: Variant = data.get("unlocked_characters", ["luffy"])
	if uc is Array:
		unlocked_characters.clear()
		for x: Variant in (uc as Array):
			var id: String = str(x)
			# Drop legacy IDs that are no longer in the roster
			if CHARACTER_STATS_PATHS.has(id):
				unlocked_characters.append(id)
	if unlocked_characters.is_empty():
		unlocked_characters.append("luffy")
	selected_character = str(data.get("selected_character", "luffy"))
	if not unlocked_characters.has(selected_character):
		selected_character = unlocked_characters[0]
	character_levels = data.get("character_levels", {"luffy": 1}) as Dictionary
	equipped_gear = data.get("equipped_gear", {"weapon": "", "armor": "", "trinket": "", "pet": ""}) as Dictionary
	# Ensure all slots exist
	for slot: String in ["weapon", "armor", "trinket", "pet"]:
		if not equipped_gear.has(slot):
			equipped_gear[slot] = ""
	var inv: Variant = data.get("inventory", [])
	inventory.clear()
	if inv is Array:
		for entry: Variant in (inv as Array):
			if entry is Dictionary:
				inventory.append(entry as Dictionary)
	var tu: Variant = data.get("talents_unlocked", [])
	if tu is Array:
		talents_unlocked.clear()
		for x: Variant in (tu as Array):
			talents_unlocked.append(str(x))
	var ta: Variant = data.get("talents_active", [])
	if ta is Array:
		talents_active.clear()
		for x: Variant in (ta as Array):
			talents_active.append(str(x))
	grasp_budget = int(data.get("grasp_budget", 3))
	var ud: Variant = data.get("unlocked_dungeons", ["verdant_crypt"])
	if ud is Array:
		unlocked_dungeons.clear()
		for x: Variant in (ud as Array):
			unlocked_dungeons.append(str(x))
	if not unlocked_dungeons.has("verdant_crypt"):
		unlocked_dungeons.append("verdant_crypt")
	selected_dungeon = str(data.get("selected_dungeon", "verdant_crypt"))
	if not unlocked_dungeons.has(selected_dungeon):
		selected_dungeon = "verdant_crypt"
	var seen: Variant = data.get("seen_upgrade_ids", [])
	if seen is Array:
		seen_upgrade_ids.clear()
		for x: Variant in (seen as Array):
			seen_upgrade_ids.append(str(x))
	var evolved: Variant = data.get("evolved_upgrade_ids", [])
	if evolved is Array:
		evolved_upgrade_ids.clear()
		for x: Variant in (evolved as Array):
			evolved_upgrade_ids.append(str(x))
	var cd: Variant = data.get("cleared_dungeons", [])
	if cd is Array:
		cleared_dungeons.clear()
		for x: Variant in (cd as Array):
			cleared_dungeons.append(str(x))
	endless_unlocked = bool(data.get("endless_unlocked", false))
	# Backfill: any save with a cleared dungeon should have endless unlocked.
	if not endless_unlocked and not cleared_dungeons.is_empty():
		endless_unlocked = true


# ---------- Dungeon registry ----------

func _load_dungeons() -> void:
	_dungeons.clear()
	var dir: DirAccess = DirAccess.open(DUNGEON_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var path: String = DUNGEON_DIR + fname
			var res: Resource = load(path)
			if res is DungeonData:
				var dd: DungeonData = res as DungeonData
				_dungeons[dd.dungeon_id] = dd
		fname = dir.get_next()
	dir.list_dir_end()


func get_dungeon(dungeon_id: String) -> DungeonData:
	if _dungeons.has(dungeon_id):
		return _dungeons[dungeon_id] as DungeonData
	return null


# ---------- Upgrade codex ----------

func save_codex_seen(id: StringName) -> void:
	var s: String = String(id)
	if s == "":
		return
	if not seen_upgrade_ids.has(s):
		seen_upgrade_ids.append(s)
		save()


func is_codex_seen(id: StringName) -> bool:
	return seen_upgrade_ids.has(String(id))


func mark_evolution_unlocked(id: StringName) -> void:
	var s: String = String(id)
	if s == "":
		return
	if not evolved_upgrade_ids.has(s):
		evolved_upgrade_ids.append(s)
		save()


func get_all_dungeons_in_order() -> Array[DungeonData]:
	var out: Array[DungeonData] = []
	for id: String in DUNGEON_ORDER:
		if _dungeons.has(id):
			out.append(_dungeons[id] as DungeonData)
	return out


func is_dungeon_unlocked(dungeon_id: String) -> bool:
	return unlocked_dungeons.has(dungeon_id)


func mark_dungeon_cleared(dungeon_id: String) -> void:
	if not cleared_dungeons.has(dungeon_id):
		cleared_dungeons.append(dungeon_id)
	# Auto-unlock the next dungeon if its requirement was clearing this one
	for dd: DungeonData in get_all_dungeons_in_order():
		if not is_dungeon_unlocked(dd.dungeon_id) and dd.unlock_requirement == "complete:" + dungeon_id:
			unlocked_dungeons.append(dd.dungeon_id)
	# First-clear of any dungeon unlocks endless mode for this profile.
	if not endless_unlocked:
		endless_unlocked = true
	save()


func select_dungeon(dungeon_id: String) -> void:
	if is_dungeon_unlocked(dungeon_id):
		selected_dungeon = dungeon_id
		save()


# ---------- Gear template registry ----------

func _load_gear_templates() -> void:
	_gear_templates.clear()
	var dir: DirAccess = DirAccess.open(GEAR_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var fname: String = dir.get_next()
	while fname != "":
		if not dir.current_is_dir() and fname.ends_with(".tres"):
			var path: String = GEAR_DIR + fname
			var res: Resource = load(path)
			if res is GearItem:
				var gi: GearItem = res as GearItem
				_gear_templates[gi.item_id] = gi
		fname = dir.get_next()
	dir.list_dir_end()


func get_gear_template(item_id: String) -> GearItem:
	if _gear_templates.has(item_id):
		return _gear_templates[item_id] as GearItem
	return null


func get_all_gear_templates() -> Array[GearItem]:
	var out: Array[GearItem] = []
	for k: String in _gear_templates.keys():
		out.append(_gear_templates[k] as GearItem)
	return out


func gear_template_to_dict(gi: GearItem) -> Dictionary:
	var icon_path: String = ""
	if gi.icon != null:
		icon_path = gi.icon.resource_path
	return {
		"id": gi.item_id,
		"name": gi.item_name,
		"type": gi.type,
		"rarity": gi.rarity,
		"hp_bonus": gi.hp_bonus,
		"damage_bonus": gi.damage_bonus,
		"speed_bonus": gi.speed_bonus,
		"crit_bonus": gi.crit_bonus,
		"icon_path": icon_path,
		"description": gi.description,
		"uid": _new_uid(),
	}


# Generate a fresh inventory item dictionary from a template id.
func make_item(item_id: String) -> Dictionary:
	var gi: GearItem = get_gear_template(item_id)
	if gi == null:
		return {}
	return gear_template_to_dict(gi)


func _new_uid() -> String:
	var t: int = Time.get_ticks_usec()
	var r: int = randi()
	return "item_%d_%d" % [t, r]


# ---------- Currency ----------

func add_coins(amount: int) -> void:
	coins = max(coins + amount, 0)
	Events.coins_changed.emit(coins)
	save()


func add_gems(amount: int) -> void:
	gems = max(gems + amount, 0)
	Events.gems_changed.emit(gems)
	save()


func add_skill_points(amount: int) -> void:
	skill_points = max(skill_points + amount, 0)
	Events.skill_points_changed.emit(skill_points)
	save()


func spend_coins(amount: int) -> bool:
	if coins < amount:
		return false
	coins -= amount
	Events.coins_changed.emit(coins)
	save()
	return true


func spend_gems(amount: int) -> bool:
	if gems < amount:
		return false
	gems -= amount
	Events.gems_changed.emit(gems)
	save()
	return true


func get_character_unlock_cost(char_name: String) -> Dictionary:
	if not CHARACTER_UNLOCK_COSTS.has(char_name):
		return {"currency": "coins", "amount": 0}
	return CHARACTER_UNLOCK_COSTS[char_name] as Dictionary


func can_afford_unlock(char_name: String) -> bool:
	var cost: Dictionary = get_character_unlock_cost(char_name)
	var amt: int = int(cost.get("amount", 0))
	if amt <= 0:
		return true
	if str(cost.get("currency", "coins")) == "gems":
		return gems >= amt
	return coins >= amt


# ---------- Characters ----------

func get_character_level(char_name: String) -> int:
	if character_levels.has(char_name):
		return int(character_levels[char_name])
	return 1


func get_character_base_stats(char_name: String) -> PlayerStats:
	if not CHARACTER_STATS_PATHS.has(char_name):
		return null
	var path: String = CHARACTER_STATS_PATHS[char_name]
	if not ResourceLoader.exists(path):
		return null
	var res: Resource = load(path)
	if res is PlayerStats:
		return (res as PlayerStats).duplicate() as PlayerStats
	return null


# Returns a fresh PlayerStats with level scaling and equipped-gear bonuses applied.
func get_character_stats(char_name: String) -> PlayerStats:
	var base: PlayerStats = get_character_base_stats(char_name)
	if base == null:
		return null
	var lv: int = get_character_level(char_name)
	# Level scaling — intentional integer truncation: every Nth level adds the bonus
	@warning_ignore("integer_division")
	var hp_levels: int = (lv - 1) / 3
	@warning_ignore("integer_division")
	var dmg_levels: int = (lv - 1) / 2
	@warning_ignore("integer_division")
	var spd_levels: int = (lv - 1) / 5
	base.max_hp += hp_levels
	base.damage += dmg_levels
	base.move_speed += float(spd_levels) * 5.0
	# Gear scaling — only applies to the SELECTED character
	if char_name == selected_character:
		var sums: Dictionary = get_equipped_stat_sums()
		base.max_hp += int(sums["hp_bonus"])
		base.damage += int(round(float(sums["damage_bonus"])))
		base.move_speed += float(sums["speed_bonus"])
		base.crit_chance += float(sums["crit_bonus"])
	return base


func get_upgrade_cost(char_name: String) -> int:
	return get_character_level(char_name) * 50


func upgrade_character(char_name: String) -> bool:
	if not unlocked_characters.has(char_name):
		return false
	var cost: int = get_upgrade_cost(char_name)
	if not spend_coins(cost):
		return false
	character_levels[char_name] = get_character_level(char_name) + 1
	Events.character_upgraded.emit(char_name, int(character_levels[char_name]))
	save()
	return true


func unlock_character(char_name: String) -> bool:
	if unlocked_characters.has(char_name):
		return false
	if not CHARACTER_UNLOCK_COSTS.has(char_name):
		return false
	var cost: Dictionary = get_character_unlock_cost(char_name)
	var amt: int = int(cost.get("amount", 0))
	var currency: String = str(cost.get("currency", "coins"))
	if amt > 0:
		var ok: bool = false
		if currency == "gems":
			ok = spend_gems(amt)
		else:
			ok = spend_coins(amt)
		if not ok:
			return false
	unlocked_characters.append(char_name)
	if not character_levels.has(char_name):
		character_levels[char_name] = 1
	save()
	return true


# ---------- Inventory & gear ----------

func add_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	if not item.has("uid"):
		item["uid"] = _new_uid()
	inventory.append(item)
	Events.item_acquired.emit(item)
	save()


func remove_item_by_uid(uid: String) -> void:
	for i: int in range(inventory.size() - 1, -1, -1):
		var it: Dictionary = inventory[i]
		if str(it.get("uid", "")) == uid:
			inventory.remove_at(i)
			# Also unequip if it was equipped
			for slot: String in equipped_gear.keys():
				if str(equipped_gear[slot]) == uid:
					equipped_gear[slot] = ""
			save()
			return


func get_item_by_uid(uid: String) -> Dictionary:
	for it: Dictionary in inventory:
		if str(it.get("uid", "")) == uid:
			return it
	return {}


func equip_item(item: Dictionary) -> void:
	if item.is_empty():
		return
	var slot: String = str(item.get("type", ""))
	if not equipped_gear.has(slot):
		return
	equipped_gear[slot] = str(item.get("uid", ""))
	save()


func unequip_slot(slot: String) -> void:
	if not equipped_gear.has(slot):
		return
	equipped_gear[slot] = ""
	save()


func get_equipped_item(slot: String) -> Dictionary:
	if not equipped_gear.has(slot):
		return {}
	var uid: String = str(equipped_gear[slot])
	if uid == "":
		return {}
	return get_item_by_uid(uid)


func get_equipped_stat_sums() -> Dictionary:
	var sums: Dictionary = {"hp_bonus": 0, "damage_bonus": 0.0, "speed_bonus": 0.0, "crit_bonus": 0.0}
	for slot: String in ["weapon", "armor", "trinket", "pet"]:
		var it: Dictionary = get_equipped_item(slot)
		if it.is_empty():
			continue
		sums["hp_bonus"] = int(sums["hp_bonus"]) + int(it.get("hp_bonus", 0))
		sums["damage_bonus"] = float(sums["damage_bonus"]) + float(it.get("damage_bonus", 0.0))
		sums["speed_bonus"] = float(sums["speed_bonus"]) + float(it.get("speed_bonus", 0.0))
		sums["crit_bonus"] = float(sums["crit_bonus"]) + float(it.get("crit_bonus", 0.0))
	return sums


func salvage_item(uid: String) -> int:
	var it: Dictionary = get_item_by_uid(uid)
	if it.is_empty():
		return 0
	var rarity: int = int(it.get("rarity", 0))
	rarity = clampi(rarity, 0, RARITY_SALVAGE.size() - 1)
	var coins_gained: int = RARITY_SALVAGE[rarity]
	remove_item_by_uid(uid)
	add_coins(coins_gained)
	return coins_gained


# ---------- Run rewards ----------

func grant_run_rewards(stats: Dictionary) -> Dictionary:
	var enemies: int = int(stats.get("enemies_killed", 0))
	var bosses: int = int(stats.get("bosses_killed", 0))
	var rooms: int = int(stats.get("rooms_cleared", 0))
	var victory: bool = bool(stats.get("victory", false))

	var coins_earned: int = enemies * 10 + bosses * 50 + rooms * 25
	var sp_earned: int = rooms + bosses * 3
	var gems_earned: int = (3 if victory else 1)

	var dropped: Array[Dictionary] = _roll_drops(rooms, victory)
	for d: Dictionary in dropped:
		add_item(d)

	add_coins(coins_earned)
	add_skill_points(sp_earned)
	add_gems(gems_earned)

	var summary: Dictionary = {
		"coins_earned": coins_earned,
		"skill_points_earned": sp_earned,
		"gems_earned": gems_earned,
		"items_dropped": dropped,
	}
	Events.run_completed.emit(victory, summary)
	return summary


func _roll_drops(rooms: int, victory: bool) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _gear_templates.is_empty():
		return out
	var drop_count: int = 1 + (1 if rooms >= 3 else 0) + (1 if victory else 0)
	for _i: int in drop_count:
		var rarity_target: int = _roll_rarity(rooms, victory)
		var template: GearItem = _pick_template_for_rarity(rarity_target)
		if template != null:
			out.append(gear_template_to_dict(template))
	return out


func _roll_rarity(rooms: int, victory: bool) -> int:
	var roll: float = randf()
	# Bias upward as rooms cleared / victory increases
	var bonus: float = float(rooms) * 0.04
	if victory:
		bonus += 0.15
	if roll < 0.55 - bonus:
		return 0
	elif roll < 0.80 - bonus * 0.5:
		return 1
	elif roll < 0.93:
		return 2
	elif roll < 0.99:
		return 3
	return 4


func _pick_template_for_rarity(target_rarity: int) -> GearItem:
	var pool: Array[GearItem] = []
	for k: String in _gear_templates.keys():
		var gi: GearItem = _gear_templates[k] as GearItem
		if gi.rarity == target_rarity:
			pool.append(gi)
	if pool.is_empty():
		# Fallback: any template
		pool = get_all_gear_templates()
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]


# ---------- Starter inventory ----------

func _seed_starter_inventory() -> void:
	var weapon: Dictionary = make_item("weapon_iron_sword")
	if not weapon.is_empty():
		inventory.append(weapon)
		equipped_gear["weapon"] = weapon["uid"]
	var leather: Dictionary = make_item("armor_leather_vest")
	if not leather.is_empty():
		inventory.append(leather)
	var amulet: Dictionary = make_item("trinket_lucky_charm")
	if not amulet.is_empty():
		inventory.append(amulet)

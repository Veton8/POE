extends Node

# Autoload — owns every UpgradeData in the catalog and runs the weighted
# offer roll. Scans `res://scenes/upgrades/catalog/` recursively at startup.

const CATALOG_ROOT: String = "res://scenes/upgrades/catalog/"

var all: Dictionary = {}  # StringName -> UpgradeData
var allow_tradeoffs: bool = false  # v1 keeps cursed cards disabled


func _ready() -> void:
	_load_catalog(CATALOG_ROOT)


func _load_catalog(root: String) -> void:
	var dir: DirAccess = DirAccess.open(root)
	if dir == null:
		push_warning("UpgradeRegistry: catalog root not found: " + root)
		return
	_scan_dir_recursive(dir, root)
	print("UpgradeRegistry: loaded %d upgrades from %s" % [all.size(), root])


func _scan_dir_recursive(dir: DirAccess, path: String) -> void:
	dir.list_dir_begin()
	var entry: String = dir.get_next()
	while entry != "":
		if entry.begins_with("."):
			entry = dir.get_next()
			continue
		var full: String = path + entry
		if dir.current_is_dir():
			var sub: DirAccess = DirAccess.open(full)
			if sub != null:
				_scan_dir_recursive(sub, full + "/")
		elif entry.ends_with(".tres"):
			var res: Resource = ResourceLoader.load(full)
			if res is UpgradeData:
				var u: UpgradeData = res as UpgradeData
				if u.id != &"":
					all[u.id] = u
		entry = dir.get_next()
	dir.list_dir_end()


func get_upgrade(id: StringName) -> UpgradeData:
	if all.has(id):
		return all[id] as UpgradeData
	return null


# Returns up to `count` distinct upgrades. Filtered for max-stacks, requirements,
# tradeoffs (when allow_tradeoffs == false), and the manager's banished_ids.
func roll_offer(count: int, hero_id: StringName, owned_stacks: Dictionary, rarity_curve: Dictionary, _luck: float = 0.0) -> Array[UpgradeData]:
	var pool: Array[UpgradeData] = []
	for id_v: Variant in all.keys():
		var id: StringName = id_v as StringName
		var u: UpgradeData = all[id] as UpgradeData
		if u == null:
			continue
		if u.tradeoff and not allow_tradeoffs:
			continue
		if _is_banished(id):
			continue
		var owned: int = int(owned_stacks.get(id, 0))
		if u.stack_mode == UpgradeData.StackMode.UNIQUE and owned >= 1:
			continue
		if u.stack_mode == UpgradeData.StackMode.CAPPED and owned >= u.max_stacks:
			continue
		if not _requires_satisfied(u, owned_stacks):
			continue
		pool.append(u)

	var picks: Array[UpgradeData] = []
	var attempts: int = 0
	while picks.size() < count and pool.size() > 0 and attempts < 100:
		attempts += 1
		var u: UpgradeData = _weighted_pick(pool, hero_id, owned_stacks, rarity_curve)
		if u != null and not picks.has(u):
			picks.append(u)
			pool.erase(u)
	return picks


func _is_banished(id: StringName) -> bool:
	if not has_node("/root/UpgradeManager"):
		return false
	var mgr: Node = get_node("/root/UpgradeManager")
	if not (mgr is Object):
		return false
	var banished: Variant = mgr.get("banished_ids")
	if banished is Array:
		return (banished as Array).has(id)
	return false


func _requires_satisfied(u: UpgradeData, owned: Dictionary) -> bool:
	for t: StringName in u.requires_tags:
		if not _has_tag(t, owned):
			return false
	for need_id: StringName in u.requires_ids:
		if not owned.has(need_id) or int(owned[need_id]) <= 0:
			return false
	return true


func _has_tag(tag: StringName, owned: Dictionary) -> bool:
	for id_v: Variant in owned.keys():
		var u: UpgradeData = all.get(id_v) as UpgradeData
		if u != null and u.tags.has(tag):
			return true
	return false


func _weighted_pick(pool: Array[UpgradeData], hero_id: StringName, owned: Dictionary, rarity_curve: Dictionary) -> UpgradeData:
	if pool.is_empty():
		return null
	var weights: Array[float] = []
	var total: float = 0.0
	for u: UpgradeData in pool:
		var w: float = u.weight
		var rcurve: float = float(rarity_curve.get(u.rarity, 1.0))
		w *= rcurve
		var tag_bonus: float = 0.0
		for tag: StringName in u.tags:
			if _has_tag(tag, owned):
				tag_bonus += 0.25
		tag_bonus = minf(tag_bonus, 1.0)
		w *= (1.0 + tag_bonus)
		if u.hero_affinity.has(hero_id):
			w *= 1.5
		weights.append(w)
		total += w
	if total <= 0.0:
		return pool[randi() % pool.size()]
	var r: float = randf() * total
	var accum: float = 0.0
	for i: int in pool.size():
		accum += weights[i]
		if r <= accum:
			return pool[i]
	return pool[pool.size() - 1]

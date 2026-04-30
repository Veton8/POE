extends Control

signal closed

const SLOT_TYPES: Array[String] = ["weapon", "armor", "trinket", "pet"]

@onready var weapon_slot: Control = $Panel/Left/PaperDoll/WeaponSlot
@onready var armor_slot: Control = $Panel/Left/PaperDoll/ArmorSlot
@onready var trinket_slot: Control = $Panel/Left/PaperDoll/TrinketSlot
@onready var pet_slot: Control = $Panel/Left/PaperDoll/PetSlot
@onready var hp_total: Label = $Panel/Left/Totals/HPRow/Value
@onready var dmg_total: Label = $Panel/Left/Totals/DmgRow/Value
@onready var spd_total: Label = $Panel/Left/Totals/SpdRow/Value
@onready var crit_total: Label = $Panel/Left/Totals/CritRow/Value
@onready var grid: GridContainer = $Panel/Right/ScrollContainer/Grid
@onready var filter_all: Button = $Panel/Right/Filters/FilterAll
@onready var filter_weapon: Button = $Panel/Right/Filters/FilterWeapon
@onready var filter_armor: Button = $Panel/Right/Filters/FilterArmor
@onready var filter_trinket: Button = $Panel/Right/Filters/FilterTrinket
@onready var filter_pet: Button = $Panel/Right/Filters/FilterPet
@onready var compare_panel: Control = $Panel/Compare
@onready var compare_name: Label = $Panel/Compare/ItemName
@onready var compare_stats: Label = $Panel/Compare/StatsLabel
@onready var equip_button: Button = $Panel/Compare/EquipButton
@onready var salvage_button: Button = $Panel/Compare/SalvageButton
@onready var back_button: Button = $Panel/BackButton

var _filter: String = "all"
var _selected_uid: String = ""


func _ready() -> void:
	filter_all.pressed.connect(func() -> void: _set_filter("all"))
	filter_weapon.pressed.connect(func() -> void: _set_filter("weapon"))
	filter_armor.pressed.connect(func() -> void: _set_filter("armor"))
	filter_trinket.pressed.connect(func() -> void: _set_filter("trinket"))
	filter_pet.pressed.connect(func() -> void: _set_filter("pet"))
	equip_button.pressed.connect(_on_equip)
	salvage_button.pressed.connect(_on_salvage)
	back_button.pressed.connect(_on_back)
	compare_panel.visible = false
	_refresh_paper_doll()
	_rebuild_grid()


func _set_filter(f: String) -> void:
	_filter = f
	_rebuild_grid()


func _refresh_paper_doll() -> void:
	_render_slot(weapon_slot, "weapon")
	_render_slot(armor_slot, "armor")
	_render_slot(trinket_slot, "trinket")
	_render_slot(pet_slot, "pet")
	var sums: Dictionary = GameState.get_equipped_stat_sums()
	hp_total.text = "+%d" % int(sums["hp_bonus"])
	dmg_total.text = "+%.1f" % float(sums["damage_bonus"])
	spd_total.text = "+%.0f" % float(sums["speed_bonus"])
	crit_total.text = "+%d%%" % int(round(float(sums["crit_bonus"]) * 100.0))


func _render_slot(slot_node: Control, slot_type: String) -> void:
	for c: Node in slot_node.get_children():
		if c.name == "Icon":
			c.queue_free()
	var item: Dictionary = GameState.get_equipped_item(slot_type)
	if item.is_empty():
		return
	var icon_path: String = str(item.get("icon_path", ""))
	if icon_path == "" or not ResourceLoader.exists(icon_path):
		return
	var ir: TextureRect = TextureRect.new()
	ir.name = "Icon"
	ir.texture = load(icon_path) as Texture2D
	ir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ir.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	slot_node.add_child(ir)


func _rebuild_grid() -> void:
	for c: Node in grid.get_children():
		c.queue_free()
	var items: Array[Dictionary] = []
	for it: Dictionary in GameState.inventory:
		if _filter == "all" or str(it.get("type", "")) == _filter:
			items.append(it)
	for item: Dictionary in items:
		var card: Control = _make_item_card(item)
		grid.add_child(card)


func _make_item_card(item: Dictionary) -> Control:
	var card: Button = Button.new()
	card.custom_minimum_size = Vector2(36, 36)
	card.flat = true
	var rarity: int = int(item.get("rarity", 0))
	var rarity_color: Color = GameState.RARITY_COLORS[clampi(rarity, 0, 4)]
	# Background tint by rarity
	var bg_color: ColorRect = ColorRect.new()
	bg_color.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg_color.color = rarity_color
	bg_color.modulate = Color(1, 1, 1, 0.25)
	bg_color.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(bg_color)
	# Icon
	var icon_path: String = str(item.get("icon_path", ""))
	if icon_path != "" and ResourceLoader.exists(icon_path):
		var ir: TextureRect = TextureRect.new()
		ir.texture = load(icon_path) as Texture2D
		ir.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ir.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		ir.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(ir)
	# Equipped indicator
	var uid: String = str(item.get("uid", ""))
	for slot: String in SLOT_TYPES:
		if str(GameState.equipped_gear.get(slot, "")) == uid:
			var marker: Label = Label.new()
			marker.text = "E"
			marker.position = Vector2(2, 0)
			marker.add_theme_color_override("font_color", Color("#F4D03F"))
			marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
			card.add_child(marker)
			break
	card.pressed.connect(func() -> void: _on_card_pressed(uid))
	return card


func _on_card_pressed(uid: String) -> void:
	_selected_uid = uid
	_refresh_compare_panel()


func _refresh_compare_panel() -> void:
	if _selected_uid == "":
		compare_panel.visible = false
		return
	var item: Dictionary = GameState.get_item_by_uid(_selected_uid)
	if item.is_empty():
		compare_panel.visible = false
		return
	compare_panel.visible = true
	var rarity: int = int(item.get("rarity", 0))
	compare_name.text = str(item.get("name", "?"))
	compare_name.add_theme_color_override("font_color", GameState.RARITY_COLORS[clampi(rarity, 0, 4)])
	# Compare against currently equipped of same slot
	var slot: String = str(item.get("type", ""))
	var equipped: Dictionary = GameState.get_equipped_item(slot)
	var lines: Array[String] = []
	for stat_key: String in ["hp_bonus", "damage_bonus", "speed_bonus", "crit_bonus"]:
		var sel_v: float = float(item.get(stat_key, 0.0))
		var eq_v: float = 0.0
		if not equipped.is_empty():
			eq_v = float(equipped.get(stat_key, 0.0))
		var diff: float = sel_v - eq_v
		var arrow: String = ""
		if diff > 0.001:
			arrow = " ▲"
		elif diff < -0.001:
			arrow = " ▼"
		lines.append("%s: %s%s" % [_stat_display_name(stat_key), _stat_format(stat_key, sel_v), arrow])
	compare_stats.text = "\n".join(lines)
	# Equip button
	var is_equipped: bool = false
	if not equipped.is_empty() and str(equipped.get("uid", "")) == _selected_uid:
		is_equipped = true
	if is_equipped:
		equip_button.text = "EQUIPPED"
		equip_button.disabled = true
	else:
		equip_button.text = "EQUIP"
		equip_button.disabled = false
	var rarity_idx: int = clampi(rarity, 0, GameState.RARITY_SALVAGE.size() - 1)
	salvage_button.text = "Salvage  +%d" % GameState.RARITY_SALVAGE[rarity_idx]
	salvage_button.disabled = is_equipped


func _stat_display_name(key: String) -> String:
	match key:
		"hp_bonus": return "HP"
		"damage_bonus": return "DMG"
		"speed_bonus": return "SPD"
		"crit_bonus": return "CRIT"
	return key


func _stat_format(key: String, v: float) -> String:
	if key == "crit_bonus":
		return "+%d%%" % int(round(v * 100.0))
	if key == "hp_bonus":
		return "+%d" % int(v)
	return "+%.1f" % v


func _on_equip() -> void:
	if _selected_uid == "":
		return
	var item: Dictionary = GameState.get_item_by_uid(_selected_uid)
	if item.is_empty():
		return
	GameState.equip_item(item)
	_refresh_paper_doll()
	_rebuild_grid()
	_refresh_compare_panel()


func _on_salvage() -> void:
	if _selected_uid == "":
		return
	var coins_gained: int = GameState.salvage_item(_selected_uid)
	if coins_gained > 0:
		_selected_uid = ""
		compare_panel.visible = false
		_refresh_paper_doll()
		_rebuild_grid()


func _on_back() -> void:
	closed.emit()

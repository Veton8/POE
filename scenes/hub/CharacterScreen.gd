extends Control

signal closed

const CHARACTER_ORDER: Array[String] = ["luffy", "ace", "goku", "gojo", "saitama", "naruto_uzumaki", "eren_yeager", "tanjiro_kamado", "levi_ackerman", "light_yagami"]
const ABILITY_INFO: Array[Dictionary] = [
	{"name": "Dash", "icon": "res://art/ui/ability_dash.svg", "desc": "Quick burst forward, brief invulnerability."},
	{"name": "Burst", "icon": "res://art/ui/ability_burst.svg", "desc": "Damages enemies in a wide radius."},
	{"name": "Heal", "icon": "res://art/ui/ability_heal.svg", "desc": "Restores some health."},
]

@onready var portrait: TextureRect = $Panel/Left/PortraitFrame/Portrait
@onready var locked_icon: TextureRect = $Panel/Left/PortraitFrame/LockedOverlay
@onready var name_label: Label = $Panel/Left/NameLabel
@onready var level_label: Label = $Panel/Left/LevelLabel
@onready var prev_button: Button = $Panel/Left/Arrows/PrevButton
@onready var next_button: Button = $Panel/Left/Arrows/NextButton
@onready var unlock_button: Button = $Panel/Left/UnlockButton
@onready var hp_label: Label = $Panel/Right/Stats/HPRow/Value
@onready var dmg_label: Label = $Panel/Right/Stats/DamageRow/Value
@onready var spd_label: Label = $Panel/Right/Stats/SpeedRow/Value
@onready var crit_label: Label = $Panel/Right/Stats/CritRow/Value
@onready var hp_preview: Label = $Panel/Right/Stats/HPRow/Preview
@onready var dmg_preview: Label = $Panel/Right/Stats/DamageRow/Preview
@onready var spd_preview: Label = $Panel/Right/Stats/SpeedRow/Preview
@onready var crit_preview: Label = $Panel/Right/Stats/CritRow/Preview
@onready var ability_row: HBoxContainer = $Panel/Right/AbilityRow
@onready var upgrade_button: Button = $Panel/Right/UpgradeButton
@onready var select_button: Button = $Panel/Right/SelectButton
@onready var back_button: Button = $Panel/BackButton

var _index: int = 0


func _ready() -> void:
	_index = CHARACTER_ORDER.find(GameState.selected_character)
	if _index < 0:
		_index = 0
	prev_button.pressed.connect(_on_prev)
	next_button.pressed.connect(_on_next)
	upgrade_button.pressed.connect(_on_upgrade)
	unlock_button.pressed.connect(_on_unlock)
	select_button.pressed.connect(_on_select)
	back_button.pressed.connect(_on_back)
	_populate_abilities()
	_refresh()


func _populate_abilities() -> void:
	for child: Node in ability_row.get_children():
		child.queue_free()
	for info: Dictionary in ABILITY_INFO:
		var box: VBoxContainer = VBoxContainer.new()
		box.custom_minimum_size = Vector2(60, 30)
		var icon_path: String = str(info["icon"])
		if ResourceLoader.exists(icon_path):
			var ir: TextureRect = TextureRect.new()
			ir.texture = load(icon_path) as Texture2D
			ir.custom_minimum_size = Vector2(16, 16)
			ir.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			ir.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
			box.add_child(ir)
		var nm: Label = Label.new()
		nm.text = str(info["name"])
		nm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nm.custom_minimum_size = Vector2(60, 12)
		box.add_child(nm)
		ability_row.add_child(box)


func _refresh() -> void:
	var char_id: String = CHARACTER_ORDER[_index]
	var unlocked: bool = GameState.unlocked_characters.has(char_id)
	var stats: PlayerStats = GameState.get_character_base_stats(char_id)
	if stats == null:
		stats = PlayerStats.new()
		stats.character_name = char_id.capitalize()
	name_label.text = stats.character_name
	if unlocked:
		var lv: int = GameState.get_character_level(char_id)
		level_label.text = "Lv %d" % lv
		portrait.modulate = Color(1, 1, 1, 1)
		locked_icon.visible = false
		# Compute current effective stats including gear (only for selected char)
		var effective: PlayerStats = GameState.get_character_stats(char_id)
		hp_label.text = str(effective.max_hp)
		dmg_label.text = str(effective.damage)
		spd_label.text = "%d" % int(effective.move_speed)
		crit_label.text = "%d%%" % int(round(effective.crit_chance * 100.0))
		# Preview = +bonuses from one more level
		var hp_gain: int = 1 if lv % 3 == 0 else 0
		var dmg_gain: int = 1 if lv % 2 == 0 else 0
		var spd_gain: int = 5 if lv % 5 == 0 else 0
		hp_preview.text = ("(+%d)" % hp_gain) if hp_gain > 0 else ""
		dmg_preview.text = ("(+%d)" % dmg_gain) if dmg_gain > 0 else ""
		spd_preview.text = ("(+%d)" % spd_gain) if spd_gain > 0 else ""
		crit_preview.text = ""
		var cost: int = GameState.get_upgrade_cost(char_id)
		upgrade_button.text = "UPGRADE  %d" % cost
		upgrade_button.disabled = GameState.coins < cost
		upgrade_button.visible = true
		unlock_button.visible = false
		if char_id == GameState.selected_character:
			select_button.text = "SELECTED"
			select_button.disabled = true
		else:
			select_button.text = "SELECT"
			select_button.disabled = false
		select_button.visible = true
	else:
		level_label.text = "LOCKED"
		portrait.modulate = Color(0.2, 0.2, 0.25, 1)
		locked_icon.visible = true
		hp_label.text = str(stats.max_hp)
		dmg_label.text = str(stats.damage)
		spd_label.text = "%d" % int(stats.move_speed)
		crit_label.text = "%d%%" % int(round(stats.crit_chance * 100.0))
		hp_preview.text = ""
		dmg_preview.text = ""
		spd_preview.text = ""
		crit_preview.text = ""
		upgrade_button.visible = false
		select_button.visible = false
		unlock_button.visible = true
		var cost: Dictionary = GameState.get_character_unlock_cost(char_id)
		var amt: int = int(cost.get("amount", 0))
		var currency: String = str(cost.get("currency", "coins"))
		var symbol: String = "G" if currency == "gems" else "C"
		if amt <= 0:
			unlock_button.text = "UNLOCK (FREE)"
			unlock_button.disabled = false
		else:
			unlock_button.text = "UNLOCK  %d %s" % [amt, symbol]
			unlock_button.disabled = not GameState.can_afford_unlock(char_id)
	if stats.portrait != null:
		portrait.texture = stats.portrait


func _on_prev() -> void:
	_index = (_index - 1 + CHARACTER_ORDER.size()) % CHARACTER_ORDER.size()
	_refresh()


func _on_next() -> void:
	_index = (_index + 1) % CHARACTER_ORDER.size()
	_refresh()


func _on_upgrade() -> void:
	var char_id: String = CHARACTER_ORDER[_index]
	if GameState.upgrade_character(char_id):
		Audio.play("door_unlock", 0.05, -2.0)
	_refresh()


func _on_unlock() -> void:
	var char_id: String = CHARACTER_ORDER[_index]
	if GameState.unlock_character(char_id):
		Audio.play("door_unlock", 0.05, -2.0)
	_refresh()


func _on_select() -> void:
	var char_id: String = CHARACTER_ORDER[_index]
	if not GameState.unlocked_characters.has(char_id):
		return
	GameState.selected_character = char_id
	GameState.save()
	_refresh()


func _on_back() -> void:
	closed.emit()

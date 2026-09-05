extends CanvasLayer

## In-game HUD — health, armor, ammo, weapon badges, gear, minimap, vignette.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var armor_label: Label = $MarginContainer/VBoxContainer/TopBar/ArmorLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/TopBar/AmmoLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/BottomBar/WeaponLabel
@onready var gear_label: Label = $MarginContainer/VBoxContainer/BottomBar/GearLabel
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel
@onready var minimap: Control = $Minimap
@onready var vignette: Control = $LowHealthVignette
@onready var health_frame: Control = get_node_or_null("HealthFrame")
@onready var ammo_frame: Control = get_node_or_null("AmmoFrame")
@onready var weapon_badge: Control = get_node_or_null("MarginContainer/VBoxContainer/BottomBar/WeaponBadge")

var _player: CharacterBody2D = null
var _weapon_manager: Node = null
var _last_health: int = 100


func setup(player: CharacterBody2D) -> void:
	_player = player
	_last_health = player.health
	_weapon_manager = player.get_node("WeaponManager")

	if not _player.health_changed.is_connected(_on_health_changed):
		_player.health_changed.connect(_on_health_changed)
	if _player.has_signal("armor_changed") and not _player.armor_changed.is_connected(_on_armor_changed):
		_player.armor_changed.connect(_on_armor_changed)
	if _player.has_signal("grenades_changed") and not _player.grenades_changed.is_connected(_on_grenades_changed):
		_player.grenades_changed.connect(_on_grenades_changed)
	if _player.has_signal("mines_changed") and not _player.mines_changed.is_connected(_on_mines_changed):
		_player.mines_changed.connect(_on_mines_changed)
	if not _weapon_manager.ammo_changed.is_connected(_on_ammo_changed):
		_weapon_manager.ammo_changed.connect(_on_ammo_changed)
	if not _weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
		_weapon_manager.weapon_switched.connect(_on_weapon_switched)

	health_bar.max_value = _player.max_health
	health_bar.value = _player.health
	_update_gear()
	armor_label.text = "Armor: %d" % _player.armor
	if minimap.has_method("setup"):
		minimap.setup(player)
	_on_health_changed(_player.health)

	if _weapon_manager and "current_weapon" in _weapon_manager and _weapon_manager.current_weapon:
		_on_weapon_switched(_weapon_manager.current_weapon)


func set_objective_text(text: String) -> void:
	objective_label.text = text


func _on_health_changed(new_health: int) -> void:
	if new_health < _last_health:
		# Trigger combat shock twitch on paper overlay
		get_tree().call_group("paper_overlay", "trigger_combat_shock", 0.025)
	_last_health = new_health
	health_bar.value = new_health
	if _player and vignette.has_method("set_health_ratio"):
		vignette.set_health_ratio(float(new_health) / float(_player.max_health))


func _on_armor_changed(new_armor: int) -> void:
	armor_label.text = "Armor: %d" % new_armor


func _on_grenades_changed(_count: int) -> void:
	_update_gear()


func _on_mines_changed(_count: int) -> void:
	_update_gear()


func _update_gear() -> void:
	if _player == null:
		return
	gear_label.text = "G:%d  M:%d  [G]grenade [F]mine" % [_player.grenade_count, _player.mine_count]


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	if current < 0:
		ammo_label.text = "∞"
	else:
		ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_weapon_switched(weapon_resource: WeaponResource) -> void:
	weapon_label.text = weapon_resource.weapon_name
	if weapon_badge and weapon_badge.has_method("set_weapon"):
		weapon_badge.set_weapon(weapon_resource.weapon_name)

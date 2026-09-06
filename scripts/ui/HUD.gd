extends CanvasLayer

## In-game HUD — health, armor, ammo, weapon slots, gear, minimap, vignette, toasts.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var armor_label: Label = $MarginContainer/VBoxContainer/TopBar/ArmorLabel
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/TopBar/AmmoLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/BottomBar/WeaponLabel
@onready var gear_indicator: Control = get_node_or_null("MarginContainer/VBoxContainer/BottomBar/GearIndicator")
@onready var objective_label: Label = $MarginContainer/VBoxContainer/ObjectiveLabel
@onready var minimap: Control = $Minimap
@onready var vignette: Control = $LowHealthVignette
@onready var reload_prompt: Label = get_node_or_null("MarginContainer/VBoxContainer/TopBar/ReloadPrompt")
@onready var health_frame: Control = get_node_or_null("HealthFrame")
@onready var ammo_frame: Control = get_node_or_null("AmmoFrame")
@onready var weapon_badge: Control = get_node_or_null("MarginContainer/VBoxContainer/BottomBar/WeaponBadge")
@onready var slot_panel: Control = get_node_or_null("MarginContainer/VBoxContainer/BottomBar/WeaponSlots")
@onready var toast_label: Label = get_node_or_null("ToastLabel")
@onready var crosshair: Control = get_node_or_null("Crosshair")
@onready var objective_arrow: Control = get_node_or_null("ObjectiveArrow")

var _player: CharacterBody2D = null
var _weapon_manager: Node = null
var _last_health: int = 100
var _ammo_flash_tween: Tween = null
var _reload_pulse_tween: Tween = null


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
	if _weapon_manager.has_signal("reserve_changed") and not _weapon_manager.reserve_changed.is_connected(_on_reserve_changed):
		_weapon_manager.reserve_changed.connect(_on_reserve_changed)
	if not _weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
		_weapon_manager.weapon_switched.connect(_on_weapon_switched)

	health_bar.max_value = _player.max_health
	health_bar.value = _player.health
	_update_gear()
	armor_label.text = "Armor: %d" % _player.armor
	if minimap.has_method("setup"):
		minimap.setup(player)
	if crosshair and crosshair.has_method("setup"):
		crosshair.setup(_weapon_manager, _player)
	_on_health_changed(_player.health)
	_update_slots()
	var weapon: WeaponResource = _weapon_manager.get_current_weapon()
	if weapon:
		_on_weapon_switched(weapon)
		_refresh_ammo_label(_weapon_manager.ammo[_weapon_manager.current_slot], weapon.max_ammo)


func set_objective_text(text: String) -> void:
	objective_label.text = text
	objective_label.modulate = Color(1.0, 0.85, 0.4)
	var tween := create_tween()
	tween.tween_property(objective_label, "modulate", Color.WHITE, 0.5)
	SoundManager.play_sfx("objective", 0.05, -4.0)


func show_toast(text: String) -> void:
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.modulate.a = 1.0
	toast_label.visible = true
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func() -> void:
		toast_label.visible = false
	)


func _on_health_changed(new_health: int) -> void:
	if new_health < _last_health:
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
	if gear_indicator and gear_indicator.has_method("set_counts"):
		gear_indicator.set_counts(_player.grenade_count, _player.mine_count)


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	_refresh_ammo_label(current, max_ammo)
	if current >= 0 and max_ammo > 0 and float(current) / float(max_ammo) <= 0.25:
		_flash_ammo()
	_update_reload_prompt(current, max_ammo)
	_update_ammo_color(current, max_ammo)
	if current >= 0 and max_ammo > 0 and float(current) / float(max_ammo) > 0.25:
		_update_reload_prompt(current, max_ammo)
		_update_ammo_color(current, max_ammo)


func _on_reserve_changed(_reserve: int) -> void:
	if _weapon_manager == null:
		return
	var weapon: WeaponResource = _weapon_manager.get_current_weapon()
	if weapon:
		_refresh_ammo_label(_weapon_manager.ammo[_weapon_manager.current_slot], weapon.max_ammo)
		_update_reload_prompt(_weapon_manager.ammo[_weapon_manager.current_slot], weapon.max_ammo)
		_update_ammo_color(_weapon_manager.ammo[_weapon_manager.current_slot], weapon.max_ammo)


func _refresh_ammo_label(current: int, max_ammo: int) -> void:
	if current < 0:
		ammo_label.text = "∞"
		return
	var reserve: int = 0
	if _weapon_manager and _weapon_manager.has_method("get_current_reserve"):
		reserve = _weapon_manager.get_current_reserve()
	if reserve < 0:
		ammo_label.text = "%d / %d" % [current, max_ammo]
	else:
		ammo_label.text = "%d / %d  (+%d)" % [current, max_ammo, reserve]


func _flash_ammo() -> void:
	if ammo_label == null:
		return
	if _ammo_flash_tween and _ammo_flash_tween.is_valid():
		_ammo_flash_tween.kill()
	_ammo_flash_tween = create_tween()
	_ammo_flash_tween.tween_property(ammo_label, "modulate", Color(1.0, 0.3, 0.2), 0.15)
	_ammo_flash_tween.tween_property(ammo_label, "modulate", Color.WHITE, 0.15)


func _update_ammo_color(current: int, max_ammo: int) -> void:
	if ammo_label == null:
		return
	if current < 0 or max_ammo <= 0:
		ammo_label.modulate = Color.WHITE
		return
	var low: bool = float(current) / float(max_ammo) <= 0.25
	ammo_label.modulate = Color(0.85, 0.4, 0.35) if low else Color.WHITE


func _update_reload_prompt(current: int, max_ammo: int) -> void:
	if reload_prompt == null or _weapon_manager == null:
		return
	if current < 0 or max_ammo <= 0:
		_hide_reload_prompt()
		return
	var low: bool = float(current) / float(max_ammo) <= 0.25
	if not low:
		_hide_reload_prompt()
		return
	if bool(_weapon_manager.get("is_reloading")):
		_hide_reload_prompt()
		return
	var reserve: int = 0
	if _weapon_manager.has_method("get_current_reserve"):
		reserve = _weapon_manager.get_current_reserve()
	if current == 0 and reserve <= 0:
		reload_prompt.text = "LOW AMMO"
	else:
		reload_prompt.text = "RELOAD [R]" if reserve > 0 else "LOW AMMO"
	_show_reload_prompt()


func _show_reload_prompt() -> void:
	if reload_prompt == null:
		return
	reload_prompt.visible = true
	if _reload_pulse_tween and _reload_pulse_tween.is_valid():
		return
	_reload_pulse_tween = create_tween()
	_reload_pulse_tween.set_loops()
	_reload_pulse_tween.tween_property(reload_prompt, "modulate:a", 0.2, 0.35)
	_reload_pulse_tween.tween_property(reload_prompt, "modulate:a", 1.0, 0.35)


func _hide_reload_prompt() -> void:
	if reload_prompt == null:
		return
	reload_prompt.visible = false
	reload_prompt.modulate.a = 1.0
	if _reload_pulse_tween and _reload_pulse_tween.is_valid():
		_reload_pulse_tween.kill()
	_reload_pulse_tween = null


func _on_weapon_switched(weapon_resource: WeaponResource) -> void:
	weapon_label.text = weapon_resource.weapon_name
	if weapon_badge and weapon_badge.has_method("set_weapon"):
		weapon_badge.set_weapon(weapon_resource.weapon_name)
	_update_slots()
	weapon_label.modulate = Color(1.0, 0.9, 0.5)
	var tween := create_tween()
	tween.tween_property(weapon_label, "modulate", Color.WHITE, 0.35)


func _update_slots() -> void:
	if slot_panel == null or _weapon_manager == null:
		return
	if slot_panel.has_method("set_slots"):
		slot_panel.set_slots(_weapon_manager.slots, _weapon_manager.current_slot)


func _process(_delta: float) -> void:
	if ammo_frame and ammo_label:
		ammo_frame.position = ammo_label.global_position - Vector2(22, 8)
		ammo_frame.size = ammo_label.size + Vector2(40, 16)

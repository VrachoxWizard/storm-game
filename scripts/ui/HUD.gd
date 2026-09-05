extends CanvasLayer

## In-game HUD — displays health, ammo, and current weapon.

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var ammo_label: Label = $MarginContainer/VBoxContainer/TopBar/AmmoLabel
@onready var weapon_label: Label = $MarginContainer/VBoxContainer/BottomBar/WeaponLabel

var _player: CharacterBody2D = null
var _weapon_manager: Node = null


func setup(player: CharacterBody2D) -> void:
	_player = player
	_weapon_manager = player.get_node("WeaponManager")

	_player.health_changed.connect(_on_health_changed)
	_weapon_manager.ammo_changed.connect(_on_ammo_changed)
	_weapon_manager.weapon_switched.connect(_on_weapon_switched)

	# Initial state
	health_bar.max_value = _player.max_health
	health_bar.value = _player.health


func _on_health_changed(new_health: int) -> void:
	health_bar.value = new_health


func _on_ammo_changed(current: int, max_ammo: int) -> void:
	if current < 0:
		ammo_label.text = "∞"
	else:
		ammo_label.text = "%d / %d" % [current, max_ammo]


func _on_weapon_switched(weapon_resource: WeaponResource) -> void:
	weapon_label.text = weapon_resource.weapon_name

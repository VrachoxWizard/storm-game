class_name WeaponManager
extends Node

## Manages weapon slots, switching, firing, and ammo for the player.

signal weapon_switched(weapon_resource: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal weapon_fired

const SLOT_COUNT: int = 3
const PISTOL_SLOT: int = 2  ## slot index for permanent pistol

@export var default_weapon: WeaponResource
@export var pistol_weapon: WeaponResource

var slots: Array[WeaponResource] = []
var ammo: Array[int] = []  ## current ammo per slot (-1 = unlimited)
var current_slot: int = 0
var can_fire: bool = true
var is_reloading: bool = false

@onready var fire_timer: Timer = $FireTimer
@onready var reload_timer: Timer = $ReloadTimer


func _ready() -> void:
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_cooldown_finished)
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_finished)

	# Initialize slots: [primary, secondary, pistol]
	slots.resize(SLOT_COUNT)
	ammo.resize(SLOT_COUNT)

	slots[0] = default_weapon
	ammo[0] = default_weapon.max_ammo if default_weapon else 0
	slots[1] = null
	ammo[1] = 0
	slots[PISTOL_SLOT] = pistol_weapon
	ammo[PISTOL_SLOT] = -1  # unlimited

	current_slot = 0
	_emit_current_state()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_1"):
		switch_to_slot(0)
	elif event.is_action_pressed("weapon_2"):
		switch_to_slot(1)
	elif event.is_action_pressed("weapon_3"):
		switch_to_slot(PISTOL_SLOT)
	elif event.is_action_pressed("reload"):
		_start_reload()


func _physics_process(_delta: float) -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return

	if weapon.is_automatic:
		if Input.is_action_pressed("shoot") and can_fire and not is_reloading:
			fire()
	else:
		if Input.is_action_just_pressed("shoot") and can_fire and not is_reloading:
			fire()


func get_current_weapon() -> WeaponResource:
	if current_slot < 0 or current_slot >= SLOT_COUNT:
		return null
	return slots[current_slot]


func fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return

	# Check ammo
	if ammo[current_slot] == 0:
		_start_reload()
		return

	# Consume ammo (skip if unlimited)
	if ammo[current_slot] > 0:
		ammo[current_slot] -= 1

	can_fire = false
	fire_timer.wait_time = weapon.fire_rate
	fire_timer.start()

	weapon_fired.emit()
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func switch_to_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	if slots[slot] == null:
		return
	if is_reloading:
		is_reloading = false
		reload_timer.stop()

	current_slot = slot
	can_fire = true
	_emit_current_state()


func add_weapon(weapon_res: WeaponResource, weapon_ammo: int) -> Dictionary:
	## Adds a weapon to the first empty slot, or swaps with current.
	## Returns {} if no displacement, else { "weapon": WeaponResource, "ammo": int }.
	for i in range(PISTOL_SLOT):  # only check slots 0 and 1
		if slots[i] == null:
			slots[i] = weapon_res
			ammo[i] = weapon_ammo
			switch_to_slot(i)
			return {}

	# All slots full — swap with current (unless pistol)
	var swap_slot := current_slot if current_slot != PISTOL_SLOT else 0
	var old_weapon := slots[swap_slot]
	var old_ammo: int = ammo[swap_slot]
	slots[swap_slot] = weapon_res
	ammo[swap_slot] = weapon_ammo
	switch_to_slot(swap_slot)
	return {"weapon": old_weapon, "ammo": old_ammo}


func add_ammo(amount: int) -> void:
	## Adds ammo to the currently held weapon.
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	ammo[current_slot] = mini(ammo[current_slot] + amount, weapon.max_ammo)
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func _start_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	if ammo[current_slot] == weapon.max_ammo:
		return
	if ammo[current_slot] == 0:
		_play_sfx("dry_fire")

	is_reloading = true
	reload_timer.wait_time = weapon.reload_time
	reload_timer.start()
	_play_sfx("reload")


func _play_sfx(sfx_id: String) -> void:
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx(sfx_id)


func _on_reload_finished() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	ammo[current_slot] = weapon.max_ammo
	is_reloading = false
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)


func _on_fire_cooldown_finished() -> void:
	can_fire = true


func _emit_current_state() -> void:
	var weapon := get_current_weapon()
	if weapon:
		weapon_switched.emit(weapon)
		ammo_changed.emit(ammo[current_slot], weapon.max_ammo)

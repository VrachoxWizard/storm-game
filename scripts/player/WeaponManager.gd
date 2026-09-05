class_name WeaponManager
extends Node

## Manages weapon slots, switching, firing, and ammo for the player.

signal weapon_switched(weapon_resource: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal reserve_changed(reserve: int)
signal weapon_fired

const SLOT_COUNT: int = 3
const PISTOL_SLOT: int = 2  ## slot index for permanent pistol

@export var default_weapon: WeaponResource
@export var pistol_weapon: WeaponResource

var slots: Array[WeaponResource] = []
var ammo: Array[int] = []  ## magazine ammo per slot (-1 = unlimited)
var reserve: Array[int] = []  ## spare ammo per slot (-1 = unlimited)
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

	slots.resize(SLOT_COUNT)
	ammo.resize(SLOT_COUNT)
	reserve.resize(SLOT_COUNT)

	slots[0] = default_weapon
	if default_weapon:
		ammo[0] = default_weapon.max_ammo
		reserve[0] = default_weapon.starting_reserve
	else:
		ammo[0] = 0
		reserve[0] = 0
	slots[1] = null
	ammo[1] = 0
	reserve[1] = 0
	slots[PISTOL_SLOT] = pistol_weapon
	ammo[PISTOL_SLOT] = -1
	reserve[PISTOL_SLOT] = -1

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


func get_current_reserve() -> int:
	if current_slot < 0 or current_slot >= SLOT_COUNT:
		return 0
	return reserve[current_slot]


func fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return

	if ammo[current_slot] == 0:
		_start_reload()
		return

	if ammo[current_slot] > 0:
		ammo[current_slot] -= 1

	can_fire = false
	fire_timer.wait_time = weapon.fire_rate
	fire_timer.start()

	weapon_fired.emit()
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
	reserve_changed.emit(reserve[current_slot])


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


func add_weapon(weapon_res: WeaponResource, total_rounds: int) -> Dictionary:
	## Adds a weapon; total_rounds fills magazine first, remainder goes to reserve.
	## Returns {} if no displacement, else { "weapon": WeaponResource, "ammo": int, "reserve": int }.
	var mag: int = 0
	var res: int = 0
	if weapon_res:
		mag = mini(total_rounds, weapon_res.max_ammo)
		res = maxi(total_rounds - mag, 0)

	for i in range(PISTOL_SLOT):
		if slots[i] == null:
			slots[i] = weapon_res
			ammo[i] = mag
			reserve[i] = res
			switch_to_slot(i)
			return {}

	var swap_slot := current_slot if current_slot != PISTOL_SLOT else 0
	var old_weapon := slots[swap_slot]
	var old_ammo: int = ammo[swap_slot]
	var old_reserve: int = reserve[swap_slot]
	slots[swap_slot] = weapon_res
	ammo[swap_slot] = mag
	reserve[swap_slot] = res
	switch_to_slot(swap_slot)
	return {"weapon": old_weapon, "ammo": old_ammo, "reserve": old_reserve}


func add_ammo(amount: int) -> void:
	## Adds rounds to the currently held weapon's reserve.
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	reserve[current_slot] += amount
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
	reserve_changed.emit(reserve[current_slot])


func get_total_ammo_for_slot(slot: int) -> int:
	if slot < 0 or slot >= SLOT_COUNT:
		return 0
	if ammo[slot] < 0:
		return -1
	return ammo[slot] + reserve[slot]


func _start_reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	if ammo[current_slot] == weapon.max_ammo:
		return
	if reserve[current_slot] <= 0:
		if ammo[current_slot] == 0:
			_play_sfx("dry_fire")
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
	var needed: int = weapon.max_ammo - ammo[current_slot]
	var taken: int = mini(needed, reserve[current_slot])
	ammo[current_slot] += taken
	reserve[current_slot] -= taken
	is_reloading = false
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
	reserve_changed.emit(reserve[current_slot])


func _on_fire_cooldown_finished() -> void:
	can_fire = true


func _emit_current_state() -> void:
	var weapon := get_current_weapon()
	if weapon:
		weapon_switched.emit(weapon)
		ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
		reserve_changed.emit(reserve[current_slot])

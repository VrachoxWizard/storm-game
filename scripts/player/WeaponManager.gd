class_name WeaponManager
extends Node

## Manages weapon slots, switching, firing, and ammo for the player.

signal weapon_switched(weapon_resource: WeaponResource)
signal ammo_changed(current: int, max_ammo: int)
signal reserve_changed(reserve: int)
signal weapon_fired
## Emitted whenever sustained-fire spread bloom changes (for crosshair ring).
signal bloom_changed(bloom: float)
## Emitted when a disposable launcher (M80 Zolja) is spent and tossed away.
signal weapon_discarded(weapon_resource: WeaponResource)

const SLOT_COUNT: int = 3
const PISTOL_SLOT: int = 2  ## slot index for permanent pistol
## How fast spread bloom recovers per second when not firing.
const BLOOM_RECOVERY_RATE: float = 0.30

@export var default_weapon: WeaponResource
@export var pistol_weapon: WeaponResource

var slots: Array[WeaponResource] = []
var ammo: Array[int] = []  ## magazine ammo per slot (-1 = unlimited)
var reserve: Array[int] = []  ## spare ammo per slot (-1 = unlimited)
var current_slot: int = 0
var _last_slot: int = 0
var can_fire: bool = true
var is_reloading: bool = false
## Extra spread (radians) accumulated from sustained automatic fire.
var current_bloom: float = 0.0
## How many projectiles the last trigger pull actually spawned (pool may be short).
var last_pellet_count: int = 1

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
	elif event.is_action_pressed("weapon_next"):
		_cycle_slot(1)
	elif event.is_action_pressed("weapon_prev"):
		_cycle_slot(-1)
	elif event.is_action_pressed("quick_swap"):
		quick_swap()
	elif event.is_action_pressed("reload"):
		_start_reload()


func _physics_process(delta: float) -> void:
	# Bloom recovers whenever the weapon is not cycling.
	if current_bloom > 0.0:
		var recovered: float = maxf(0.0, current_bloom - BLOOM_RECOVERY_RATE * delta)
		if not is_equal_approx(recovered, current_bloom):
			current_bloom = recovered
			bloom_changed.emit(current_bloom)

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
	if not can_fire or is_reloading or not can_process():
		return
	var weapon := get_current_weapon()
	if weapon == null:
		return

	if ammo[current_slot] == 0:
		_start_reload()
		return

	# Pre-check the projectile pool so a shortfall never burns ammo for nothing.
	last_pellet_count = maxi(1, weapon.projectile_count)
	if not weapon.is_explosive:
		var shooter := get_parent()
		if shooter and shooter.has_method("count_free_projectiles"):
			var free_count: int = shooter.count_free_projectiles()
			if free_count <= 0:
				return  # Pool exhausted: no shot, no ammo spent.
			last_pellet_count = mini(last_pellet_count, free_count)

	if ammo[current_slot] > 0:
		ammo[current_slot] -= 1

	can_fire = false
	fire_timer.wait_time = weapon.fire_rate
	fire_timer.start()

	# Sustained-fire spread bloom.
	if weapon.bloom_per_shot > 0.0:
		current_bloom = minf(current_bloom + weapon.bloom_per_shot, weapon.max_bloom)
		bloom_changed.emit(current_bloom)

	weapon_fired.emit()
	ammo_changed.emit(ammo[current_slot], weapon.max_ammo)
	reserve_changed.emit(reserve[current_slot])

	# Disposable launchers (M80 Zolja) are tossed away after the single shot.
	if weapon.is_disposable and ammo[current_slot] <= 0 and reserve[current_slot] <= 0:
		_discard_current_weapon()


## Removes the current (spent disposable) weapon and falls back to a carried one.
func _discard_current_weapon() -> void:
	var tossed := slots[current_slot]
	slots[current_slot] = null
	ammo[current_slot] = 0
	reserve[current_slot] = 0
	if tossed:
		weapon_discarded.emit(tossed)
	# Prefer the previous slot, then any other non-empty slot, else the pistol.
	var fallback: int = -1
	if _last_slot != current_slot and _last_slot >= 0 and _last_slot < SLOT_COUNT and slots[_last_slot] != null:
		fallback = _last_slot
	else:
		for i in range(SLOT_COUNT):
			if slots[i] != null:
				fallback = i
				break
	if fallback >= 0:
		# _last_slot bookkeeping: don't point at the now-empty slot.
		_last_slot = fallback
		switch_to_slot(fallback)
	else:
		_emit_current_state()


func switch_to_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	if slots[slot] == null:
		return
	if is_reloading:
		is_reloading = false
		reload_timer.stop()

	if slot != current_slot:
		_last_slot = current_slot
	current_slot = slot
	can_fire = fire_timer.is_stopped()
	# Switching weapons resets sustained-fire bloom.
	if current_bloom > 0.0:
		current_bloom = 0.0
		bloom_changed.emit(0.0)
	_emit_current_state()


func quick_swap() -> void:
	if _last_slot == current_slot:
		return
	if _last_slot < 0 or _last_slot >= SLOT_COUNT:
		return
	if slots[_last_slot] == null:
		return
	switch_to_slot(_last_slot)


func _cycle_slot(dir: int) -> void:
	if dir == 0:
		return
	var start: int = current_slot
	for i in range(SLOT_COUNT):
		var idx := (start + dir * (i + 1)) % SLOT_COUNT
		if idx < 0:
			idx += SLOT_COUNT
		if slots[idx] != null:
			switch_to_slot(idx)
			return


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
	## If the pistol is held (unlimited ammo), redirect to the best carried gun instead.
	var target_slot: int = current_slot
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		target_slot = -1
		for i in range(PISTOL_SLOT):
			if slots[i] != null:
				target_slot = i
				break
		if target_slot < 0:
			return
		weapon = slots[target_slot]
	reserve[target_slot] += amount
	ammo_changed.emit(ammo[current_slot], get_current_weapon().max_ammo if get_current_weapon() else 0)
	reserve_changed.emit(reserve[current_slot])


func get_total_ammo_for_slot(slot: int) -> int:
	if slot < 0 or slot >= SLOT_COUNT:
		return 0
	if ammo[slot] < 0:
		return -1
	return ammo[slot] + reserve[slot]


func _start_reload() -> void:
	if is_reloading:
		return
	var weapon := get_current_weapon()
	if weapon == null or weapon.is_pistol:
		return
	if ammo[current_slot] == weapon.max_ammo:
		return
	if reserve[current_slot] <= 0:
		if ammo[current_slot] == 0:
			_play_sfx("dry_fire")
		return

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


## Clears transient actions when restoring a checkpoint.
func reset_action_state() -> void:
	fire_timer.stop()
	reload_timer.stop()
	can_fire = true
	is_reloading = false
	if current_bloom > 0.0:
		current_bloom = 0.0
		bloom_changed.emit(0.0)

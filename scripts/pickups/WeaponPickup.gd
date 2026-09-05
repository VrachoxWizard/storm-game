extends "res://scripts/pickups/PickupBase.gd"

## Gives the player a new weapon, or swaps with current if slots are full.

@export var weapon_resource: WeaponResource
@export var ammo_count: int = -1  ## -1 means use weapon's max_ammo


func _apply_effect(player: Node2D) -> void:
	if weapon_resource == null:
		return

	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if weapon_manager == null:
		return

	var actual_ammo := ammo_count
	if actual_ammo < 0:
		actual_ammo = weapon_resource.max_ammo

	var displaced: WeaponResource = weapon_manager.add_weapon(weapon_resource, actual_ammo)
	if displaced:
		_spawn_dropped_weapon(displaced)


func _spawn_dropped_weapon(_weapon: WeaponResource) -> void:
	## For Phase 1, displaced weapons are simply lost.
	pass

extends "res://scripts/pickups/PickupBase.gd"

## Refills ammo for the player's current weapon.

@export var ammo_amount: int = 15


func _apply_effect(player: Node2D) -> void:
	var weapon_manager: Node = player.get_node_or_null("WeaponManager")
	if weapon_manager and weapon_manager.has_method("add_ammo"):
		weapon_manager.add_ammo(ammo_amount)

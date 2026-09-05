extends "res://scripts/pickups/PickupBase.gd"

## Armor vest — 50% damage reduction until depleted.

@export var armor_amount: int = 50


func _apply_effect(player: Node2D) -> void:
	if player.has_method("add_armor"):
		player.add_armor(armor_amount)

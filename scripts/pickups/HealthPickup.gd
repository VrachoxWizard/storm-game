extends "res://scripts/pickups/PickupBase.gd"

## Restores player health on pickup.

@export var heal_amount: int = 30


func _apply_effect(player: Node2D) -> void:
	if player.has_method("heal"):
		player.heal(heal_amount)

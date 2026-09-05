extends "res://scripts/pickups/PickupBase.gd"

## Large health kit — restores 70 HP.

@export var heal_amount: int = 70


func _apply_effect(player: Node2D) -> void:
	if player.has_method("heal"):
		player.heal(heal_amount)

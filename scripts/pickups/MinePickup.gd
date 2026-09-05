extends "res://scripts/pickups/PickupBase.gd"

## Grants placeable mines to the player.

@export var mine_count: int = 1


func _apply_effect(player: Node2D) -> void:
	if player.has_method("add_mines"):
		player.add_mines(mine_count)

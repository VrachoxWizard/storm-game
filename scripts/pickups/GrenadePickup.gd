extends "res://scripts/pickups/PickupBase.gd"

## Grants M75 hand grenades to the player.

@export var grenade_count: int = 2


func _apply_effect(player: Node2D) -> void:
	if player.has_method("add_grenades"):
		player.add_grenades(grenade_count)

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
		actual_ammo = weapon_resource.max_ammo + weapon_resource.starting_reserve

	var result: Dictionary = weapon_manager.add_weapon(weapon_resource, actual_ammo)
	if not result.is_empty() and result.get("weapon") != null:
		var dropped_total: int = int(result.get("ammo", 0)) + int(result.get("reserve", 0))
		_spawn_dropped_weapon(result["weapon"], dropped_total)


func _spawn_dropped_weapon(weapon: WeaponResource, dropped_ammo: int) -> void:
	var drop_scene: PackedScene = load("res://scenes/pickups/WeaponPickup.tscn")
	var drop: Node2D = drop_scene.instantiate()
	drop.set("weapon_resource", weapon)
	drop.set("ammo_count", dropped_ammo)
	drop.global_position = global_position + Vector2(24, 0)
	var pickups := get_parent()
	if pickups:
		pickups.call_deferred("add_child", drop)
	else:
		get_tree().current_scene.call_deferred("add_child", drop)

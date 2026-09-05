class_name ExplosionHelper
extends RefCounted

## Shared splash damage for RPG, grenades, mines, mortar shells.


static func explode(
	tree: SceneTree,
	center: Vector2,
	radius: float,
	damage: int,
	shake_intensity: float = 10.0,
	hurt_player: bool = true
) -> void:
	if tree == null:
		return

	var space := tree.root.get_viewport().find_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	query.shape = circle
	query.transform = Transform2D(0.0, center)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.collision_mask = 1 | 2 | 64  # Player, Enemies, Vehicles

	var hits: Array[Dictionary] = space.intersect_shape(query, 32)
	var damaged: Dictionary = {}
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or damaged.has(collider):
			continue
		damaged[collider] = true
		if not hurt_player and collider is Node and (collider as Node).is_in_group("player"):
			continue
		if collider.has_method("take_damage"):
			collider.take_damage(damage)

	# Camera shake via player
	var players := tree.get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("shake_camera"):
		players[0].shake_camera(shake_intensity)

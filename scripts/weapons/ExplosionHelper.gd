class_name ExplosionHelper
extends RefCounted

## Shared splash damage for RPG, grenades, mines, mortar shells.


static func explode(
	tree: SceneTree,
	center: Vector2,
	radius: float,
	damage: int,
	shake_intensity: float = 10.0,
	hurt_player: bool = true,
	from_player: bool = false
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
	var scored_hit: bool = false
	for hit in hits:
		var collider: Object = hit.get("collider")
		if collider == null or damaged.has(collider):
			continue
		damaged[collider] = true
		if not hurt_player and collider is Node and (collider as Node).is_in_group("player"):
			continue
		if collider.has_method("take_explosive_damage"):
			collider.take_explosive_damage(damage)
		elif collider.has_method("take_damage"):
			collider.take_damage(damage)
		if from_player and collider is Node:
			var n := collider as Node
			if n.is_in_group("enemies") or n.is_in_group("vehicle") or n.is_in_group("emplacement") or n.is_in_group("bunker"):
				scored_hit = true

	if from_player and scored_hit:
		var sm = tree.root.get_node_or_null("ScoreManager")
		if sm and sm.has_method("record_shot_hit"):
			sm.record_shot_hit()

	# Camera shake via player
	var players := tree.get_nodes_in_group("player")
	if not players.is_empty() and players[0].has_method("shake_camera"):
		var distance: float = players[0].global_position.distance_to(center)
		var falloff: float = clampf(1.0 - distance / 500.0, 0.0, 1.0)
		if falloff > 0.0: players[0].shake_camera(shake_intensity * falloff)

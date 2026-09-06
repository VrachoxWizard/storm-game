extends RefCounted

## Chooses an open local route around authored cover without changing enemy roles.
static func direction(body: CharacterBody2D, destination: Vector2, side: float) -> Vector2:
	var desired := (destination - body.global_position).normalized()
	if desired == Vector2.ZERO:
		return desired
	var space := body.get_world_2d().direct_space_state
	for angle in [0.0, side * 0.65, -side * 0.65, side * 1.25, -side * 1.25, side * 1.8]:
		var candidate := desired.rotated(angle)
		var clear: bool = true
		for lateral in [-16.0, 0.0, 16.0]:
			var start: Vector2 = body.global_position + candidate.orthogonal() * lateral
			var query := PhysicsRayQueryParameters2D.create(start, start + candidate * 72.0, 32)
			if not space.intersect_ray(query).is_empty():
				clear = false
				break
		if clear:
			return candidate
	return desired  ## Fall back to desired direction when all probes fail.

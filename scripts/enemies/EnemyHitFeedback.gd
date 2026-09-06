extends RefCounted

## Short damage flash and rig recoil, separate from enemy decision logic.

static func flash_hit(enemy: CharacterBody2D) -> void:
	var target_sprite: Sprite2D = enemy.body_sprite if enemy.body_sprite else enemy.sprite
	if target_sprite:
		target_sprite.modulate = Color(1.0, 0.35, 0.35)
		# Node-bound tween is cancelled automatically when the enemy is freed.
		enemy.create_tween().tween_property(target_sprite, "modulate", Color.WHITE, 0.12)

	if enemy.torso_container and enemy.is_inside_tree():
		var tween := enemy.create_tween()
		if tween:
			tween.tween_property(enemy.torso_container, "scale", Vector2(1.15, 1.15), 0.05)
			tween.tween_property(enemy.torso_container, "scale", Vector2.ONE, 0.08)


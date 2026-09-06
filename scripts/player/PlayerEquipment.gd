extends RefCounted

## Throwable equipment actions shared by the player controller.

static func throw_grenade(player: CharacterBody2D, scene: PackedScene) -> void:
	if player.grenade_count <= 0: return
	player.grenade_count -= 1; player.grenades_changed.emit(player.grenade_count)
	var container: Node = null
	if player.get_tree() and player.get_tree().root:
		container = player.get_tree().root.get_node_or_null("Main/Projectiles")
	if container == null:
		container = player.get_parent()
	if container:
		var grenade: Area2D = scene.instantiate()
		container.add_child(grenade)
		var dir := (player.get_global_mouse_position() - player.global_position).normalized()
		grenade.throw_at(player.global_position + dir * 20.0, player.get_global_mouse_position() - player.global_position - dir * 20.0, true)


static func place_mine(player: CharacterBody2D, scene: PackedScene) -> void:
	if player.mine_count <= 0: return
	player.mine_count -= 1; player.mines_changed.emit(player.mine_count)
	var mine: Area2D = scene.instantiate()
	var parent_node := player.get_parent() if player.get_parent() else player.get_tree().root.get_node_or_null("Main/Projectiles")
	if parent_node: parent_node.add_child(mine)
	mine.global_position = player.global_position


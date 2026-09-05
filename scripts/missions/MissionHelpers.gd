class_name MissionHelpers
extends RefCounted

## Shared helpers for mission controllers — checkpoints, death, HUD text.


static func connect_checkpoints(mission_root: Node, player: CharacterBody2D) -> void:
	if player == null:
		return
	player.save_checkpoint(player.global_position)
	var checkpoints_node := mission_root.get_node_or_null("Checkpoints")
	if checkpoints_node == null:
		return
	for cp in checkpoints_node.get_children():
		if cp.has_signal("checkpoint_reached"):
			cp.checkpoint_reached.connect(func(checkpoint: Area2D) -> void:
				player.save_checkpoint(checkpoint.global_position)
				_notify_checkpoint(player)
			)


static func handle_player_died(player: CharacterBody2D) -> void:
	if player == null or not player.is_inside_tree():
		return
	var sm = player.get_tree().root.get_node_or_null("ScoreManager")
	if sm and sm.has_method("record_death"):
		sm.record_death()
	player.get_tree().create_timer(1.0).timeout.connect(func() -> void:
		if is_instance_valid(player):
			player.restore_checkpoint()
	)


static func set_hud_objective(tree: SceneTree, text: String) -> void:
	if tree == null or tree.root == null:
		return
	var hud := tree.root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("set_objective_text"):
		hud.set_objective_text(text)


static func complete_mission(tree: SceneTree) -> void:
	if tree == null or tree.root == null:
		return
	var gm = tree.root.get_node_or_null("GameManager")
	if gm and gm.has_method("complete_mission"):
		gm.complete_mission()


static func notify_checkpoint(player: Node) -> void:
	if player == null or not player.is_inside_tree():
		return
	var hud := player.get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("show_toast"):
		hud.show_toast("Checkpoint reached")
	var snd = player.get_tree().root.get_node_or_null("SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("checkpoint")


static func _notify_checkpoint(player: Node) -> void:
	notify_checkpoint(player)


static func set_group_active(node: Node, active: bool) -> void:
	if node == null:
		return
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if node is CanvasItem:
		(node as CanvasItem).visible = active
	for child in node.get_children():
		child.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if child is CanvasItem:
			(child as CanvasItem).visible = active


static func spawn_enemy_at(scene: PackedScene, parent: Node, pos: Vector2, on_died: Callable = Callable()) -> Node:
	if scene == null or parent == null:
		return null
	var enemy: Node = scene.instantiate()
	parent.add_child(enemy)
	if enemy is Node2D:
		(enemy as Node2D).global_position = pos
	if on_died.is_valid() and enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(on_died)
	return enemy

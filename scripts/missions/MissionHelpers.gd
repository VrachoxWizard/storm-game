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
	if not is_instance_valid(node): return
	node.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if node is CanvasItem: node.visible = active
	_set_encounter_collisions(node, active)


static func _set_encounter_collisions(node: Node, active: bool) -> void:
	if node is CollisionObject2D:
		if not active and not node.has_meta("encounter_layer"):
			node.set_meta("encounter_layer", node.collision_layer)
			node.set_meta("encounter_mask", node.collision_mask)
		if node.has_meta("encounter_layer"):
			node.set_deferred("collision_layer", node.get_meta("encounter_layer") if active else 0)
			node.set_deferred("collision_mask", node.get_meta("encounter_mask") if active else 0)
	for child in node.get_children():
		_set_encounter_collisions(child, active)


static func spawn_enemy_at(scene: PackedScene, parent: Node, pos: Vector2, on_died: Callable = Callable()) -> Node:
	if scene == null or parent == null:
		return null
	var enemy: Node = scene.instantiate()
	if enemy is Node2D:
		(enemy as Node2D).position = parent.to_local(pos) if parent is Node2D else pos
	parent.add_child(enemy)
	if on_died.is_valid() and enemy.has_signal("enemy_died"):
		enemy.enemy_died.connect(on_died)
	return enemy


## Adds a visible ink banner + ground ring on an invisible Area2D objective zone.
static func add_zone_banner(zone: Area2D, caption: String) -> void:
	if zone == null or not is_instance_valid(zone):
		return
	if zone.has_meta("zone_banner"):
		return
	var banner := Node2D.new()
	banner.name = "ZoneBanner"
	banner.z_index = 8
	zone.add_child(banner)

	var ring := Sprite2D.new()
	ring.texture = _make_zone_ring_texture()
	ring.modulate = Color(0.95, 0.8, 0.25, 0.55)
	ring.scale = Vector2(1.4, 0.85)
	banner.add_child(ring)

	var label := Label.new()
	label.text = caption
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.35, 0.95))
	label.add_theme_color_override("font_outline_color", Color(0.12, 0.1, 0.08, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	label.position = Vector2(-70.0, -48.0)
	label.custom_minimum_size = Vector2(140.0, 20.0)
	banner.add_child(label)
	zone.set_meta("zone_banner", banner)


static func bind_objective_guidance(controller: Node, tracker: ObjectiveTracker, host: Node = null) -> ObjectiveGuidance:
	var guidance := ObjectiveGuidance.new()
	guidance.name = "ObjectiveGuidance"
	controller.add_child(guidance)
	var marker_host: Node = host if host != null else controller.get_parent()
	guidance.setup(tracker, marker_host)
	return guidance


static func _make_zone_ring_texture() -> ImageTexture:
	var size: int = 64
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var cx: float = size * 0.5
	var cy: float = size * 0.5
	for y in range(size):
		for x in range(size):
			var d: float = Vector2(float(x) + 0.5 - cx, float(y) + 0.5 - cy).length()
			if d > 24.0 and d < 28.0:
				img.set_pixel(x, y, Color(0.95, 0.8, 0.25, 0.9))
			elif d > 22.0 and d < 30.0:
				img.set_pixel(x, y, Color(0.95, 0.8, 0.25, 0.3))
	return ImageTexture.create_from_image(img)

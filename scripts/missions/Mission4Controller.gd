extends Node

## Mission 4 — The Heart: clear street segments, destroy mortars, reach fortress approach.

@onready var player: CharacterBody2D = $"../Player"
@onready var enemies_node: Node2D = $"../Enemies"
@onready var mortars_node: Node2D = $"../Mortars"
@onready var approach_zone: Area2D = $"../ApproachZone"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _mission_complete: bool = false
var _segment: int = 0
var _segment_groups: Array[Array] = []
var _guidance: ObjectiveGuidance = null
var _street_objective_count: int = 0


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	_add_extra_checkpoint(Vector2(750, 500))
	MissionHelpers.add_zone_banner(approach_zone, "FORTRESS APPROACH")
	_partition_street_segments()
	# Activate only first segment enemies; defer rest
	for i in range(1, _segment_groups.size()):
		for e in _segment_groups[i]:
			if is_instance_valid(e):
				MissionHelpers.set_group_active(e, false)
	objective_tracker.sequential = true
	for i in range(_segment_groups.size()):
		objective_tracker.add_destroy_objective(_segment_groups[i], "Clear Knin street block %d" % (i + 1))
	_street_objective_count = _segment_groups.size()
	objective_tracker.add_destroy_objective(mortars_node.get_children(), "Destroy SVK mortar battery")
	objective_tracker.add_area_objective(approach_zone, "Reach Knin fortress approach")
	objective_tracker.all_objectives_complete.connect(_complete)
	objective_tracker.objective_updated.connect(_on_progress)
	_guidance = ObjectiveGuidance.new()
	_guidance.name = "ObjectiveGuidance"
	add_child(_guidance)
	# During street clears, omit noisy per-enemy markers — enable at mortars+.
	_watch_segment_clears()
	var total_objectives: int = int(objective_tracker.get_progress()["total"])
	_on_progress(0, total_objectives)
	MissionHelpers.set_hud_objective(get_tree(), "Clear the first Knin street — push east under SVK mortar fire")


func _add_extra_checkpoint(pos: Vector2) -> void:
	var cps := get_parent().get_node_or_null("Checkpoints")
	if cps == null:
		return
	var cp := Area2D.new()
	cp.position = pos
	cp.collision_layer = 0
	cp.collision_mask = 1
	cp.set_script(load("res://scripts/missions/Checkpoint.gd"))
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 40.0
	shape.shape = circle
	cp.add_child(shape)
	cps.add_child(cp)
	cp.checkpoint_reached.connect(func(c: Area2D) -> void:
		player.save_checkpoint(c.global_position)
		MissionHelpers._notify_checkpoint(player)
	)


func _partition_street_segments() -> void:
	var children := enemies_node.get_children()
	var seg_a: Array = []
	var seg_b: Array = []
	var seg_c: Array = []
	for e in children:
		if not (e is Node2D):
			continue
		var x: float = (e as Node2D).global_position.x
		if x < 550.0:
			seg_a.append(e)
		elif x < 900.0:
			seg_b.append(e)
		else:
			seg_c.append(e)
	if not seg_a.is_empty():
		_segment_groups.append(seg_a)
	if not seg_b.is_empty():
		_segment_groups.append(seg_b)
	if not seg_c.is_empty():
		_segment_groups.append(seg_c)
	if _segment_groups.is_empty():
		_segment_groups.append(children)


func _watch_segment_clears() -> void:
	var timer := Timer.new()
	timer.wait_time = 0.75
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_check_segments)


func _check_segments() -> void:
	if _segment >= _segment_groups.size():
		return
	var alive: int = 0
	for e in _segment_groups[_segment]:
		if is_instance_valid(e) and not e.is_queued_for_deletion():
			if not (e is EnemyBase) or e.current_state != EnemyBase.State.DEAD:
				alive += 1
	if alive <= 0:
		_advance_segment()


func _advance_segment() -> void:
	_segment += 1
	player.save_checkpoint(player.global_position)
	MissionHelpers._notify_checkpoint(player)
	if _segment < _segment_groups.size():
		for e in _segment_groups[_segment]:
			if is_instance_valid(e):
				MissionHelpers.set_group_active(e, true)
				if e is EnemyBase: e.order_assault(player)
		MissionHelpers.set_hud_objective(get_tree(), "Knin street %d clear — push to the next block" % _segment)
	else:
		MissionHelpers.set_hud_objective(get_tree(), "Streets clear — destroy SVK mortars, reach the fortress")
		# Enable positional guidance for mortars / approach.
		if _guidance and objective_tracker:
			_guidance.set_targets(objective_tracker.get_current_targets())


func _on_progress(completed: int, total: int) -> void:
	var label := objective_tracker.get_current_label()
	MissionHelpers.set_hud_objective(get_tree(), "Objectives: %d/%d — %s" % [completed, total, label])
	# Only show markers once street clears are done (mortars + approach).
	if _guidance and completed >= _street_objective_count:
		_guidance.set_targets(objective_tracker.get_current_targets())
	elif _guidance and completed < _street_objective_count:
		_guidance.clear()


func _complete() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	MissionHelpers.complete_mission(get_tree())

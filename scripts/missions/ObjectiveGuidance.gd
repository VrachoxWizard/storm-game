class_name ObjectiveGuidance
extends Node

## Binds an ObjectiveTracker (or manual target list) to world markers + HUD edge arrow.

const MARKER_SCENE: PackedScene = preload("res://scenes/effects/ObjectiveMarker.tscn")

var _markers: Array[ObjectiveMarker] = []
var _tracker: ObjectiveTracker = null
var _host: Node = null
var _is_flag: bool = false


func setup(tracker: ObjectiveTracker, host: Node = null) -> void:
	_tracker = tracker
	_host = host if host != null else get_parent()
	if _tracker.objective_target_changed.is_connected(_on_target_changed):
		_tracker.objective_target_changed.disconnect(_on_target_changed)
	_tracker.objective_target_changed.connect(_on_target_changed)
	# Defer so markers are not added while the mission tree is still in _ready.
	call_deferred("_emit_initial")


func _emit_initial() -> void:
	if is_instance_valid(_tracker):
		_tracker.emit_initial_target()


func set_targets(targets: Array, is_flag: bool = false) -> void:
	_is_flag = is_flag
	if _host == null or not is_instance_valid(_host):
		_host = get_parent()
	_rebuild_markers(targets)
	_update_arrow(targets)


func clear() -> void:
	_clear_markers()
	_update_arrow([])


func _on_target_changed(targets: Array, _label: String) -> void:
	_is_flag = false
	_rebuild_markers(targets)
	_update_arrow(targets)


func _rebuild_markers(targets: Array) -> void:
	_clear_markers()
	if _host == null or not is_instance_valid(_host):
		_host = get_parent()
	if _host == null or not is_instance_valid(_host):
		return
	# Prefer mission root over MissionController so markers are siblings of world entities.
	var marker_parent: Node = _host
	if marker_parent.name == "MissionController" and marker_parent.get_parent() != null:
		marker_parent = marker_parent.get_parent()
	for t in targets:
		if not is_instance_valid(t) or not (t is Node2D):
			continue
		var marker: ObjectiveMarker = MARKER_SCENE.instantiate() as ObjectiveMarker
		marker.is_flag = _is_flag
		marker_parent.add_child(marker)
		marker.set_target(t as Node2D)
		_markers.append(marker)


func _clear_markers() -> void:
	for m in _markers:
		if is_instance_valid(m):
			m.deactivate()
			m.queue_free()
	_markers.clear()


func _update_arrow(targets: Array) -> void:
	var arrow := _find_arrow()
	if arrow == null:
		return
	if arrow.has_method("set_targets"):
		arrow.set_targets(targets)


func _find_arrow() -> Node:
	if not is_inside_tree():
		return null
	var hud := get_tree().root.get_node_or_null("Main/HUD")
	if hud == null:
		return null
	return hud.get_node_or_null("ObjectiveArrow")


func _exit_tree() -> void:
	_clear_markers()
	var arrow := _find_arrow()
	if arrow and arrow.has_method("clear_targets"):
		arrow.clear_targets()

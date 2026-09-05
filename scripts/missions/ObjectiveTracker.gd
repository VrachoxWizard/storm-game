class_name ObjectiveTracker
extends Node

## Tracks mission objectives: destroy targets, enter areas, kill counts, survive timers.

signal objective_updated(completed: int, total: int)
signal all_objectives_complete

enum ObjectiveType { DESTROY, AREA, KILL_COUNT, SURVIVE }

var _objectives: Array[Dictionary] = []
var _completed_count: int = 0
var _mission_complete: bool = false


func add_destroy_objective(targets: Array, label: String = "Destroy targets") -> void:
	var idx: int = _objectives.size()
	var remaining: Array = []
	for t in targets:
		if is_instance_valid(t):
			remaining.append(t)
			_connect_destroy_target(t, idx)
	_objectives.append({
		"type": ObjectiveType.DESTROY,
		"label": label,
		"targets": remaining,
		"remaining": remaining.size(),
		"done": remaining.is_empty(),
	})
	if remaining.is_empty():
		_completed_count += 1
	objective_updated.emit(_completed_count, _objectives.size())


func add_area_objective(area: Area2D, label: String = "Reach objective") -> void:
	var idx: int = _objectives.size()
	_objectives.append({
		"type": ObjectiveType.AREA,
		"label": label,
		"done": false,
	})
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and not _objectives[idx]["done"]:
			_complete_objective(idx)
	)


func add_kill_count_objective(count: int, label: String = "Eliminate enemies") -> void:
	_objectives.append({
		"type": ObjectiveType.KILL_COUNT,
		"label": label,
		"required": count,
		"current": 0,
		"done": false,
	})
	objective_updated.emit(_completed_count, _objectives.size())


func add_survive_objective(duration: float, label: String = "Survive") -> void:
	var idx: int = _objectives.size()
	_objectives.append({
		"type": ObjectiveType.SURVIVE,
		"label": label,
		"done": false,
	})
	get_tree().create_timer(duration).timeout.connect(func() -> void:
		if idx < _objectives.size() and not _objectives[idx]["done"]:
			_complete_objective(idx)
	)


func register_enemy_kill() -> void:
	for i in range(_objectives.size()):
		var obj: Dictionary = _objectives[i]
		if obj["type"] == ObjectiveType.KILL_COUNT and not obj["done"]:
			obj["current"] = int(obj["current"]) + 1
			if int(obj["current"]) >= int(obj["required"]):
				_complete_objective(i)
			else:
				objective_updated.emit(_completed_count, _objectives.size())
			return


func get_progress() -> Dictionary:
	return {"completed": _completed_count, "total": _objectives.size()}


func _connect_destroy_target(target: Node, obj_idx: int) -> void:
	var callback := func(_a = null, _b = null) -> void:
		_on_destroy_progress(obj_idx)
	if target.has_signal("enemy_died"):
		target.enemy_died.connect(callback)
	elif target.has_signal("destroyed"):
		target.destroyed.connect(callback)
	elif target.has_signal("died"):
		target.died.connect(callback)


func _on_destroy_progress(obj_idx: int) -> void:
	if obj_idx < 0 or obj_idx >= _objectives.size():
		return
	var obj: Dictionary = _objectives[obj_idx]
	if obj["type"] != ObjectiveType.DESTROY or obj["done"]:
		return
	obj["remaining"] = maxi(int(obj["remaining"]) - 1, 0)
	if int(obj["remaining"]) <= 0:
		_complete_objective(obj_idx)


func _complete_objective(index: int) -> void:
	if index < 0 or index >= _objectives.size():
		return
	if _objectives[index]["done"]:
		return
	_objectives[index]["done"] = true
	_completed_count += 1
	objective_updated.emit(_completed_count, _objectives.size())
	if _completed_count >= _objectives.size() and not _mission_complete:
		_mission_complete = true
		all_objectives_complete.emit()

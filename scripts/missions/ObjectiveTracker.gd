class_name ObjectiveTracker
extends Node

## Tracks mission objectives: destroy targets, enter areas, kill counts, survive timers.
## Supports sequential gating so later objectives cannot complete until prior ones finish.

signal objective_updated(completed: int, total: int)
signal objective_target_changed(targets: Array, label: String)
signal all_objectives_complete

enum ObjectiveType { DESTROY, AREA, KILL_COUNT, SURVIVE }

var _objectives: Array[Dictionary] = []
var _completed_count: int = 0
var _mission_complete: bool = false
## When true, objective N cannot complete until objectives 0..N-1 are done.
var sequential: bool = false


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
		"done": false,
	})

	objective_updated.emit(_completed_count, _objectives.size())


func add_area_objective(area: Area2D, label: String = "Reach objective") -> void:
	var idx: int = _objectives.size()
	_objectives.append({
		"type": ObjectiveType.AREA,
		"area": area,
		"label": label,
		"done": false,
	})
	area.body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player") and not _objectives[idx]["done"]:
			if _can_complete(idx):
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
	_objectives[idx]["time_left"] = duration


func register_enemy_kill() -> void:
	for i in range(_objectives.size()):
		var obj: Dictionary = _objectives[i]
		if obj["type"] == ObjectiveType.KILL_COUNT and not obj["done"]:
			if not _can_complete(i):
				return
			obj["current"] = int(obj["current"]) + 1
			if int(obj["current"]) >= int(obj["required"]):
				_complete_objective(i)
			else:
				objective_updated.emit(_completed_count, _objectives.size())
			return


func get_progress() -> Dictionary:
	return {"completed": _completed_count, "total": _objectives.size()}


func get_current_label() -> String:
	for obj in _objectives:
		if not obj["done"]:
			return str(obj.get("label", "Objective"))
	return "Complete"


func get_current_targets() -> Array[Node2D]:
	var result: Array[Node2D] = []
	for obj in _objectives:
		if obj["done"]:
			continue
		match obj["type"]:
			ObjectiveType.DESTROY:
				for t in obj["targets"]:
					if is_instance_valid(t) and t is Node2D:
						if t is EnemyBase and t.current_state == EnemyBase.State.DEAD:
							continue
						if t.get("is_destroyed") == true:
							continue
						result.append(t as Node2D)
			ObjectiveType.AREA:
				var area: Variant = obj.get("area")
				if is_instance_valid(area) and area is Node2D:
					result.append(area as Node2D)
			_:
				pass
		return result
	return result


func emit_initial_target() -> void:
	objective_target_changed.emit(get_current_targets(), get_current_label())


func _can_complete(index: int) -> bool:
	if not sequential:
		return true
	for i in range(index):
		if not _objectives[i]["done"]:
			return false
	return true


func _connect_destroy_target(target: Node, obj_idx: int) -> void:
	var callback := func(_a = null, _b = null) -> void:
		_on_destroy_progress(obj_idx)
	if target.has_signal("enemy_died"):
		target.enemy_died.connect(callback, CONNECT_ONE_SHOT)
	elif target.has_signal("destroyed"):
		target.destroyed.connect(callback, CONNECT_ONE_SHOT)
	elif target.has_signal("died"):
		target.died.connect(callback, CONNECT_ONE_SHOT)


func _on_destroy_progress(obj_idx: int) -> void:
	if obj_idx < 0 or obj_idx >= _objectives.size():
		return
	var obj: Dictionary = _objectives[obj_idx]
	if obj["type"] != ObjectiveType.DESTROY or obj["done"]:
		return
	obj["remaining"] = maxi(int(obj["remaining"]) - 1, 0)
	# Partial progress feedback before the objective fully completes.
	objective_updated.emit(_completed_count, _objectives.size())
	if int(obj["remaining"]) <= 0 and _can_complete(obj_idx):
		_complete_objective(obj_idx)
	else:
		objective_target_changed.emit(get_current_targets(), get_current_label())


func _complete_objective(index: int) -> void:
	if index < 0 or index >= _objectives.size():
		return
	if _objectives[index]["done"]:
		return
	if not _can_complete(index):
		return
	_objectives[index]["done"] = true
	_completed_count += 1
	objective_updated.emit(_completed_count, _objectives.size())
	objective_target_changed.emit(get_current_targets(), get_current_label())
	if _completed_count >= _objectives.size() and not _mission_complete:
		_mission_complete = true
		all_objectives_complete.emit()


func _process(delta: float) -> void:
	if _mission_complete: return
	for i in range(_objectives.size()):
		var obj: Dictionary = _objectives[i]
		if obj["done"] or not _can_complete(i): continue
		match obj["type"]:
			ObjectiveType.DESTROY:
				if int(obj["remaining"]) <= 0: _complete_objective(i)
			ObjectiveType.AREA:
				var area: Area2D = obj["area"]
				if is_instance_valid(area):
					for body in area.get_overlapping_bodies():
						if body.is_in_group("player") and body.get("_is_dead") != true:
							_complete_objective(i)
			ObjectiveType.SURVIVE:
				obj["time_left"] = maxf(0.0, float(obj["time_left"]) - delta)
				if float(obj["time_left"]) <= 0.0: _complete_objective(i)

extends Node

## Mission 2 — Breaking the Line: destroy bunkers (ordered), then breach east.
## Reinforcements spawn when the first bunker takes damage.

@export var rifleman_scene: PackedScene
@export var shotgunner_scene: PackedScene
@export var machine_gunner_scene: PackedScene

@onready var player: CharacterBody2D = $"../Player"
@onready var enemies_container: Node2D = $"../Enemies"
@onready var bunkers_node: Node2D = $"../Bunkers"
@onready var exit_area: Area2D = $"../ExitZone"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _mission_complete: bool = false
var _reinforcements_spawned: bool = false


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	_add_extra_checkpoint(Vector2(1000, 440))
	_spawn_defenders()
	objective_tracker.sequential = true
	var bunkers: Array = bunkers_node.get_children()
	objective_tracker.add_destroy_objective(bunkers, "Destroy bunker emplacements")
	objective_tracker.add_area_objective(exit_area, "Breach the line")
	objective_tracker.all_objectives_complete.connect(_on_all_complete)
	objective_tracker.objective_updated.connect(_on_objective_updated)
	_hook_bunker_alerts(bunkers)
	_update_hud_objective()


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


func _hook_bunker_alerts(bunkers: Array) -> void:
	for b in bunkers:
		if not is_instance_valid(b):
			continue
		# Poll health via take_damage override is hard; use timer to detect damage
		b.set_meta("start_health", b.get("health") if "health" in b else 200)
	# Check periodically for damaged bunkers
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_check_bunker_damage)


func _check_bunker_damage() -> void:
	if _reinforcements_spawned:
		return
	for b in bunkers_node.get_children():
		if not is_instance_valid(b):
			continue
		var start_hp: int = int(b.get_meta("start_health", 200))
		var hp: int = int(b.get("health")) if "health" in b else start_hp
		if hp < start_hp:
			_spawn_reinforcements()
			return


func _spawn_defenders() -> void:
	var markers := $"../SpawnMarkers".get_children()
	var roster: Array[PackedScene] = [rifleman_scene, machine_gunner_scene, shotgunner_scene, rifleman_scene, machine_gunner_scene]
	for i in range(mini(roster.size(), markers.size())):
		if roster[i] == null:
			continue
		MissionHelpers.spawn_enemy_at(roster[i], enemies_container, markers[i].global_position)


func _spawn_reinforcements() -> void:
	if _reinforcements_spawned:
		return
	_reinforcements_spawned = true
	var markers := $"../SpawnMarkers".get_children()
	var scenes: Array[PackedScene] = [rifleman_scene, rifleman_scene, shotgunner_scene]
	for i in range(scenes.size()):
		if scenes[i] == null or markers.is_empty():
			continue
		var pos: Vector2 = markers[i % markers.size()].global_position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		MissionHelpers.spawn_enemy_at(scenes[i], enemies_container, pos)
	MissionHelpers.set_hud_objective(get_tree(), "Reinforcements inbound! Destroy bunkers, then breach east")


func _on_objective_updated(completed: int, total: int) -> void:
	_update_hud_objective(completed, total)


func _update_hud_objective(completed: int = -1, total: int = -1) -> void:
	var progress := objective_tracker.get_progress()
	var c: int = completed if completed >= 0 else int(progress["completed"])
	var t: int = total if total >= 0 else int(progress["total"])
	var label := objective_tracker.get_current_label()
	MissionHelpers.set_hud_objective(get_tree(), "Objectives: %d/%d — %s" % [c, t, label])


func _on_all_complete() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	MissionHelpers.complete_mission(get_tree())

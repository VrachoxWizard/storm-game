extends Node

## Mission 2 — Breaking the Line: destroy bunkers in order (north then south), then breach east.
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
var _guidance: ObjectiveGuidance = null
var _initial_bunker_count: int = 0


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	_add_extra_checkpoint(Vector2(1000, 440))
	_spawn_defenders()
	MissionHelpers.add_zone_banner(exit_area, "BREACH EAST")
	objective_tracker.sequential = true
	var bunkers: Array = bunkers_node.get_children()
	# Enforce north bunker first, then south — matches briefing "in order".
	var ordered: Array = bunkers.duplicate()
	ordered.sort_custom(func(a: Node, b: Node) -> bool:
		if not (a is Node2D) or not (b is Node2D):
			return false
		return (a as Node2D).position.y < (b as Node2D).position.y
	)
	if ordered.size() >= 1:
		objective_tracker.add_destroy_objective([ordered[0]], "Destroy SVK bunker 1 (north)")
	if ordered.size() >= 2:
		objective_tracker.add_destroy_objective([ordered[1]], "Destroy SVK bunker 2 (south)")
	objective_tracker.add_area_objective(exit_area, "Breach the Medak line (east)")
	objective_tracker.all_objectives_complete.connect(_on_all_complete)
	objective_tracker.objective_updated.connect(_on_objective_updated)
	_guidance = MissionHelpers.bind_objective_guidance(self, objective_tracker)
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
	_initial_bunker_count = bunkers.size()
	for b in bunkers:
		if not is_instance_valid(b):
			continue
		# Deferred: difficulty scaling adjusts bunker health after _ready —
		# snapshot AFTER it, else easy mode trips reinforcements instantly.
		call_deferred("_snapshot_bunker_health", b)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(_check_bunker_damage)


func _snapshot_bunker_health(b: Node) -> void:
	if is_instance_valid(b):
		b.set_meta("start_health", int(b.get("health")) if "health" in b else 200)


func _check_bunker_damage() -> void:
	if _reinforcements_spawned:
		return
	# A bunker destroyed outright (e.g. one-shot rocket) counts as "damaged".
	if bunkers_node.get_child_count() < _initial_bunker_count:
		_spawn_reinforcements()
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
		var pos: Vector2 = Vector2(1180, 230 + i * 210)
		var enemy := MissionHelpers.spawn_enemy_at(scenes[i], enemies_container, pos)
		if enemy is EnemyBase: enemy.order_assault(player)
	MissionHelpers.set_hud_objective(get_tree(), "SVK 15th Lika reinforcements inbound! Finish the bunkers north→south, then breach east")


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

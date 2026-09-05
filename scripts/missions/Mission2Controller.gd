extends Node

## Mission 2 — Breaking the Line: destroy bunkers and clear the path.

@export var rifleman_scene: PackedScene
@export var shotgunner_scene: PackedScene
@export var machine_gunner_scene: PackedScene

@onready var player: CharacterBody2D = $"../Player"
@onready var enemies_container: Node2D = $"../Enemies"
@onready var bunkers_node: Node2D = $"../Bunkers"
@onready var exit_area: Area2D = $"../ExitZone"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _mission_complete: bool = false


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.save_checkpoint(player.global_position)
	_connect_checkpoints()
	_spawn_defenders()
	_setup_objectives()
	objective_tracker.all_objectives_complete.connect(_on_all_complete)
	objective_tracker.objective_updated.connect(_on_objective_updated)
	_update_hud_objective()


func _connect_checkpoints() -> void:
	var checkpoints_node := get_node_or_null("../Checkpoints")
	if checkpoints_node == null:
		return
	for cp in checkpoints_node.get_children():
		if cp.has_signal("checkpoint_reached"):
			cp.checkpoint_reached.connect(func(checkpoint: Area2D) -> void:
				player.save_checkpoint(checkpoint.global_position)
			)


func _spawn_defenders() -> void:
	var markers := $"../SpawnMarkers".get_children()
	var roster: Array[PackedScene] = [rifleman_scene, machine_gunner_scene, shotgunner_scene, rifleman_scene, machine_gunner_scene]
	for i in range(mini(roster.size(), markers.size())):
		if roster[i] == null:
			continue
		var enemy: Node = roster[i].instantiate()
		enemy.global_position = markers[i].global_position
		enemies_container.add_child(enemy)


func _setup_objectives() -> void:
	var bunkers: Array = bunkers_node.get_children()
	objective_tracker.add_destroy_objective(bunkers, "Destroy bunker emplacements")
	objective_tracker.add_area_objective(exit_area, "Breach the line")


func _on_objective_updated(completed: int, total: int) -> void:
	_update_hud_objective(completed, total)


func _update_hud_objective(completed: int = -1, total: int = -1) -> void:
	var hud := get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("set_objective_text"):
		var progress := objective_tracker.get_progress()
		var c: int = completed if completed >= 0 else int(progress["completed"])
		var t: int = total if total >= 0 else int(progress["total"])
		hud.set_objective_text("Objectives: %d / %d — Destroy bunkers, then breach east" % [c, t])


func _on_all_complete() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	GameManager.complete_mission()


func _on_player_died() -> void:
	ScoreManager.record_death()
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		player.restore_checkpoint()
	)

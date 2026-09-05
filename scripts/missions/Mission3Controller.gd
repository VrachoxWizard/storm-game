extends Node

## Mission 3 — Open Road: destroy armor and liberate the village.

@onready var player: CharacterBody2D = $"../Player"
@onready var vehicles_node: Node2D = $"../Vehicles"
@onready var village_zone: Area2D = $"../VillageZone"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _mission_complete: bool = false


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.save_checkpoint(player.global_position)
	_connect_checkpoints()
	var vehicles: Array = vehicles_node.get_children()
	objective_tracker.add_destroy_objective(vehicles, "Destroy armored vehicles")
	objective_tracker.add_area_objective(village_zone, "Liberate the village")
	objective_tracker.all_objectives_complete.connect(_complete)
	objective_tracker.objective_updated.connect(_on_progress)
	_on_progress(0, 2)


func _connect_checkpoints() -> void:
	var node := get_node_or_null("../Checkpoints")
	if node == null:
		return
	for cp in node.get_children():
		if cp.has_signal("checkpoint_reached"):
			cp.checkpoint_reached.connect(func(c: Area2D) -> void:
				player.save_checkpoint(c.global_position)
			)


func _on_progress(completed: int, total: int) -> void:
	var hud := get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("set_objective_text"):
		hud.set_objective_text("Objectives: %d/%d — Destroy armor, liberate village" % [completed, total])


func _complete() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	var gm = get_node_or_null("/root/GameManager")
	if gm:
		gm.complete_mission()


func _on_player_died() -> void:
	var sm = get_node_or_null("/root/ScoreManager")
	if sm:
		sm.record_death()
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		player.restore_checkpoint()
	)

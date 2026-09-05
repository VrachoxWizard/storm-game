extends Node

## Mission 5 — Victory: destroy T-55, clear courtyard, raise the flag.

enum Stage { APPROACH, TANK, COURTYARD, FLAG }

@onready var player: CharacterBody2D = $"../Player"
@onready var tank: Node = $"../Vehicles/Tank"
@onready var courtyard_enemies: Node2D = $"../CourtyardEnemies"
@onready var flag: Area2D = $"../FlagObjective"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _stage: Stage = Stage.APPROACH
var _mission_complete: bool = false
var _courtyard_remaining: int = 0


func _ready() -> void:
	player.died.connect(_on_player_died)
	player.save_checkpoint(player.global_position)
	_connect_checkpoints()
	if tank and tank.has_signal("destroyed"):
		tank.destroyed.connect(_on_tank_destroyed)
	elif tank and tank.has_signal("died"):
		tank.died.connect(_on_tank_destroyed)
	for e in courtyard_enemies.get_children():
		_courtyard_remaining += 1
		if e.has_signal("enemy_died"):
			e.enemy_died.connect(_on_courtyard_kill)
	flag.flag_raised.connect(_on_flag_raised)
	# Staged objectives via tracker for HUD; completion gated by stages
	objective_tracker.add_destroy_objective([tank] if tank else [], "Destroy the T-55")
	_set_hud("Stage 1: Destroy the T-55 tank")


func _connect_checkpoints() -> void:
	var node := get_node_or_null("../Checkpoints")
	if node == null:
		return
	for cp in node.get_children():
		if cp.has_signal("checkpoint_reached"):
			cp.checkpoint_reached.connect(func(c: Area2D) -> void:
				player.save_checkpoint(c.global_position)
			)


func _on_tank_destroyed(_a = null) -> void:
	_stage = Stage.COURTYARD
	_set_hud("Stage 2: Clear the courtyard (%d left)" % _courtyard_remaining)
	if _courtyard_remaining <= 0:
		_enter_flag_stage()


func _on_courtyard_kill(_e = null) -> void:
	_courtyard_remaining = maxi(_courtyard_remaining - 1, 0)
	if _stage == Stage.COURTYARD:
		_set_hud("Stage 2: Clear the courtyard (%d left)" % _courtyard_remaining)
		if _courtyard_remaining <= 0:
			_enter_flag_stage()


func _enter_flag_stage() -> void:
	_stage = Stage.FLAG
	_set_hud("Stage 3: Raise the flag on the fortress")


func _on_flag_raised() -> void:
	if _mission_complete:
		return
	if _stage != Stage.FLAG and _courtyard_remaining > 0:
		return
	_mission_complete = true
	_set_hud("Victory! The flag flies over Knin.")
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		GameManager.complete_mission()
	)


func _set_hud(text: String) -> void:
	var hud := get_tree().root.get_node_or_null("Main/HUD")
	if hud and hud.has_method("set_objective_text"):
		hud.set_objective_text(text)


func _on_player_died() -> void:
	ScoreManager.record_death()
	get_tree().create_timer(1.0).timeout.connect(func() -> void:
		player.restore_checkpoint()
	)

extends Node

## Mission 5 — Victory: approach climb, destroy T-55, clear courtyard, raise the flag.

enum Stage { APPROACH, TANK, COURTYARD, FLAG }

@onready var player: CharacterBody2D = $"../Player"
@onready var tank: Node = $"../Vehicles/Tank"
@onready var approach_enemies: Node2D = $"../ApproachEnemies"
@onready var courtyard_enemies: Node2D = $"../CourtyardEnemies"
@onready var flag: Area2D = $"../FlagObjective"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _stage: Stage = Stage.APPROACH
var _mission_complete: bool = false
var _courtyard_remaining: int = 0
var _approach_remaining: int = 0


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	if tank and tank.has_signal("destroyed"):
		tank.destroyed.connect(_on_tank_destroyed)
	elif tank and tank.has_signal("died"):
		tank.died.connect(_on_tank_destroyed)
	for e in courtyard_enemies.get_children():
		_courtyard_remaining += 1
		if e.has_signal("enemy_died"):
			e.enemy_died.connect(_on_courtyard_kill)
	for e in approach_enemies.get_children():
		_approach_remaining += 1
		if e.has_signal("enemy_died"):
			e.enemy_died.connect(_on_approach_kill)
	flag.flag_raised.connect(_on_flag_raised)
	MissionHelpers.set_group_active(courtyard_enemies, false)
	if tank:
		tank.process_mode = Node.PROCESS_MODE_DISABLED
		tank.visible = false
	objective_tracker.add_destroy_objective([tank] if tank else [], "Destroy the T-55")
	MissionHelpers.set_hud_objective(get_tree(), "Stage 1: Clear the fortress approach")


func _on_approach_kill(_e = null) -> void:
	_approach_remaining = maxi(_approach_remaining - 1, 0)
	if _stage == Stage.APPROACH and _approach_remaining <= 0:
		_enter_tank_stage()


func _enter_tank_stage() -> void:
	_stage = Stage.TANK
	player.save_checkpoint(player.global_position)
	MissionHelpers._notify_checkpoint(player)
	if tank:
		tank.visible = true
		tank.process_mode = Node.PROCESS_MODE_INHERIT
	MissionHelpers.set_hud_objective(get_tree(), "Stage 2: Destroy the T-55 tank")


func _on_tank_destroyed(_a = null) -> void:
	_stage = Stage.COURTYARD
	player.save_checkpoint(player.global_position)
	MissionHelpers._notify_checkpoint(player)
	MissionHelpers.set_group_active(courtyard_enemies, true)
	MissionHelpers.set_hud_objective(get_tree(), "Stage 3: Clear the courtyard (%d left)" % _courtyard_remaining)
	if _courtyard_remaining <= 0:
		_enter_flag_stage()


func _on_courtyard_kill(_e = null) -> void:
	_courtyard_remaining = maxi(_courtyard_remaining - 1, 0)
	if _stage == Stage.COURTYARD:
		MissionHelpers.set_hud_objective(get_tree(), "Stage 3: Clear the courtyard (%d left)" % _courtyard_remaining)
		if _courtyard_remaining <= 0:
			_enter_flag_stage()


func _enter_flag_stage() -> void:
	_stage = Stage.FLAG
	MissionHelpers.set_hud_objective(get_tree(), "Stage 4: Raise the flag on the fortress")


func _on_flag_raised() -> void:
	if _mission_complete:
		return
	if _stage != Stage.FLAG:
		return
	_mission_complete = true
	MissionHelpers.set_hud_objective(get_tree(), "Victory! The flag flies over Knin.")
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		MissionHelpers.complete_mission(get_tree())
	)

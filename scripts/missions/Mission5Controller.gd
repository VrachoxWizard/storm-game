extends Node

## Mission 5 — Victory: approach climb, destroy SVK T-55, clear courtyard, raise the šahovnica.
## Stage flow is driven by Approach/Tank/Courtyard/Flag; ObjectiveTracker mirrors the tank objective.

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
var _guidance: ObjectiveGuidance = null


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	_guidance = ObjectiveGuidance.new()
	_guidance.name = "ObjectiveGuidance"
	add_child(_guidance)
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
		MissionHelpers.set_group_active(tank, false)
	# Tracker mirrors stage 2 only — HUD stages remain authoritative for approach/courtyard/flag.
	if tank:
		objective_tracker.add_destroy_objective([tank], "Destroy the SVK T-55")
		objective_tracker.objective_updated.connect(_on_tracker_progress)
	MissionHelpers.set_hud_objective(get_tree(), "Stage 1: Clear the Knin fortress approach")


func _on_tracker_progress(completed: int, total: int) -> void:
	if _stage == Stage.TANK:
		var label := objective_tracker.get_current_label()
		MissionHelpers.set_hud_objective(get_tree(), "Stage 2: %s (%d/%d)" % [label, completed, total])


func _on_approach_kill(_e = null) -> void:
	_approach_remaining = maxi(_approach_remaining - 1, 0)
	if _stage == Stage.APPROACH and _approach_remaining <= 0:
		_enter_tank_stage()


func _enter_tank_stage() -> void:
	_stage = Stage.TANK
	player.save_checkpoint(player.global_position)
	MissionHelpers._notify_checkpoint(player)
	if tank:
		MissionHelpers.set_group_active(tank, true)
		if _guidance:
			_guidance.set_targets([tank])
	MissionHelpers.set_hud_objective(get_tree(), "Stage 2: Destroy the SVK T-55 tank")


func _on_tank_destroyed(_a = null) -> void:
	_stage = Stage.COURTYARD
	player.save_checkpoint(player.global_position)
	MissionHelpers._notify_checkpoint(player)
	MissionHelpers.set_group_active(courtyard_enemies, true)
	if _guidance:
		_guidance.clear()
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
	flag.enabled = true
	if _guidance:
		_guidance.set_targets([flag], true)
	MissionHelpers.set_hud_objective(get_tree(), "Stage 4: Hold [E] at the flag to raise the šahovnica")


func _on_flag_raised() -> void:
	if _mission_complete:
		return
	if _stage != Stage.FLAG:
		return
	_mission_complete = true
	if _guidance:
		_guidance.clear()
	MissionHelpers.set_hud_objective(get_tree(), "Victory! The šahovnica flies over Knin.")
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_voice_line"):
		snd.play_voice_line("oluja")
	get_tree().create_timer(1.5).timeout.connect(func() -> void:
		if is_instance_valid(self) and is_inside_tree() and get_tree():
			MissionHelpers.complete_mission(get_tree())
	)

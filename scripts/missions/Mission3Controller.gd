extends Node

## Mission 3 — Open Road: stop APC convoy before escape, then tank, then liberate village.

@onready var player: CharacterBody2D = $"../Player"
@onready var vehicles_node: Node2D = $"../Vehicles"
@onready var village_zone: Area2D = $"../VillageZone"
@onready var objective_tracker: ObjectiveTracker = $ObjectiveTracker

var _mission_complete: bool = false
var _apc: Node = null
var _tank: Node = null
var _convoy_escaped: bool = false
var _convoy_started: bool = false
var _convoy_speed: float = 55.0
var _exit_x: float = 1550.0
var _guidance: ObjectiveGuidance = null


func _ready() -> void:
	player.died.connect(func() -> void: MissionHelpers.handle_player_died(player))
	MissionHelpers.connect_checkpoints(get_parent(), player)
	_add_extra_checkpoint(Vector2(700, 480))
	MissionHelpers.add_zone_banner(village_zone, "LIBERATE VILLAGE")
	_apc = vehicles_node.get_node_or_null("Apc")
	_tank = vehicles_node.get_node_or_null("Tank")
	if _tank:
		MissionHelpers.set_group_active(_tank, false)
	if _apc and _apc is Node:
		_apc.convoy_mode = true
		_apc.convoy_speed = 0.0
	objective_tracker.sequential = true
	if _apc:
		objective_tracker.add_destroy_objective([_apc], "Stop the SVK M-80 convoy")
		if _apc.has_signal("destroyed"):
			_apc.destroyed.connect(_on_apc_destroyed)
	if _tank:
		objective_tracker.add_destroy_objective([_tank], "Destroy the SVK T-55")
	objective_tracker.add_area_objective(village_zone, "Liberate Kijevo / Vrlika")
	objective_tracker.all_objectives_complete.connect(_complete)
	objective_tracker.objective_updated.connect(_on_progress)
	_guidance = MissionHelpers.bind_objective_guidance(self, objective_tracker)
	_on_progress(0, objective_tracker.get_progress()["total"])


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


func _physics_process(_delta: float) -> void:
	if _mission_complete or _convoy_escaped:
		return
	if _apc == null or not is_instance_valid(_apc):
		return
	if _apc.get("is_destroyed"):
		return
	if _apc is CharacterBody2D:
		var body := _apc as CharacterBody2D
		if not _convoy_started and player.global_position.x >= 350.0:
			_convoy_started = true
			_apc.convoy_speed = _convoy_speed
			MissionHelpers.set_hud_objective(get_tree(), "SVK 7th Dalmatian convoy moving east! Cut it off with RPGs or mines")
		if body.global_position.x >= _exit_x:
			_on_convoy_escaped()


func _on_apc_destroyed(_a = null) -> void:
	if _tank:
		MissionHelpers.set_group_active(_tank, true)
		player.save_checkpoint(player.global_position)
		MissionHelpers._notify_checkpoint(player)
		MissionHelpers.set_hud_objective(get_tree(), "M-80 down! Destroy the SVK T-55, then liberate the village")
		# Refresh guidance now that the tank is active/visible.
		if _guidance and objective_tracker:
			_guidance.set_targets(objective_tracker.get_current_targets())


func _on_convoy_escaped() -> void:
	if _convoy_escaped:
		return
	_convoy_escaped = true
	MissionHelpers.set_hud_objective(get_tree(), "Convoy escaped — regrouping for another attempt")
	_apc.convoy_speed = 0.0
	get_tree().create_timer(2.5).timeout.connect(func() -> void:
		if not is_instance_valid(self) or not is_inside_tree():
			return
		var gm := get_node_or_null("/root/GameManager")
		if gm and gm.current_state == gm.GameState.PLAYING:
			gm.start_mission(2)
	)



func _on_progress(completed: int, total: int) -> void:
	var label := objective_tracker.get_current_label()
	MissionHelpers.set_hud_objective(get_tree(), "Objectives: %d/%d — %s" % [completed, total, label])


func _complete() -> void:
	if _mission_complete:
		return
	_mission_complete = true
	MissionHelpers.complete_mission(get_tree())

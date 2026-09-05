extends Node

## Singleton — tracks kills, accuracy, time, and calculates score/rank.

var kills: int = 0
var shots_fired: int = 0
var shots_hit: int = 0
var vehicles_destroyed: int = 0
var emplacements_destroyed: int = 0
var deaths: int = 0
var elapsed_time: float = 0.0
var _is_tracking: bool = false

const KILL_POINTS: int = 100
const VEHICLE_POINTS: int = 500
const EMPLACEMENT_POINTS: int = 300
const NO_DEATH_BONUS: int = 1000
const TIME_BONUS_THRESHOLD: float = 300.0


func _process(delta: float) -> void:
	if _is_tracking:
		elapsed_time += delta


func reset() -> void:
	kills = 0
	shots_fired = 0
	shots_hit = 0
	vehicles_destroyed = 0
	emplacements_destroyed = 0
	deaths = 0
	elapsed_time = 0.0
	_is_tracking = false


func start_tracking() -> void:
	_is_tracking = true


func stop_tracking() -> void:
	_is_tracking = false


func record_kill() -> void:
	kills += 1


func record_shot_fired() -> void:
	shots_fired += 1


func record_shot_hit() -> void:
	shots_hit += 1


func record_vehicle_destroyed() -> void:
	vehicles_destroyed += 1


func record_emplacement_destroyed() -> void:
	emplacements_destroyed += 1


func record_death() -> void:
	deaths += 1


func get_accuracy() -> float:
	if shots_fired == 0:
		return 0.0
	return float(shots_hit) / float(shots_fired) * 100.0


func get_total_score() -> int:
	var score: int = 0
	score += kills * KILL_POINTS
	score += vehicles_destroyed * VEHICLE_POINTS
	score += emplacements_destroyed * EMPLACEMENT_POINTS

	var acc := get_accuracy()
	if acc >= 80.0:
		score = int(score * 1.5)
	elif acc >= 60.0:
		score = int(score * 1.25)
	elif acc >= 40.0:
		score = int(score * 1.0)
	else:
		score = int(score * 0.75)

	if elapsed_time < TIME_BONUS_THRESHOLD:
		score += int((TIME_BONUS_THRESHOLD - elapsed_time) * 2.0)

	if deaths == 0:
		score += NO_DEATH_BONUS

	return score


func get_rank() -> String:
	var score := get_total_score()
	var max_possible := 5000
	var percentage := float(score) / float(max_possible) * 100.0

	if percentage >= 90.0:
		return "A"
	elif percentage >= 70.0:
		return "B"
	elif percentage >= 50.0:
		return "C"
	else:
		return "D"

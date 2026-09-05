extends Control

## Post-mission results screen showing score, stats, and rank.

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var accuracy_label: Label = $CenterContainer/VBoxContainer/AccuracyLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/TimeLabel
@onready var rank_label: Label = $CenterContainer/VBoxContainer/RankLabel
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var next_button: Button = $CenterContainer/VBoxContainer/NextButton


func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	next_button.pressed.connect(_on_next)


func show_results() -> void:
	score_label.text = "Score: %d" % ScoreManager.get_total_score()
	kills_label.text = "Kills: %d" % ScoreManager.kills
	accuracy_label.text = "Accuracy: %.0f%%" % ScoreManager.get_accuracy()

	var minutes := int(ScoreManager.elapsed_time) / 60
	var seconds := int(ScoreManager.elapsed_time) % 60
	time_label.text = "Time: %d:%02d" % [minutes, seconds]

	rank_label.text = "Rank: %s" % ScoreManager.get_rank()

	var next_idx: int = GameManager.current_mission + 1
	var has_next: bool = next_idx < GameManager.MISSION_SCENES.size() and SaveManager.is_mission_unlocked(next_idx)
	next_button.visible = has_next
	if has_next:
		next_button.text = "Next: %s" % GameManager.MISSION_NAMES[next_idx]
	else:
		next_button.text = "Next"
	visible = true


func _on_continue() -> void:
	visible = false
	GameManager.return_to_menu()


func _on_next() -> void:
	var next_idx: int = GameManager.current_mission + 1
	visible = false
	GameManager.start_mission(next_idx)

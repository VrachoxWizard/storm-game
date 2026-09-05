extends Control

## Post-mission results screen showing score, stats, rank, and stamped official seal.

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var accuracy_label: Label = $CenterContainer/VBoxContainer/AccuracyLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/TimeLabel
@onready var rank_label: Label = $CenterContainer/VBoxContainer/RankLabel
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var next_button: Button = $CenterContainer/VBoxContainer/NextButton
@onready var complete_stamp: TextureRect = get_node_or_null("CenterContainer/VBoxContainer/StampContainer/CompleteStamp")
@onready var detail_label: Label = get_node_or_null("CenterContainer/VBoxContainer/DetailLabel")


func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	next_button.pressed.connect(_on_next)
	if detail_label == null:
		detail_label = Label.new()
		detail_label.name = "DetailLabel"
		detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var vbox := $CenterContainer/VBoxContainer
		vbox.add_child(detail_label)
		vbox.move_child(detail_label, rank_label.get_index() + 1)


func show_results() -> void:
	var sm = get_node_or_null("/root/ScoreManager")
	var gm = get_node_or_null("/root/GameManager")
	var svm = get_node_or_null("/root/SaveManager")

	if sm:
		score_label.text = "Score: %d" % sm.get_total_score()
		kills_label.text = "Kills: %d" % sm.kills
		accuracy_label.text = "Accuracy: %.0f%%" % sm.get_accuracy()
		var minutes: int = int(sm.elapsed_time) / 60
		var seconds: int = int(sm.elapsed_time) % 60
		time_label.text = "Time: %d:%02d" % [minutes, seconds]
		rank_label.text = "Rank: %s" % sm.get_rank()
		if detail_label:
			detail_label.text = "Vehicles: %d  |  Emplacements: %d  |  Deaths: %d%s" % [
				sm.vehicles_destroyed,
				sm.emplacements_destroyed,
				sm.deaths,
				"  |  No-Death Bonus!" if sm.deaths == 0 else "",
			]

	if gm and svm:
		var next_idx: int = gm.current_mission + 1
		var has_next: bool = next_idx < gm.MISSION_SCENES.size() and svm.is_mission_unlocked(next_idx)
		next_button.visible = has_next
		if has_next:
			next_button.text = "Next: %s" % gm.MISSION_NAMES[next_idx]
		else:
			next_button.text = "Next"

	if complete_stamp:
		complete_stamp.scale = Vector2(1.5, 1.5)
		complete_stamp.modulate.a = 0.0
		complete_stamp.rotation = -0.12
		var tween := create_tween()
		tween.parallel().tween_property(complete_stamp, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.parallel().tween_property(complete_stamp, "modulate:a", 1.0, 0.12)
		SoundManager.play_sfx("objective")

	visible = true


func _on_continue() -> void:
	SoundManager.play_sfx("ui_click")
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("return_to_menu"):
		gm.return_to_menu()


func _on_next() -> void:
	SoundManager.play_sfx("ui_click")
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("start_mission"):
		var next_idx: int = gm.current_mission + 1
		visible = false
		gm.start_mission(next_idx)

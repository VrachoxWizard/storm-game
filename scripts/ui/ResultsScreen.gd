extends CanvasLayer

## Post-mission results screen showing score, stats, rank, debrief lore, and stamped seal.
## CanvasLayer so the active mission Camera2D cannot transform this UI.

const Briefings = preload("res://scripts/missions/MissionBriefings.gd")

@onready var score_label: Label = $CenterContainer/VBoxContainer/ScoreLabel
@onready var kills_label: Label = $CenterContainer/VBoxContainer/KillsLabel
@onready var accuracy_label: Label = $CenterContainer/VBoxContainer/AccuracyLabel
@onready var time_label: Label = $CenterContainer/VBoxContainer/TimeLabel
@onready var rank_label: Label = $CenterContainer/VBoxContainer/RankLabel
@onready var detail_label: Label = $CenterContainer/VBoxContainer/DetailLabel
@onready var debrief_label: Label = $CenterContainer/VBoxContainer/DebriefLabel
@onready var continue_button: Button = $CenterContainer/VBoxContainer/ContinueButton
@onready var next_button: Button = $CenterContainer/VBoxContainer/NextButton
@onready var complete_stamp: TextureRect = $CenterContainer/VBoxContainer/StampContainer/CompleteStamp


func _ready() -> void:
	continue_button.pressed.connect(_on_continue)
	next_button.pressed.connect(_on_next)
	visible = false


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
		detail_label.text = "Vehicles: %d  |  Emplacements: %d  |  Deaths: %d%s" % [
			sm.vehicles_destroyed,
			sm.emplacements_destroyed,
			sm.deaths,
			"  |  No-Death Bonus!" if sm.deaths == 0 else "",
		]

	if gm:
		debrief_label.text = Briefings.get_debrief(gm.current_mission)

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
	# region agent log
	await get_tree().process_frame
	_agent_dbg_results("post-layout")
	# endregion


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


# region agent log
const _AGENT_LOG_PATH := "C:/Users/user1/OneDrive/Desktop/Moji Osobni projekti/2d-arcade-shooter-desktop/debug-951e11.log"


func _agent_dbg_log(hypothesis_id: String, location: String, message: String, data: Dictionary) -> void:
	var payload := {
		"sessionId": "951e11",
		"runId": "post-fix",
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_ticks_msec(),
	}
	var f: FileAccess
	if FileAccess.file_exists(_AGENT_LOG_PATH):
		f = FileAccess.open(_AGENT_LOG_PATH, FileAccess.READ_WRITE)
		if f:
			f.seek_end()
	else:
		f = FileAccess.open(_AGENT_LOG_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("agent dbg log open failed: %s" % FileAccess.get_open_error())
		return
	f.store_line(JSON.stringify(payload))
	f.close()
	print("[agent-dbg] ", hypothesis_id, " ", message)


func _agent_dbg_results(phase: String) -> void:
	var bg: TextureRect = get_node_or_null("BackgroundParchment") as TextureRect
	var vbox: VBoxContainer = get_node_or_null("CenterContainer/VBoxContainer") as VBoxContainer
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var stamp_tex: Texture2D = complete_stamp.texture if complete_stamp else null
	var detail_col := detail_label.get_theme_color("font_color") if detail_label else Color.TRANSPARENT
	var debrief_size := debrief_label.size if debrief_label else Vector2.ZERO
	var overlap := false
	if detail_label and debrief_label:
		overlap = detail_label.get_global_rect().intersects(debrief_label.get_global_rect())
	var stamp_overlap := false
	if complete_stamp and debrief_label:
		stamp_overlap = complete_stamp.get_global_rect().intersects(debrief_label.get_global_rect())
	_agent_dbg_log("B", "ResultsScreen.gd:show_results", "parchment_bg_state", {
		"phase": phase,
		"vp_size": {"x": vp_size.x, "y": vp_size.y},
		"layer": layer,
		"bg_size": {"x": bg.size.x if bg else -1.0, "y": bg.size.y if bg else -1.0},
		"bg_stretch_mode": bg.stretch_mode if bg else -1,
		"bg_stretch_is_aspect_covered": bg != null and bg.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED,
		"bg_modulate_a": bg.modulate.a if bg else -1.0,
		"bg_has_texture": bg.texture != null if bg else false,
	})
	_agent_dbg_log("C", "ResultsScreen.gd:show_results", "world_bleed_context", {
		"phase": phase,
		"results_visible": visible,
		"is_canvas_layer": true,
		"layer": layer,
	})
	_agent_dbg_log("D", "ResultsScreen.gd:show_results", "label_layout", {
		"phase": phase,
		"vbox_size": {"x": vbox.size.x if vbox else -1.0, "y": vbox.size.y if vbox else -1.0},
		"debrief_size": {"x": debrief_size.x, "y": debrief_size.y},
		"detail_debrief_overlap": overlap,
		"stamp_debrief_overlap": stamp_overlap,
		"child_order": _agent_vbox_order(vbox),
	})
	_agent_dbg_log("E", "ResultsScreen.gd:show_results", "detail_label_theme", {
		"phase": phase,
		"detail_exists": detail_label != null,
		"detail_font_color": {"r": detail_col.r, "g": detail_col.g, "b": detail_col.b, "a": detail_col.a},
		"detail_is_ink_brown": detail_col.r < 0.5 and detail_col.g < 0.4,
	})
	_agent_dbg_log("A", "ResultsScreen.gd:show_results", "stamp_texture_state", {
		"phase": phase,
		"has_stamp": complete_stamp != null,
		"stamp_path": stamp_tex.resource_path if stamp_tex else "",
		"stamp_size": {"x": stamp_tex.get_width() if stamp_tex else 0, "y": stamp_tex.get_height() if stamp_tex else 0},
	})


func _agent_vbox_order(vbox: VBoxContainer) -> Array:
	var order: Array = []
	if vbox == null:
		return order
	for child in vbox.get_children():
		order.append(str(child.name))
	return order
# endregion

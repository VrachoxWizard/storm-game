extends Control

## Journal-style mission briefing screen.

const Briefings = preload("res://scripts/missions/MissionBriefings.gd")

@onready var mission_title: Label = $MarginContainer/VBoxContainer/MissionTitle
@onready var mission_desc: RichTextLabel = $MarginContainer/VBoxContainer/MissionDesc
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)


func show_briefing(mission_index: int) -> void:
	var briefing: Dictionary = Briefings.get_briefing(mission_index)
	mission_title.text = str(briefing.get("title", "Mission"))
	mission_desc.text = str(briefing.get("description", ""))
	visible = true


func _on_start() -> void:
	visible = false
	GameManager.begin_gameplay()

extends Control

## Journal-style mission briefing screen.

const BRIEFINGS: Array[Dictionary] = [
	{
		"title": "Mission 1: First Thunder",
		"description": "August 4, 1995 — Dawn.\n\nThe artillery barrage has begun. Operation Storm is underway.\n\nYour task: Hold the forward positions against enemy counterattacks while our forces prepare the main assault. Survive the waves. Hold the line.\n\nZa dom!",
	},
]

@onready var mission_title: Label = $MarginContainer/VBoxContainer/MissionTitle
@onready var mission_desc: RichTextLabel = $MarginContainer/VBoxContainer/MissionDesc
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start)


func show_briefing(mission_index: int) -> void:
	if mission_index < BRIEFINGS.size():
		var briefing: Dictionary = BRIEFINGS[mission_index]
		mission_title.text = briefing["title"]
		mission_desc.text = briefing["description"]
	visible = true


func _on_start() -> void:
	visible = false
	GameManager.begin_gameplay()

extends Control

## Journal-style mission briefing screen with HV / SVK authenticity metadata.

const Briefings = preload("res://scripts/missions/MissionBriefings.gd")
const HV_FACTION: FactionResource = preload("res://resources/factions/hv_faction.tres")
const SVK_FACTION: FactionResource = preload("res://resources/factions/svk_faction.tres")

@onready var mission_title: Label = $MarginContainer/VBoxContainer/MissionTitle
@onready var mission_desc: RichTextLabel = $MarginContainer/VBoxContainer/MissionDesc
@onready var start_button: Button = $MarginContainer/VBoxContainer/StartButton

var _meta_label: Label
var _hv_icon: TextureRect
var _svk_icon: TextureRect


func _ready() -> void:
	start_button.pressed.connect(_on_start)
	_ensure_meta_ui()


func _ensure_meta_ui() -> void:
	var vbox := $MarginContainer/VBoxContainer
	_meta_label = vbox.get_node_or_null("MetaLabel") as Label
	if _meta_label == null:
		_meta_label = Label.new()
		_meta_label.name = "MetaLabel"
		_meta_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_meta_label.add_theme_font_size_override("font_size", 14)
		_meta_label.add_theme_color_override("font_color", Color(0.35, 0.28, 0.22, 1))
		vbox.add_child(_meta_label)
		vbox.move_child(_meta_label, mission_title.get_index() + 1)

	var row := vbox.get_node_or_null("FactionRow") as HBoxContainer
	if row == null:
		row = HBoxContainer.new()
		row.name = "FactionRow"
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 24)
		vbox.add_child(row)
		vbox.move_child(row, _meta_label.get_index() + 1)
		_hv_icon = TextureRect.new()
		_hv_icon.name = "HvIcon"
		_hv_icon.custom_minimum_size = Vector2(72, 36)
		_hv_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_hv_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(_hv_icon)
		var vs := Label.new()
		vs.text = "vs"
		vs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(vs)
		_svk_icon = TextureRect.new()
		_svk_icon.name = "SvkIcon"
		_svk_icon.custom_minimum_size = Vector2(72, 36)
		_svk_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_svk_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(_svk_icon)
	else:
		_hv_icon = row.get_node_or_null("HvIcon") as TextureRect
		_svk_icon = row.get_node_or_null("SvkIcon") as TextureRect


func show_briefing(mission_index: int) -> void:
	_ensure_meta_ui()
	var briefing: Dictionary = Briefings.get_briefing(mission_index)
	mission_title.text = str(briefing.get("title", "Mission"))
	mission_desc.text = str(briefing.get("description", ""))
	var meta_parts: PackedStringArray = []
	if briefing.has("date"):
		meta_parts.append(str(briefing["date"]))
	if briefing.has("sector"):
		meta_parts.append(str(briefing["sector"]))
	if briefing.has("hv_unit"):
		meta_parts.append("HV: %s" % str(briefing["hv_unit"]))
	if briefing.has("svk_unit"):
		meta_parts.append("SVK: %s" % str(briefing["svk_unit"]))
	_meta_label.text = "  ·  ".join(meta_parts)
	var dm := get_node_or_null("/root/DifficultyManager")
	if dm and dm.has_method("current_label"):
		_meta_label.text += "  ·  Difficulty: %s" % dm.current_label()
	if _hv_icon:
		_hv_icon.texture = HV_FACTION.flag_texture if HV_FACTION.flag_texture else HV_FACTION.insignia_texture
	if _svk_icon:
		_svk_icon.texture = SVK_FACTION.flag_texture if SVK_FACTION.flag_texture else SVK_FACTION.insignia_texture
	visible = true


func _on_start() -> void:
	visible = false
	var gm = get_node_or_null("/root/GameManager")
	if gm and gm.has_method("begin_gameplay"):
		gm.begin_gameplay()
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_voice_line"):
		snd.play_voice_line("naprijed")

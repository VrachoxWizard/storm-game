extends Area2D

## Interactable flag raise zone for Mission 5 victory.

signal flag_raised

@export var hold_time: float = 2.0

var enabled: bool = false
var _player_inside: bool = false
var _hold: float = 0.0
var _raised: bool = false
var _track: ColorRect
var _fill: ColorRect
var _flag_sprite: Sprite2D
var _flag_rest_y: float = 0.0

const _BAR_SIZE := Vector2(64, 6)


func _ready() -> void:
	add_to_group("flag")
	collision_layer = 0
	collision_mask = 1
	_build_hold_bar()
	# The flag starts lowered at the pole base; it rises when the objective completes.
	_flag_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _flag_sprite:
		_flag_rest_y = _flag_sprite.position.y
		_flag_sprite.position.y = _flag_rest_y + 30.0
		_flag_sprite.modulate.a = 0.45
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = false
			_hold = 0.0
			_set_hold_visible(false)
			_update_fill(0.0)
	)


func _build_hold_bar() -> void:
	## Thin ink-style meter — never use default ProgressBar chrome (draws huge black rects).
	_track = ColorRect.new()
	_track.name = "HoldTrack"
	_track.size = _BAR_SIZE
	_track.position = Vector2(-_BAR_SIZE.x * 0.5, -40.0)
	_track.color = Color(0.12, 0.1, 0.08, 0.75)
	_track.visible = false
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_track)

	_fill = ColorRect.new()
	_fill.name = "HoldFill"
	_fill.size = Vector2(0.0, _BAR_SIZE.y)
	_fill.position = Vector2.ZERO
	_fill.color = Color(0.85, 0.72, 0.28, 0.95)
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_track.add_child(_fill)


func _set_hold_visible(show_bar: bool) -> void:
	if _track:
		_track.visible = show_bar


func _update_fill(ratio: float) -> void:
	if _fill:
		_fill.size = Vector2(_BAR_SIZE.x * clampf(ratio, 0.0, 1.0), _BAR_SIZE.y)


func _process(delta: float) -> void:
	if not enabled:
		_hold = 0.0
		_set_hold_visible(false)
		return
	if _raised:
		return
	if _player_inside and Input.is_action_pressed("interact"):
		_set_hold_visible(true)
		_hold += delta
		_update_fill(_hold / hold_time)
		if _hold >= hold_time:
			_raised = true
			_set_hold_visible(false)
			# Raise the šahovnica up the pole.
			if _flag_sprite and is_inside_tree():
				var tween := create_tween()
				if tween:
					tween.set_parallel(true)
					tween.tween_property(_flag_sprite, "position:y", _flag_rest_y - 12.0, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					tween.tween_property(_flag_sprite, "modulate:a", 1.0, 0.6)
			flag_raised.emit()
	else:
		_hold = 0.0
		_update_fill(0.0)
		if not _player_inside:
			_set_hold_visible(false)

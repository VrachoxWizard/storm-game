extends Area2D

## Interactable flag raise zone for Mission 5 victory.

signal flag_raised

@export var hold_time: float = 2.0

var enabled: bool = false
var _player_inside: bool = false
var _hold: float = 0.0
var _raised: bool = false
var _progress_bar: ProgressBar
var _flag_sprite: Sprite2D
var _flag_rest_y: float = 0.0


func _ready() -> void:
	add_to_group("flag")
	collision_layer = 0
	collision_mask = 1
	_progress_bar = ProgressBar.new()
	_progress_bar.custom_minimum_size = Vector2(64, 8)
	_progress_bar.max_value = hold_time
	_progress_bar.value = 0.0
	_progress_bar.show_percentage = false
	_progress_bar.visible = false
	_progress_bar.position = Vector2(-32, -40)
	add_child(_progress_bar)
	# The flag starts lowered at the pole base; it rises when the objective completes.
	_flag_sprite = get_node_or_null("Sprite2D") as Sprite2D
	if _flag_sprite:
		_flag_rest_y = _flag_sprite.position.y
		_flag_sprite.position.y = _flag_rest_y + 30.0
		_flag_sprite.modulate.a = 0.45
	body_entered.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = true
			_progress_bar.visible = true
	)
	body_exited.connect(func(body: Node2D) -> void:
		if body.is_in_group("player"):
			_player_inside = false
			_hold = 0.0
			_progress_bar.value = 0.0
			_progress_bar.visible = false
	)


func _process(delta: float) -> void:
	if not enabled:
		_hold = 0.0
		_progress_bar.visible = false
		return
	if _raised:
		return
	if _player_inside and Input.is_action_pressed("interact"):
		_progress_bar.visible = true
		_hold += delta
		_progress_bar.value = _hold
		if _hold >= hold_time:
			_raised = true
			_progress_bar.visible = false
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
		_progress_bar.value = 0.0

extends Area2D

## Base class for all pickups. Detects player collision and applies effect.

signal picked_up


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_apply_effect(body)
		picked_up.emit()
		var root_node = Engine.get_main_loop().root if Engine.get_main_loop() else null
		var sm = root_node.get_node_or_null("/root/SoundManager") if root_node else null
		if sm:
			sm.play_sfx("pickup")
		queue_free()


## Override in subclasses to define what the pickup does.
func _apply_effect(_player: Node2D) -> void:
	pass

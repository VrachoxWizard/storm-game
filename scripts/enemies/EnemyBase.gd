extends CharacterBody2D

## Base class for all enemies. Simple state machine AI.

signal enemy_died(enemy: CharacterBody2D)

enum State { PATROL, ALERT, CHASE, ATTACK, DEAD }

@export var max_health: int = 50
@export var speed: float = 100.0
@export var attack_range: float = 150.0
@export var detection_range: float = 200.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0

var health: int = max_health
var current_state: State = State.PATROL
var target: CharacterBody2D = null
var _patrol_direction: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var state_timer: Timer = $StateTimer


func _ready() -> void:
	health = max_health
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.one_shot = true
	state_timer.one_shot = true
	_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ALERT:
			_process_alert(delta)
		State.CHASE:
			_process_chase(delta)
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			pass


func take_damage(amount: int) -> void:
	if current_state == State.DEAD:
		return

	health -= amount
	_flash_hit()

	if health <= 0:
		_die()
	elif current_state == State.PATROL:
		_enter_alert()


func _die() -> void:
	current_state = State.DEAD
	enemy_died.emit(self)
	queue_free()


func _process_patrol(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer > 3.0:
		_patrol_timer = 0.0
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)

	velocity = _patrol_direction * speed * 0.3
	look_at(global_position + _patrol_direction)
	move_and_slide()


func _process_alert(_delta: float) -> void:
	if target and is_instance_valid(target):
		look_at(target.global_position)
		_enter_chase()


func _process_chase(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return

	var dir := (target.global_position - global_position).normalized()
	velocity = dir * speed
	look_at(target.global_position)
	move_and_slide()

	var dist := global_position.distance_to(target.global_position)
	if dist <= attack_range:
		_enter_attack()


func _process_attack(_delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return

	look_at(target.global_position)
	var dist := global_position.distance_to(target.global_position)
	if dist > attack_range * 1.2:
		_enter_chase()


func _enter_alert() -> void:
	current_state = State.ALERT


func _enter_chase() -> void:
	current_state = State.CHASE


func _enter_attack() -> void:
	current_state = State.ATTACK
	_perform_attack()
	attack_timer.wait_time = attack_cooldown
	attack_timer.start()


## Override in subclasses for specific attack behavior.
func _perform_attack() -> void:
	pass


func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACK:
		_perform_attack()
		attack_timer.start()


func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		target = body
		if current_state == State.PATROL:
			_enter_alert()


func _on_detection_body_exited(body: Node2D) -> void:
	if body == target:
		if current_state == State.CHASE or current_state == State.ATTACK:
			target = null
			current_state = State.PATROL


func _flash_hit() -> void:
	sprite.modulate = Color.RED
	get_tree().create_timer(0.1).timeout.connect(func() -> void: sprite.modulate = Color.WHITE)

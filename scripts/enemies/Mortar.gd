extends EnemyBase

## Mortar pit — telegraphs red warning circle then splash damage.

signal destroyed

@export var telegraph_time: float = 1.5
@export var splash_radius: float = 70.0
@export var splash_damage: int = 35

var _firing: bool = false
var _warning: Sprite2D


func _ready() -> void:
	super._ready()
	max_health = 120
	health = max_health
	speed = 0.0
	attack_range = 500.0
	detection_range = 550.0
	damage = splash_damage
	attack_cooldown = 4.0
	add_to_group("emplacement")
	add_to_group("mortar")
	_warning = Sprite2D.new()
	_warning.texture = preload("res://assets/sprites/warning_circle.png")
	_warning.visible = false
	_warning.z_index = 10
	# Parent under world so it stays at target point
	call_deferred("_attach_warning")


func _attach_warning() -> void:
	var world := get_parent()
	if world:
		world.add_child(_warning)
	else:
		add_child(_warning)


func _physics_process(delta: float) -> void:
	match current_state:
		State.PATROL, State.ALERT, State.CHASE:
			if target and is_instance_valid(target):
				_enter_attack()
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			pass


func _die() -> void:
	if is_instance_valid(_warning):
		_warning.queue_free()
	current_state = State.DEAD
	destroyed.emit()
	enemy_died.emit(self)
	var sm = get_node_or_null("/root/ScoreManager")
	if sm:
		sm.record_emplacement_destroyed()
	queue_free()


func _perform_attack() -> void:
	if _firing or target == null or not is_instance_valid(target):
		return
	_firing = true
	var impact_pos: Vector2 = target.global_position
	_warning.global_position = impact_pos
	_warning.scale = Vector2.ONE * (splash_radius / 32.0)
	_warning.modulate = Color(1, 0.15, 0.15, 0.45)
	_warning.visible = true
	get_tree().create_timer(telegraph_time).timeout.connect(func() -> void:
		_warning.visible = false
		ExplosionHelper.explode(get_tree(), impact_pos, splash_radius, splash_damage, 11.0, true)
		_firing = false
	)

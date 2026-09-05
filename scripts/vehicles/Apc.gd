extends VehicleBase

## B-80 APC — turret fire + deploys infantry when damaged or stopped.

@export var infantry_scene: PackedScene
@export var bullet_scene: PackedScene
@export var deploy_count: int = 3
@export var turret_damage: int = 12

var _deployed: bool = false
var _patrol_dir: Vector2 = Vector2.RIGHT
var _can_fire: bool = true


func _ready() -> void:
	max_health = 250
	armor_threshold = 14
	speed = 80.0
	super._ready()
	_patrol_dir = Vector2.RIGHT


func _vehicle_ai(_delta: float) -> void:
	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist > 180.0:
			velocity = (target.global_position - global_position).normalized() * speed
		else:
			velocity = Vector2.ZERO
			if not _deployed:
				_deploy_infantry()
		look_at(target.global_position)
		move_and_slide()
		if _can_fire and dist < 350.0:
			_fire_turret()
	else:
		velocity = _patrol_dir * speed * 0.5
		move_and_slide()
		if randf() < 0.01:
			_patrol_dir = Vector2.RIGHT.rotated(randf() * TAU)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if health < max_health * 0.6 and not _deployed:
		_deploy_infantry()


func _deploy_infantry() -> void:
	_deployed = true
	if infantry_scene == null:
		return
	var container: Node = get_tree().root.get_node_or_null("Main/WorldContainer")
	if container and container.get_child_count() > 0:
		var mission: Node = container.get_child(0)
		if mission.has_node("Enemies"):
			container = mission.get_node("Enemies")
	for i in range(deploy_count):
		var soldier: Node = infantry_scene.instantiate()
		var offset := Vector2.RIGHT.rotated(float(i) * TAU / float(deploy_count)) * 40.0
		container.add_child(soldier)
		soldier.global_position = global_position + offset


func _fire_turret() -> void:
	if bullet_scene == null or target == null:
		return
	_can_fire = false
	var bullet: Area2D = bullet_scene.instantiate()
	get_tree().root.get_node("Main/Projectiles").add_child(bullet)
	var dir := (target.global_position - global_position).normalized()
	bullet.activate(global_position + dir * 30.0, dir.angle(), 450.0, turret_damage)
	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		_can_fire = true
	)

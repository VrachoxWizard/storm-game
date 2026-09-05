extends VehicleBase

## B-80 APC — 8-wheeled armored chassis with independent 360° twin MG turret.
## Deploys infantry squads when damaged or engaging close targets.

@export var infantry_scene: PackedScene
@export var bullet_scene: PackedScene
@export var deploy_count: int = 3
@export var turret_damage: int = 12
@export var turret_turn_speed: float = 6.0

var _deployed: bool = false
var _patrol_dir: Vector2 = Vector2.RIGHT
var _can_fire: bool = true

@onready var muzzle_marker: Marker2D = get_node_or_null("Turret/MuzzleMarker")


func _ready() -> void:
	max_health = 250
	armor_threshold = 14
	speed = 80.0
	is_tank = false
	super._ready()
	_patrol_dir = Vector2.RIGHT


func _vehicle_ai(delta: float) -> void:
	if is_destroyed:
		return

	if target and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist > 180.0:
			velocity = (target.global_position - global_position).normalized() * speed
		else:
			velocity = Vector2.ZERO
			if not _deployed:
				_deploy_infantry()

		# Independent hull steering toward movement vector
		if velocity.length_squared() > 10.0:
			rotation = lerp_angle(rotation, velocity.angle(), 3.5 * delta)

		# Independent turret tracking toward player target
		if turret:
			var target_angle := (target.global_position - turret.global_position).angle()
			turret.global_rotation = lerp_angle(turret.global_rotation, target_angle, turret_turn_speed * delta)

		if is_inside_tree() and get_world_2d():
			move_and_slide()

		if _can_fire and dist < 350.0:
			_fire_turret()
	else:
		velocity = _patrol_dir * speed * 0.5
		if velocity.length_squared() > 10.0:
			rotation = lerp_angle(rotation, velocity.angle(), 3.5 * delta)

		# Re-center turret to chassis facing when idling
		if turret:
			turret.rotation = lerp_angle(turret.rotation, 0.0, 2.5 * delta)

		if is_inside_tree() and get_world_2d():
			move_and_slide()
		if randf() < 0.01:
			_patrol_dir = Vector2.RIGHT.rotated(randf() * TAU)


func take_damage(amount: int) -> void:
	super.take_damage(amount)
	if health < max_health * 0.6 and not _deployed and not is_destroyed:
		_deploy_infantry()


func _deploy_infantry() -> void:
	_deployed = true
	if infantry_scene == null:
		return
	var container: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		container = get_tree().root.get_node_or_null("Main/WorldContainer")
		if container and container.get_child_count() > 0:
			var mission: Node = container.get_child(0)
			if mission.has_node("Enemies"):
				container = mission.get_node("Enemies")
	if container == null:
		container = get_parent()
	if container == null:
		return

	for i in range(deploy_count):
		var soldier: Node = infantry_scene.instantiate()
		var offset := Vector2.RIGHT.rotated(float(i) * TAU / float(deploy_count)) * 45.0
		container.add_child(soldier)
		if soldier is Node2D:
			(soldier as Node2D).global_position = global_position + offset


func _fire_turret() -> void:
	if bullet_scene == null or target == null or is_destroyed:
		return
	_can_fire = false

	var fire_rot: float = turret.global_rotation if turret else rotation
	var fire_pos: Vector2 = muzzle_marker.global_position if muzzle_marker else global_position + Vector2.RIGHT.rotated(fire_rot) * 28.0

	var proj_container: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		proj_container = get_tree().root.get_node_or_null("Main/Projectiles")
	if proj_container == null:
		proj_container = get_parent()

	if proj_container:
		var bullet: Area2D = bullet_scene.instantiate()
		proj_container.add_child(bullet)
		if bullet.has_method("activate"):
			bullet.activate(fire_pos, fire_rot, 450.0, turret_damage)

	# Visuals: Muzzle flash & cupola recoil kickback
	CombatVfxScript.vfx_muzzle_flash(fire_pos, fire_rot, "heavy")
	if turret:
		var t_sprite: Sprite2D = turret.get_node_or_null("Sprite2D")
		if t_sprite and is_inside_tree():
			t_sprite.position.x = -3.5
			var tw := create_tween()
			if tw:
				tw.tween_property(t_sprite, "position:x", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	get_tree().create_timer(0.25).timeout.connect(func() -> void:
		_can_fire = true
	)

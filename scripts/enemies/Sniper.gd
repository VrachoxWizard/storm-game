extends EnemyBase

## Long-range sniper with red laser telegraph, LOS raycast, and heavy recoil.

@export var aim_time: float = 1.5
@export var bullet_damage: int = 35

var _aiming: bool = false
var _aim_generation: int = 0
var _laser: Line2D


func _ready() -> void:
	unit_key = "sniper"
	super._ready()
	max_health = 40
	health = max_health
	speed = 40.0
	attack_range = 450.0
	detection_range = 500.0
	damage = bullet_damage
	attack_cooldown = 3.0
	_laser = Line2D.new()
	_laser.width = 2.0
	_laser.default_color = Color(1.0, 0.1, 0.1, 0.8)
	_laser.visible = false
	add_child(_laser)


func _physics_process(delta: float) -> void:
	if _aiming and (not is_instance_valid(target) or not _has_line_of_sight()):
		_cancel_aim()
	if _aiming and target and is_instance_valid(target):
		_laser.clear_points()
		var start_pt: Vector2 = to_local(muzzle.global_position if muzzle else global_position)
		_laser.add_point(start_pt)
		_laser.add_point(to_local(target.global_position))
		_update_rig_aim(target.global_position)
		# Cancel aim if LOS blocked
		if not _has_line_of_sight():
			_cancel_aim()
		return
	super._physics_process(delta)


func _perform_attack() -> void:
	if _aiming or target == null:
		return
	if not _has_line_of_sight():
		return
	_aiming = true
	_laser.visible = true
	velocity = Vector2.ZERO
	_aim_generation += 1
	var generation: int = _aim_generation
	get_tree().create_timer(aim_time).timeout.connect(func() -> void:
		if generation == _aim_generation and _aiming:
			_fire_sniper_shot()
	)


func _has_line_of_sight() -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not is_inside_tree() or get_world_2d() == null:
		return true
	var space := get_world_2d().direct_space_state
	var from_pos: Vector2 = muzzle.global_position if muzzle else global_position
	var query := PhysicsRayQueryParameters2D.create(from_pos, target.global_position)
	query.collision_mask = 32  ## Environment layer 6
	query.exclude = [self.get_rid()]
	var result := space.intersect_ray(query)
	return result.is_empty()


func _fire_sniper_shot() -> void:
	if not _aiming: return
	_aiming = false
	_laser.visible = false
	_laser.clear_points()
	if target == null or not is_instance_valid(target) or current_state == State.DEAD:
		return
	if not _has_line_of_sight():
		return
	var fire_pos: Vector2 = muzzle.global_position if muzzle else global_position
	apply_recoil(8.0)
	var flash_rot: float = torso_container.rotation if torso_container else (target.global_position - fire_pos).angle()
	CombatVfxScript.vfx_muzzle_flash(fire_pos, flash_rot, "rifle")
	if target.has_method("take_damage"):
		if target.get("is_dodging"):
			return
		if float(target.get("_respawn_protection") if target.get("_respawn_protection") != null else 0.0) > 0.0:
			return
		# Use scaled `damage` so DifficultyManager multipliers apply.
		target.take_damage(damage)


func _cancel_aim() -> void:
	_aim_generation += 1
	_aiming = false
	_laser.visible = false
	_laser.clear_points()

func _die() -> void:
	_cancel_aim()
	super._die()

extends VehicleBase

## T-55 Tank mini-boss — heavy tracked armored vehicle with 360° rotating turret,
## powerful cannon recoil, muzzle flash, and vulnerable rear engine weak point (3x damage).

@export var shell_scene: PackedScene
@export var shell_damage: int = 40
@export var shell_radius: float = 70.0
@export var fire_cooldown: float = 2.5
@export var turret_turn_speed: float = 1.5

var _can_fire: bool = true

@onready var muzzle_marker: Marker2D = get_node_or_null("Turret/MuzzleMarker")
@onready var weak_point_area: Area2D = get_node_or_null("EngineWeakPoint")


func _ready() -> void:
	max_health = 500
	armor_threshold = 18
	speed = 45.0
	is_tank = true
	super._ready()
	if weak_point_area:
		weak_point_area.area_entered.connect(_on_weak_point_area_entered)


func _vehicle_ai(delta: float) -> void:
	if is_destroyed:
		return

	if target and is_instance_valid(target):
		var to_target := target.global_position - global_position
		var target_angle := to_target.angle()
		var dist := global_position.distance_to(target.global_position)

		# Heavy hull steering toward target
		if dist > 250.0:
			rotation = lerp_angle(rotation, target_angle, 0.85 * delta)
			velocity = Vector2.RIGHT.rotated(rotation) * speed
		else:
			velocity = Vector2.ZERO

		# Independent turret deliberate traverse toward target
		if turret:
			var t_angle := (target.global_position - turret.global_position).angle()
			turret.global_rotation = lerp_angle(turret.global_rotation, t_angle, turret_turn_speed * delta)

		if is_inside_tree() and get_world_2d():
			move_and_slide()

		if _can_fire and dist < 420.0:
			_fire_shell()
	else:
		velocity = Vector2.ZERO
		if turret:
			turret.rotation = lerp_angle(turret.rotation, 0.0, 1.2 * delta)


func take_damage(amount: int) -> void:
	if is_destroyed:
		return
	# Rear weak point: attacker behind tank triggers 3x damage
	if target and is_instance_valid(target):
		var to_attacker := (target.global_position - global_position).normalized()
		var rear := -Vector2.RIGHT.rotated(rotation)
		if rear.dot(to_attacker) > 0.4:
			take_rear_damage(amount)
			return
	super.take_damage(amount)


func _on_weak_point_area_entered(area: Area2D) -> void:
	if is_destroyed:
		return
	if (area.collision_layer & 4) != 0 or area.is_in_group("player_bullets"):
		var dmg: int = 25
		if "damage" in area:
			dmg = area.damage
		take_rear_damage(dmg)


func _fire_shell() -> void:
	if is_destroyed or target == null:
		return
	_can_fire = false

	var fire_rot: float = turret.global_rotation if turret else rotation
	var origin: Vector2 = muzzle_marker.global_position if muzzle_marker else global_position + Vector2.RIGHT.rotated(fire_rot) * 56.0

	var proj_container: Node = null
	if is_inside_tree() and get_tree() and get_tree().root:
		proj_container = get_tree().root.get_node_or_null("Main/Projectiles")
	if proj_container == null:
		proj_container = get_parent()

	if shell_scene and proj_container:
		var shell: Area2D = shell_scene.instantiate()
		proj_container.add_child(shell)
		if shell.has_method("launch"):
			shell.launch(origin, fire_rot, 320.0, shell_damage, shell_radius, shell_damage, false)
	else:
		# Fallback splash at predicted point
		if is_inside_tree() and get_tree():
			ExplosionHelper.explode(get_tree(), target.global_position, shell_radius, shell_damage, 14.0, true)

	# Visuals: Cannon muzzle flash and heavy barrel recoil
	CombatVfxScript.vfx_muzzle_flash(origin, fire_rot, "cannon")
	if turret:
		var t_sprite: Sprite2D = turret.get_node_or_null("Sprite2D")
		if t_sprite and is_inside_tree():
			t_sprite.position.x = -10.0
			var tw := create_tween()
			if tw:
				tw.tween_property(t_sprite, "position:x", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# Combat feedback: Camera shake
	if target and target.has_method("shake_camera"):
		target.shake_camera(6.0)

	get_tree().create_timer(fire_cooldown).timeout.connect(func() -> void:
		_can_fire = true
	)

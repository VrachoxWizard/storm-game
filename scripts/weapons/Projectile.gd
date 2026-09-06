extends Area2D

## A single projectile. Managed by an object pool — never freed, only activated/deactivated.

var speed: float = 0.0
var damage: int = 0
var _active: bool = false
var _weak_point_handled: bool = false

@onready var lifetime_timer: Timer = $LifetimeTimer
@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	z_index = 2
	if lifetime_timer and not lifetime_timer.timeout.is_connected(deactivate):
		lifetime_timer.timeout.connect(deactivate)
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	deactivate()


func _physics_process(delta: float) -> void:
	if not _active:
		return
	var end := global_position + Vector2.RIGHT.rotated(global_rotation) * speed * delta
	var query := PhysicsRayQueryParameters2D.create(global_position, end, collision_mask)
	query.collide_with_areas = true
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit["position"]
		if hit["collider"] is Area2D:
			_on_area_entered(hit["collider"])
		else:
			_on_body_entered(hit["collider"])
	else:
		global_position = end


func activate(pos: Vector2, rot: float, spd: float, dmg: int) -> void:
	global_position = pos
	global_rotation = rot
	speed = spd
	damage = dmg
	_active = true
	_weak_point_handled = false
	visible = true
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)
	if lifetime_timer and lifetime_timer.is_inside_tree():
		lifetime_timer.start()


func deactivate() -> void:
	_active = false
	_weak_point_handled = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	if lifetime_timer and is_instance_valid(lifetime_timer) and lifetime_timer.is_inside_tree():
		lifetime_timer.stop()
	global_position = Vector2(-9999, -9999)


func is_pool_active() -> bool:
	return _active


func _on_body_entered(body: Node2D) -> void:
	if not _active:
		return
	_active = false
	if body.has_method("take_damage"):
		if body is Node and (body as Node).is_in_group("bunker"):
			body.set_meta("last_hit_from", global_position)
		body.take_damage(damage)
		if (collision_layer & 4) != 0 and is_inside_tree():
			var sm = get_node_or_null("/root/ScoreManager")
			if sm and sm.has_method("record_shot_hit"):
				sm.record_shot_hit()
		var vfx: Node = null
		if get_tree() and get_tree().root:
			vfx = get_tree().root.get_node_or_null("Main/CombatVfx")
		if vfx and body.is_in_group("enemies") and vfx.has_method("spawn_blood"):
			vfx.spawn_blood(global_position)
		elif vfx and vfx.has_method("spawn_dust"):
			vfx.spawn_dust(global_position)
		var snd = get_node_or_null("/root/SoundManager")
		if snd and snd.has_method("play_sfx"):
			if body.is_in_group("enemies") or body.is_in_group("player"):
				snd.play_sfx("impact_flesh")
			else:
				snd.play_sfx("impact_metal")
	deactivate()


func _on_area_entered(area: Area2D) -> void:
	if not _active:
		return
	var owner_body := area.get_parent()
	if (collision_layer & 4) != 0 and area.name == "EngineWeakPoint" and owner_body.has_method("_on_weak_point_area_entered"):
		if _weak_point_handled:
			deactivate()
			return
		# Tank handler marks this bullet handled and deactivates it.
		owner_body._on_weak_point_area_entered(self)
		return
	CombatVfx.vfx_ricochet(global_position, Vector2.RIGHT.rotated(global_rotation))
	var snd = get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("impact_metal")
	deactivate()

class_name EnemyBase
extends CharacterBody2D

## Base class for all infantry enemies — modular 3-layer rig and state machine AI.

const CombatVfxScript = preload("res://scripts/effects/CombatVfx.gd")
const DecalManagerScript = preload("res://scripts/effects/DecalManager.gd")

var speed_buff: float = 1.0
var fire_rate_buff: float = 1.0

signal enemy_died(enemy: CharacterBody2D)

enum State { PATROL, ALERT, CHASE, ATTACK, DEAD }

@export var max_health: int = 50
@export var speed: float = 100.0
@export var attack_range: float = 150.0
@export var detection_range: float = 200.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0
@export var torso_texture: Texture2D = null
## Faction identity — defaults to SVK (Srpska vojska Krajine).
@export var faction: FactionResource = null
## Unit key used with FactionResource.unit_names (rifleman, officer, knindze, …).
@export var unit_key: String = "rifleman"

var health: int = max_health
var current_state: State = State.PATROL
var target: CharacterBody2D = null
var _patrol_direction: Vector2 = Vector2.RIGHT
var _patrol_timer: float = 0.0
var _walk_cycle_time: float = 0.0
var _guard_origin: Vector2
var _assault_target: bool = false
var _route_side: float = 1.0
var _faction_badge: Sprite2D = null
const HitFeedback = preload("res://scripts/enemies/EnemyHitFeedback.gd")
const Steering = preload("res://scripts/enemies/EnemySteering.gd")
const DEFAULT_SVK_FACTION: FactionResource = preload("res://resources/factions/svk_faction.tres")

@onready var shadow_sprite: Sprite2D = get_node_or_null("ShadowSprite")
@onready var legs_sprite: Sprite2D = get_node_or_null("LegsSprite")
@onready var torso_container: Node2D = get_node_or_null("TorsoContainer")
@onready var body_sprite: Sprite2D = get_node_or_null("TorsoContainer/BodySprite")
@onready var weapon_sprite: Sprite2D = get_node_or_null("TorsoContainer/WeaponSprite")
@onready var muzzle: Marker2D = get_node_or_null("TorsoContainer/MuzzleMarker")
@onready var brass_marker: Marker2D = get_node_or_null("TorsoContainer/BrassMarker")
@onready var sprite: Sprite2D = body_sprite if body_sprite else get_node_or_null("Sprite2D")

@onready var detection_area: Area2D = $DetectionArea
@onready var attack_timer: Timer = $AttackTimer
@onready var state_timer: Timer = $StateTimer

func _enter_tree() -> void:
	_ensure_rig()

func _ensure_rig() -> void:
	if shadow_sprite == null: shadow_sprite = get_node_or_null("ShadowSprite")
	if legs_sprite == null: legs_sprite = get_node_or_null("LegsSprite")
	if torso_container == null: torso_container = get_node_or_null("TorsoContainer")
	if body_sprite == null: body_sprite = get_node_or_null("TorsoContainer/BodySprite")
	if weapon_sprite == null: weapon_sprite = get_node_or_null("TorsoContainer/WeaponSprite")
	if muzzle == null: muzzle = get_node_or_null("TorsoContainer/MuzzleMarker")
	if brass_marker == null: brass_marker = get_node_or_null("TorsoContainer/BrassMarker")
	if sprite == null: sprite = body_sprite if body_sprite else get_node_or_null("Sprite2D")

func _ready() -> void:
	z_index = 1
	health = max_health
	_guard_origin = global_position
	_route_side = 1.0 if get_instance_id() % 2 == 0 else -1.0
	add_to_group("enemies")
	if faction == null:
		faction = DEFAULT_SVK_FACTION
	if torso_texture != null and body_sprite != null:
		body_sprite.texture = torso_texture
	_apply_faction_visuals()
	detection_area.body_entered.connect(_on_detection_body_entered)
	detection_area.body_exited.connect(_on_detection_body_exited)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.one_shot = true
	state_timer.one_shot = true
	_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)
	# Deferred so subclass _ready() can set detection_range / stats first.
	call_deferred("_apply_difficulty")


## Scales authored combat stats from DifficultyManager, then rebuilds detection radius.
func _apply_difficulty() -> void:
	if not is_inside_tree():
		return
	var dm := get_node_or_null("/root/DifficultyManager")
	if dm == null:
		_apply_detection_range()
		return
	max_health = maxi(1, int(round(float(max_health) * dm.get_multiplier("enemy_hp"))))
	health = max_health
	damage = maxi(1, int(round(float(damage) * dm.get_multiplier("enemy_dmg"))))
	attack_cooldown = maxf(0.1, attack_cooldown * dm.get_multiplier("enemy_cooldown"))
	speed = maxf(10.0, speed * dm.get_multiplier("enemy_speed"))
	detection_range = maxf(40.0, detection_range * dm.get_multiplier("enemy_detect"))
	_apply_detection_range()


## Applies SVK/HV uniform tint and optional armband/insignia badge.
func _apply_faction_visuals() -> void:
	if faction == null:
		return
	if body_sprite:
		body_sprite.modulate = faction.uniform_tint
	_ensure_faction_badge()


func _ensure_faction_badge() -> void:
	if faction == null or torso_container == null:
		return
	if _faction_badge == null:
		_faction_badge = get_node_or_null("TorsoContainer/FactionBadge") as Sprite2D
	if _faction_badge == null:
		_faction_badge = Sprite2D.new()
		_faction_badge.name = "FactionBadge"
		_faction_badge.z_index = 2
		_faction_badge.position = Vector2(6.0, -10.0)
		_faction_badge.scale = Vector2(0.35, 0.35)
		torso_container.add_child(_faction_badge)
	if faction.insignia_texture:
		_faction_badge.texture = faction.insignia_texture
		_faction_badge.visible = true
	elif faction.flag_texture:
		_faction_badge.texture = faction.flag_texture
		_faction_badge.visible = true
	else:
		_faction_badge.visible = false


func get_unit_label() -> String:
	if faction:
		return faction.get_unit_label(unit_key)
	return unit_key

func _apply_detection_range() -> void:
	if detection_area == null:
		return
	var col := detection_area.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col == null:
		return
	var circle := CircleShape2D.new()
	circle.radius = detection_range
	col.shape = circle

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
	if current_state == State.DEAD or not can_process():
		return
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("player") as CharacterBody2D
	health -= amount
	_flash_hit()
	if health <= 0:
		_die()
	elif current_state == State.PATROL:
		_enter_alert()

func _die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	enemy_died.emit(self)
	_ensure_rig()
	if is_inside_tree() and get_tree():
		var sm = get_tree().root.get_node_or_null("ScoreManager")
		if sm and sm.has_method("record_kill"):
			sm.record_kill()

	velocity = Vector2.ZERO
	set_physics_process(false)
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if detection_area:
		detection_area.set_deferred("monitoring", false)

	DecalManagerScript.stamp_blood(global_position)
	if is_inside_tree() and get_tree():
		var vfx := get_tree().root.get_node_or_null("Main/CombatVfx")
		if vfx and vfx.has_method("spawn_blood"):
			vfx.spawn_blood(global_position)

	var rot := torso_container.rotation if torso_container else rotation
	if is_inside_tree() and torso_container:
		var tween := create_tween()
		if tween:
			tween.set_parallel(true)
			tween.tween_property(torso_container, "scale", Vector2(0.5, 0.5), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			if shadow_sprite:
				tween.tween_property(shadow_sprite, "modulate:a", 0.0, 0.2)
			tween.tween_property(self, "modulate:a", 0.3, 0.22)
			tween.chain().tween_callback(func() -> void:
				DecalManagerScript.stamp_casualty(global_position, rot)
				queue_free()
			)
			return

	DecalManagerScript.stamp_casualty(global_position, rot)
	queue_free()

func apply_recoil(recoil_px: float = 4.0) -> void:
	if torso_container == null or not is_inside_tree():
		return
	torso_container.position = Vector2.LEFT.rotated(torso_container.rotation) * recoil_px
	var tween := create_tween()
	if tween:
		tween.tween_property(torso_container, "position", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_rig_aim(aim_pos: Vector2) -> void:
	if torso_container:
		torso_container.look_at(aim_pos)
	else:
		look_at(aim_pos)

func _update_legs(delta: float) -> void:
	if legs_sprite == null:
		return
	if velocity.length() > 5.0:
		legs_sprite.rotation = velocity.angle()
		_walk_cycle_time += delta * 10.0 * (velocity.length() / maxf(speed, 1.0))
		legs_sprite.frame = int(_walk_cycle_time) % 4
	else:
		legs_sprite.frame = 0

func _process_patrol(delta: float) -> void:
	_patrol_timer += delta
	if _patrol_timer > 3.0:
		_patrol_timer = 0.0
		_patrol_direction = Vector2.RIGHT.rotated(randf() * TAU)
	if global_position.distance_to(_guard_origin) > 70.0 or is_on_wall():
		_patrol_direction = (_guard_origin - global_position).normalized()
	velocity = _patrol_direction * speed * speed_buff * 0.3
	_update_rig_aim(global_position + _patrol_direction)
	move_and_slide()
	_update_legs(delta)

func _process_alert(_delta: float) -> void:
	if target and is_instance_valid(target):
		_update_rig_aim(target.global_position)
		velocity = Vector2.ZERO
	else:
		current_state = State.PATROL

func _process_chase(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return
	var dir := Steering.direction(self, target.global_position, _route_side)
	velocity = dir * speed * speed_buff
	_update_rig_aim(target.global_position)
	move_and_slide()
	_update_legs(delta)

	if global_position.distance_to(target.global_position) <= attack_range and has_clear_shot():
		_enter_attack()

func _process_attack(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		current_state = State.PATROL
		return
	_update_rig_aim(target.global_position)
	velocity = Vector2.ZERO
	_update_legs(delta)
	if global_position.distance_to(target.global_position) > attack_range * 1.2:
		_enter_chase()

func _enter_alert() -> void:
	current_state = State.ALERT
	velocity = Vector2.ZERO
	if not state_timer.timeout.is_connected(_on_alert_timeout):
		state_timer.timeout.connect(_on_alert_timeout)
	state_timer.wait_time = randf_range(0.4, 0.8)
	state_timer.start()

func _on_alert_timeout() -> void:
	if current_state == State.ALERT and target and is_instance_valid(target):
		_enter_chase()

func _enter_chase() -> void:
	current_state = State.CHASE

func _enter_attack() -> void:
	current_state = State.ATTACK
	if attack_timer.is_stopped():
		_on_attack_timer_timeout()

func _perform_attack() -> void:
	pass

func _on_attack_timer_timeout() -> void:
	if current_state == State.ATTACK and has_clear_shot():
		_perform_attack()
		attack_timer.start(attack_cooldown / maxf(fire_rate_buff, 0.1))
	elif current_state == State.ATTACK:
		_enter_chase()

func _on_detection_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D and body.is_in_group("player"):
		target = body
		if current_state == State.PATROL:
			_enter_alert()

func _on_detection_body_exited(body: Node2D) -> void:
	if body == target and not _assault_target:
		if current_state != State.DEAD:
			target = null
			current_state = State.PATROL

func _flash_hit() -> void:
	HitFeedback.flash_hit(self)

## Holdout attackers pursue the position instead of wandering outside detection range.
func order_assault(player: CharacterBody2D) -> void:
	target = player
	_assault_target = true
	_enter_alert()

## Ballistic infantry must see the player before firing through a lane.
func has_clear_shot() -> bool:
	if not is_instance_valid(target) or target.get("_is_dead") == true:
		return false
	var query := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 32)
	return get_world_2d().direct_space_state.intersect_ray(query).is_empty()

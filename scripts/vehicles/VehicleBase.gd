class_name VehicleBase
extends CharacterBody2D

## Base class for armored vehicles (APC, Tank). Layer 7 (collision layer 64).
## Supports independent turret rotation, continuous tread imprints,
## wheel dust particles, and persistent charred burning wreck destruction state.

signal destroyed
signal died

const CombatVfxScript = preload("res://scripts/effects/CombatVfx.gd")
const DecalManagerScript = preload("res://scripts/effects/DecalManager.gd")
const TREAD_DISTANCE_STEP: float = 20.0

@export var max_health: int = 300
@export var armor_threshold: int = 12  ## Damage below this is heavily reduced
@export var speed: float = 60.0
@export var detection_range: float = 400.0
@export var wreck_texture: Texture2D = null
## Faction identity — defaults to SVK (Srpska vojska Krajine).
@export var faction: FactionResource = null
## Unit key used with FactionResource.unit_names (apc, tank).
@export var unit_key: String = "apc"

var health: int = 300
var target: CharacterBody2D = null
var is_destroyed: bool = false
var is_tank: bool = false

var _last_tread_pos: Vector2 = Vector2.ZERO
var _faction_mark: Sprite2D = null
const DEFAULT_SVK_FACTION: FactionResource = preload("res://resources/factions/svk_faction.tres")

@onready var sprite: Sprite2D = $Sprite2D
@onready var turret: Node2D = get_node_or_null("Turret")
@onready var detection_area: Area2D = get_node_or_null("DetectionArea")
@onready var attack_timer: Timer = get_node_or_null("AttackTimer")
@onready var dust_particles: GPUParticles2D = get_node_or_null("DustParticles")


func _ensure_nodes() -> void:
	if sprite == null and has_node("Sprite2D"):
		sprite = get_node("Sprite2D") as Sprite2D
	if turret == null and has_node("Turret"):
		turret = get_node("Turret") as Node2D
	if detection_area == null and has_node("DetectionArea"):
		detection_area = get_node("DetectionArea") as Area2D
	if attack_timer == null and has_node("AttackTimer"):
		attack_timer = get_node("AttackTimer") as Timer
	if dust_particles == null and has_node("DustParticles"):
		dust_particles = get_node("DustParticles") as GPUParticles2D


func _ready() -> void:
	_ensure_nodes()
	health = max_health
	_last_tread_pos = global_position
	add_to_group("vehicle")
	collision_layer = 64
	collision_mask = 33  # Player + Environment
	if faction == null:
		faction = DEFAULT_SVK_FACTION
	_apply_faction_mark()
	if detection_area:
		detection_area.body_entered.connect(_on_detect_entered)
		detection_area.body_exited.connect(_on_detect_exited)
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timeout)
		attack_timer.one_shot = true
	# Deferred so Tank/Apc subclass _ready can set max_health first.
	call_deferred("_apply_difficulty")


## Scales vehicle health from DifficultyManager (turret fire stays authored).
func _apply_difficulty() -> void:
	if not is_inside_tree() or is_destroyed:
		return
	var dm := get_node_or_null("/root/DifficultyManager")
	if dm == null:
		return
	max_health = maxi(1, int(round(float(max_health) * dm.get_multiplier("enemy_hp"))))
	health = max_health


func _apply_faction_mark() -> void:
	if faction == null:
		return
	if sprite:
		sprite.modulate = faction.uniform_tint
	if _faction_mark == null:
		_faction_mark = get_node_or_null("FactionMark") as Sprite2D
	if _faction_mark == null:
		_faction_mark = Sprite2D.new()
		_faction_mark.name = "FactionMark"
		_faction_mark.z_index = 3
		_faction_mark.position = Vector2(0.0, -18.0)
		_faction_mark.scale = Vector2(0.45, 0.45)
		add_child(_faction_mark)
	if faction.flag_texture:
		_faction_mark.texture = faction.flag_texture
		_faction_mark.visible = true
	elif faction.insignia_texture:
		_faction_mark.texture = faction.insignia_texture
		_faction_mark.visible = true
	else:
		_faction_mark.visible = false


func get_unit_label() -> String:
	if faction:
		return faction.get_unit_label(unit_key)
	return unit_key


func _physics_process(delta: float) -> void:
	if is_destroyed:
		return
	_ensure_nodes()
	_vehicle_ai(delta)
	_update_treads_and_dust()


func _vehicle_ai(_delta: float) -> void:
	pass


func _update_treads_and_dust() -> void:
	if is_destroyed:
		return
	if global_position.distance_to(_last_tread_pos) >= TREAD_DISTANCE_STEP:
		_last_tread_pos = global_position
		DecalManagerScript.stamp_tread(global_position, rotation, is_tank)
	if dust_particles:
		dust_particles.emitting = velocity.length_squared() > 100.0


func take_damage(amount: int) -> void:
	if is_destroyed or not can_process():
		return
	_ensure_nodes()
	var final_amount: int = amount
	if amount < armor_threshold:
		final_amount = maxi(1, int(float(amount) * 0.2))
	health -= final_amount
	_flash_hit()
	if health <= 0:
		destroy_vehicle()


func take_rear_damage(amount: int) -> void:
	## Weak-point damage (used by Tank).
	take_damage(amount * 3)


func destroy_vehicle() -> void:
	if is_destroyed:
		return
	_ensure_nodes()
	is_destroyed = true
	health = 0
	velocity = Vector2.ZERO
	set_physics_process(false)

	# 1. Disable collision and detection
	var col := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if col:
		col.set_deferred("disabled", true)
	if detection_area:
		detection_area.set_deferred("monitoring", false)
	var weak_point := get_node_or_null("EngineWeakPoint") as Area2D
	if weak_point:
		weak_point.set_deferred("monitoring", false)
		weak_point.set_deferred("monitorable", false)

	# 2. Halt dust emission
	if dust_particles:
		dust_particles.emitting = false

	# 3. Swap hull sprite to blackened wreck texture
	if wreck_texture and sprite:
		sprite.texture = wreck_texture
	elif sprite:
		sprite.modulate = Color(0.24, 0.22, 0.2, 1.0)

	# 4. Dislodge / offset turret
	if turret:
		turret.position += Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 8.0))
		turret.rotation += randf_range(-0.35, 0.35)
		turret.modulate = Color(0.35, 0.32, 0.3, 1.0)

	# 5. Multi-stage explosion & persistent burning wreck fire
	CombatVfxScript.spawn_multi_stage_explosion(global_position, 95.0 if is_tank else 80.0)
	CombatVfxScript.spawn_burning_wreck_fire(global_position)

	# 6. Audio
	if is_inside_tree() and get_tree() and get_tree().root:
		var snd: Node = get_tree().root.get_node_or_null("SoundManager")
		if snd and snd.has_method("play_sfx"):
			snd.play_sfx("explosion")

	# 7. Notify listeners and record statistics
	destroyed.emit()
	died.emit()
	if is_inside_tree() and get_tree() and get_tree().root:
		var score_mgr: Node = get_tree().root.get_node_or_null("ScoreManager")
		if score_mgr and score_mgr.has_method("record_vehicle_destroyed"):
			score_mgr.record_vehicle_destroyed()


func _die() -> void:
	destroy_vehicle()


func _flash_hit() -> void:
	_ensure_nodes()
	if not sprite:
		return
	sprite.modulate = Color.ORANGE
	if is_inside_tree() and get_tree():
		get_tree().create_timer(0.1).timeout.connect(func() -> void:
			if is_instance_valid(sprite) and not is_destroyed:
				sprite.modulate = Color.WHITE
		)


func _on_detect_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body is CharacterBody2D:
		target = body as CharacterBody2D


func _on_detect_exited(body: Node2D) -> void:
	if body == target:
		target = null


func _on_attack_timeout() -> void:
	_perform_attack()


func _perform_attack() -> void:
	pass


func _start_attack_cooldown(wait: float) -> void:
	_ensure_nodes()
	if attack_timer:
		attack_timer.wait_time = wait
		attack_timer.start()

class_name CombatVfx
extends Node2D

## Dynamic combat VFX system — weapon-scaled muzzle flashes with transient 2D lights,
## multi-stage charcoal explosions, bullet ricochets, burning vehicle fires, and hit dust/blood.

const FLASH_M70_TEX: Texture2D = preload("res://assets/sprites/vfx/muzzle_flash_m70.png")
const FLASH_SHOTGUN_TEX: Texture2D = preload("res://assets/sprites/vfx/muzzle_flash_shotgun.png")
const EXPLOSION_CHARCOAL_TEX: Texture2D = preload("res://assets/sprites/vfx/explosion_charcoal.png")

static var instance: CombatVfx = null
static var _radial_light_texture: Texture2D = null


func _init() -> void:
	if instance == null:
		instance = self


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


# ---------------------------------------------------------
# Static Shared Resources & Helpers
# ---------------------------------------------------------

static func get_radial_light_texture() -> Texture2D:
	if _radial_light_texture == null:
		var grad := Gradient.new()
		grad.set_color(0, Color(1, 1, 1, 1))
		grad.set_color(1, Color(1, 1, 1, 0))
		var tex := GradientTexture2D.new()
		tex.gradient = grad
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 128
		tex.height = 128
		_radial_light_texture = tex
	return _radial_light_texture


static func vfx_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle") -> void:
	if instance:
		instance.spawn_muzzle_flash(pos, rot, weapon_type)


static func vfx_explosion(pos: Vector2, radius: float = 80.0) -> void:
	if instance:
		instance.spawn_multi_stage_explosion(pos, radius)


static func vfx_ricochet(pos: Vector2, normal: Vector2) -> void:
	if instance:
		instance.spawn_ricochet(pos, normal)


static func vfx_blood(pos: Vector2) -> void:
	if instance:
		instance.spawn_blood(pos)


static func vfx_dust(pos: Vector2) -> void:
	if instance:
		instance.spawn_dust(pos)


# ---------------------------------------------------------
# Inner Visual Helper Nodes
# ---------------------------------------------------------

class ShockwaveRing extends Node2D:
	var current_radius: float = 6.0
	var max_radius: float = 80.0
	var ring_color: Color = Color(1.0, 0.9, 0.7, 0.85)
	var ring_width: float = 3.0

	func _draw() -> void:
		if ring_color.a > 0.01 and current_radius > 0.0:
			draw_arc(Vector2.ZERO, current_radius, 0.0, TAU, 36, ring_color, ring_width, true)

	func trigger(target_rad: float, duration: float = 0.28) -> void:
		max_radius = target_rad
		if is_inside_tree():
			var tween := create_tween()
			if tween:
				tween.set_parallel(true)
				tween.tween_property(self, "current_radius", max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				var end_col := Color(ring_color.r, ring_color.g, ring_color.b, 0.0)
				tween.tween_property(self, "ring_color", end_col, duration).set_ease(Tween.EASE_IN)
				tween.set_parallel(false)
				tween.tween_callback(queue_free)
				return
		queue_free()

	func _process(_delta: float) -> void:
		queue_redraw()


class FlashCircle extends Node2D:
	var current_radius: float = 4.0
	var max_radius: float = 40.0
	var flash_color: Color = Color(1.0, 0.95, 0.7, 0.9)

	func _draw() -> void:
		if flash_color.a > 0.01 and current_radius > 0.0:
			draw_circle(Vector2.ZERO, current_radius, flash_color)

	func trigger(target_rad: float, duration: float = 0.18) -> void:
		max_radius = target_rad
		if is_inside_tree():
			var tween := create_tween()
			if tween:
				tween.set_parallel(true)
				tween.tween_property(self, "current_radius", max_radius, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				var end_col := Color(1.0, 0.4, 0.1, 0.0)
				tween.tween_property(self, "flash_color", end_col, duration).set_ease(Tween.EASE_IN)
				tween.set_parallel(false)
				tween.tween_callback(queue_free)
				return
		queue_free()

	func _process(_delta: float) -> void:
		queue_redraw()


class BurningFireNode extends Node2D:
	var light: PointLight2D = null
	var _base_energy: float = 1.3
	var _time: float = 0.0

	func _process(delta: float) -> void:
		if light and is_instance_valid(light):
			_time += delta * 12.0
			light.energy = _base_energy + sin(_time) * 0.25 + sin(_time * 2.3) * 0.15


# ---------------------------------------------------------
# Core Gameplay VFX API
# ---------------------------------------------------------

func spawn_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle") -> void:
	var wtype := weapon_type.to_lower()
	var is_shotgun := "shotgun" in wtype
	var flash_scale := Vector2(1.0, 0.8)
	var light_energy := 1.8
	var light_scale := 1.2
	var light_duration := 0.05
	var tex := FLASH_M70_TEX
	var spark_count := 8
	var speed_min := 50.0
	var speed_max := 100.0

	if is_shotgun:
		tex = FLASH_SHOTGUN_TEX
		flash_scale = Vector2(1.2, 1.2)
		light_energy = 2.4
		light_scale = 1.6
		spark_count = 14
		speed_min = 70.0
		speed_max = 140.0
	elif "pistol" in wtype or "tt-33" in wtype:
		flash_scale = Vector2(0.6, 0.4)
		light_energy = 1.3
		light_scale = 0.8
		light_duration = 0.04
		spark_count = 4
		speed_min = 35.0
		speed_max = 70.0
	elif "heavy" in wtype or "rpg" in wtype or "cannon" in wtype:
		flash_scale = Vector2(2.0, 1.6)
		light_energy = 2.8
		light_scale = 2.4
		light_duration = 0.07
		spark_count = 18
		speed_min = 100.0
		speed_max = 200.0

	# 1. Flash Sprite
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.global_position = pos + Vector2.RIGHT.rotated(rot) * (10.0 * flash_scale.x)
	sprite.rotation = rot
	sprite.scale = flash_scale
	sprite.modulate = Color(1.0, 0.95, 0.6, 0.95)
	add_child(sprite)

	if is_inside_tree():
		var sp_tween := create_tween()
		if sp_tween:
			sp_tween.tween_property(sprite, "modulate:a", 0.0, light_duration)
			sp_tween.tween_callback(sprite.queue_free)
	else:
		sprite.queue_free()

	# 2. Dynamic PointLight2D (0.05s)
	_create_transient_light(pos + Vector2.RIGHT.rotated(rot) * (8.0 * flash_scale.x), Color(1.0, 0.82, 0.4), light_energy, light_scale, light_duration)

	# 3. Particle Sparks
	var flash_p := _create_burst(spark_count, light_duration * 2.5, Color(1.0, 0.85, 0.35, 1.0), speed_min, speed_max, 35.0 if is_shotgun else 22.0, Vector3.ZERO, Vector3(1, 0, 0))
	flash_p.global_position = pos
	flash_p.rotation = rot
	add_child(flash_p)
	flash_p.emitting = true
	_auto_free(flash_p, flash_p.lifetime + 0.1)

	# 4. Spent Casing Ejection via DecalManager
	var eject_angle: float = rot + randf_range(1.2, 1.9)
	var eject_dir := Vector2.RIGHT.rotated(eject_angle)
	DecalManager.spawn_casing(pos, eject_dir, is_shotgun)


func spawn_multi_stage_explosion(pos: Vector2, radius: float = 80.0) -> void:
	# Stage 1: Blinding Core Dynamic PointLight2D (0.25s expanding light pulse)
	var light_scale := clampf(radius / 32.0, 1.2, 5.0)
	_create_transient_light(pos, Color(1.0, 0.75, 0.3), 2.5, light_scale, 0.25)

	# Stage 2: Expanding Core Fire Flash Circle
	var flash := FlashCircle.new()
	flash.global_position = pos
	add_child(flash)
	flash.trigger(radius * 0.75, 0.18)

	# Stage 3: Shockwave Ring
	var ring := ShockwaveRing.new()
	ring.global_position = pos
	add_child(ring)
	ring.trigger(radius * 1.35, 0.28)

	# Stage 4: Charcoal Smoke Plume
	var smoke := GPUParticles2D.new()
	smoke.texture = EXPLOSION_CHARCOAL_TEX
	smoke.amount = 16
	smoke.lifetime = 0.9
	smoke.one_shot = true
	smoke.explosiveness = 0.85
	smoke.local_coords = false

	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_mat.emission_sphere_radius = 12.0
	smoke_mat.direction = Vector3(0, -1, 0)
	smoke_mat.spread = 50.0
	smoke_mat.initial_velocity_min = 40.0 * (radius / 80.0)
	smoke_mat.initial_velocity_max = 90.0 * (radius / 80.0)
	smoke_mat.gravity = Vector3(0, -20, 0)
	smoke_mat.damping_min = 20.0
	smoke_mat.damping_max = 30.0
	smoke_mat.scale_min = 0.7 * (radius / 80.0)
	smoke_mat.scale_max = 1.3 * (radius / 80.0)
	smoke_mat.color = Color(0.16, 0.14, 0.12, 0.85)
	smoke.process_material = smoke_mat
	smoke.global_position = pos
	add_child(smoke)
	smoke.emitting = true
	_auto_free(smoke, 1.1)

	# Stage 5: High-velocity Sparks and Debris
	var sparks := _create_burst(18, 0.35, Color(1.0, 0.7, 0.15, 1.0), 140.0, 280.0, 180.0, Vector3(0, 150, 0))
	sparks.global_position = pos
	add_child(sparks)
	sparks.emitting = true
	_auto_free(sparks, 0.45)

	var debris := _create_burst(12, 0.45, Color(0.32, 0.24, 0.16, 1.0), 60.0, 140.0, 180.0, Vector3(0, 180, 0))
	debris.global_position = pos
	add_child(debris)
	debris.emitting = true
	_auto_free(debris, 0.55)

	# Stage 6: Scorch Decal Stamp via DecalManager
	DecalManager.stamp_scorch(pos, clampf(radius / 70.0, 0.8, 2.5))


func spawn_ricochet(pos: Vector2, normal: Vector2) -> void:
	var dir := normal.normalized() if normal != Vector2.ZERO else Vector2.UP

	# Transient Micro-Light
	_create_transient_light(pos, Color(1.0, 0.85, 0.4), 1.2, 0.6, 0.04)

	# Sparks along reflection normal
	var sparks := _create_burst(8, 0.18, Color(1.0, 0.9, 0.4, 1.0), 120.0, 220.0, 35.0, Vector3(0, 80, 0), Vector3(dir.x, dir.y, 0))
	sparks.global_position = pos
	add_child(sparks)
	sparks.emitting = true
	_auto_free(sparks, 0.25)

	# Dust puff
	var dust := _create_burst(6, 0.28, Color(0.6, 0.56, 0.48, 0.7), 15.0, 45.0, 180.0)
	dust.global_position = pos
	add_child(dust)
	dust.emitting = true
	_auto_free(dust, 0.35)


func spawn_burning_wreck_fire(pos: Vector2) -> Node2D:
	var fire_node := BurningFireNode.new()
	fire_node.global_position = pos
	add_child(fire_node)

	# 1. Fire GPUParticles2D
	var fire_p := GPUParticles2D.new()
	fire_p.amount = 16
	fire_p.lifetime = 0.65
	fire_p.one_shot = false
	fire_p.explosiveness = 0.0
	fire_p.local_coords = false

	var fire_mat := ParticleProcessMaterial.new()
	fire_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	fire_mat.emission_sphere_radius = 10.0
	fire_mat.direction = Vector3(0, -1, 0)
	fire_mat.spread = 25.0
	fire_mat.initial_velocity_min = 35.0
	fire_mat.initial_velocity_max = 75.0
	fire_mat.gravity = Vector3(0, -25, 0)
	fire_mat.color = Color(1.0, 0.52, 0.12, 0.9)
	fire_mat.scale_min = 1.2
	fire_mat.scale_max = 2.6
	fire_p.process_material = fire_mat
	fire_node.add_child(fire_p)
	fire_p.emitting = true

	# 2. Charcoal Smoke GPUParticles2D
	var smoke_p := GPUParticles2D.new()
	smoke_p.texture = EXPLOSION_CHARCOAL_TEX
	smoke_p.amount = 10
	smoke_p.lifetime = 1.2
	smoke_p.one_shot = false
	smoke_p.explosiveness = 0.0
	smoke_p.local_coords = false

	var smoke_mat := ParticleProcessMaterial.new()
	smoke_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	smoke_mat.emission_sphere_radius = 12.0
	smoke_mat.direction = Vector3(0, -1, 0)
	smoke_mat.spread = 35.0
	smoke_mat.initial_velocity_min = 20.0
	smoke_mat.initial_velocity_max = 50.0
	smoke_mat.gravity = Vector3(0, -30, 0)
	smoke_mat.color = Color(0.16, 0.14, 0.12, 0.75)
	smoke_mat.scale_min = 0.7
	smoke_mat.scale_max = 1.4
	smoke_p.process_material = smoke_mat
	fire_node.add_child(smoke_p)
	smoke_p.emitting = true

	# 3. Dynamic Flickering PointLight2D
	var light := PointLight2D.new()
	light.texture = get_radial_light_texture()
	light.color = Color(1.0, 0.65, 0.25)
	light.energy = 1.3
	light.texture_scale = 1.8
	fire_node.add_child(light)
	fire_node.light = light

	return fire_node


func spawn_blood(pos: Vector2) -> void:
	var p := _create_burst(10, 0.35, Color(0.55, 0.05, 0.05, 1.0), 20.0, 70.0, 180.0, Vector3(0, 40, 0))
	p.global_position = pos
	add_child(p)
	p.emitting = true
	_auto_free(p, 0.5)

	DecalManager.stamp_blood(pos)


func spawn_dust(pos: Vector2) -> void:
	var p := _create_burst(6, 0.3, Color(0.55, 0.5, 0.4, 0.8), 10.0, 40.0, 180.0)
	p.global_position = pos
	add_child(p)
	p.emitting = true
	_auto_free(p, 0.45)


# ---------------------------------------------------------
# Internal Helper Functions
# ---------------------------------------------------------

func _create_burst(amount: int, lifetime: float, color: Color, vel_min: float, vel_max: float, spread: float = 180.0, grav: Vector3 = Vector3.ZERO, dir: Vector3 = Vector3(1, 0, 0)) -> GPUParticles2D:
	var p := GPUParticles2D.new()
	p.amount = amount
	p.lifetime = lifetime
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = dir
	mat.spread = spread
	mat.initial_velocity_min = vel_min
	mat.initial_velocity_max = vel_max
	mat.gravity = grav
	mat.color = color
	p.process_material = mat
	return p


func _create_transient_light(pos: Vector2, color: Color, energy: float, scale_factor: float, duration: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = get_radial_light_texture()
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor
	light.global_position = pos
	add_child(light)
	if is_inside_tree():
		var tween := create_tween()
		if tween:
			tween.tween_property(light, "energy", 0.0, duration)
			tween.tween_callback(light.queue_free)
			return light
	light.queue_free()
	return null


func _auto_free(node: Node, delay: float) -> void:
	if is_inside_tree() and get_tree():
		get_tree().create_timer(delay).timeout.connect(node.queue_free)
	else:
		node.queue_free()

class_name CombatVfx
extends Node2D

## Dynamic combat VFX system — weapon-scaled muzzle flashes with transient 2D lights,
## multi-stage charcoal explosions, bullet ricochets, burning vehicle fires, and hit dust/blood.

const FLASH_M70_TEX: Texture2D = preload("res://assets/sprites/vfx/muzzle_flash_m70.png")
const FLASH_SHOTGUN_TEX: Texture2D = preload("res://assets/sprites/vfx/muzzle_flash_shotgun.png")
const EXPLOSION_CHARCOAL_TEX: Texture2D = preload("res://assets/sprites/vfx/explosion_charcoal.png")
const VfxComp = preload("res://scripts/effects/VfxComponents.gd")

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

## Returns the lazily initialized radial gradient texture for 2D dynamic lights.
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


## Static helper to spawn a muzzle flash via the active CombatVfx instance.
static func vfx_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle") -> void:
	if instance:
		instance.spawn_muzzle_flash(pos, rot, weapon_type)


## Static helper to spawn a multi-stage explosion via the active CombatVfx instance.
static func vfx_explosion(pos: Vector2, radius: float = 80.0) -> void:
	spawn_multi_stage_explosion(pos, radius)


## Spawns a multi-stage explosion statically or via instance.
static func spawn_multi_stage_explosion(pos: Vector2, radius: float = 80.0) -> void:
	if instance:
		instance._do_spawn_multi_stage_explosion(pos, radius)


## Spawns a persistent burning wreck fire statically or via instance.
static func spawn_burning_wreck_fire(pos: Vector2) -> Node2D:
	if instance:
		return instance._do_spawn_burning_wreck_fire(pos)
	return null


## Static helper to spawn a burning fire loop via the active CombatVfx instance.
static func vfx_burning_wreck_fire(pos: Vector2) -> Node2D:
	return spawn_burning_wreck_fire(pos)


## Static helper to spawn a ricochet effect via the active CombatVfx instance.
static func vfx_ricochet(pos: Vector2, normal: Vector2) -> void:
	if instance:
		instance.spawn_ricochet(pos, normal)


## Static helper to spawn blood particles and decals via the active CombatVfx instance.
static func vfx_blood(pos: Vector2) -> void:
	if instance:
		instance.spawn_blood(pos)


## Static helper to spawn hit dust puffs via the active CombatVfx instance.
static func vfx_dust(pos: Vector2) -> void:
	if instance:
		instance.spawn_dust(pos)


# ---------------------------------------------------------
# Core Gameplay VFX API
# ---------------------------------------------------------

## Spawns a weapon-scaled muzzle flash with dynamic PointLight2D and casing ejection.
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
	elif "heavy" in wtype or "rpg" in wtype or "cannon" in wtype or "rocket" in wtype:
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
	sprite.rotation = rot
	sprite.scale = flash_scale
	sprite.modulate = Color(1.0, 0.95, 0.6, 0.95)
	add_child(sprite)
	sprite.global_position = pos + Vector2.RIGHT.rotated(rot) * (10.0 * flash_scale.x)

	if is_inside_tree():
		var sp_tween := create_tween()
		if sp_tween:
			sp_tween.tween_property(sprite, "modulate:a", 0.0, light_duration)
			sp_tween.tween_callback(sprite.queue_free)
	else:
		sprite.queue_free()

	# 2. Dynamic PointLight2D (0.05s)
	VfxComp.create_transient_light(self, pos + Vector2.RIGHT.rotated(rot) * (8.0 * flash_scale.x), get_radial_light_texture(), Color(1.0, 0.82, 0.4), light_energy, light_scale, light_duration)

	# 3. Particle Sparks
	var flash_p := VfxComp.create_burst(spark_count, light_duration * 2.5, Color(1.0, 0.85, 0.35, 1.0), speed_min, speed_max, 35.0 if is_shotgun else 22.0, Vector3.ZERO, Vector3(1, 0, 0))
	flash_p.rotation = rot
	add_child(flash_p)
	flash_p.global_position = pos
	flash_p.emitting = true
	VfxComp.auto_free(flash_p, flash_p.lifetime + 0.1)

	# 4. Spent Casing Ejection via DecalManager (omitted for rockets / heavy artillery)
	var is_heavy_explosive := "rocket" in wtype or "rpg" in wtype or "cannon" in wtype
	if not is_heavy_explosive:
		var eject_angle: float = rot + randf_range(1.2, 1.9)
		var eject_dir := Vector2.RIGHT.rotated(eject_angle)
		DecalManager.spawn_casing(pos, eject_dir, is_shotgun)


## Spawns a multi-stage explosion with blinding light, core flash, shockwave ring, charcoal smoke plume, debris, and scorch decal.
func _do_spawn_multi_stage_explosion(pos: Vector2, radius: float = 80.0) -> void:
	# Stage 1: Blinding Core Dynamic PointLight2D (0.25s expanding light pulse)
	var light_scale := clampf(radius / 32.0, 1.2, 5.0)
	VfxComp.create_transient_light(self, pos, get_radial_light_texture(), Color(1.0, 0.75, 0.3), 2.5, light_scale, 0.25)
	if is_inside_tree():
		get_tree().call_group("paper_overlay", "trigger_combat_shock", clampf(radius / 100.0 * 0.03, 0.015, 0.045))

	# Stage 2: Expanding Core Fire Flash Circle
	var flash := VfxComp.FlashCircle.new()
	add_child(flash)
	flash.global_position = pos
	flash.trigger(radius * 0.75, 0.18)

	# Stage 3: Shockwave Ring
	var ring := VfxComp.ShockwaveRing.new()
	add_child(ring)
	ring.global_position = pos
	ring.trigger(radius * 1.35, 0.28)

	# Stage 4: Charcoal Smoke Plume
	var smoke := VfxComp.spawn_smoke_plume(self, pos, EXPLOSION_CHARCOAL_TEX, radius)
	VfxComp.auto_free(smoke, 1.1)

	# Stage 5: High-velocity Sparks and Debris
	var sparks := VfxComp.create_burst(18, 0.35, Color(1.0, 0.7, 0.15, 1.0), 140.0, 280.0, 180.0, Vector3(0, 150, 0))
	add_child(sparks)
	sparks.global_position = pos
	sparks.emitting = true
	VfxComp.auto_free(sparks, 0.45)

	var debris := VfxComp.create_burst(12, 0.45, Color(0.32, 0.24, 0.16, 1.0), 60.0, 140.0, 180.0, Vector3(0, 180, 0))
	add_child(debris)
	debris.global_position = pos
	debris.emitting = true
	VfxComp.auto_free(debris, 0.55)

	# Stage 6: Scorch Decal Stamp via DecalManager
	DecalManager.stamp_scorch(pos, clampf(radius / 70.0, 0.8, 2.5))


## Spawns bullet ricochet sparks and dust puff along surface reflection normal.
func spawn_ricochet(pos: Vector2, normal: Vector2) -> void:
	var dir := normal.normalized() if normal != Vector2.ZERO else Vector2.UP

	# Transient Micro-Light
	VfxComp.create_transient_light(self, pos, get_radial_light_texture(), Color(1.0, 0.85, 0.4), 1.2, 0.6, 0.04)

	# Sparks along reflection normal
	var sparks := VfxComp.create_burst(8, 0.18, Color(1.0, 0.9, 0.4, 1.0), 120.0, 220.0, 35.0, Vector3(0, 80, 0), Vector3(dir.x, dir.y, 0))
	add_child(sparks)
	sparks.global_position = pos
	sparks.emitting = true
	VfxComp.auto_free(sparks, 0.25)

	# Dust puff
	var dust := VfxComp.create_burst(6, 0.28, Color(0.6, 0.56, 0.48, 0.7), 15.0, 45.0, 180.0)
	add_child(dust)
	dust.global_position = pos
	dust.emitting = true
	VfxComp.auto_free(dust, 0.35)


## Spawns a persistent burning wreck fire node with looping flame particles, charcoal smoke, and flickering light.
func _do_spawn_burning_wreck_fire(pos: Vector2) -> Node2D:
	return VfxComp.build_burning_fire(self, pos, EXPLOSION_CHARCOAL_TEX, get_radial_light_texture())


## Spawns blood spray particles and stamps an ink-wash blood decal via DecalManager.
func spawn_blood(pos: Vector2) -> void:
	var p := VfxComp.create_burst(10, 0.35, Color(0.55, 0.05, 0.05, 1.0), 20.0, 70.0, 180.0, Vector3(0, 40, 0))
	add_child(p)
	p.global_position = pos
	p.emitting = true
	VfxComp.auto_free(p, 0.5)

	DecalManager.stamp_blood(pos)


## Spawns a dust burst puff at the given position.
func spawn_dust(pos: Vector2) -> void:
	var p := VfxComp.create_burst(6, 0.3, Color(0.55, 0.5, 0.4, 0.8), 10.0, 40.0, 180.0)
	add_child(p)
	p.global_position = pos
	p.emitting = true
	VfxComp.auto_free(p, 0.45)
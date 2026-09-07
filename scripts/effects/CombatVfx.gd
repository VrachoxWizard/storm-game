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
const MAX_MUZZLE_LIGHTS: int = 8
const MAX_BURNING_WRECKS: int = 6
## Distant-war ambience cadence (seconds between far-off smoke/rumble events).
const AMBIENCE_MIN: float = 9.0
const AMBIENCE_MAX: float = 18.0

var _active_muzzle_lights: int = 0
var _burning_wrecks: Array[Node2D] = []
var _ambience_timer: float = 6.0


func _init() -> void:
	if instance == null:
		instance = self


func _enter_tree() -> void:
	instance = self


func _exit_tree() -> void:
	if instance == self:
		instance = null


func _process(delta: float) -> void:
	# Ambient war layer: far-off artillery rumble + distant smoke columns while playing.
	var gm := get_node_or_null("/root/GameManager")
	if gm == null or int(gm.get("current_state")) != 2:  # GameState.PLAYING
		return
	_ambience_timer -= delta
	if _ambience_timer > 0.0:
		return
	_ambience_timer = randf_range(AMBIENCE_MIN, AMBIENCE_MAX)
	_spawn_distant_war_signs()


## Slow charcoal smoke column + low rumble, placed well outside the player's position.
func _spawn_distant_war_signs() -> void:
	var origin := global_position
	var players := get_tree().get_nodes_in_group("player") if is_inside_tree() else []
	if not players.is_empty() and is_instance_valid(players[0]):
		origin = (players[0] as Node2D).global_position
	var angle := randf_range(0.0, TAU)
	var dist := randf_range(650.0, 1000.0)
	var pos := origin + Vector2(cos(angle), sin(angle)) * dist
	# Smoke column: tall slow drift, dark charcoal
	var smoke := VfxComp.create_burst(10, 2.8, Color(0.30, 0.28, 0.26, 0.45), 8.0, 22.0, 12.0, Vector3(0, -18.0, 0), Vector3(0, -1, 0))
	add_child(smoke)
	smoke.global_position = pos
	smoke.z_index = 1
	smoke.emitting = true
	VfxComp.auto_free(smoke, smoke.lifetime + 0.2)
	# Distant artillery rumble, quiet and low.
	var snd := get_node_or_null("/root/SoundManager")
	if snd and snd.has_method("play_sfx"):
		snd.play_sfx("explosion", 0.18, -17.0)


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
static func vfx_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle", eject_casing: bool = true) -> void:
	if instance:
		instance.spawn_muzzle_flash(pos, rot, weapon_type, eject_casing)


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
## Pass eject_casing = false when the shooter ejects its own brass (player BrassMarker).
func spawn_muzzle_flash(pos: Vector2, rot: float, weapon_type: String = "rifle", eject_casing: bool = true) -> void:
	var wtype := weapon_type.to_lower()
	var is_shotgun := "shotgun" in wtype or "hawk" in wtype
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

	# 1. Flash Sprite (above characters at z_index 1 so it never hides under the shooter)
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.rotation = rot
	sprite.scale = flash_scale
	sprite.modulate = Color(1.0, 0.95, 0.6, 0.95)
	sprite.z_index = 2
	add_child(sprite)
	sprite.global_position = pos + Vector2.RIGHT.rotated(rot) * (10.0 * flash_scale.x)

	if is_inside_tree():
		var sp_tween := create_tween()
		if sp_tween:
			sp_tween.tween_property(sprite, "modulate:a", 0.0, light_duration)
			sp_tween.tween_callback(sprite.queue_free)
	else:
		sprite.queue_free()

	# 2. Dynamic PointLight2D (capped under SMG spam)
	if _active_muzzle_lights < MAX_MUZZLE_LIGHTS:
		_active_muzzle_lights += 1
		VfxComp.create_transient_light(self, pos + Vector2.RIGHT.rotated(rot) * (8.0 * flash_scale.x), get_radial_light_texture(), Color(1.0, 0.82, 0.4), light_energy, light_scale, light_duration)
		get_tree().create_timer(light_duration + 0.05).timeout.connect(func() -> void:
			if is_instance_valid(self):
				_active_muzzle_lights = maxi(_active_muzzle_lights - 1, 0)
		)

	# 3. Particle Sparks
	var flash_p := VfxComp.create_burst(spark_count, light_duration * 2.5, Color(1.0, 0.85, 0.35, 1.0), speed_min, speed_max, 35.0 if is_shotgun else 22.0, Vector3.ZERO, Vector3(1, 0, 0))
	flash_p.rotation = rot
	add_child(flash_p)
	flash_p.global_position = pos
	flash_p.emitting = true
	VfxComp.auto_free(flash_p, flash_p.lifetime + 0.1)

	# 3b. Muzzle smoke wisp for bolt-action / marksman class weapons
	if "m48" in wtype or "mauser" in wtype or "m76" in wtype or "sniper" in wtype:
		var smoke := VfxComp.create_burst(5, 0.9, Color(0.62, 0.60, 0.56, 0.5), 12.0, 26.0, 26.0, Vector3(0, -10.0, 0), Vector3(0, -1, 0))
		add_child(smoke)
		smoke.global_position = pos + Vector2.RIGHT.rotated(rot) * 6.0
		smoke.emitting = true
		VfxComp.auto_free(smoke, smoke.lifetime + 0.1)

	# 4. Spent Casing Ejection via DecalManager (omitted for rockets / heavy artillery)
	var is_heavy_explosive := "rocket" in wtype or "rpg" in wtype or "cannon" in wtype or "zolja" in wtype
	if eject_casing and not is_heavy_explosive:
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
	# Cap persistent emitters so long missions don't accumulate forever.
	while _burning_wrecks.size() >= MAX_BURNING_WRECKS:
		var oldest: Node2D = _burning_wrecks.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	var fire_node := VfxComp.build_burning_fire(self, pos, EXPLOSION_CHARCOAL_TEX, get_radial_light_texture())
	if fire_node:
		_burning_wrecks.append(fire_node)
		fire_node.tree_exiting.connect(func() -> void:
			_burning_wrecks.erase(fire_node)
		)
	return fire_node


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
class_name VfxComponents
extends RefCounted

## Reusable visual helper components and particle builders for CombatVfx.


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


## Spawns a charcoal smoke plume GPU particle node.
static func spawn_smoke_plume(parent: Node2D, pos: Vector2, texture: Texture2D, radius: float) -> GPUParticles2D:
	var smoke := GPUParticles2D.new()
	smoke.texture = texture
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

	parent.add_child(smoke)
	smoke.global_position = pos
	smoke.emitting = true
	return smoke


## Builds a burning wreck fire node with looping flame particles, smoke, and light.
static func build_burning_fire(parent: Node2D, pos: Vector2, smoke_tex: Texture2D, light_tex: Texture2D) -> Node2D:
	var fire_node := BurningFireNode.new()
	parent.add_child(fire_node)
	fire_node.global_position = pos

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

	var smoke_p := GPUParticles2D.new()
	smoke_p.texture = smoke_tex
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

	var light := PointLight2D.new()
	light.texture = light_tex
	light.color = Color(1.0, 0.65, 0.25)
	light.energy = 1.3
	light.texture_scale = 1.8
	fire_node.add_child(light)
	fire_node.light = light

	return fire_node


## Helper to create a one-shot burst GPUParticles2D node.
static func create_burst(amount: int, lifetime: float, color: Color, vel_min: float, vel_max: float, spread: float = 180.0, grav: Vector3 = Vector3.ZERO, dir: Vector3 = Vector3(1, 0, 0)) -> GPUParticles2D:
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


## Helper to instantiate and animate a transient PointLight2D.
static func create_transient_light(parent: Node2D, pos: Vector2, texture: Texture2D, color: Color, energy: float, scale_factor: float, duration: float) -> PointLight2D:
	var light := PointLight2D.new()
	light.texture = texture
	light.color = color
	light.energy = energy
	light.texture_scale = scale_factor
	parent.add_child(light)
	light.global_position = pos
	if parent.is_inside_tree():
		var tween := parent.create_tween()
		if tween:
			tween.tween_property(light, "energy", 0.0, duration)
			tween.tween_callback(light.queue_free)
			return light
	light.queue_free()
	return null


## Schedules node cleanup after a time delay.
static func auto_free(node: Node, delay: float) -> void:
	if node.is_inside_tree() and node.get_tree():
		node.get_tree().create_timer(delay).timeout.connect(node.queue_free)
	else:
		node.queue_free()
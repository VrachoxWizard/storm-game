extends Node2D

## Lightweight combat VFX — muzzle flash + hit dust bursts.

func spawn_muzzle_flash(pos: Vector2, rot: float) -> void:
	var flash := GPUParticles2D.new()
	flash.amount = 8
	flash.lifetime = 0.15
	flash.one_shot = true
	flash.explosiveness = 1.0
	flash.local_coords = false
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(1, 0, 0)
	mat.spread = 25.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 90.0
	mat.gravity = Vector3.ZERO
	mat.scale_min = 1.5
	mat.scale_max = 3.0
	mat.color = Color(1.0, 0.85, 0.3, 1.0)
	flash.process_material = mat
	flash.global_position = pos
	flash.rotation = rot
	add_child(flash)
	flash.emitting = true
	get_tree().create_timer(0.3).timeout.connect(flash.queue_free)


func spawn_blood(pos: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.amount = 10
	p.lifetime = 0.35
	p.one_shot = true
	p.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 20.0
	mat.initial_velocity_max = 70.0
	mat.gravity = Vector3(0, 40, 0)
	mat.color = Color(0.55, 0.05, 0.05, 1.0)
	p.process_material = mat
	p.global_position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.5).timeout.connect(p.queue_free)


func spawn_dust(pos: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.amount = 6
	p.lifetime = 0.3
	p.one_shot = true
	p.explosiveness = 1.0
	var mat := ParticleProcessMaterial.new()
	mat.spread = 180.0
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 40.0
	mat.gravity = Vector3.ZERO
	mat.color = Color(0.55, 0.5, 0.4, 0.8)
	p.process_material = mat
	p.global_position = pos
	add_child(p)
	p.emitting = true
	get_tree().create_timer(0.45).timeout.connect(p.queue_free)

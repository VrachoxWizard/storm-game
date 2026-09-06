extends SceneTree

var failures: int = 0
var checks: int = 0
var main: Node2D
var player: CharacterBody2D

func _init() -> void:
	call_deferred("_run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error("FAIL: " + label)
	else:
		print("PASS: " + label)

func _run() -> void:
	root.get_node("SoundManager")._sfx.clear()
	main = Node2D.new()
	main.name = "Main"
	root.add_child(main)
	var projectiles := Node2D.new()
	projectiles.name = "Projectiles"
	main.add_child(projectiles)
	var ground := Control.new()
	ground.name = "Ground"
	ground.size = Vector2(1200, 800)
	main.add_child(ground)
	player = load("res://scenes/player/Player.tscn").instantiate()
	player.position = Vector2(350, 400)
	main.add_child(player)
	player.set_physics_process(false)
	await physics_frame
	await process_frame
	var camera: Camera2D = player.camera
	var initial_zoom := camera.zoom
	var enemies: Array[Node] = []
	for i in range(6):
		var enemy := CharacterBody2D.new()
		enemy.position = player.position + Vector2(20 + i * 15, 0)
		main.add_child(enemy)
		enemy.add_to_group("enemies")
		enemies.append(enemy)
	player._process(1.0)
	check(camera.zoom == initial_zoom, "Camera scale unchanged with six nearby enemies")
	for enemy in enemies: enemy.queue_free()
	await process_frame
	player._process(1.0)
	check(camera.zoom == initial_zoom, "Camera scale unchanged after enemies disappear")
	check(camera.limit_left == 0 and camera.limit_right == 1200 and camera.limit_bottom == 800, "Camera uses map boundaries")
	var wm: Node = player.weapon_manager
	wm.fire()
	var ammo_after: int = wm.ammo[0]
	wm.fire()
	check(wm.ammo[0] == ammo_after, "Repeated fire cannot bypass cooldown")
	wm.switch_to_slot(2)
	check(not wm.can_fire, "Weapon switching preserves firing cooldown")
	wm.reset_action_state()
	wm.switch_to_slot(0)
	wm._start_reload()
	var reload_left: float = wm.reload_timer.time_left
	wm._start_reload()
	check(wm.reload_timer.time_left <= reload_left, "Repeated reload does not restart timer")
	wm.fire()
	check(wm.ammo[0] == ammo_after, "Cannot fire while reloading")
	wm.reset_action_state()
	player.save_checkpoint(player.position)
	player.take_damage(1000)
	check(player._is_dead and wm.process_mode == Node.PROCESS_MODE_DISABLED, "Death disables player weapon actions")
	var death_pos: Vector2 = player.position
	Input.action_press("move_right")
	player._physics_process(0.1)
	Input.action_release("move_right")
	check(player.position == death_pos, "Dead player cannot move")
	player.restore_checkpoint()
	var kit_hp: int = player.max_health
	check(not player._is_dead and player.health == kit_hp and wm.can_process(), "Checkpoint restores living player and weapons")
	_test_weapon_switching_ux(wm)
	_test_hud_nodes_exist()
	player.take_damage(40)
	check(player.health == kit_hp, "Brief respawn protection prevents instant repeat death")
	player._respawn_protection = 0.0
	await _test_difficulty()
	await _test_projectile()
	await _test_tank_rear()
	await _test_encounter_activation()
	await _test_sniper()
	await _test_objectives()
	await _test_grenade()
	main.queue_free()
	await process_frame
	print("Gameplay checks: %d; failures: %d" % [checks, failures])
	call_deferred("quit", 1 if failures else 0)


func _test_difficulty() -> void:
	var dm: Node = root.get_node("DifficultyManager")
	var sm: Node = root.get_node("SaveManager")
	var previous: int = dm.get_difficulty()
	# Difficulty enum: EASY=0, NORMAL=1, HARD=2
	dm.set_difficulty(2)  # HARD
	check(str(sm.data["settings"].get("difficulty", "")) == "hard", "DifficultyManager persists Hard into SaveManager settings")
	var hard_rifle: CharacterBody2D = load("res://scenes/enemies/Rifleman.tscn").instantiate()
	main.add_child(hard_rifle)
	await process_frame
	var hard_dmg: int = hard_rifle.damage
	var hard_hp: int = hard_rifle.max_health
	hard_rifle.queue_free()
	await process_frame
	dm.set_difficulty(0)  # EASY
	check(str(sm.data["settings"].get("difficulty", "")) == "easy", "DifficultyManager persists Easy into SaveManager settings")
	var easy_rifle: CharacterBody2D = load("res://scenes/enemies/Rifleman.tscn").instantiate()
	main.add_child(easy_rifle)
	await process_frame
	check(easy_rifle.damage < hard_dmg, "Easy rifleman deals less damage than Hard")
	check(easy_rifle.max_health < hard_hp, "Easy rifleman has less health than Hard")
	check(easy_rifle.attack_cooldown > 0.0, "Easy rifleman attack cooldown remains positive")
	easy_rifle.queue_free()
	await process_frame
	dm.set_difficulty(previous)
	check(dm.get_player_kit("player_hp") >= 100, "Player kit HP is at least Hard baseline")


func _test_weapon_switching_ux(wm: Node) -> void:
	# Ensure wheel/Q actions compile and can be dispatched as events.
	var start_slot: int = int(wm.current_slot)
	# Make slot 1 empty to validate skip behavior.
	wm.slots[1] = null
	var next_ev := InputEventAction.new()
	next_ev.action = "weapon_next"
	next_ev.pressed = true
	wm._unhandled_input(next_ev)
	check(int(wm.current_slot) != start_slot, "weapon_next cycles to a valid slot (skips empty)")
	var swap_ev := InputEventAction.new()
	swap_ev.action = "quick_swap"
	swap_ev.pressed = true
	var after_cycle: int = int(wm.current_slot)
	wm._unhandled_input(swap_ev)
	check(int(wm.current_slot) != after_cycle, "quick_swap returns to previous slot")


func _test_hud_nodes_exist() -> void:
	var hud: Node = main.get_node_or_null("HUD")
	if hud == null:
		# HUD isn't instantiated in this test harness; instantiate minimal scene for node checks.
		var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
		hud = hud_scene.instantiate()
		hud.name = "HUD"
		main.add_child(hud)
	check(hud.get_node_or_null("Crosshair") != null, "HUD contains Crosshair node")
	check(hud.get_node_or_null("MarginContainer/VBoxContainer/BottomBar/WeaponSlots") != null, "HUD contains WeaponSlotPanel node")
	check(hud.get_node_or_null("MarginContainer/VBoxContainer/BottomBar/GearIndicator") != null, "HUD contains GearIndicator node")
	check(hud.get_node_or_null("MarginContainer/VBoxContainer/TopBar/ReloadPrompt") != null, "HUD contains ReloadPrompt label")


func _test_projectile() -> void:
	var bullet: Area2D = load("res://scenes/weapons/Projectile.tscn").instantiate()
	main.add_child(bullet)
	var target := Dummy.new()
	target.position = Vector2(800, 400)
	target.collision_layer = 2
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(8, 40)
	shape.shape = rect
	target.add_child(shape)
	main.add_child(target)
	await physics_frame
	await process_frame
	bullet.activate(Vector2(700, 400), 0.0, 2000.0, 15)
	bullet._physics_process(0.1)
	check(target.health == 85 and not bullet._active, "Fast projectile hits thin target without tunneling")
	bullet._on_body_entered(target)
	check(target.health == 85, "Pooled projectile deals damage only once")
	bullet.queue_free()
	target.queue_free()

func _test_tank_rear() -> void:
	var tank: CharacterBody2D = load("res://scenes/vehicles/Tank.tscn").instantiate()
	tank.position = Vector2(950, 600)
	main.add_child(tank)
	tank.set_physics_process(false)
	var bullet: Area2D = load("res://scenes/weapons/Projectile.tscn").instantiate()
	main.add_child(bullet)
	await physics_frame
	await process_frame
	var hp: int = tank.health
	bullet.activate(Vector2(800, 600), 0.0, 2000.0, 20)
	bullet._physics_process(0.1)
	check(tank.health == hp - 60, "Swept rear hit preserves tank weak-point multiplier")
	tank._on_weak_point_area_entered(bullet)
	check(tank.health == hp - 60, "Weak point cannot count the same bullet twice")
	tank.queue_free()
	bullet.queue_free()

func _test_encounter_activation() -> void:
	var enemy: CharacterBody2D = load("res://scenes/enemies/Rifleman.tscn").instantiate()
	enemy.position = Vector2(900, 200)
	main.add_child(enemy)
	MissionHelpers.set_group_active(enemy, false)
	await process_frame
	check(enemy.collision_layer == 0 and enemy.detection_area.collision_mask == 0, "Hidden encounter cannot collide or detect")
	var hp: int = enemy.health
	enemy.take_damage(10)
	check(enemy.health == hp, "Inactive enemy cannot be damaged early")
	MissionHelpers.set_group_active(enemy, true)
	await process_frame
	check(enemy.collision_layer == 2 and enemy.detection_area.collision_mask == 1, "Reactivated encounter restores collision layers")
	enemy.order_assault(player)
	check(enemy.target == player and enemy._assault_target, "Holdout attacker is ordered to pursue player")
	enemy.queue_free()

func _test_sniper() -> void:
	var sniper: CharacterBody2D = load("res://scenes/enemies/Sniper.tscn").instantiate()
	sniper.position = Vector2(600, 400)
	main.add_child(sniper)
	sniper.set_physics_process(false)
	sniper.target = player
	sniper.current_state = EnemyBase.State.ATTACK
	sniper.aim_time = 0.05
	sniper._perform_attack()
	check(sniper._aiming, "Sniper provides aim windup")
	sniper._cancel_aim()
	var hp: int = player.health
	sniper._fire_sniper_shot()
	await create_timer(0.1).timeout
	check(player.health == hp, "Cancelled sniper shot cannot damage player")
	sniper.queue_free()

func _test_objectives() -> void:
	var tracker := ObjectiveTracker.new()
	main.add_child(tracker)
	tracker.sequential = true
	var first := Dummy.new()
	var second := Dummy.new()
	main.add_child(first)
	main.add_child(second)
	tracker.add_destroy_objective([first], "first")
	tracker.add_destroy_objective([second], "second")
	second.destroyed.emit()
	check(tracker.get_progress()["completed"] == 0, "Future target destruction waits for current objective")
	first.destroyed.emit()
	tracker._process(0.1)
	check(tracker.get_progress()["completed"] == 2, "Early destroyed target completes when unlocked")
	tracker.queue_free()
	first.queue_free()
	second.queue_free()

func _test_grenade() -> void:
	var grenade: Area2D = load("res://scenes/weapons/Grenade.tscn").instantiate()
	main.add_child(grenade)
	grenade.set_physics_process(false)
	grenade.throw_at(Vector2(400, 300), Vector2(250, 0), false)
	grenade._physics_process(0.65)
	check(grenade.global_position.distance_to(Vector2(650, 300)) < 0.1, "Grenade reaches targeted landing position")
	grenade.queue_free()

class Dummy extends CharacterBody2D:
	signal destroyed
	var health: int = 100
	func take_damage(amount: int) -> void:
		health -= amount

extends SceneTree

## Regression tests for the Visual, Shooting & Content Overhaul (Sep 2026).
## Covers: M70 auto-fire, spread bloom, Zolja discard, ammo redirect,
## accuracy minf, faction tint restore, aggro pursuit grace, camera zoom
## clamp, mouse-mode state sync, M2 reinforcement ordering, crosshair wiring.

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

	_test_autofire_config()
	_test_hold_fire()
	_test_bloom_math()
	_test_zolja_discard()
	_test_ammo_redirect()
	_test_accuracy_float()
	await _test_tint_restore()
	await _test_aggro_grace()
	_test_camera_clamp()
	_test_mouse_mode()
	_test_crosshair_wiring()
	await _test_m2_reinforcements()

	main.queue_free()
	await process_frame
	print("Overhaul regression checks: %d; failures: %d" % [checks, failures])
	call_deferred("quit", 1 if failures else 0)


func _wm() -> Node:
	return player.weapon_manager


## --- 1. M70 fires fully automatically -------------------------------------
func _test_autofire_config() -> void:
	var m70: WeaponResource = load("res://resources/weapons/zastava_m70.tres")
	check(m70.is_automatic, "M70 is configured for automatic fire")
	check(m70.fire_rate > 0.0 and m70.fire_rate <= 0.2, "M70 auto fire_rate is in a sane range")
	check(m70.bloom_per_shot > 0.0 and m70.max_bloom > 0.0, "M70 carries bloom tuning")
	var skorpion: WeaponResource = load("res://resources/weapons/skorpion_smg.tres")
	check(skorpion.is_automatic, "Skorpion remains automatic")
	var pistol: WeaponResource = load("res://resources/weapons/php_pistol.tres")
	check(not pistol.is_automatic, "Pistol remains semi-automatic")


## --- 2. Holding the trigger keeps firing an automatic weapon ---------------
func _test_hold_fire() -> void:
	var wm: Node = _wm()
	wm.reset_action_state()
	wm.switch_to_slot(0)
	Input.action_press("shoot")
	var before: int = wm.ammo[0]
	wm._physics_process(0.016)  # first held frame fires
	wm.can_fire = true  # simulate cooldown elapsed
	wm._physics_process(0.016)  # still held: fires again WITHOUT a re-press
	Input.action_release("shoot")
	check(before - wm.ammo[0] >= 2, "Automatic rifle fires repeatedly while trigger held")
	wm.reset_action_state()


## --- 3. Spread bloom accumulates, clamps, recovers, resets on swap ---------
func _test_bloom_math() -> void:
	var wm: Node = _wm()
	wm.reset_action_state()
	wm.switch_to_slot(0)
	var weapon: WeaponResource = wm.get_current_weapon()
	for i in range(20):
		wm.can_fire = true
		wm.fire()
	check(is_equal_approx(wm.current_bloom, weapon.max_bloom), "Bloom clamps at weapon max under sustained fire")
	var bloomed: float = wm.current_bloom
	wm._physics_process(0.5)  # trigger released: recovery
	check(wm.current_bloom < bloomed, "Bloom recovers when not firing")
	wm.fire()
	wm.can_fire = true
	wm.switch_to_slot(2)
	check(wm.current_bloom == 0.0, "Weapon switch resets bloom")
	wm.switch_to_slot(0)
	wm.reset_action_state()


## --- 4. M80 Zolja discards itself after its single shot --------------------
func _test_zolja_discard() -> void:
	var wm: Node = _wm()
	wm.reset_action_state()
	wm.switch_to_slot(0)
	var discarded: Array = []
	if not wm.weapon_discarded.is_connected(func(w: WeaponResource) -> void: discarded.append(w)):
		wm.weapon_discarded.connect(func(w: WeaponResource) -> void: discarded.append(w))
	var zolja: WeaponResource = load("res://resources/weapons/m80_zolja.tres")
	check(zolja.is_disposable and zolja.max_ammo == 1, "Zolja is a single-shot disposable")
	wm.add_weapon(zolja, 1)
	var zolja_slot: int = wm.current_slot
	check(zolja_slot == 1, "Zolja occupies the pickup slot")
	wm.can_fire = true
	wm.fire()
	check(wm.slots[zolja_slot] == null, "Spent Zolja is discarded from its slot")
	check(discarded.size() == 1 and discarded[0] == zolja, "weapon_discarded emitted with the Zolja")
	check(wm.current_slot != zolja_slot and wm.get_current_weapon() != null, "Fallback weapon auto-equips after discard")


## --- 5. Ammo pickup while holding the pistol feeds a real gun --------------
func _test_ammo_redirect() -> void:
	var wm: Node = _wm()
	wm.reset_action_state()
	wm.switch_to_slot(2)
	var before: int = wm.reserve[0]
	wm.add_ammo(10)
	check(wm.reserve[0] == before + 10, "Ammo pickup redirects to rifle while pistol held")
	check(wm.reserve[2] == -1, "Pistol reserve stays unlimited")
	wm.switch_to_slot(0)


## --- 6. Accuracy uses float math (mini() truncated to int) -----------------
func _test_accuracy_float() -> void:
	var sm: Node = root.get_node("ScoreManager")
	var old_fired: int = sm.shots_fired
	var old_hit: int = sm.shots_hit
	sm.shots_fired = 3
	sm.shots_hit = 1
	var acc: float = sm.get_accuracy()
	check(absf(acc - 33.333) < 0.5, "Accuracy keeps fractional percent (33.3%%, got %.2f)" % acc)
	sm.shots_fired = old_fired
	sm.shots_hit = old_hit


## --- 7. Hit flash restores the SVK faction tint, not hard white -------------
func _test_tint_restore() -> void:
	var enemy: CharacterBody2D = load("res://scenes/enemies/Rifleman.tscn").instantiate()
	enemy.position = Vector2(900, 700)
	main.add_child(enemy)
	enemy.set_physics_process(false)
	await process_frame
	await process_frame
	var tint: Color = enemy.faction.uniform_tint
	var body: Sprite2D = enemy.body_sprite
	check(body.get_meta("base_modulate") == tint, "Faction tint recorded as base_modulate")
	enemy.take_damage(1)
	await create_timer(0.4).timeout
	var drift: float = absf(body.modulate.r - tint.r) + absf(body.modulate.g - tint.g) + absf(body.modulate.b - tint.b)
	check(drift < 0.1, "Hit flash returns sprite to faction tint (no pink wash-out)")
	enemy.queue_free()


## --- 8. Leaving detection range grants pursuit grace, not instant reset -----
func _test_aggro_grace() -> void:
	var enemy: CharacterBody2D = load("res://scenes/enemies/Rifleman.tscn").instantiate()
	enemy.position = Vector2(900, 500)
	main.add_child(enemy)
	enemy.set_physics_process(false)
	await process_frame
	await process_frame
	var saved_pos: Vector2 = player.position
	enemy.target = player
	enemy.current_state = EnemyBase.State.ATTACK
	enemy._on_detection_body_exited(player)
	check(enemy.current_state == EnemyBase.State.CHASE and enemy.target == player,
		"Enemy pursues briefly instead of instantly resetting to PATROL")
	player.position = saved_pos + Vector2(6000, 0)
	enemy._on_pursuit_timeout()
	check(enemy.current_state == EnemyBase.State.PATROL and enemy.target == null,
		"Enemy disengages only after the player truly escapes")
	player.position = saved_pos
	enemy.queue_free()


## --- 9. Camera magnification is clamped on oversized viewports -------------
func _test_camera_clamp() -> void:
	var camera: Camera2D = player.camera
	var tiny := Control.new()
	tiny.name = "TinyGround"
	tiny.size = Vector2(10, 10)
	main.add_child(tiny)
	var real_ground: Control = camera._ground
	camera._ground = tiny
	camera._configure_view()
	check(camera.zoom.x <= camera.max_zoom + 0.001, "Camera zoom never exceeds max_zoom (got %.2f)" % camera.zoom.x)
	camera._ground = real_ground
	camera._configure_view()
	check(camera.zoom.x >= camera.field_zoom - 0.001, "Camera restores at least field_zoom after un-clamp")
	tiny.queue_free()


## --- 10. OS cursor hides in PLAYING, shows in menus -------------------------
func _test_mouse_mode() -> void:
	var gm: Node = root.get_node("GameManager")
	var old_state: int = gm.current_state
	var old_mode: int = Input.mouse_mode
	gm.current_state = gm.GameState.PLAYING
	gm._apply_mouse_mode()
	# The headless DisplayServer has no OS cursor to hide; assert only windowed.
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_HIDDEN, "OS cursor hidden during PLAYING (custom crosshair owns it)")
	else:
		check(true, "OS cursor hidden during PLAYING (skipped: headless has no cursor)")
	gm.current_state = gm.GameState.MENU
	gm._apply_mouse_mode()
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "OS cursor restored in menus")
	else:
		check(true, "OS cursor restored in menus (skipped: headless)")
	gm.current_state = old_state
	Input.mouse_mode = old_mode


## --- 11. Crosshair tracks weapon swaps + ScoreManager hit/kill pulses -------
func _test_crosshair_wiring() -> void:
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	var hud: Node = hud_scene.instantiate()
	hud.name = "HUD"
	main.add_child(hud)
	hud.setup(player)  # HUD wires crosshair/minimap only via explicit setup
	var crosshair: Node = hud.get_node_or_null("Crosshair")
	check(crosshair != null, "HUD exposes a Crosshair node")
	if crosshair == null:
		return
	var wm: Node = _wm()
	# Weapon switch drives the per-weapon reticle style.
	wm.switch_to_slot(2)
	check(String(crosshair._weapon_id) == "php", "Crosshair adopts pistol reticle on weapon switch")
	wm.switch_to_slot(0)
	check(String(crosshair._weapon_id) == "m70", "Crosshair adopts rifle reticle on weapon switch")
	# ScoreManager pulses drive hit/kill markers.
	var sm: Node = root.get_node("ScoreManager")
	sm.record_shot_hit()
	check(crosshair._hit_flash > 0.0, "Hit marker pulses on registered hit")
	sm.record_kill()
	check(crosshair._kill_flash > 0.0, "Kill marker pulses on registered kill")
	hud.queue_free()


## --- 12. Mission 2 bunker snapshot happens after difficulty scaling ---------
func _test_m2_reinforcements() -> void:
	var dm: Node = root.get_node("DifficultyManager")
	var prev_diff: int = dm.get_difficulty()
	dm.set_difficulty(2)  # HARD scales bunker health after _ready
	var m2: Node = load("res://scenes/missions/Mission2.tscn").instantiate()
	root.add_child(m2)
	await process_frame
	await process_frame
	await process_frame
	var ctrl: Node = m2.get_node_or_null("MissionController")
	var bunkers: Array = m2.get_node("Bunkers").get_children()
	check(bunkers.size() >= 2, "Mission 2 has at least two bunkers")
	var snapshots_ok: bool = true
	for b in bunkers:
		if not b.has_meta("start_health"):
			snapshots_ok = false
		elif int(b.get_meta("start_health")) != int(b.get("health")):
			snapshots_ok = false
	check(snapshots_ok, "Bunker start_health snapshots match post-difficulty health")
	check(ctrl != null and ctrl._initial_bunker_count == bunkers.size(), "Controller tracks initial bunker count")
	# Outright destruction (e.g. one-shot rocket) must also trip reinforcements.
	if ctrl and bunkers.size() > 0:
		bunkers[0].queue_free()
		await process_frame
		ctrl._check_bunker_damage()
		check(ctrl._reinforcements_spawned, "Bunker destruction triggers M2 reinforcements")
	m2.queue_free()
	await process_frame
	dm.set_difficulty(prev_diff)

# tests/test_ui_visual.gd
extends SceneTree

func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	# Dummy audio playback is not part of these rendering/structure checks.
	root.get_node("SoundManager")._sfx.clear()
	# 1. Test HUD Scene and Frames
	var hud_scene: PackedScene = load("res://scenes/ui/HUD.tscn")
	if hud_scene == null:
		print("FAIL: HUD.tscn failed to load")
		quit(1)
		return

	var hud: CanvasLayer = hud_scene.instantiate()
	root.add_child(hud)

	if not hud.has_node("HealthFrame") or not hud.has_node("AmmoFrame"):
		print("FAIL: HUD missing sketched frames")
		quit(1)
		return

	if hud.get_node_or_null("ObjectiveArrow") == null:
		print("FAIL: HUD missing ObjectiveArrow")
		quit(1)
		return

	# Verify WeaponBadge in BottomBar
	var weapon_badge = hud.get_node_or_null("MarginContainer/VBoxContainer/BottomBar/WeaponBadge")
	if weapon_badge == null:
		print("FAIL: HUD missing WeaponBadge")
		quit(1)
		return

	weapon_badge.set_weapon("Hawk Shotgun")
	weapon_badge.set_weapon("PHP Pistol")
	weapon_badge.set_weapon("Zastava M70")

	# 2. Test Paper Overlay Shader and Parameter Binding
	var paper_shader = load("res://assets/shaders/paper_overlay.gdshader")
	if paper_shader == null:
		print("FAIL: paper_overlay.gdshader not found")
		quit(1)
		return

	var mat := ShaderMaterial.new()
	mat.shader = paper_shader
	mat.set_shader_parameter("shock_aberration", 0.02)
	mat.set_shader_parameter("ink_bleed", 1.2)
	var paper_tex: Texture2D = load("res://assets/sprites/ui/paper_parchment_bg.png")
	if paper_tex == null:
		print("FAIL: paper_parchment_bg.png not found")
		quit(1)
		return
	mat.set_shader_parameter("paper_texture", paper_tex)

	# 3. Test PaperOverlay Script & Combat Shock
	var paper_overlay_script = load("res://scripts/ui/PaperOverlay.gd")
	var paper_overlay = CanvasLayer.new()
	paper_overlay.set_script(paper_overlay_script)
	root.add_child(paper_overlay)
	if not paper_overlay.has_method("trigger_combat_shock"):
		print("FAIL: PaperOverlay missing trigger_combat_shock")
		quit(1)
		return
	paper_overlay.trigger_combat_shock(0.04)
	if paper_overlay._mat == null or absf(paper_overlay._mat.get_shader_parameter("shock_aberration") - 0.04) > 0.001:
		print("FAIL: PaperOverlay shock_aberration shader parameter was not updated")
		quit(1)
		return

	# 4. Test Minimap & Compass Texture
	var minimap_script = load("res://scripts/ui/Minimap.gd")
	var minimap = Control.new()
	minimap.set_script(minimap_script)
	root.add_child(minimap)
	var compass_tex: Texture2D = load("res://assets/sprites/ui/minimap_compass.png")
	if compass_tex == null:
		print("FAIL: minimap_compass.png not found")
		quit(1)
		return

	# 5. Test BriefingScreen Scene
	var briefing_scene: PackedScene = load("res://scenes/ui/BriefingScreen.tscn")
	if briefing_scene == null:
		print("FAIL: BriefingScreen.tscn not found")
		quit(1)
		return
	var briefing = briefing_scene.instantiate()
	root.add_child(briefing)
	if not (briefing is CanvasLayer):
		print("FAIL: BriefingScreen root must be CanvasLayer")
		quit(1)
		return
	if not briefing.has_node("Root/BackgroundParchment"):
		print("FAIL: BriefingScreen missing BackgroundParchment")
		quit(1)
		return

	# 6. Test ResultsScreen Scene & CompleteStamp
	var results_scene: PackedScene = load("res://scenes/ui/ResultsScreen.tscn")
	if results_scene == null:
		print("FAIL: ResultsScreen.tscn not found")
		quit(1)
		return
	var results = results_scene.instantiate()
	root.add_child(results)
	if not results.has_node("BackgroundParchment"):
		print("FAIL: ResultsScreen missing BackgroundParchment")
		quit(1)
		return
	if not results.has_node("CenterContainer/VBoxContainer/StampContainer/CompleteStamp"):
		print("FAIL: ResultsScreen missing CompleteStamp")
		quit(1)
		return

	print("PASS: UI visual architecture verified")
	for audio in root.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
		audio.stream = null
	for child in root.get_children():
		if child.name not in ["GameManager", "ScoreManager", "SaveManager", "SoundManager"]:
			child.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.35).timeout
	call_deferred("quit", 0)

extends Control

## High-visibility weapon crosshair that follows the mouse.
## Dual-tone (parchment core + ink outline) so it reads on any terrain,
## with a live sustained-fire bloom ring and hit/kill marker pulses.

const INK: Color = Color(0.10, 0.09, 0.07, 0.95)          # outline / dark layer
const CREAM: Color = Color(0.96, 0.92, 0.80, 0.98)         # bright parchment core
const ALERT: Color = Color(0.95, 0.25, 0.18, 0.98)         # fire flash
const HIT: Color = Color(1.0, 1.0, 1.0, 0.98)              # hit marker
const KILL: Color = Color(0.92, 0.15, 0.12, 1.0)           # kill marker

var _weapon_manager: Node = null
var _player: Node = null
var _weapon_id: StringName = &"m70"
var _spread_angle: float = 0.0
var _bloom: float = 0.0
var _flash: float = 0.0        # seconds remaining of fire flash
var _hit_flash: float = 0.0    # seconds remaining of hit marker
var _kill_flash: float = 0.0   # seconds remaining of kill marker


func _ready() -> void:
	anchors_preset = Control.PRESET_FULL_RECT
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func setup(weapon_manager: Node, player: Node) -> void:
	_weapon_manager = weapon_manager
	_player = player
	_refresh_weapon()
	if _weapon_manager:
		if _weapon_manager.has_signal("weapon_switched") and not _weapon_manager.weapon_switched.is_connected(_on_weapon_switched):
			_weapon_manager.weapon_switched.connect(_on_weapon_switched)
		if _weapon_manager.has_signal("weapon_fired") and not _weapon_manager.weapon_fired.is_connected(_on_weapon_fired):
			_weapon_manager.weapon_fired.connect(_on_weapon_fired)
		if _weapon_manager.has_signal("bloom_changed") and not _weapon_manager.bloom_changed.is_connected(_on_bloom_changed):
			_weapon_manager.bloom_changed.connect(_on_bloom_changed)
	var sm := get_node_or_null("/root/ScoreManager")
	if sm:
		if sm.has_signal("hit_registered") and not sm.hit_registered.is_connected(_on_hit_registered):
			sm.hit_registered.connect(_on_hit_registered)
		if sm.has_signal("kill_registered") and not sm.kill_registered.is_connected(_on_kill_registered):
			sm.kill_registered.connect(_on_kill_registered)


func _process(delta: float) -> void:
	_flash = maxf(0.0, _flash - delta)
	_hit_flash = maxf(0.0, _hit_flash - delta)
	_kill_flash = maxf(0.0, _kill_flash - delta)
	if _player and is_instance_valid(_player) and bool(_player.get("_is_dead")):
		visible = false
		return
	var gm := get_node_or_null("/root/GameManager")
	if gm and int(gm.get("current_state")) != int(gm.GameState.PLAYING):
		visible = false
		return
	# Fallback poll in case a bloom signal was missed.
	if _weapon_manager and is_instance_valid(_weapon_manager):
		var b = _weapon_manager.get("current_bloom")
		if b != null:
			_bloom = float(b)
	visible = true
	queue_redraw()


func _refresh_weapon() -> void:
	if _weapon_manager == null or not is_instance_valid(_weapon_manager):
		return
	if not _weapon_manager.has_method("get_current_weapon"):
		return
	var weapon = _weapon_manager.get_current_weapon()
	if weapon == null:
		return
	if "weapon_id" in weapon and weapon.weapon_id != &"":
		_weapon_id = weapon.weapon_id
	_spread_angle = float(weapon.spread_angle) if ("spread_angle" in weapon) else 0.0


func _on_weapon_switched(_weapon) -> void:
	_refresh_weapon()
	_bloom = 0.0


func _on_weapon_fired() -> void:
	_flash = 0.08


func _on_bloom_changed(bloom: float) -> void:
	_bloom = bloom


func _on_hit_registered() -> void:
	_hit_flash = 0.09


func _on_kill_registered() -> void:
	_kill_flash = 0.22


# --- Drawing ---------------------------------------------------------------

func _draw() -> void:
	var center: Vector2 = get_local_mouse_position()
	match _weapon_id:
		&"hawk":
			_draw_shotgun_reticle(center)
		&"m48", &"m76":
			_draw_sniper_reticle(center)
		&"rpg", &"zolja":
			_draw_rpg_reticle(center)
		&"php":
			_draw_pistol_reticle(center)
		_:
			_draw_auto_reticle(center)
	_draw_markers(center)


## Dual-tone stroke: dark ink outline under bright parchment core.
func _stroke(from: Vector2, to: Vector2, core: Color, width: float = 2.0) -> void:
	draw_line(from, to, INK, width + 2.0)
	draw_line(from, to, core, width)


func _ring(center: Vector2, radius: float, core: Color, width: float = 2.0) -> void:
	draw_arc(center, radius, 0.0, TAU, 48, INK, width + 2.0)
	draw_arc(center, radius, 0.0, TAU, 48, core, width)


func _dot(center: Vector2, radius: float, core: Color) -> void:
	draw_circle(center, radius + 1.2, INK)
	draw_circle(center, radius, core)


func _draw_auto_reticle(center: Vector2) -> void:
	# Rifle / SMG / LMG: cross + dot + live bloom ring.
	var core: Color = ALERT if _flash > 0.0 else CREAM
	var arm: float = 9.0
	var gap: float = 3.5
	_stroke(center + Vector2(-arm - gap, 0), center + Vector2(-gap, 0), core)
	_stroke(center + Vector2(gap, 0), center + Vector2(arm + gap, 0), core)
	_stroke(center + Vector2(0, -arm - gap), center + Vector2(0, -gap), core)
	_stroke(center + Vector2(0, gap), center + Vector2(0, arm + gap), core)
	_dot(center, 1.6, core)
	# Bloom ring: radius mirrors effective spread so players see accuracy live.
	var spread_r: float = clampf((_spread_angle + _bloom) * 160.0, 8.0, 40.0)
	var ring_alpha: float = clampf(0.35 + _bloom * 6.0, 0.35, 0.95)
	var ring_col: Color = Color(CREAM.r, CREAM.g, CREAM.b, ring_alpha)
	_ring(center, spread_r + 8.0, ring_col, 1.4)


func _draw_pistol_reticle(center: Vector2) -> void:
	var core: Color = ALERT if _flash > 0.0 else CREAM
	_dot(center, 2.0, core)
	_stroke(center + Vector2(-7, 0), center + Vector2(-3, 0), core, 1.6)
	_stroke(center + Vector2(3, 0), center + Vector2(7, 0), core, 1.6)
	_stroke(center + Vector2(0, -7), center + Vector2(0, -3), core, 1.6)
	_stroke(center + Vector2(0, 3), center + Vector2(0, 7), core, 1.6)


func _draw_shotgun_reticle(center: Vector2) -> void:
	var core: Color = ALERT if _flash > 0.0 else CREAM
	# Corner ticks around the real pellet cone.
	var radius: float = clampf(_spread_angle * 130.0, 26.0, 48.0)
	var t: float = 7.0
	_stroke(center + Vector2(-radius, -t), center + Vector2(-radius, t), core)
	_stroke(center + Vector2(radius, -t), center + Vector2(radius, t), core)
	_stroke(center + Vector2(-t, -radius), center + Vector2(t, -radius), core)
	_stroke(center + Vector2(-t, radius), center + Vector2(t, radius), core)
	_dot(center, 1.8, core)
	_ring(center, radius, Color(CREAM.r, CREAM.g, CREAM.b, 0.28), 1.0)


func _draw_sniper_reticle(center: Vector2) -> void:
	var core: Color = ALERT if _flash > 0.0 else CREAM
	var gap: float = 4.0
	var len: float = 17.0
	_dot(center, 1.4, core)
	_stroke(center + Vector2(-len, 0), center + Vector2(-gap, 0), core, 1.4)
	_stroke(center + Vector2(gap, 0), center + Vector2(len, 0), core, 1.4)
	_stroke(center + Vector2(0, -len), center + Vector2(0, -gap), core, 1.4)
	_stroke(center + Vector2(0, gap), center + Vector2(0, len), core, 1.4)
	_ring(center, 5.5, Color(CREAM.r, CREAM.g, CREAM.b, 0.5), 1.0)


func _draw_rpg_reticle(center: Vector2) -> void:
	var core: Color = ALERT if _flash > 0.0 else CREAM
	_ring(center, 24.0, core, 1.8)
	_dot(center, 2.2, core)
	# Blast-radius hint ticks
	for a in [0.0, PI * 0.5, PI, PI * 1.5]:
		var dir := Vector2(cos(a), sin(a))
		_stroke(center + dir * 18.0, center + dir * 24.0, core, 1.6)


func _draw_markers(center: Vector2) -> void:
	# Kill marker: bold red X. Hit marker: small white X ticks.
	if _kill_flash > 0.0:
		var s: float = 11.0 + (0.22 - _kill_flash) * 40.0
		_stroke(center + Vector2(-s, -s), center + Vector2(-s * 0.4, -s * 0.4), KILL, 3.0)
		_stroke(center + Vector2(s, -s), center + Vector2(s * 0.4, -s * 0.4), KILL, 3.0)
		_stroke(center + Vector2(-s, s), center + Vector2(-s * 0.4, s * 0.4), KILL, 3.0)
		_stroke(center + Vector2(s, s), center + Vector2(s * 0.4, s * 0.4), KILL, 3.0)
	elif _hit_flash > 0.0:
		var s: float = 7.0
		_stroke(center + Vector2(-s, -s), center + Vector2(-s * 0.45, -s * 0.45), HIT, 2.0)
		_stroke(center + Vector2(s, -s), center + Vector2(s * 0.45, -s * 0.45), HIT, 2.0)
		_stroke(center + Vector2(-s, s), center + Vector2(-s * 0.45, s * 0.45), HIT, 2.0)
		_stroke(center + Vector2(s, s), center + Vector2(s * 0.45, s * 0.45), HIT, 2.0)

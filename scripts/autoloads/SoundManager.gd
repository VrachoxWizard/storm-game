extends Node

## Autoload — plays SFX/music and manages bus volumes / low-pass filter.

var _sfx: Dictionary = {}
var _music: Dictionary = {}
var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _music_player_b: AudioStreamPlayer
var _ambient_player: AudioStreamPlayer
var _active_music_a: bool = true
var _low_pass_active: bool = false
var _current_music_id: String = ""
const POOL_SIZE: int = 14

const _SFX_PATHS: Dictionary = {
	"shoot": "res://assets/audio/shoot.wav",
	"shoot_rifle": "res://assets/audio/shoot_rifle.wav",
	"shoot_pistol": "res://assets/audio/shoot_pistol.wav",
	"shoot_shotgun": "res://assets/audio/shoot_shotgun.wav",
	"shoot_smg": "res://assets/audio/shoot_smg.wav",
	"shoot_sniper": "res://assets/audio/shoot_sniper.wav",
	"shoot_rpg": "res://assets/audio/shoot_rpg.wav",
	"shoot_enemy": "res://assets/audio/shoot_enemy.wav",
	"reload": "res://assets/audio/reload.wav",
	"dry_fire": "res://assets/audio/dry_fire.wav",
	"hit": "res://assets/audio/hit.wav",
	"impact_flesh": "res://assets/audio/impact_flesh.wav",
	"impact_metal": "res://assets/audio/impact_metal.wav",
	"explosion": "res://assets/audio/explosion.wav",
	"dodge": "res://assets/audio/dodge.wav",
	"pickup": "res://assets/audio/pickup.wav",
	"death": "res://assets/audio/death.wav",
	"ui_click": "res://assets/audio/ui_click.wav",
	"checkpoint": "res://assets/audio/checkpoint.wav",
	"objective": "res://assets/audio/objective.wav",
}

const _MUSIC_PATHS: Dictionary = {
	"title": "res://assets/audio/music_title.wav",
	"combat": "res://assets/audio/music_combat.wav",
	"tension": "res://assets/audio/music_tension.wav",
}

const _AMBIENT_PATH: String = "res://assets/audio/ambient_wind.wav"


func _ready() -> void:
	for id in _SFX_PATHS:
		_sfx[id] = _safe_load_stream(_SFX_PATHS[id])
	for id in _MUSIC_PATHS:
		_music[id] = _safe_load_stream(_MUSIC_PATHS[id])
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Music"
	add_child(_music_player)
	_music_player_b = AudioStreamPlayer.new()
	_music_player_b.bus = "Music"
	add_child(_music_player_b)
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Music"
	_ambient_player.volume_db = -18.0
	add_child(_ambient_player)
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_sfx_players.append(p)
	# Ensure Music bus has low-pass for critical HP muffling
	_ensure_music_lowpass()
	apply_saved_volumes()
	play_music("title")
	_start_ambient()


func _ensure_music_lowpass() -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	if AudioServer.get_bus_effect_count(idx) == 0:
		var lp := AudioEffectLowPassFilter.new()
		lp.cutoff_hz = 500.0
		AudioServer.add_bus_effect(idx, lp)
		AudioServer.set_bus_effect_enabled(idx, 0, false)


func _safe_load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("SoundManager: missing audio %s" % path)
		return null
	var res: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REUSE)
	if res is AudioStream:
		return res as AudioStream
	push_warning("SoundManager: failed to load audio %s" % path)
	return null


func apply_saved_volumes() -> void:
	var settings: Dictionary = SaveManager.data.get("settings", {})
	set_music_volume(float(settings.get("music_volume", 0.8)))
	set_sfx_volume(float(settings.get("sfx_volume", 1.0)))


func set_music_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("Music")
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
	if not SaveManager.data.has("settings"):
		SaveManager.data["settings"] = {}
	SaveManager.data["settings"]["music_volume"] = linear
	SaveManager.save_data()


func set_sfx_volume(linear: float) -> void:
	var idx := AudioServer.get_bus_index("SFX")
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(clampf(linear, 0.0001, 1.0)))
	if not SaveManager.data.has("settings"):
		SaveManager.data["settings"] = {}
	SaveManager.data["settings"]["sfx_volume"] = linear
	SaveManager.save_data()


## Plays a short Croatian radio/battle-cry cue remapped onto existing SFX.
func play_voice_line(line_id: String) -> void:
	match line_id:
		"naprijed":
			play_sfx("objective", 0.02, -2.0)
		"pokrivaj":
			play_sfx("checkpoint", 0.02, -2.0)
		"za_dom":
			play_sfx("objective", 0.02, 0.0)
		"oluja":
			play_sfx("objective", 0.0, 2.0)
		_:
			play_sfx("ui_click", 0.0, -4.0)


func play_sfx(id: String, pitch_variance: float = 0.08, volume_db: float = 0.0) -> void:
	var stream_id := id
	if not _sfx.has(stream_id) or _sfx[stream_id] == null:
		# Fallbacks
		if id.begins_with("shoot_"):
			stream_id = "shoot"
		elif id.begins_with("impact_"):
			stream_id = "hit"
		else:
			return
	if not _sfx.has(stream_id) or _sfx[stream_id] == null:
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx[stream_id]
			p.pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
			p.volume_db = volume_db
			p.play()
			return
	_sfx_players[0].stream = _sfx[stream_id]
	_sfx_players[0].pitch_scale = randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	_sfx_players[0].volume_db = volume_db
	_sfx_players[0].play()


func play_weapon_shoot(weapon_name: String) -> void:
	var key := "shoot_rifle"
	var n := weapon_name.to_lower()
	if "pistol" in n or "php" in n:
		key = "shoot_pistol"
	elif "shotgun" in n or "hawk" in n:
		key = "shoot_shotgun"
	elif "skorpion" in n or "škorpion" in n or "smg" in n:
		key = "shoot_smg"
	elif "mauser" in n or "sniper" in n or "m48" in n:
		key = "shoot_sniper"
	elif "rpg" in n:
		key = "shoot_rpg"
	play_sfx(key)


func play_music(id: String, crossfade: float = 1.0) -> void:
	if not _music.has(id) or _music[id] == null:
		return
	if _current_music_id == id:
		return
	var stream: AudioStream = _music[id]
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	var incoming: AudioStreamPlayer = _music_player_b if _active_music_a else _music_player
	var outgoing: AudioStreamPlayer = _music_player if _active_music_a else _music_player_b
	incoming.stream = stream
	incoming.volume_db = -40.0
	incoming.play()
	_current_music_id = id
	_active_music_a = not _active_music_a
	if crossfade <= 0.0:
		incoming.volume_db = 0.0
		outgoing.stop()
		return
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(incoming, "volume_db", 0.0, crossfade)
	tween.tween_property(outgoing, "volume_db", -40.0, crossfade)
	tween.chain().tween_callback(func() -> void:
		outgoing.stop()
	)


func _start_ambient() -> void:
	var stream := _safe_load_stream(_AMBIENT_PATH)
	if stream == null:
		return
	if stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_ambient_player.stream = stream
	_ambient_player.play()


func set_low_pass(enabled: bool) -> void:
	if _low_pass_active == enabled:
		return
	_low_pass_active = enabled
	for bus_name in ["SFX", "Music"]:
		var bus_idx := AudioServer.get_bus_index(bus_name)
		if bus_idx >= 0 and AudioServer.get_bus_effect_count(bus_idx) > 0:
			AudioServer.set_bus_effect_enabled(bus_idx, 0, enabled)

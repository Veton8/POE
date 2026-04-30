extends Node

const SFX_DIR := "res://audio/sfx/"
const MUSIC_DIR := "res://audio/music/"
const VOICE_COUNT := 12

const KNOWN_SFX := [
	"shoot", "hit", "enemy_die", "boss_die",
	"ability_dash", "ability_burst", "ability_heal",
	"door_unlock", "boss_phase2", "player_hurt", "footstep",
]

var _cache: Dictionary = {}
var _missing: Dictionary = {}
var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music_player: AudioStreamPlayer = null
var _master_sfx_db: float = 0.0
var _master_music_db: float = -6.0

func _ready() -> void:
	for i in VOICE_COUNT:
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_voices.append(p)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = _master_music_db
	add_child(_music_player)

func play(sfx_name: String, pitch_variation: float = 0.05, volume_db: float = 0.0) -> void:
	var stream := _load_sfx(sfx_name)
	if stream == null:
		return
	var v := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	v.stream = stream
	v.volume_db = _master_sfx_db + volume_db
	v.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	v.play()

func play_music(track: String) -> void:
	var stream := _load_audio(MUSIC_DIR + track)
	if stream == null:
		return
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	_music_player.stream = stream
	_music_player.play()

func stop_music() -> void:
	if _music_player and _music_player.playing:
		_music_player.stop()

func _load_sfx(sfx_name: String) -> AudioStream:
	if _cache.has(sfx_name):
		return _cache[sfx_name]
	if _missing.has(sfx_name):
		return null
	var stream := _load_audio(SFX_DIR + sfx_name)
	if stream == null:
		_missing[sfx_name] = true
		return null
	_cache[sfx_name] = stream
	return stream

func _load_audio(path_no_ext: String) -> AudioStream:
	for ext: String in [".wav", ".ogg", ".mp3"]:
		var full: String = path_no_ext + ext
		if ResourceLoader.exists(full):
			return load(full) as AudioStream
	return null

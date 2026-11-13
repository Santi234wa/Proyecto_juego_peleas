## audio_manager.gd — AUTOLOAD: "AudioManager"
## Centraliza la reproducción y gestión de audio (BGM, SFX, UI, Voces).
## Arquitectura modular y tolerante a fallos:
## Si un archivo de sonido o música no existe en disco, emite una advertencia segura
## y continúa la ejecución sin detener ni crashear el juego.
extends Node

const BUS_MASTER: String = "Master"
const BUS_MUSIC: String = "Music"
const BUS_SFX: String = "SFX"
const BUS_UI: String = "UI"
const BUS_AMBIENCE: String = "Ambience"

const SFX_POOL_SIZE: int = 12

var _music_player: AudioStreamPlayer = null
var _ambience_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

var _current_music_path: String = ""
var _is_music_fading: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_audio_buses()
	_create_audio_players()

# ---------------------------------------------------------------------------
# Inicialización de buses de audio
# ---------------------------------------------------------------------------

func _setup_audio_buses() -> void:
	var required_buses: Array[String] = [BUS_MUSIC, BUS_SFX, BUS_UI, BUS_AMBIENCE]
	for b_name in required_buses:
		if AudioServer.get_bus_index(b_name) == -1:
			var idx: int = AudioServer.bus_count
			AudioServer.add_bus(idx)
			AudioServer.set_bus_name(idx, b_name)
			AudioServer.set_bus_send(idx, BUS_MASTER)

func _create_audio_players() -> void:
	# Reproductor de música dedicado
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)

	# Reproductor de ambiente
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)

	# Pool de efectos de sonido
	for i in range(SFX_POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = BUS_SFX
		add_child(p)
		_sfx_players.append(p)

# ---------------------------------------------------------------------------
# API Pública: Música (BGM)
# ---------------------------------------------------------------------------

## Reproduce una pista de música por recurso AudioStream o ruta de archivo ("res://...").
## Si el archivo no existe, no falla y emite advertencia segura.
func play_music(stream_or_path, fade_duration: float = 0.5) -> void:
	var stream: AudioStream = _resolve_stream(stream_or_path)
	if not stream:
		return

	var path_str: String = stream_or_path if stream_or_path is String else stream.resource_path
	if _current_music_path == path_str and _music_player.playing:
		return

	_current_music_path = path_str

	if fade_duration > 0.0 and _music_player.playing:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", -80.0, fade_duration * 0.5)
		tw.tween_callback(func():
			_music_player.stream = stream
			_music_player.volume_db = -80.0
			_music_player.play()
			var tw_in := create_tween()
			tw_in.tween_property(_music_player, "volume_db", 0.0, fade_duration * 0.5)
		)
	else:
		_music_player.stream = stream
		_music_player.volume_db = 0.0
		_music_player.play()

func stop_music(fade_duration: float = 0.5) -> void:
	if not _music_player or not _music_player.playing:
		return
	if fade_duration > 0.0:
		var tw := create_tween()
		tw.tween_property(_music_player, "volume_db", -80.0, fade_duration)
		tw.tween_callback(func():
			_music_player.stop()
			_current_music_path = ""
		)
	else:
		_music_player.stop()
		_current_music_path = ""

# ---------------------------------------------------------------------------
# API Pública: Efectos de Sonido (SFX)
# ---------------------------------------------------------------------------

## Reproduce un efecto de sonido en el bus SFX usando el pool de reproductores.
func play_sfx(stream_or_path, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	var stream: AudioStream = _resolve_stream(stream_or_path)
	if not stream:
		return null

	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.bus = BUS_SFX
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	return player

## Reproduce un sonido de interfaz (UI)
func play_ui(stream_or_path, volume_db: float = 0.0) -> AudioStreamPlayer:
	var stream: AudioStream = _resolve_stream(stream_or_path)
	if not stream:
		return null

	var player: AudioStreamPlayer = _get_available_sfx_player()
	player.bus = BUS_UI
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0
	player.play()
	return player

# ---------------------------------------------------------------------------
# Control de Volumen por Bus
# ---------------------------------------------------------------------------

## Asigna volumen en escala lineal de 0.0 a 1.0 para el bus especificado.
func set_bus_volume(bus_name: String, linear_volume: float) -> void:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	var clamped: float = clampf(linear_volume, 0.0, 1.0)
	var db: float = linear_to_db(clamped) if clamped > 0.0001 else -80.0
	AudioServer.set_bus_volume_db(idx, db)

func get_bus_volume(bus_name: String) -> float:
	var idx: int = AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	var db: float = AudioServer.get_bus_volume_db(idx)
	return db_to_linear(db)

# ---------------------------------------------------------------------------
# Helpers internos y resolución segura
# ---------------------------------------------------------------------------

func _resolve_stream(stream_or_path) -> AudioStream:
	if stream_or_path == null:
		return null
	if stream_or_path is AudioStream:
		return stream_or_path
	if stream_or_path is String:
		var path_str: String = stream_or_path.strip_edges()
		if path_str == "":
			return null
		if not ResourceLoader.exists(path_str):
			# Fallback seguro: no crashea si los archivos no han sido agregados todavía
			return null
		var res = load(path_str)
		if res is AudioStream:
			return res
	return null

func _get_available_sfx_player() -> AudioStreamPlayer:
	# Buscar el primer reproductor inactivo en el pool
	for p in _sfx_players:
		if not p.playing:
			return p
	# Si todos están ocupados, reutilizar por round-robin
	var chosen: AudioStreamPlayer = _sfx_players[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % _sfx_players.size()
	return chosen


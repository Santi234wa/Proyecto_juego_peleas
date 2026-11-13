## story_manager.gd  — AUTOLOAD: "StoryManager"
## Controlador central del Modo Historia "ECOS".
## Administra los capítulos, la preparación de combates contra la IA,
## la captura de resultados, el registro de decisiones y el guardado del progreso.
extends Node

# ---------------------------------------------------------------------------
# Señales públicas (Interfaz para futuras escenas narrativas y UI)
# ---------------------------------------------------------------------------
signal chapter_loaded(chapter: StoryChapter)
signal combat_prepared(chapter: StoryChapter)
signal story_match_finished(won: bool, chapter: StoryChapter)
signal decision_required(prompt: String, options: Array[Dictionary])
signal chapter_advanced(new_chapter: StoryChapter)
signal story_completed(ending_id: String)
signal progress_saved()

# ---------------------------------------------------------------------------
# Rutas de recursos de capítulos
# ---------------------------------------------------------------------------
const CHAPTER_PATHS: Array[String] = [
	"res://resources/story/chapter_01.tres",
	"res://resources/story/chapter_02.tres",
	"res://resources/story/chapter_03.tres",
	"res://resources/story/chapter_04.tres",
	"res://resources/story/chapter_05.tres",
	"res://resources/story/chapter_06.tres",
]

# ---------------------------------------------------------------------------
# Estado de ECOS en memoria
# ---------------------------------------------------------------------------
var chapters: Array[StoryChapter] = []
var chapters_by_id: Dictionary = {}

var current_chapter_index: int = 1  ## Capítulos 1 al 6 (1-based para congruencia narrativa)
var current_chapter: StoryChapter = null

var decisions: Array = []
var unlocked_endings: Array = []
var is_completed: bool = false

var last_match_won: bool = false

# ---------------------------------------------------------------------------
# Ciclo de vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_load_all_chapter_resources()
	_connect_game_data_signals()
	sync_from_save_manager()

func _connect_game_data_signals() -> void:
	var gdata = get_node_or_null("/root/GameData")
	if gdata:
		if not gdata.match_finished.is_connected(_on_match_finished):
			gdata.match_finished.connect(_on_match_finished)

# ---------------------------------------------------------------------------
# Carga de recursos
# ---------------------------------------------------------------------------

func _load_all_chapter_resources() -> void:
	chapters.clear()
	chapters_by_id.clear()

	for path in CHAPTER_PATHS:
		if ResourceLoader.exists(path):
			var ch = load(path) as StoryChapter
			if ch:
				chapters.append(ch)
				chapters_by_id[ch.chapter_id] = ch
		else:
			push_warning("StoryManager: No se encontró recurso de capítulo en '%s'." % path)

# ---------------------------------------------------------------------------
# Inicialización y Navegación
# ---------------------------------------------------------------------------

## Inicia el modo historia desde el inicio o desde el progreso guardado.
func start_story(from_beginning: bool = false) -> void:
	if from_beginning:
		current_chapter_index = 1
		decisions.clear()
		unlocked_endings.clear()
		is_completed = false
		save_progress()
	else:
		sync_from_save_manager()

	load_chapter(current_chapter_index)

## Carga un capítulo por su número ordinal (1 a 6).
func load_chapter(index: int) -> bool:
	if index < 1 or index > chapters.size():
		push_error("StoryManager: Índice de capítulo inválido: %d (Total disponibles: %d)." % [index, chapters.size()])
		return false

	current_chapter_index = index
	current_chapter = chapters[index - 1]
	emit_signal("chapter_loaded", current_chapter)
	print("[StoryManager] 📖 Capítulo %d cargado: '%s'" % [current_chapter.chapter_number, current_chapter.title])
	return true

## Carga un capítulo por su ID único (ej: 'chapter_02').
func load_chapter_by_id(ch_id: String) -> bool:
	if not chapters_by_id.has(ch_id):
		push_error("StoryManager: ID de capítulo no encontrado: '%s'." % ch_id)
		return false

	current_chapter = chapters_by_id[ch_id]
	current_chapter_index = current_chapter.chapter_number
	emit_signal("chapter_loaded", current_chapter)
	print("[StoryManager] 📖 Capítulo cargado por ID: '%s' (%s)" % [ch_id, current_chapter.title])
	return true

# ---------------------------------------------------------------------------
# Preparación del Combate
# ---------------------------------------------------------------------------

## Configura GameData con los parámetros del capítulo para iniciar combate contra la IA.
func prepare_combat_for_current_chapter() -> void:
	if not current_chapter:
		push_error("StoryManager: No hay capítulo cargado para preparar combate.")
		return

	var gdata = get_node_or_null("/root/GameData")
	if not gdata:
		push_error("StoryManager: No se encontró el autoload GameData.")
		return

	# 1. Configurar modo Historia
	gdata.current_mode = gdata.GameMode.STORY

	# 2. Asignar protagonista (P1 = Goku por defecto)
	gdata.player1_data = _resolve_character_data(current_chapter.player_character_id)

	# 3. Asignar rival como Jugador 2 (controlado por IA)
	gdata.player2_data = _resolve_character_data(current_chapter.opponent_character_id)

	# 4. Establecer dificultad de IA del capítulo
	gdata.ai_difficulty = current_chapter.ai_difficulty

	# 5. Establecer escenario del capítulo
	gdata.selected_map_id = current_chapter.map_id

	# 6. Rondas para ganar (Dummy = 1 ronda de calentamiento; combates normales = 2 rondas)
	if current_chapter.opponent_character_id == "dummy":
		gdata.rounds_to_win = 1
	else:
		gdata.rounds_to_win = 2

	# 7. Reiniciar contadores de ronda previos
	gdata.reset_match()

	print("[StoryManager] ⚔️ Combate preparado:")
	print("  Modo: STORY")
	print("  P1: %s" % (gdata.player1_data.display_name if gdata.player1_data else current_chapter.player_character_id))
	print("  P2 (IA): %s" % (gdata.player2_data.display_name if gdata.player2_data else current_chapter.opponent_character_id))
	print("  Dificultad IA: %d" % gdata.ai_difficulty)
	print("  Mapa: %s" % gdata.selected_map_id)

	emit_signal("combat_prepared", current_chapter)

# ---------------------------------------------------------------------------
# Resolución de Resultados
# ---------------------------------------------------------------------------

func _on_match_finished(winner_key: String) -> void:
	var gdata = get_node_or_null("/root/GameData")
	if not gdata or gdata.current_mode != gdata.GameMode.STORY:
		return

	var won: bool = (winner_key == "player1")
	last_match_won = won

	print("[StoryManager] 🏁 Resultado de combate en ECOS:")
	print("  Ganador: %s (Victoria del jugador: %s)" % [winner_key, str(won)])

	emit_signal("story_match_finished", won, current_chapter)

	if won:
		# Si el capítulo tiene una decisión tras ganar, solicitarla
		if current_chapter and current_chapter.has_decision and current_chapter.decision_options.size() > 0:
			emit_signal("decision_required", current_chapter.decision_prompt, current_chapter.decision_options)
		elif current_chapter and current_chapter.is_ending_chapter():
			complete_story()

## Reintenta el combate del capítulo actual.
func retry_current_chapter() -> void:
	prepare_combat_for_current_chapter()

# ---------------------------------------------------------------------------
# Avance y Decisiones
# ---------------------------------------------------------------------------

## Avanza al siguiente capítulo (lineal o por ID explícito).
func advance_chapter(next_id: String = "") -> bool:
	if not next_id.is_empty():
		if load_chapter_by_id(next_id):
			save_progress()
			emit_signal("chapter_advanced", current_chapter)
			return true
		return false

	if current_chapter and not current_chapter.next_chapter_id.is_empty():
		if load_chapter_by_id(current_chapter.next_chapter_id):
			save_progress()
			emit_signal("chapter_advanced", current_chapter)
			return true
		return false

	# Avance por índice numérico si no se especificó ID
	var next_idx := current_chapter_index + 1
	if next_idx <= chapters.size():
		if load_chapter(next_idx):
			save_progress()
			emit_signal("chapter_advanced", current_chapter)
			return true
	else:
		complete_story()

	return false

## Registra la decisión del jugador en el capítulo.
func record_decision(chapter_id: String, option_id: String, target_chapter_id: String = "", ending_id: String = "") -> void:
	var entry := {
		"chapter_id": chapter_id,
		"option_id": option_id,
		"target_chapter_id": target_chapter_id,
		"ending_id": ending_id,
		"timestamp": Time.get_datetime_string_from_system()
	}
	decisions.append(entry)
	print("[StoryManager] ⚖️ Decisión registrada: Capítulo '%s' -> Opción '%s'" % [chapter_id, option_id])

	if not ending_id.is_empty():
		unlock_ending(ending_id)

	save_progress()

	if not target_chapter_id.is_empty():
		advance_chapter(target_chapter_id)

## Desbloquea un final alternativo (ej: 'ending_a', 'ending_b').
func unlock_ending(ending_id: String) -> void:
	if not ending_id in unlocked_endings:
		unlocked_endings.append(ending_id)
		print("[StoryManager] 🏆 Final desbloqueado: '%s'" % ending_id)
		save_progress()

## Marca el modo historia como completado.
func complete_story(ending_id: String = "") -> void:
	is_completed = true
	if not ending_id.is_empty():
		unlock_ending(ending_id)
	save_progress()
	print("[StoryManager] ✨ Modo historia ECOS completado con éxito.")
	emit_signal("story_completed", ending_id)

# ---------------------------------------------------------------------------
# Persistencia y Sincronización con SaveManager
# ---------------------------------------------------------------------------

## Guarda el estado actual de ECOS en disco mediante SaveManager.
func save_progress() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("save_ecos_progress"):
		sm.save_ecos_progress(current_chapter_index, decisions, unlocked_endings, is_completed)
		emit_signal("progress_saved")

## Carga y sincroniza el estado de ECOS desde SaveManager.
func sync_from_save_manager() -> void:
	var sm = get_node_or_null("/root/SaveManager")
	if sm and sm.has_method("get_ecos_chapter_index"):
		current_chapter_index = sm.get_ecos_chapter_index()
		decisions = sm.get_ecos_decisions()
		unlocked_endings = sm.get_ecos_unlocked_endings()
		is_completed = sm.is_ecos_completed()
		print("[StoryManager] Sincronizado desde SaveManager: Capítulo %d, Decisiones: %d, Finales: %s" % [
			current_chapter_index, decisions.size(), str(unlocked_endings)
		])

# ---------------------------------------------------------------------------
# Métodos auxiliares
# ---------------------------------------------------------------------------

func _resolve_character_data(char_id: String) -> CharacterData:
	# 1. Buscar en GameData.all_characters
	var gdata = get_node_or_null("/root/GameData")
	if gdata:
		for cd in gdata.all_characters:
			if cd and cd.id == char_id:
				return cd

	# 2. Buscar recurso .tres en disco
	var path := "res://resources/characters/%s.tres" % char_id
	if ResourceLoader.exists(path):
		var cd = load(path) as CharacterData
		if cd:
			return cd

	# 3. Fallback seguro en memoria (evita caídas si el personaje aún está en integración)
	var fallback := CharacterData.new()
	fallback.id = char_id
	fallback.display_name = char_id.capitalize()
	fallback.max_health = 100.0
	fallback.max_energy = 100.0
	return fallback

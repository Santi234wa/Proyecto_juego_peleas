## save_manager.gd  — AUTOLOAD: "SaveManager"
## Gestiona el guardado y carga del progreso en disco usando ConfigFile.
## Patrón: Singleton — acceso global sin acoplamiento directo al sistema de archivos.
## ConfigFile es más robusto que JSON en Godot y soporta tipos nativos directamente.
extends Node

const DEFAULT_SAVE_PATH: String = "user://save_data.cfg"

## Ruta activa del archivo de guardado.
## Las pruebas unitarias pueden cambiarla a un archivo temporal para aislarse por completo
## sin tocar ni arriesgar el archivo de progreso real del usuario.
var save_path: String = DEFAULT_SAVE_PATH

# ---------------------------------------------------------------------------
# Guardado
# ---------------------------------------------------------------------------

## Guarda el progreso actual desde GameData a disco.
## Se llama al salir de un combate, al comprar en la tienda, etc.
func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.load(save_path)  # Cargar previo para preservar secciones y datos existentes

	# --- Progreso general ---
	cfg.set_value("progress", "unlocked_characters", GameData.unlocked_character_ids)
	cfg.set_value("progress", "unlocked_maps", GameData.unlocked_map_ids)

	# --- Economía ---
	var saved_coins: int = cfg.get_value("economy", "total_coins", 0)
	cfg.set_value("economy", "total_coins", saved_coins + GameData.session_coins)

	# --- Historia Tradicional ---
	cfg.set_value("story", "battle_index", GameData.story_battle_index)

	# --- Historia ECOS ---
	var sm = get_node_or_null("/root/StoryManager")
	var ecos_ch: int = sm.current_chapter_index if sm else cfg.get_value("story", "ecos_chapter_index", 1)
	var ecos_dec: Array = sm.decisions if sm else cfg.get_value("story", "ecos_decisions", [])
	var ecos_end: Array = sm.unlocked_endings if sm else cfg.get_value("story", "ecos_unlocked_endings", [])
	var ecos_comp: bool = sm.is_completed if sm else cfg.get_value("story", "ecos_completed", false)

	cfg.set_value("story", "ecos_chapter_index", ecos_ch)
	cfg.set_value("story", "ecos_decisions", ecos_dec)
	cfg.set_value("story", "ecos_unlocked_endings", ecos_end)
	cfg.set_value("story", "ecos_completed", ecos_comp)

	var err := cfg.save(save_path)
	if err != OK:
		push_error("SaveManager: Error al guardar (%d)." % err)
	else:
		print("SaveManager: Progreso guardado en %s." % save_path)

# ---------------------------------------------------------------------------
# Carga
# ---------------------------------------------------------------------------

## Carga el progreso desde disco e inyecta los datos en GameData y StoryManager.
## Se llama al arrancar el juego.
func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(save_path)

	if err == ERR_FILE_NOT_FOUND:
		print("SaveManager: No hay guardado previo en %s. Iniciando con valores por defecto." % save_path)
		return
	elif err != OK:
		push_error("SaveManager: Error al cargar (%d). Se usarán valores por defecto." % err)
		return

	# --- Progreso general ---
	GameData.unlocked_character_ids = cfg.get_value(
		"progress", "unlocked_characters", ["goku", "naruto", "madara"]
	)
	if not "madara" in GameData.unlocked_character_ids:
		GameData.unlocked_character_ids.append("madara")
	GameData.unlocked_map_ids = cfg.get_value(
		"progress", "unlocked_maps", ["valley_of_end", "tournament"]
	)

	# --- Historia Tradicional ---
	GameData.story_battle_index = cfg.get_value("story", "battle_index", 0)

	# --- Historia ECOS ---
	var sm = get_node_or_null("/root/StoryManager")
	if sm and sm.has_method("sync_from_save_manager"):
		sm.sync_from_save_manager()

	print("SaveManager: Progreso cargado desde %s. Monedas totales: %d | Capítulo ECOS: %d" % [
		save_path,
		get_total_coins(),
		cfg.get_value("story", "ecos_chapter_index", 1)
	])

# ---------------------------------------------------------------------------
# Consultas y Operaciones de ECOS
# ---------------------------------------------------------------------------

## Guarda específicamente el progreso del modo historia ECOS sin tocar economía ni otros campos.
func save_ecos_progress(chapter_index: int, decisions: Array, unlocked_endings: Array, completed: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(save_path)

	cfg.set_value("story", "ecos_chapter_index", chapter_index)
	cfg.set_value("story", "ecos_decisions", decisions)
	cfg.set_value("story", "ecos_unlocked_endings", unlocked_endings)
	cfg.set_value("story", "ecos_completed", completed)

	var err := cfg.save(save_path)
	if err != OK:
		push_error("SaveManager: Error al guardar progreso de ECOS (%d)." % err)
	else:
		print("SaveManager: Progreso de ECOS guardado en %s (Capítulo %d)." % [save_path, chapter_index])

## Retorna el índice de capítulo guardado de ECOS (default: 1).
func get_ecos_chapter_index() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return 1
	return cfg.get_value("story", "ecos_chapter_index", 1)

## Retorna el historial de decisiones tomadas en ECOS.
func get_ecos_decisions() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return []
	return cfg.get_value("story", "ecos_decisions", [])

## Retorna la lista de IDs de finales desbloqueados en ECOS.
func get_ecos_unlocked_endings() -> Array:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return []
	return cfg.get_value("story", "ecos_unlocked_endings", [])

## Retorna si el modo ECOS ya ha sido completado al menos una vez.
func is_ecos_completed() -> bool:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return false
	return cfg.get_value("story", "ecos_completed", false)

## Reinicia los datos de ECOS conservando monedas y personajes desbloqueados.
func reset_ecos_progress() -> void:
	save_ecos_progress(1, [], [], false)
	var sm = get_node_or_null("/root/StoryManager")
	if sm and sm.has_method("sync_from_save_manager"):
		sm.sync_from_save_manager()
	print("SaveManager: Progreso de ECOS reiniciado al Capítulo 1.")

# ---------------------------------------------------------------------------
# Consultas de Economía y Utilidades
# ---------------------------------------------------------------------------

## Retorna el total de monedas guardadas en disco (sin las de la sesión actual).
func get_total_coins() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return 0
	return cfg.get_value("economy", "total_coins", 0)

## Gasta monedas. Retorna false si no hay suficiente saldo.
func spend_coins(amount: int) -> bool:
	var current := get_total_coins()
	if current < amount:
		return false

	var cfg := ConfigFile.new()
	cfg.load(save_path)
	cfg.set_value("economy", "total_coins", current - amount)
	cfg.save(save_path)
	return true

## Elimina el archivo de guardado activo (útil para tests y 'nueva partida').
func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("SaveManager: Guardado en %s eliminado." % save_path)

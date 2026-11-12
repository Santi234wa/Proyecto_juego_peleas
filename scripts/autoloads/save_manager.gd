## save_manager.gd  — AUTOLOAD: "SaveManager"
## Gestiona el guardado y carga del progreso en disco usando ConfigFile.
## Patrón: Singleton — acceso global sin acoplamiento directo al sistema de archivos.
## ConfigFile es más robusto que JSON en Godot y soporta tipos nativos directamente.
extends Node

const SAVE_PATH: String = "user://save_data.cfg"

# ---------------------------------------------------------------------------
# Guardado
# ---------------------------------------------------------------------------

## Guarda el progreso actual desde GameData a disco.
## Se llama al salir de un combate, al comprar en la tienda, etc.
func save_game() -> void:
	var cfg := ConfigFile.new()

	# --- Progreso general ---
	cfg.set_value("progress", "unlocked_characters", GameData.unlocked_character_ids)
	cfg.set_value("progress", "unlocked_maps", GameData.unlocked_map_ids)

	# --- Economía ---
	var saved_coins: int = cfg.get_value("economy", "total_coins", 0)
	cfg.set_value("economy", "total_coins", saved_coins + GameData.session_coins)

	# --- Historia ---
	cfg.set_value("story", "battle_index", GameData.story_battle_index)

	var err := cfg.save(SAVE_PATH)
	if err != OK:
		push_error("SaveManager: Error al guardar (%d)." % err)
	else:
		print("SaveManager: Progreso guardado en %s." % SAVE_PATH)

# ---------------------------------------------------------------------------
# Carga
# ---------------------------------------------------------------------------

## Carga el progreso desde disco e inyecta los datos en GameData.
## Se llama una sola vez al arrancar el juego.
func load_game() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)

	if err == ERR_FILE_NOT_FOUND:
		print("SaveManager: No hay guardado previo. Iniciando con valores por defecto.")
		return
	elif err != OK:
		push_error("SaveManager: Error al cargar (%d). Se usarán valores por defecto." % err)
		return

	# --- Progreso general ---
	GameData.unlocked_character_ids = cfg.get_value(
		"progress", "unlocked_characters", ["goku", "naruto"]
	)
	GameData.unlocked_map_ids = cfg.get_value(
		"progress", "unlocked_maps", ["valley_of_end", "tournament"]
	)

	# --- Historia ---
	GameData.story_battle_index = cfg.get_value("story", "battle_index", 0)

	print("SaveManager: Progreso cargado. Monedas totales: %d" % get_total_coins())

# ---------------------------------------------------------------------------
# Consultas
# ---------------------------------------------------------------------------

## Retorna el total de monedas guardadas en disco (sin las de la sesión actual).
func get_total_coins() -> int:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return 0
	return cfg.get_value("economy", "total_coins", 0)

## Gasta monedas. Retorna false si no hay suficiente saldo.
func spend_coins(amount: int) -> bool:
	var current := get_total_coins()
	if current < amount:
		return false

	var cfg := ConfigFile.new()
	cfg.load(SAVE_PATH)
	cfg.set_value("economy", "total_coins", current - amount)
	cfg.save(SAVE_PATH)
	return true

## Elimina el archivo de guardado (útil para tests y "nueva partida").
func delete_save() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	print("SaveManager: Guardado eliminado.")


## game_data.gd  — AUTOLOAD: "GameData"
## Singleton que centraliza el estado de la partida en memoria.
## Patrón: Singleton (Autoload de Godot) — punto único de verdad sobre la sesión.
## NO guarda a disco; eso lo hace SaveManager. Este nodo vive entre escenas.
extends Node

# ---------------------------------------------------------------------------
# Personajes disponibles (se llena al iniciar el juego)
# ---------------------------------------------------------------------------
## Lista de todos los CharacterData registrados en el juego.
var all_characters: Array[CharacterData] = []

## Lista de ids desbloqueados por el jugador.
var unlocked_character_ids: Array[String] = ["goku", "naruto", "madara", "vegetto"]

## Lista de ids de mapas desbloqueados.
var unlocked_map_ids: Array[String] = ["valle_del_fin", "torneo", "dimension_ecos", "valley_of_end", "tournament"]

# ---------------------------------------------------------------------------
# Sesión de combate actual
# ---------------------------------------------------------------------------
var player1_data: CharacterData = null  ## Personaje elegido por P1
var player2_data: CharacterData = null  ## Personaje elegido por P2 / IA
var selected_map_id: String = "valle_del_fin"

## Resultado de la última ronda: "player1", "player2", "" (en curso)
var round_winner: String = ""

## Resultados acumulados de rondas en el combate actual.
var round_wins: Dictionary = {"player1": 0, "player2": 0}

## Rondas necesarias para ganar el combate (best-of-3 → 2). Configurable.
@export var rounds_to_win: int = 2

## Monedas acumuladas en la sesión (se suman al guardar).
var session_coins: int = 0

# ---------------------------------------------------------------------------
# Modo de juego
# ---------------------------------------------------------------------------
enum GameMode { STORY, LOCAL, VS_AI }
var current_mode: GameMode = GameMode.LOCAL

## Dificultad de la IA: 0 = fácil, 1 = normal, 2 = difícil.
var ai_difficulty: int = 1

## Índice del combate actual en el modo historia (0-4).
var story_battle_index: int = 0

# ---------------------------------------------------------------------------
# Señales de sesión (Patrón Observer)
# ---------------------------------------------------------------------------
signal round_ended(winner: String)
signal match_ended(winner: String)
signal match_finished(winner: String)
signal back_to_menu_requested()
signal coins_updated(total: int)

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

## Registra el final de una ronda y verifica si hay ganador de partida.
func report_round_winner(winner_key: String) -> void:
	round_winner = winner_key
	round_wins[winner_key] = round_wins.get(winner_key, 0) + 1
	emit_signal("round_ended", winner_key)

	if round_wins[winner_key] >= rounds_to_win:
		emit_signal("match_finished", winner_key)
		emit_signal("match_ended", winner_key)
		# En el modo historia ECOS, StoryManager procesa el resultado sin mostrar la UI de victoria local
		if current_mode != GameMode.STORY:
			_spawn_victory_screen(winner_key)

## Retorna el nombre en pantalla del personaje ganador leyendo su CharacterData (Resource).
func get_character_display_name(winner_key: String) -> String:
	var target_pid: int = 1 if winner_key == "player1" else 2
	var pdata = player1_data if target_pid == 1 else player2_data
	if pdata and pdata.display_name != "":
		return pdata.display_name

	var tree := get_tree()
	if tree and tree.current_scene:
		for node in tree.current_scene.find_children("*", "CharacterBase", true, false):
			if node.get("player_id") == target_pid and not node.name.to_lower().begins_with("dummy"):
				if node.get("data") and node.data and node.data.display_name != "":
					return node.data.display_name
				return node.name.capitalize()

	return "Jugador 1" if target_pid == 1 else "Jugador 2"

func _spawn_victory_screen(winner_key: String) -> void:
	var tree := get_tree()
	if not tree:
		return
	if tree.root.has_node("VictoryScreenLayer"):
		return

	var vscreen = preload("res://scripts/ui/victory_screen_ui.gd").new()
	vscreen.name = "VictoryScreenLayer"
	tree.root.add_child(vscreen)
	vscreen.setup_victory(winner_key)

## Reinicia contadores de ronda (entre combates de historia, por ejemplo).
func reset_match() -> void:
	round_wins = {"player1": 0, "player2": 0}
	round_winner = ""
	session_coins = 0

## Añade monedas y emite señal para que la UI se actualice.
func add_coins(amount: int) -> void:
	session_coins += amount
	emit_signal("coins_updated", session_coins)

## Verifica si un personaje está desbloqueado.
func is_character_unlocked(id: String) -> bool:
	return id in unlocked_character_ids

## Desbloquea un personaje (lo llama ShopManager después de confirmar el pago).
func unlock_character(id: String) -> void:
	if not is_character_unlocked(id):
		unlocked_character_ids.append(id)

## Verifica si un mapa está desbloqueado.
func is_map_unlocked(id: String) -> bool:
	return id in unlocked_map_ids

## Desbloquea un mapa.
func unlock_map(id: String) -> void:
	if not is_map_unlocked(id):
		unlocked_map_ids.append(id)


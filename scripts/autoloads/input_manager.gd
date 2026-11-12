## input_manager.gd  — AUTOLOAD: "InputManager"
## Centraliza la lectura de inputs para P1 y P2.
## Razón: en modo local ambos jugadores usan el mismo teclado con distintos mapeos.
## Desacopla el código de personajes del nombre concreto de las acciones de InputMap.
extends Node

# ---------------------------------------------------------------------------
# Mapeo de acciones por jugador
# Las acciones deben existir en Project → Input Map (instrucciones en el README).
# ---------------------------------------------------------------------------
const ACTIONS: Dictionary = {
	1: {
		"left":      "p1_left",
		"right":     "p1_right",
		"jump":      "p1_jump",
		"attack":    "p1_attack",
		"special":   "p1_special",
		"block":     "p1_block",
		"transform": "p1_transform",
	},
	2: {
		"left":      "p2_left",
		"right":     "p2_right",
		"jump":      "p2_jump",
		"attack":    "p2_attack",
		"special":   "p2_special",
		"block":     "p2_block",
		"transform": "p2_transform",
	},
}

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

## Retorna true si la acción está siendo sostenida en este frame.
func is_action_held(player_id: int, action: String) -> bool:
	var mapped := _get_action(player_id, action)
	return Input.is_action_pressed(mapped) if mapped else false

## Retorna true si la acción fue presionada ESTE frame (flanco de subida).
func is_action_just_pressed(player_id: int, action: String) -> bool:
	var mapped := _get_action(player_id, action)
	return Input.is_action_just_pressed(mapped) if mapped else false

## Retorna el eje horizontal como float (-1, 0, +1).
func get_horizontal_axis(player_id: int) -> float:
	var right := is_action_held(player_id, "right")
	var left := is_action_held(player_id, "left")
	return float(int(right) - int(left))

# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

func _get_action(player_id: int, action: String) -> String:
	if not ACTIONS.has(player_id):
		push_error("InputManager: player_id %d no válido." % player_id)
		return ""
	if not ACTIONS[player_id].has(action):
		push_error("InputManager: acción '%s' no registrada para P%d." % [action, player_id])
		return ""
	return ACTIONS[player_id][action]


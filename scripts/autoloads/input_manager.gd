## input_manager.gd  — AUTOLOAD: "InputManager"
## Centraliza la lectura de inputs para P1 y P2.
extends Node

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

func _ready() -> void:
	_register_default_p2_actions()

## Registra automáticamente los controles por defecto de Player 2 si no están configurados en project.godot
func _register_default_p2_actions() -> void:
	var defaults: Dictionary = {
		"p2_left":      [KEY_LEFT],
		"p2_right":     [KEY_RIGHT],
		"p2_jump":      [KEY_UP],
		"p2_block":     [KEY_DOWN],
		"p2_attack":    [KEY_K, KEY_KP_1],
		"p2_special":   [KEY_L, KEY_KP_2],
		"p2_transform": [KEY_P, KEY_KP_3],
	}

	for action_name in defaults:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in defaults[action_name]:
				var event := InputEventKey.new()
				event.physical_keycode = key_code
				InputMap.action_add_event(action_name, event)

## Retorna true si la acción está siendo sostenida en este frame.
func is_action_held(player_id: int, action: String) -> bool:
	var mapped: String = _get_action(player_id, action)
	if mapped == "" or not InputMap.has_action(mapped):
		return false
	return Input.is_action_pressed(mapped)

## Retorna true si la acción fue presionada ESTE frame.
func is_action_just_pressed(player_id: int, action: String) -> bool:
	var mapped: String = _get_action(player_id, action)
	if mapped == "" or not InputMap.has_action(mapped):
		return false
	return Input.is_action_just_pressed(mapped)

## Retorna el eje horizontal como float (-1, 0, +1).
func get_horizontal_axis(player_id: int) -> float:
	var right: bool = is_action_held(player_id, "right")
	var left: bool = is_action_held(player_id, "left")
	return float(int(right) - int(left))

func _get_action(player_id: int, action: String) -> String:
	if not ACTIONS.has(player_id):
		return ""
	if not ACTIONS[player_id].has(action):
		return ""
	return ACTIONS[player_id][action]

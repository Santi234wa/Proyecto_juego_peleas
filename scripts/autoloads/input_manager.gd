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
		"ultimate":  "p1_ultimate",
	},
	2: {
		"left":      "p2_left",
		"right":     "p2_right",
		"jump":      "p2_jump",
		"attack":    "p2_attack",
		"special":   "p2_special",
		"block":     "p2_block",
		"transform": "p2_transform",
		"ultimate":  "p2_ultimate",
	},
}

# Estado de control por IA (por jugador)
var _ai_active: Dictionary = {1: false, 2: false}
var _ai_held: Dictionary = {1: {}, 2: {}}
var _ai_just_pressed: Dictionary = {1: {}, 2: {}}
var _ai_axis: Dictionary = {1: 0.0, 2: 0.0}

func _ready() -> void:
	_register_default_p2_actions()

func _unhandled_input(event: InputEvent) -> void:
	# Tecla F1: alternar control de IA para Jugador 2 (atajo rápido de desarrollo)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			set_player_ai(2, not is_player_ai(2))

## Registra automáticamente los controles por defecto de Player 1 y 2 si no están configurados en project.godot
func _register_default_p2_actions() -> void:
	var defaults: Dictionary = {
		"p1_special":   [KEY_G, KEY_R],
		"p1_ultimate":  [KEY_U, KEY_Y],
		"p2_left":      [KEY_LEFT],
		"p2_right":     [KEY_RIGHT],
		"p2_jump":      [KEY_UP],
		"p2_block":     [KEY_DOWN],
		"p2_attack":    [KEY_K, KEY_KP_1],
		"p2_special":   [KEY_L, KEY_KP_2],
		"p2_transform": [KEY_P, KEY_KP_3],
		"p2_ultimate":  [KEY_O, KEY_KP_4, KEY_KP_5, KEY_KP_ENTER],
	}

	for action_name in defaults:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)
			for key_code in defaults[action_name]:
				var event := InputEventKey.new()
				event.physical_keycode = key_code
				InputMap.action_add_event(action_name, event)

# ---------------------------------------------------------------------------
# API de Control por IA Virtual
# ---------------------------------------------------------------------------

func set_player_ai(player_id: int, enabled: bool) -> void:
	_ai_active[player_id] = enabled
	if not enabled:
		_ai_held[player_id] = {}
		_ai_just_pressed[player_id] = {}
		_ai_axis[player_id] = 0.0

	# Sincronizar dinámicamente con los luchadores presentes en escena
	var tree := get_tree()
	if tree:
		for fighter in tree.get_nodes_in_group("fighters"):
			if fighter is CharacterBase and fighter.player_id == player_id:
				if enabled:
					if not fighter.has_node("EnemyAI"):
						fighter._setup_ai()
					else:
						var ai = fighter.get_node_or_null("EnemyAI")
						if ai:
							ai.set("enabled", true)
							ai.set_physics_process(true)
				else:
					var ai = fighter.get_node_or_null("EnemyAI")
					if ai:
						ai.set("enabled", false)
						ai.set_physics_process(false)

	print("[InputManager] 🤖 Control por IA para Jugador %d: %s" % [player_id, "ACTIVADO" if enabled else "DESACTIVADO"])

func is_player_ai(player_id: int) -> bool:
	return _ai_active.get(player_id, false)

func set_ai_horizontal_axis(player_id: int, axis: float) -> void:
	_ai_axis[player_id] = clampf(axis, -1.0, 1.0)

func set_ai_action_held(player_id: int, action: String, held: bool) -> void:
	if not _ai_held.has(player_id):
		_ai_held[player_id] = {}
	_ai_held[player_id][action] = held

func trigger_ai_action(player_id: int, action: String) -> void:
	if not _ai_just_pressed.has(player_id):
		_ai_just_pressed[player_id] = {}
	_ai_just_pressed[player_id][action] = true

# ---------------------------------------------------------------------------
# Consultas de Input
# ---------------------------------------------------------------------------

## Retorna true si la acción está siendo sostenida en este frame.
func is_action_held(player_id: int, action: String) -> bool:
	if _ai_active.get(player_id, false):
		return _ai_held.get(player_id, {}).get(action, false)

	var mapped: String = _get_action(player_id, action)
	if mapped == "" or not InputMap.has_action(mapped):
		return false
	return Input.is_action_pressed(mapped)

## Retorna true si la acción fue presionada ESTE frame.
func is_action_just_pressed(player_id: int, action: String) -> bool:
	if _ai_active.get(player_id, false):
		if _ai_just_pressed.get(player_id, {}).get(action, false):
			_ai_just_pressed[player_id][action] = false # One-shot consumido
			return true
		return false

	var mapped: String = _get_action(player_id, action)
	if mapped == "" or not InputMap.has_action(mapped):
		return false
	return Input.is_action_just_pressed(mapped)

## Retorna el eje horizontal como float (-1, 0, +1).
func get_horizontal_axis(player_id: int) -> float:
	if _ai_active.get(player_id, false):
		return _ai_axis.get(player_id, 0.0)

	var right: bool = is_action_held(player_id, "right")
	var left: bool = is_action_held(player_id, "left")
	return float(int(right) - int(left))

func _get_action(player_id: int, action: String) -> String:
	if not ACTIONS.has(player_id):
		return ""
	if not ACTIONS[player_id].has(action):
		return ""
	return ACTIONS[player_id][action]

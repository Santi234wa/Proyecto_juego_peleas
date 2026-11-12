## state_machine.gd
## Máquina de estados finitos (FSM) genérica y reutilizable.
## Patrón: State — desacopla la lógica de cada estado del nodo que los usa.
##
## NOTA: 'current_state' es sin tipo explícito (CharacterState en runtime)
## para evitar la dependencia circular CharacterBase → StateMachine → CharacterState.
class_name StateMachine
extends Node

## Estado actualmente activo. Es CharacterState en runtime.
var current_state = null

## Diccionario nombre_nodo → nodo_estado. Se construye en init().
var _states: Dictionary = {}

## Emitida al cambiar de estado. Útil para debug y animaciones externas.
signal state_changed(previous: String, next: String)

# ---------------------------------------------------------------------------
# Inicialización
# ---------------------------------------------------------------------------

## Registra todos los estados hijos, inyecta referencias y entra al estado inicial.
## Llamar desde el personaje en _ready().
func init(owner_character, initial_state_name: String) -> void:
	for child in get_children():
		if child is CharacterState:
			child.character    = owner_character
			child.state_machine = self
			_states[child.name] = child

	if _states.has(initial_state_name):
		current_state = _states[initial_state_name]
		current_state.enter()
	else:
		push_error("StateMachine: Estado inicial '%s' no encontrado. Disponibles: %s"
				   % [initial_state_name, _states.keys()])

# ---------------------------------------------------------------------------
# Actualización — llamar desde el personaje
# ---------------------------------------------------------------------------

func physics_update(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func process_update(delta: float) -> void:
	if current_state:
		current_state.process_update(delta)

func handle_input(event: InputEvent) -> void:
	if current_state:
		var next: String = current_state.handle_input(event)
		if next != "":
			transition_to(next)

# ---------------------------------------------------------------------------
# Transición entre estados
# ---------------------------------------------------------------------------

## Cambia al estado indicado. Los estados deben hacer 'return' justo después.
func transition_to(state_name: String) -> void:
	if not _states.has(state_name):
		push_error("StateMachine: Estado '%s' no existe. Disponibles: %s"
				   % [state_name, _states.keys()])
		return

	var previous_name: String = current_state.name if current_state else ""

	# No re-entrar al mismo estado
	if previous_name == state_name:
		return

	if current_state:
		current_state.exit()

	current_state = _states[state_name]
	current_state.enter()
	emit_signal("state_changed", previous_name, state_name)

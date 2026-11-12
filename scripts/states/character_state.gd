## character_state.gd
## Clase base para todos los estados de la máquina de estados del personaje.
## Patrón: State Pattern.
##
## NOTA DE ARQUITECTURA: 'character' y 'state_machine' son intencionalmente
## sin anotación de tipo para evitar dependencias circulares en tiempo de parseo:
##   CharacterState → CharacterBase → StateMachine → CharacterState (ciclo)
## A nivel de runtime los tipos son correctos; GDScript usa duck typing aquí.
class_name CharacterState
extends Node

## CharacterBase en runtime. Sin anotación de tipo para evitar ciclo de parseo.
var character = null

## StateMachine en runtime. Sin anotación de tipo para evitar ciclo de parseo.
var state_machine = null

# ---------------------------------------------------------------------------
# Interfaz que cada estado concreto sobreescribe
# ---------------------------------------------------------------------------

## Llamado al entrar al estado: inicializa animación, timers y flags.
func enter() -> void:
	pass

## Llamado en _physics_process: movimiento, gravedad y transiciones.
## REGLA: llamar 'return' inmediatamente después de state_machine.transition_to().
func physics_update(_delta: float) -> void:
	pass

## Llamado en _process: lógica visual que no necesita física.
func process_update(_delta: float) -> void:
	pass

## Llamado al salir del estado: limpia flags, desactiva hitboxes, etc.
func exit() -> void:
	pass

## Recibe InputEvent discretos. Retorna nombre del siguiente estado o "".
func handle_input(_event: InputEvent) -> String:
	return ""

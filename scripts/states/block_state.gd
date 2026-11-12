## block_state.gd
## Estado de guardia/bloqueo del personaje.
## Reduce el daño recibido al 50% y deshabilita ataques y movimiento.
## Transiciones: Idle (al soltar la tecla de bloqueo).
class_name BlockState
extends CharacterState

const GRAVITY: float = 980.0

func enter() -> void:
	character.is_blocked = true
	character.velocity.x = 0.0
	character.play_animation("block")
	# Tinte azulado de guardia como feedback visual si no hay sprite específico
	character.modulate = Color(0.6, 0.85, 1.0)

func physics_update(delta: float) -> void:
	# Gravedad si cae en el aire
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0

	# REGLA: No se puede atacar ni desplazarse mientras bloquea.
	# Si el jugador suelta el botón de bloqueo, regresa a Idle
	if not InputManager.is_action_held(character.player_id, "block"):
		state_machine.transition_to("Idle")
		return

func exit() -> void:
	character.is_blocked = false
	character.modulate = Color(1.0, 1.0, 1.0)


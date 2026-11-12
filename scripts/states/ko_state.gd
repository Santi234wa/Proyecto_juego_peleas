## ko_state.gd
## El personaje ha muerto. Permanece en el suelo sin responder a inputs.
## La señal character_died ya fue emitida en CharacterBase.take_damage().
## El sistema de rondas (Phase 3+) escucha esa señal y reinicia el combate.
class_name KOState
extends CharacterState

const GRAVITY: float = 980.0

func enter() -> void:
	character.velocity = Vector2.ZERO
	character.play_animation("ko")

func physics_update(delta: float) -> void:
	# Mantener el personaje en el suelo
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0
	# No hay transiciones desde KO; el sistema de rondas reinicia la escena.

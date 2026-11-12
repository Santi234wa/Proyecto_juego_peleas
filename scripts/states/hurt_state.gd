## hurt_state.gd
## El personaje recibió un golpe: animación de daño + hitstun + knockback.
## Transiciones: Idle (al terminar el hitstun).
class_name HurtState
extends CharacterState

const GRAVITY: float = 980.0

var _timer: float = 0.0

func enter() -> void:
	_timer = character.data.hurt_duration if character.data else 0.4
	character.play_animation("hurt")

	# Knockback: empujar en la dirección opuesta a la que mira el personaje.
	var knockback_dir: float = -1.0 if character.is_facing_right else 1.0
	character.velocity.x = knockback_dir * 150.0

func physics_update(delta: float) -> void:
	# ── Gravedad ──────────────────────────────────────────────────────────
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	# Desacelerar el knockback suavemente
	character.velocity.x = move_toward(character.velocity.x, 0.0, 300.0 * delta)

	_timer -= delta
	if _timer <= 0.0:
		state_machine.transition_to("Idle")
		return

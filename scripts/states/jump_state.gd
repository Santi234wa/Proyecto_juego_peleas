## jump_state.gd
## El personaje está en el aire: gestiona ascenso, cénit y aterrizaje.
## Transiciones: Idle o Walk (al aterrizar), Attack (ataque aéreo).
class_name JumpState
extends CharacterState

const GRAVITY: float = 980.0

func enter() -> void:
	# Fuerza de salto: valor negativo porque en Godot Y+ = hacia abajo.
	var jump_force: float = character.data.jump_force if character.data else -680.0
	character.velocity.y = jump_force
	character.play_animation("jump")

func physics_update(delta: float) -> void:
	# ── Gravedad (siempre en el aire) ─────────────────────────────────────
	character.velocity.y += GRAVITY * delta

	# ── Movimiento horizontal en el aire ──────────────────────────────────
	var h: float = InputManager.get_horizontal_axis(character.player_id)
	character.velocity.x = h * character.get_effective_speed()
	if h != 0.0:
		character.set_facing(h > 0.0)

	# ── Ataque aéreo ──────────────────────────────────────────────────────
	if InputManager.is_action_just_pressed(character.player_id, "attack"):
		state_machine.transition_to("Attack")
		return

	# ── Aterrizaje ────────────────────────────────────────────────────────
	# is_on_floor() usa el resultado de move_and_slide() del frame anterior,
	# lo cual es el comportamiento estándar en Godot.
	if character.is_on_floor():
		character.velocity.y = 0.0
		var h2: float = InputManager.get_horizontal_axis(character.player_id)
		if h2 != 0.0:
			state_machine.transition_to("Walk")
		else:
			state_machine.transition_to("Idle")
		return

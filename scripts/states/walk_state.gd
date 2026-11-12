## walk_state.gd
## El personaje camina horizontalmente en el suelo.
## Transiciones: Idle (eje = 0), Jump, Attack.
class_name WalkState
extends CharacterState

const GRAVITY: float = 980.0

func enter() -> void:
	character.play_animation("walk")

func physics_update(delta: float) -> void:
	# ── Gravedad ──────────────────────────────────────────────────────────
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	# ── Movimiento horizontal ─────────────────────────────────────────────
	var h: float = InputManager.get_horizontal_axis(character.player_id)

	if h == 0.0:
		state_machine.transition_to("Idle")
		return

	character.velocity.x = h * character.get_effective_speed()
	character.set_facing(h > 0.0)

	# ── Otras transiciones ────────────────────────────────────────────────
	if character.is_on_floor() and InputManager.is_action_just_pressed(character.player_id, "jump"):
		state_machine.transition_to("Jump")
		return

	if InputManager.is_action_just_pressed(character.player_id, "attack"):
		state_machine.transition_to("Attack")
		return

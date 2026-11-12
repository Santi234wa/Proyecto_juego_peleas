## idle_state.gd
## El personaje está quieto en el suelo, esperando input.
## Transiciones: Walk, Jump, Attack.
class_name IdleState
extends CharacterState

## Constante local para evitar referencia circular a CharacterBase.GRAVITY
const GRAVITY: float = 980.0

func enter() -> void:
	character.velocity.x = 0.0
	character.play_animation("idle")

func physics_update(delta: float) -> void:
	# ── Gravedad ──────────────────────────────────────────────────────────
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	# ── Transiciones (de mayor a menor prioridad) ─────────────────────────

	var h: float = InputManager.get_horizontal_axis(character.player_id)
	if h != 0.0:
		state_machine.transition_to("Walk")
		return  # SIEMPRE 'return' después de transition_to()

	if character.is_on_floor() and InputManager.is_action_just_pressed(character.player_id, "jump"):
		state_machine.transition_to("Jump")
		return

	if InputManager.is_action_just_pressed(character.player_id, "attack"):
		state_machine.transition_to("Attack")
		return

## idle_state.gd
## El personaje está quieto en el suelo, esperando input.
## Transiciones: Walk, Jump, Attack, Blocking.
class_name IdleState
extends CharacterState

const GRAVITY: float = 980.0

func enter() -> void:
	character.velocity.x = 0.0
	character.play_animation("idle")

func physics_update(delta: float) -> void:
	# Gravedad
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	# ── Prioridad de transiciones ─────────────────────────────────────────

	# 1. Transformación (tecla H: si tiene Ki suficiente y no está en cooldown)
	if InputManager.is_action_just_pressed(character.player_id, "transform"):
		if character.can_transform():
			state_machine.transition_to("Transforming")
			return

	# 2. Bloqueo (guardia sostenida con S)
	if InputManager.is_action_held(character.player_id, "block"):
		state_machine.transition_to("Blocking")
		return

	# 3. Movimiento horizontal → Walk
	var h: float = InputManager.get_horizontal_axis(character.player_id)
	if h != 0.0:
		state_machine.transition_to("Walk")
		return

	# 4. Salto
	if character.is_on_floor() and InputManager.is_action_just_pressed(character.player_id, "jump"):
		state_machine.transition_to("Jump")
		return

	# 5. Ataque básico
	if InputManager.is_action_just_pressed(character.player_id, "attack"):
		state_machine.transition_to("Attack")
		return

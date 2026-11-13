## goku.gd
## Personaje Goku. Extiende CharacterBase y configura su FSM.
## Los stats y datos están en resources/characters/goku.tres (CharacterData).
class_name Goku
extends CharacterBase

const GokuSpecialStateRef = preload("res://scripts/states/goku_special_state.gd")

func _setup_state_machine() -> void:
	if not state_machine:
		push_error("Goku: No se encontró el nodo 'StateMachine'. Revisar goku.tscn.")
		return

	# Resguardo de seguridad: si el nodo 'Transforming' aún no está en la escena goku.tscn,
	# se instancia dinámicamente para que la FSM lo reconozca de inmediato.
	if not state_machine.has_node("Transforming"):
		var trans_node = TransformingState.new()
		trans_node.name = "Transforming"
		state_machine.add_child(trans_node)

	# Estado de Ataque Especial: Ráfaga Kamehameha Azul
	if not state_machine.has_node("Special"):
		var sp_node := GokuSpecialStateRef.new()
		sp_node.name = "Special"
		state_machine.add_child(sp_node)
	elif not (state_machine.get_node("Special") is GokuSpecialStateRef):
		var old_sp = state_machine.get_node("Special")
		old_sp.name = "OldSpecial"
		old_sp.queue_free()
		var sp_node := GokuSpecialStateRef.new()
		sp_node.name = "Special"
		state_machine.add_child(sp_node)

	if not state_machine.has_node("Ultimate"):
		var ult_node := UltimateState.new()
		ult_node.name = "Ultimate"
		state_machine.add_child(ult_node)

	state_machine.init(self, "Idle")

	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

func _physics_process(delta: float) -> void:
	# Disparo de Ráfaga Kamehameha desde estados libres (Idle/Walk)
	if state_machine and state_machine.current_state:
		var s_name: String = state_machine.current_state.name
		if s_name in ["Idle", "Walk"]:
			if InputManager.is_action_just_pressed(player_id, "special"):
				var cost: float = data.energy_cost_special if data else 20.0
				if current_energy >= cost:
					state_machine.transition_to("Special")
					return

	super._physics_process(delta)

func _on_state_changed(previous: String, next: String) -> void:
	print("[Goku P%d] %s → %s" % [player_id, previous, next])

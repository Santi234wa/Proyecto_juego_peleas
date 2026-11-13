## goku.gd
## Personaje Goku. Extiende CharacterBase y configura su FSM.
## Los stats y datos están en resources/characters/goku.tres (CharacterData).
class_name Goku
extends CharacterBase

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

	if not state_machine.has_node("Ultimate"):
		var ult_node := UltimateState.new()
		ult_node.name = "Ultimate"
		state_machine.add_child(ult_node)

	state_machine.init(self, "Idle")

	# Debug: imprimir cada transición en la consola para verificar la FSM.
	# Remover antes de la entrega final si genera ruido.
	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(previous: String, next: String) -> void:
	print("[Goku P%d] %s → %s" % [player_id, previous, next])

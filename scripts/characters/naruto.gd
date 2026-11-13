## naruto.gd
## Personaje Naruto Uzumaki. Extiende CharacterBase y configura su FSM.
## Los stats y datos residen en resources/characters/naruto.tres (CharacterData).
class_name Naruto
extends CharacterBase

func _ready() -> void:
	# Por defecto, Naruto inicia como Jugador 2 en modo versus
	if player_id == 1:
		player_id = 2
	super._ready()

func _setup_state_machine() -> void:
	if not state_machine:
		push_error("Naruto: No se encontró el nodo 'StateMachine'. Revisar naruto.tscn.")
		return

	# Fallback de seguridad: instanciar Transforming si aún no está en la escena
	if not state_machine.has_node("Transforming"):
		var trans_node = TransformingState.new()
		trans_node.name = "Transforming"
		state_machine.add_child(trans_node)

	state_machine.init(self, "Idle")

	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(previous: String, next: String) -> void:
	print("[Naruto P%d] %s → %s" % [player_id, previous, next])

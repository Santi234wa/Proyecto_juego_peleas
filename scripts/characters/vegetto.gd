## vegetto.gd
## Personaje Vegetto. Extiende CharacterBase y configura su FSM de combate.
## El luchador definitivo del juego: máxima potencia base, sin transformación,
## combo ofensivo dinámico y letal Ataque de Energía (VegettoKiBlast).
class_name Vegetto
extends CharacterBase

const VegettoAttackStateRef = preload("res://scripts/states/vegetto_attack_state.gd")
const VegettoKiStateRef = preload("res://scripts/states/vegetto_ki_state.gd")

func _ready() -> void:
	super._ready()

func _setup_state_machine() -> void:
	if not state_machine:
		push_error("Vegetto: No se encontró el nodo 'StateMachine'. Revisar vegetto.tscn.")
		return

	# Estado de Ataque con combo fluido (punch_1 -> punch_2 -> kick -> combo)
	if not state_machine.has_node("Attack"):
		var atk_node = VegettoAttackStateRef.new()
		atk_node.name = "Attack"
		state_machine.add_child(atk_node)
	elif not (state_machine.get_node("Attack") is VegettoAttackStateRef):
		var old_atk = state_machine.get_node("Attack")
		old_atk.name = "OldAttack"
		old_atk.queue_free()
		var atk_node = VegettoAttackStateRef.new()
		atk_node.name = "Attack"
		state_machine.add_child(atk_node)

	# Estado de Ataque Especial de Ki (Ataque de Energía)
	if not state_machine.has_node("Special"):
		var ki_node = VegettoKiStateRef.new()
		ki_node.name = "Special"
		state_machine.add_child(ki_node)
	elif not (state_machine.get_node("Special") is VegettoKiStateRef):
		var old_ki = state_machine.get_node("Special")
		old_ki.name = "OldSpecial"
		old_ki.queue_free()
		var ki_node = VegettoKiStateRef.new()
		ki_node.name = "Special"
		state_machine.add_child(ki_node)

	# Remover estado de transformación si existe en la jerarquía
	if state_machine.has_node("Transforming"):
		var old_t = state_machine.get_node("Transforming")
		old_t.name = "OldTransforming"
		old_t.queue_free()

	state_machine.init(self, "Idle")

	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

func _physics_process(delta: float) -> void:
	# Disparo de Ataque de Energía desde estados libres (Idle/Walk)
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
	print("[Vegetto P%d] %s → %s" % [player_id, previous, next])

## Vegetto no tiene transformación: ya posee el poder máximo definitivo
func can_transform() -> bool:
	return false

func begin_transform() -> bool:
	return false

# ---------------------------------------------------------------------------
# Hooks de Audio y Efectos
# ---------------------------------------------------------------------------

func on_attack_connected() -> void:
	var hit_node = get_node_or_null("SFX/Hit")
	if hit_node and hit_node is AudioStreamPlayer2D and hit_node.stream:
		hit_node.play()
	elif AudioManager and data and data.sfx_basic_attack:
		AudioManager.play_sfx(data.sfx_basic_attack)

func on_ki_projectile_spawned() -> void:
	var ki_node = get_node_or_null("SFX/KiShoot")
	if ki_node and ki_node is AudioStreamPlayer2D and ki_node.stream:
		ki_node.play()
	elif AudioManager and data and data.sfx_special_attack:
		AudioManager.play_sfx(data.sfx_special_attack)

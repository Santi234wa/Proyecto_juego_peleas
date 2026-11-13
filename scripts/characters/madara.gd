## madara.gd
## Personaje Madara Uchiha. Extiende CharacterBase y configura su FSM.
## Los stats y datos residen en resources/characters/madara.tres (CharacterData).
class_name Madara
extends CharacterBase

const MadaraAttackStateRef = preload("res://scripts/states/madara_attack_state.gd")
const SharinganTransformingStateRef = preload("res://scripts/states/sharingan_transforming_state.gd")

var _sharingan_particles: CPUParticles2D = null

func _ready() -> void:
	# Por defecto, Madara puede iniciar como P2 en combate versus
	super._ready()
	_setup_sharingan_aura()

func _setup_state_machine() -> void:
	if not state_machine:
		push_error("Madara: No se encontró el nodo 'StateMachine'. Revisar madara.tscn.")
		return

	# Estado de Ataque con combo de 3 golpes (Punch 1 -> Punch 2 -> Kick -> repeat)
	if not state_machine.has_node("Attack"):
		var atk_node = MadaraAttackStateRef.new()
		atk_node.name = "Attack"
		state_machine.add_child(atk_node)
	elif not (state_machine.get_node("Attack") is MadaraAttackStateRef):
		var old_atk = state_machine.get_node("Attack")
		old_atk.name = "OldAttack"
		old_atk.queue_free()
		var atk_node = MadaraAttackStateRef.new()
		atk_node.name = "Attack"
		state_machine.add_child(atk_node)

	# Estado de Transformación Sharingan
	if not state_machine.has_node("Transforming"):
		var trans_node = SharinganTransformingStateRef.new()
		trans_node.name = "Transforming"
		state_machine.add_child(trans_node)

	# Estado Ultimate
	if not state_machine.has_node("Ultimate"):
		var ult_node := UltimateState.new()
		ult_node.name = "Ultimate"
		state_machine.add_child(ult_node)

	state_machine.init(self, "Idle")

	if not state_machine.state_changed.is_connected(_on_state_changed):
		state_machine.state_changed.connect(_on_state_changed)

func _on_state_changed(previous: String, next: String) -> void:
	print("[Madara P%d] %s → %s" % [player_id, previous, next])

func _setup_sharingan_aura() -> void:
	if _sharingan_particles and is_instance_valid(_sharingan_particles):
		return
	_sharingan_particles = CPUParticles2D.new()
	_sharingan_particles.name = "SharinganAura"
	_sharingan_particles.amount = 35
	_sharingan_particles.lifetime = 0.8
	_sharingan_particles.direction = Vector2.UP
	_sharingan_particles.spread = 35.0
	_sharingan_particles.gravity = Vector2(0, -10)
	_sharingan_particles.initial_velocity_min = 35.0
	_sharingan_particles.initial_velocity_max = 85.0
	_sharingan_particles.scale_amount_min = 2.0
	_sharingan_particles.scale_amount_max = 4.2
	_sharingan_particles.color = Color(1.0, 0.08, 0.15, 0.85)
	_sharingan_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_sharingan_particles.emission_rect_extents = Vector2(12, 4)
	_sharingan_particles.position = Vector2(0, 20)
	_sharingan_particles.emitting = false
	add_child(_sharingan_particles)

func finish_transform() -> void:
	super.finish_transform()
	modulate = Color(1.15, 0.90, 0.92, 1.0)
	if _sharingan_particles:
		_sharingan_particles.emitting = true

func end_transformation() -> void:
	super.end_transformation()
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	if _sharingan_particles:
		_sharingan_particles.emitting = false

## Mecánica de Semi-Jefe Sharingan:
## - Lectura Uchiha: reduce el daño recibido un 30% mientras está transformado.
## - Super-Armor: durante la ejecución de ataques en Sharingan no es interrumpido (no entra a Hurt).
func take_damage(amount: float) -> void:
	if invulnerable:
		return

	var effective: float = amount
	if is_transformed:
		effective = amount * 0.70

	# Super-Armor en Sharingan si está atacando
	if is_transformed and state_machine and state_machine.current_state and state_machine.current_state.name == "Attack":
		var max_hp: float = data.max_health if data else 100.0
		var final_dmg: float = effective * 0.5 if is_blocked else effective
		current_health = maxf(0.0, current_health - final_dmg)
		emit_signal("health_changed", current_health, max_hp)
		_flash_hit()
		if current_health <= 0.0:
			emit_signal("character_died")
			state_machine.transition_to("KO")
		return

	super.take_damage(effective)

func play_animation(anim_name: String) -> void:
	# Fallback inteligente si se invoca 'attack' genérico
	if anim_name == "attack":
		var atk_state = state_machine.get_node_or_null("Attack") if state_machine else null
		if atk_state and atk_state is MadaraAttackStateRef:
			super.play_animation(atk_state._step_anim)
			return
		elif _animated_sprite and _animated_sprite.sprite_frames and _animated_sprite.sprite_frames.has_animation("punch_1"):
			super.play_animation("punch_1")
			return
	super.play_animation(anim_name)

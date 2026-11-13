## vegetto.gd
## Personaje Vegetto. Extiende CharacterBase y configura su FSM de combate.
## Integra combo de 4 golpes, ataque especial de Ki, transformación en Super Saiyajin
## y hooks para sistema de audio profesional con fallback tolerante.
class_name Vegetto
extends CharacterBase

const VegettoAttackStateRef = preload("res://scripts/states/vegetto_attack_state.gd")
const VegettoKiStateRef = preload("res://scripts/states/vegetto_ki_state.gd")
const VegettoTransformingStateRef = preload("res://scripts/states/vegetto_transforming_state.gd")

var _ssj_particles: CPUParticles2D = null

func _ready() -> void:
	super._ready()
	_setup_ssj_aura()

func _setup_state_machine() -> void:
	if not state_machine:
		push_error("Vegetto: No se encontró el nodo 'StateMachine'. Revisar vegetto.tscn.")
		return

	# Estado de Ataque con combo de 4 golpes
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

	# Estado de Ataque Especial de Ki
	if not state_machine.has_node("Special"):
		var ki_node = VegettoKiStateRef.new()
		ki_node.name = "Special"
		state_machine.add_child(ki_node)

	# Estado de Transformación en Super Saiyajin
	if not state_machine.has_node("Transforming"):
		var trans_node = VegettoTransformingStateRef.new()
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

func _physics_process(delta: float) -> void:
	# Permitir transición a Ataque Especial desde estados libres (Idle/Walk)
	if state_machine and state_machine.current_state:
		var s_name: String = state_machine.current_state.name
		if s_name in ["Idle", "Walk"]:
			if InputManager.is_action_just_pressed(player_id, "special"):
				if current_energy >= (data.energy_cost_special if data else 20.0):
					state_machine.transition_to("Special")
					return

	super._physics_process(delta)

func _on_state_changed(previous: String, next: String) -> void:
	print("[Vegetto P%d] %s → %s" % [player_id, previous, next])
	if next == "Idle" and is_transformed:
		if _ssj_particles:
			_ssj_particles.emitting = true

# ---------------------------------------------------------------------------
# Aura de Super Saiyajin
# ---------------------------------------------------------------------------

func _setup_ssj_aura() -> void:
	if _ssj_particles and is_instance_valid(_ssj_particles):
		return
	_ssj_particles = CPUParticles2D.new()
	_ssj_particles.name = "SSJAura"
	_ssj_particles.amount = 26
	_ssj_particles.lifetime = 0.55
	_ssj_particles.explosiveness = 0.0
	_ssj_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_ssj_particles.emission_rect_extents = Vector2(16.0, 22.0)
	_ssj_particles.direction = Vector2(0, -1)
	_ssj_particles.spread = 15.0
	_ssj_particles.gravity = Vector2(0, -180.0)
	_ssj_particles.initial_velocity_min = 25.0
	_ssj_particles.initial_velocity_max = 55.0
	_ssj_particles.scale_amount_min = 2.0
	_ssj_particles.scale_amount_max = 3.5
	_ssj_particles.color = Color(1.0, 0.88, 0.28, 0.85) # Dorado relámpago
	_ssj_particles.emitting = false
	_ssj_particles.position = Vector2(0, 0)
	_ssj_particles.z_index = -1
	add_child(_ssj_particles)
	_aura_particles = _ssj_particles

func finish_transform() -> void:
	super.finish_transform()
	if _ssj_particles:
		_ssj_particles.emitting = true

func end_transformation() -> void:
	super.end_transformation()
	if _ssj_particles:
		_ssj_particles.emitting = false

# ---------------------------------------------------------------------------
# Hooks de Audio (compatibles con scripts/examples/audio_vegetto_example.gd)
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

func on_transformation_started() -> void:
	var trans_node = get_node_or_null("SFX/Transform")
	if trans_node and trans_node is AudioStreamPlayer2D and trans_node.stream:
		trans_node.play()
	elif AudioManager and data and data.sfx_transform:
		AudioManager.play_sfx(data.sfx_transform)

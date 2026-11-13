## enemy_ai.gd
## Controlador de Inteligencia Artificial para luchadores (HU-10 / Fase 6 - Paso 1).
## Maneja 3 niveles de dificultad (Fácil, Normal, Difícil) y simula inputs
## en InputManager para gobernar al personaje a través de su propia StateMachine.
class_name EnemyAI
extends Node

# ---------------------------------------------------------------------------
# Configuración y Parámetros
# ---------------------------------------------------------------------------
@export_group("Configuración de IA")
## 0 = Fácil, 1 = Normal, 2 = Difícil. Se sincroniza automáticamente con GameData.ai_difficulty.
@export var difficulty: int = 1
@export var enabled: bool = true
@export var attack_range: float = 52.0       ## Distancia máxima para conectar ataque cuerpo a cuerpo
@export var spacing_distance: float = 70.0   ## Distancia deseada para medir espacio

# ---------------------------------------------------------------------------
# Referencias y Estado Interno
# ---------------------------------------------------------------------------
var character: CharacterBase = null
var target: CharacterBase = null

## Estados de IA: "AIIdle", "AIApproach", "AIAttack", "AIBlock", "AIBackstep"
var current_ai_state: String = "AIIdle"

var _think_timer: float = 0.0
var _think_interval: float = 0.4
var _block_timer: float = 0.0
var _state_timer: float = 0.0

# Parámetros calibrados por dificultad
var _block_chance: float = 0.40
var _transform_chance: float = 0.40
var _ultimate_chance: float = 0.40
var _jump_chance: float = 0.15
var _backstep_chance: float = 0.20

# ---------------------------------------------------------------------------
# Ciclo de Vida de Godot
# ---------------------------------------------------------------------------

func _ready() -> void:
	character = get_parent() as CharacterBase
	if not character:
		push_error("EnemyAI: Debe ser hijo directo de un CharacterBase.")
		set_physics_process(false)
		return

	# Sincronizar dificultad con GameData si está presente
	var gdata = get_node_or_null("/root/GameData")
	if gdata and "ai_difficulty" in gdata:
		difficulty = gdata.ai_difficulty

	_calibrate_difficulty()

	# Registrar control de IA en InputManager para el jugador correspondiente
	InputManager.set_player_ai(character.player_id, true)
	print("[EnemyAI] 🧠 IA activada para Jugador %d (%s) — Dificultad: %s (%d)" % [
		character.player_id,
		character.name,
		_get_difficulty_name(),
		difficulty
	])

func _exit_tree() -> void:
	if character and is_instance_valid(character):
		InputManager.set_player_ai(character.player_id, false)

func _physics_process(delta: float) -> void:
	if not enabled or not character or not is_instance_valid(character):
		return

	# Si el personaje o el rival están en K.O. o no tienen vida, detener toda acción
	if character.current_health <= 0.0:
		_reset_inputs()
		return

	_resolve_target()
	if not target or not is_instance_valid(target) or target.current_health <= 0.0:
		_reset_inputs()
		return

	# Si el personaje está en una cinemática (invulnerable o transformándose), pausar inputs
	if character.invulnerable or character.is_transforming:
		_reset_inputs()
		return

	_process_ai_state(delta)

# ---------------------------------------------------------------------------
# Calibración de Dificultades (HU-10)
# ---------------------------------------------------------------------------

func _calibrate_difficulty() -> void:
	match difficulty:
		0: # FÁCIL: Delays largos, no bloquea casi nunca, solo ataques básicos, no se transforma
			_think_interval = 0.80
			_block_chance = 0.05
			_transform_chance = 0.00
			_ultimate_chance = 0.00
			_jump_chance = 0.02
			_backstep_chance = 0.00
			attack_range = 48.0
		1: # NORMAL: Delays moderados, bloquea ocasionalmente, usa transformación y mide distancias
			_think_interval = 0.40
			_block_chance = 0.40
			_transform_chance = 0.40
			_ultimate_chance = 0.40
			_jump_chance = 0.15
			_backstep_chance = 0.20
			attack_range = 52.0
		2: # DIFÍCIL: Reacción rápida, persigue agresivamente, bloquea con frecuencia, usa ultimate y combos
			_think_interval = 0.15
			_block_chance = 0.80
			_transform_chance = 0.85
			_ultimate_chance = 0.90
			_jump_chance = 0.30
			_backstep_chance = 0.30
			attack_range = 56.0

func _get_difficulty_name() -> String:
	match difficulty:
		0: return "Fácil"
		1: return "Normal"
		2: return "Difícil"
		_: return "Desconocida"

func _resolve_target() -> void:
	if target and is_instance_valid(target):
		return
	if character.has_method("get_opponent"):
		var opp = character.get_opponent()
		if opp is CharacterBase:
			target = opp
			return
	for node in get_tree().get_nodes_in_group("fighters"):
		if node != character and node is CharacterBase:
			target = node
			break

# ---------------------------------------------------------------------------
# Máquina de Estados de la IA (Diagrama de Estados sección 3)
# ---------------------------------------------------------------------------

func _process_ai_state(delta: float) -> void:
	var dist_x: float = target.global_position.x - character.global_position.x
	var abs_dist: float = absf(dist_x)
	var dir_to_target: float = signf(dist_x)

	var target_is_attacking: bool = _is_target_attacking()

	# Interrupción de guardia reactiva: si el rival ataca cerca y la tirada de bloqueo acierta
	if target_is_attacking and abs_dist <= attack_range * 1.6:
		if current_ai_state != "AIBlock" and randf() < _block_chance and difficulty >= 1:
			_enter_block()
			return

	match current_ai_state:
		"AIIdle":
			InputManager.set_ai_horizontal_axis(character.player_id, 0.0)
			_think_timer -= delta
			if _think_timer <= 0.0:
				_decide_next_action(abs_dist, dir_to_target)

		"AIApproach":
			_state_timer -= delta
			if abs_dist <= attack_range:
				_enter_attack(dir_to_target)
			else:
				# Moverse hacia el objetivo
				InputManager.set_ai_horizontal_axis(character.player_id, dir_to_target)

				# Salto táctico de aproximación en dificultades Normal y Difícil
				if difficulty >= 1 and character.is_on_floor() and randf() < (_jump_chance * delta * 2.0):
					InputManager.trigger_ai_action(character.player_id, "jump")

				# Si tarda mucho en acercarse, repensar
				if _state_timer <= 0.0:
					_transition_to("AIIdle")

		"AIAttack":
			# Detener movimiento y encarar al objetivo
			InputManager.set_ai_horizontal_axis(character.player_id, 0.0)
			character.set_facing(dir_to_target > 0.0)

			_execute_attack()
			_transition_to("AIIdle")

		"AIBlock":
			InputManager.set_ai_horizontal_axis(character.player_id, 0.0)
			InputManager.set_ai_action_held(character.player_id, "block", true)
			_block_timer -= delta

			# Terminar guardia cuando termina el temporizador o el rival deja de atacar
			if _block_timer <= 0.0 or not target_is_attacking:
				InputManager.set_ai_action_held(character.player_id, "block", false)
				_transition_to("AIIdle")

		"AIBackstep":
			_state_timer -= delta
			# Retroceder alejándose del objetivo
			InputManager.set_ai_horizontal_axis(character.player_id, -dir_to_target)
			if _state_timer <= 0.0 or abs_dist >= spacing_distance:
				InputManager.set_ai_horizontal_axis(character.player_id, 0.0)
				_transition_to("AIIdle")

# ---------------------------------------------------------------------------
# Transiciones y Decisiones
# ---------------------------------------------------------------------------

func _decide_next_action(abs_dist: float, dir_to_target: float) -> void:
	_think_timer = _think_interval * randf_range(0.9, 1.1)

	# 1. Si está en rango de golpe cuerpo a cuerpo:
	if abs_dist <= attack_range:
		# Posibilidad de retroceder (backstep) para medir distancia si está en dificultad Normal o Difícil
		if randf() < _backstep_chance and difficulty >= 1:
			_enter_backstep()
		else:
			_enter_attack(dir_to_target)
		return

	# 2. Si está fuera de rango pero tiene Ki al 100% y es Difícil: puede desatar Ultimate si es viable
	if difficulty == 2 and character.has_method("can_ultimate") and character.can_ultimate():
		if randf() < _ultimate_chance:
			_enter_attack(dir_to_target)
			return

	# 2.5. Ataque Especial a media distancia (proyectil característico)
	var sp_cost: float = character.data.energy_cost_special if character.data else 20.0
	if character.current_energy >= sp_cost and abs_dist > attack_range and abs_dist <= 280.0:
		if randf() < 0.45:
			character.set_facing(dir_to_target > 0.0)
			InputManager.trigger_ai_action(character.player_id, "special")
			_transition_to("AIIdle")
			return

	# 3. Si está fuera de rango: acercarse al objetivo
	_transition_to("AIApproach")
	_state_timer = 2.0 # Tiempo máximo de persecución continua antes de reevaluar

func _enter_attack(dir_to_target: float) -> void:
	character.set_facing(dir_to_target > 0.0)
	_transition_to("AIAttack")

func _enter_block() -> void:
	_block_timer = randf_range(0.35, 0.65)
	_transition_to("AIBlock")

func _enter_backstep() -> void:
	_state_timer = randf_range(0.2, 0.35)
	_transition_to("AIBackstep")

func _transition_to(next_state: String) -> void:
	current_ai_state = next_state

# ---------------------------------------------------------------------------
# Ejecución de Ataques por Prioridad
# ---------------------------------------------------------------------------

func _execute_attack() -> void:
	# 1. Ultimate: solo disponible con Ki al 100% (prioridad en Difícil)
	if difficulty >= 1 and character.has_method("can_ultimate") and character.can_ultimate():
		if randf() < _ultimate_chance:
			InputManager.trigger_ai_action(character.player_id, "ultimate")
			return

	# 2. Transformación: si tiene Ki suficiente y no está en cooldown
	if difficulty >= 1 and character.has_method("can_transform") and character.can_transform():
		if randf() < _transform_chance:
			InputManager.trigger_ai_action(character.player_id, "transform")
			return

	# 2.5. Ataque Especial (técnica con Ki)
	var sp_cost: float = character.data.energy_cost_special if character.data else 20.0
	if character.current_energy >= sp_cost and randf() < 0.35:
		InputManager.trigger_ai_action(character.player_id, "special")
		return

	# 3. Ataque básico por defecto
	InputManager.trigger_ai_action(character.player_id, "attack")

# ---------------------------------------------------------------------------
# Sensores y Helpers
# ---------------------------------------------------------------------------

func _is_target_attacking() -> bool:
	if not target or not is_instance_valid(target):
		return false
	if target.state_machine and target.state_machine.current_state:
		var st_name: String = target.state_machine.current_state.name
		return st_name in ["Attack", "Special", "Ultimate"]
	return false

func _reset_inputs() -> void:
	if character:
		InputManager.set_ai_horizontal_axis(character.player_id, 0.0)
		InputManager.set_ai_action_held(character.player_id, "block", false)


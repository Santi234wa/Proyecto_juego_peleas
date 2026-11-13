## madara_attack_state.gd
## Combo de tres golpes de Madara Uchiha:
##   Golpe 1: Puñetazo derecho (punch_1)
##   Golpe 2: Puñetazo izquierdo (punch_2)
##   Golpe 3: Patada alta rematadora (kick)
##   Bucle: 1 → 2 → 3 → 1 (se repite continuamente).
## Si transcurren más de COMBO_RESET_DELAY segundos sin atacar, el combo se reinicia a 1.
class_name MadaraAttackState
extends AttackState

const COMBO_RESET_DELAY: float = 0.85

var combo_step: int = 1
var _last_attack_time: float = -999.0
var _buffered_next_attack: bool = false
var _step_duration: float = 0.36
var _step_active_start: float = 0.08
var _step_active_end: float = 0.24
var _step_damage: float = 8.0
var _step_knockback: Vector2 = Vector2(80.0, 0.0)
var _step_anim: String = "punch_1"

func enter() -> void:
	_elapsed = 0.0
	_hitbox_was_active = false
	_buffered_next_attack = false

	# Comprobar tiempo desde el último ataque para reiniciar el combo si se demoró
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_attack_time > COMBO_RESET_DELAY:
		combo_step = 1

	_setup_combo_step(combo_step)

	_hitbox = character.get_node_or_null("Hitbox") as Hitbox
	if _hitbox:
		_hitbox.deactivate()

	character.velocity.x = 0.0

	# Reproducir animación del golpe correspondiente
	if character.has_method("play_animation"):
		character.play_animation(_step_anim)

	print("[Madara P%d] 🥋 Combo Paso %d: %s (Daño: %.1f)" % [
		character.player_id, combo_step, _step_anim, _step_damage
	])

func _setup_combo_step(step: int) -> void:
	var base_dmg: float = character.data.damage_basic if character.data else 8.0
	match step:
		1:
			_step_anim = "punch_1"
			_step_duration = 0.34
			_step_active_start = 0.08
			_step_active_end = 0.22
			_step_damage = base_dmg
			_step_knockback = Vector2(70.0, 0.0)
		2:
			_step_anim = "punch_2"
			_step_duration = 0.34
			_step_active_start = 0.08
			_step_active_end = 0.22
			_step_damage = base_dmg * 1.15
			_step_knockback = Vector2(95.0, 0.0)
		3:
			_step_anim = "kick"
			_step_duration = 0.44
			_step_active_start = 0.10
			_step_active_end = 0.30
			_step_damage = base_dmg * 1.65
			_step_knockback = Vector2(220.0, -90.0)
		_:
			combo_step = 1
			_setup_combo_step(1)

func physics_update(delta: float) -> void:
	# Gravedad si ataca en el aire
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# Buffer de siguiente ataque si el jugador presiona atacar durante la animación
	if not _buffered_next_attack and _elapsed >= _step_active_start:
		if InputManager.is_action_just_pressed(character.player_id, "attack"):
			_buffered_next_attack = true

	# Gestión de frames activos del Hitbox
	if _elapsed >= _step_active_start and _elapsed < _step_active_end:
		if not _hitbox_was_active:
			_hitbox_was_active = true
			if _hitbox:
				var eff_dmg: float = character.get_effective_damage(_step_damage)
				var dir: float = 1.0 if character.is_facing_right else -1.0
				if "knockback_vector" in _hitbox:
					_hitbox.knockback_vector = Vector2(_step_knockback.x * dir, _step_knockback.y)
				_hitbox.activate(eff_dmg)
		elif _hitbox:
			_hitbox.check_overlaps()
	elif _elapsed >= _step_active_end and _hitbox_was_active:
		_hitbox_was_active = false
		if _hitbox:
			_hitbox.deactivate()

	# Fin del ataque actual
	if _elapsed >= _step_duration:
		_advance_combo()

func _advance_combo() -> void:
	_last_attack_time = Time.get_ticks_msec() / 1000.0

	# Bucle de tres golpes: 1 → 2 → 3 → 1 ...
	if combo_step == 1:
		combo_step = 2
	elif combo_step == 2:
		combo_step = 3
	else:
		combo_step = 1

	if _buffered_next_attack:
		# Encadenar inmediatamente el siguiente golpe del combo
		enter()
	else:
		state_machine.transition_to("Idle")

func exit() -> void:
	_last_attack_time = Time.get_ticks_msec() / 1000.0
	if _hitbox:
		_hitbox.deactivate()
	_hitbox_was_active = false
	_buffered_next_attack = false


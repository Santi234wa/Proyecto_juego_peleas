## vegetto_attack_state.gd
## Combo de combate de Vegetto:
##   Golpe 1: Puñetazo rápido (punch_1 / ssj_punch)
##   Golpe 2: Gancho directo (punch_2 / ssj_punch)
##   Golpe 3: Patada alta (kick / ssj_kick)
##   Golpe 4: Ráfaga de golpes relámpago (combo / ssj_combo)
##   Bucle: 1 → 2 → 3 → 4 → 1
## Si pasan más de COMBO_RESET_DELAY segundos sin atacar, el combo se reinicia al paso 1.
class_name VegettoAttackState
extends AttackState

const COMBO_RESET_DELAY: float = 0.85

var combo_step: int = 1
var _last_attack_time: float = -999.0
var _buffered_next_attack: bool = false
var _step_duration: float = 0.34
var _step_active_start: float = 0.08
var _step_active_end: float = 0.22
var _step_damage: float = 9.0
var _step_knockback: Vector2 = Vector2(80.0, 0.0)
var _step_anim: String = "punch_1"

func enter() -> void:
	_elapsed = 0.0
	_hitbox_was_active = false
	_buffered_next_attack = false

	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_attack_time > COMBO_RESET_DELAY:
		combo_step = 1

	_setup_combo_step(combo_step)

	_hitbox = character.get_node_or_null("Hitbox") as Hitbox
	if _hitbox:
		_hitbox.deactivate()

	character.velocity.x = 0.0

	if character.has_method("play_animation"):
		character.play_animation(_step_anim)

func _setup_combo_step(step: int) -> void:
	var base_dmg: float = character.data.damage_basic if character.data else 9.0
	var is_ssj: bool = character.is_transformed

	match step:
		1:
			_step_anim = "ssj_punch" if is_ssj else "punch_1"
			_step_duration = 0.32
			_step_active_start = 0.07
			_step_active_end = 0.20
			_step_damage = base_dmg
			_step_knockback = Vector2(70.0, 0.0)
		2:
			_step_anim = "ssj_punch" if is_ssj else "punch_2"
			_step_duration = 0.32
			_step_active_start = 0.07
			_step_active_end = 0.20
			_step_damage = base_dmg * 1.1
			_step_knockback = Vector2(90.0, 0.0)
		3:
			_step_anim = "ssj_kick" if is_ssj else "kick"
			_step_duration = 0.36
			_step_active_start = 0.08
			_step_active_end = 0.24
			_step_damage = base_dmg * 1.3
			_step_knockback = Vector2(120.0, -20.0)
		4:
			_step_anim = "ssj_combo" if is_ssj else "combo"
			_step_duration = 0.45
			_step_active_start = 0.08
			_step_active_end = 0.32
			_step_damage = base_dmg * 1.6
			_step_knockback = Vector2(170.0, -35.0)

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# Buffer de ataque
	if _elapsed > 0.12 and InputManager.is_action_just_pressed(character.player_id, "attack"):
		_buffered_next_attack = true

	# Gestión de frames activos de la Hitbox
	if _elapsed >= _step_active_start and _elapsed < _step_active_end:
		if not _hitbox_was_active:
			_hitbox_was_active = true
			if _hitbox:
				var eff_dmg: float = character.get_effective_damage(_step_damage)
				_hitbox.activate(eff_dmg)
				var dir: float = 1.0 if character.is_facing_right else -1.0
				_hitbox.knockback_vector = Vector2(_step_knockback.x * dir, _step_knockback.y)
		elif _hitbox:
			_hitbox.check_overlaps()
	elif _elapsed >= _step_active_end and _hitbox_was_active:
		_hitbox_was_active = false
		if _hitbox:
			_hitbox.deactivate()

	# Fin del paso de ataque
	if _elapsed >= _step_duration:
		_last_attack_time = Time.get_ticks_msec() / 1000.0
		if _buffered_next_attack:
			_advance_combo()
			enter()
			return

		_advance_combo()
		state_machine.transition_to("Idle")
		return

func _advance_combo() -> void:
	combo_step += 1
	if combo_step > 4:
		combo_step = 1

func exit() -> void:
	if _hitbox:
		_hitbox.deactivate()
	_hitbox_was_active = false
	_buffered_next_attack = false

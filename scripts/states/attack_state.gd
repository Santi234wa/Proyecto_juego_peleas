## attack_state.gd
## Gestiona el ataque básico: startup → frames activos → recovery.
## Activa y desactiva el Hitbox usando set_deferred según los tiempos de CharacterData.
## Transiciones: Idle (al terminar el ataque).
class_name AttackState
extends CharacterState

const GRAVITY: float = 980.0

var _hitbox: Hitbox = null
var _elapsed: float = 0.0
var _total_duration: float = 0.5
var _active_start: float = 0.1
var _active_end: float = 0.35
var _hitbox_was_active: bool = false

func enter() -> void:
	_elapsed = 0.0
	_hitbox_was_active = false

	# Cargar tiempos desde CharacterData
	if character.data:
		_total_duration = character.data.attack_duration
		_active_start   = character.data.attack_active_start
		_active_end     = character.data.attack_active_end

	# Buscar y preparar el hitbox
	_hitbox = character.get_node_or_null("Hitbox") as Hitbox
	if not _hitbox:
		push_warning("%s: No tiene nodo 'Hitbox' asignado. No conectará golpes." % character.name)
	else:
		_hitbox.deactivate()

	# El personaje se detiene para golpear
	character.velocity.x = 0.0
	character.play_animation("attack")

func physics_update(delta: float) -> void:
	# Gravedad si ataca en el aire
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# ── Gestión de frames activos (Hitbox con set_deferred) ────────────────
	if _elapsed >= _active_start and _elapsed < _active_end:
		if not _hitbox_was_active:
			_hitbox_was_active = true
			if _hitbox:
				var base_dmg: float = character.data.damage_basic if character.data else 8.0
				_hitbox.activate(character.get_effective_damage(base_dmg))
	elif _elapsed >= _active_end and _hitbox_was_active:
		_hitbox_was_active = false
		if _hitbox:
			_hitbox.deactivate()

	# ── Fin del ataque ─────────────────────────────────────────────────────
	if _elapsed >= _total_duration:
		state_machine.transition_to("Idle")
		return

func exit() -> void:
	# Garantizar que el hitbox quede desactivado al salir del estado
	if _hitbox:
		_hitbox.deactivate()
	_hitbox_was_active = false

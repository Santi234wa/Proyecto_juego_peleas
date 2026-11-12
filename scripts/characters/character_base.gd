## character_base.gd
## Clase base de TODOS los personajes jugables y enemigos.
## Patrón: Template Method.
class_name CharacterBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Constantes de física
# ---------------------------------------------------------------------------
const GRAVITY: float = 980.0

# ---------------------------------------------------------------------------
# Señales (Patrón Observer)
# ---------------------------------------------------------------------------
signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)
signal character_died()
signal transformation_started(transform_name: String)
signal transformation_ended()

# ---------------------------------------------------------------------------
# Datos del personaje
# ---------------------------------------------------------------------------
@export var data: CharacterData = null
@export var player_id: int = 1

# ---------------------------------------------------------------------------
# Estado en tiempo de ejecución
# ---------------------------------------------------------------------------
var current_health: float = 0.0
var current_energy: float = 0.0
var is_transformed: bool = false
var is_facing_right: bool = true
var is_blocked: bool = false

var _speed_mult: float = 1.0
var _damage_mult: float = 1.0
var _cooldown_timer: float = 0.0  # Temporizador de espera post-transformación

# ---------------------------------------------------------------------------
# Nodos hijos
# ---------------------------------------------------------------------------
var state_machine = null
var _animated_sprite: AnimatedSprite2D = null
var _aura_particles: Node = null

# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	_find_child_nodes()
	_initialize_stats()
	_setup_state_machine()

func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.physics_update(delta)
	move_and_slide()

	# ── Drenaje dinámico de Ki mientras está transformado ───────────────
	if is_transformed:
		var drain: float = (data.ki_drain_per_second if data else 8.0) * delta
		current_energy = maxf(0.0, current_energy - drain)
		var max_e: float = data.max_energy if data else 100.0
		emit_signal("energy_changed", current_energy, max_e)

		# La transformación termina automáticamente cuando el Ki llega a 0
		if current_energy <= 0.0:
			end_transformation()

	# ── Cuenta regresiva de enfriamiento (Cooldown) ─────────────────────
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

func _process(delta: float) -> void:
	if state_machine:
		state_machine.process_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input(event)

# ---------------------------------------------------------------------------
# Inicialización interna
# ---------------------------------------------------------------------------

func _find_child_nodes() -> void:
	state_machine    = get_node_or_null("StateMachine")
	_animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_aura_particles  = get_node_or_null("AuraParticles")

	if not _animated_sprite:
		push_warning("%s: No tiene 'AnimatedSprite2D'." % name)

func _initialize_stats() -> void:
	if not data:
		push_warning("%s: CharacterData no asignada. Usando valores por defecto." % name)
		current_health = 100.0
		current_energy = 0.0
		return
	current_health = data.max_health
	current_energy = 0.0

func _setup_state_machine() -> void:
	pass

# ---------------------------------------------------------------------------
# API pública de combate
# ---------------------------------------------------------------------------

## Aplica daño. Si está bloqueando, reduce al 50%.
func take_damage(amount: float) -> void:
	var max_hp: float = data.max_health if data else 100.0
	var effective: float = amount * 0.5 if is_blocked else amount
	current_health = maxf(0.0, current_health - effective)
	emit_signal("health_changed", current_health, max_hp)

	# REGLA: Si está transformado, recibir daño NO suma Ki.
	# Fuera de la transformación, suma energía normalmente.
	if not is_transformed:
		var gain: float = data.energy_on_hit_taken if data else 5.0
		gain_energy(gain)

	if current_health <= 0.0:
		emit_signal("character_died")
		if state_machine:
			state_machine.transition_to("KO")
	else:
		if not is_blocked and state_machine and state_machine.current_state and state_machine.current_state.name != "KO":
			state_machine.transition_to("Hurt")

## Suma energía Ki/Chakra respetando el tope máximo y emite señal Observer
func gain_energy(amount: float) -> void:
	var max_e: float = data.max_energy if data else 100.0
	current_energy = minf(max_e, current_energy + amount)
	emit_signal("energy_changed", current_energy, max_e)
	print("[%s] ⚡ Ki: +%.1f | Total Ki: %.1f/%s" % [name, amount, current_energy, max_e])

## Gasta energía. Retorna false si no hay suficiente.
func spend_energy(amount: float) -> bool:
	if current_energy < amount:
		return false
	current_energy -= amount
	var max_e: float = data.max_energy if data else 100.0
	emit_signal("energy_changed", current_energy, max_e)
	return true

# ---------------------------------------------------------------------------
# API de transformación
# ---------------------------------------------------------------------------

## Activa la transformación si tiene suficiente Ki acumulado y no está en cooldown
func try_transform() -> bool:
	if not data:
		return false
	if is_transformed:
		print("[%s] Ya está transformado en %s." % [name, data.transform_name])
		return false

	# Validar enfriamiento
	if _cooldown_timer > 0.0:
		print("[%s] ⏳ Enfriamiento activo: espera %.1fs para volver a transformar." % [name, _cooldown_timer])
		return false

	var min_cost: float = data.energy_cost_transform
	if current_energy < min_cost:
		print("[%s] ❌ Ki insuficiente para %s: Requiere al menos %s Ki (Tienes %.1f Ki)" % [
			name, data.transform_name, min_cost, current_energy
		])
		return false

	is_transformed = true
	_speed_mult = data.transform_speed_mult
	_damage_mult = data.transform_damage_mult

	# Tinte dorado brillante Super Saiyajin
	modulate = Color(1.35, 1.25, 0.45)

	if _aura_particles:
		_aura_particles.set("emitting", true)

	emit_signal("transformation_started", data.transform_name)
	print("[%s] 🔥 ¡TRANSFORMACIÓN ACTIVADA! (%s) | Drenando %.1f Ki/s hasta llegar a 0..." % [
		name, data.transform_name, data.ki_drain_per_second
	])
	return true

## Termina la transformación y restaura todos los valores a la normalidad
func end_transformation() -> void:
	if not is_transformed:
		return
	is_transformed = false
	_speed_mult = 1.0
	_damage_mult = 1.0
	modulate = Color(1.0, 1.0, 1.0)

	# Iniciar temporizador de enfriamiento
	_cooldown_timer = data.transform_cooldown if data else 4.0

	if _aura_particles:
		_aura_particles.set("emitting", false)

	emit_signal("transformation_ended")
	print("[%s] 💨 Ki agotado (0 Ki). Fin de la transformación. Cooldown de %.1fs iniciado." % [name, _cooldown_timer])

# ---------------------------------------------------------------------------
# Helpers para los estados
# ---------------------------------------------------------------------------

func get_effective_speed() -> float:
	return (data.move_speed if data else 180.0) * _speed_mult

func get_effective_damage(base_damage: float) -> float:
	return base_damage * _damage_mult

func play_animation(anim_name: String) -> void:
	if not _animated_sprite:
		return
	if not _animated_sprite.sprite_frames:
		return
	if not _animated_sprite.sprite_frames.has_animation(anim_name):
		return
	if _animated_sprite.animation == anim_name and _animated_sprite.is_playing():
		return
	_animated_sprite.play(anim_name)

func set_facing(facing_right: bool) -> void:
	is_facing_right = facing_right
	if _animated_sprite:
		_animated_sprite.flip_h = not facing_right
	
	var hitbox := get_node_or_null("Hitbox") as Node2D
	if hitbox:
		hitbox.position.x = absf(hitbox.position.x) * (1.0 if facing_right else -1.0)

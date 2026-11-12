## character_base.gd
## Clase base de TODOS los personajes jugables y enemigos.
## Patrón: Template Method.
##
## NOTA: 'state_machine' es sin tipo explícito (StateMachine en runtime)
## para evitar dependencia circular: CharacterBase → StateMachine → CharacterState → CharacterBase.
class_name CharacterBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Constantes de física (accesibles vía CharacterBase.GRAVITY si se necesita)
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
# Datos del personaje (inyectados desde el Inspector o por CharacterFactory)
# ---------------------------------------------------------------------------
@export var data: CharacterData = null

## ID del jugador que controla este personaje: 1 o 2.
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
var _transform_timer: float = 0.0

# ---------------------------------------------------------------------------
# Nodos hijos
# ---------------------------------------------------------------------------
## StateMachine en runtime. Sin tipo explícito para evitar ciclo de parseo.
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

	if is_transformed:
		_transform_timer -= delta
		if _transform_timer <= 0.0:
			end_transformation()

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

	if not state_machine:
		push_error("%s: Falta nodo 'StateMachine' como hijo directo." % name)
	if not _animated_sprite:
		push_error("%s: Falta nodo 'AnimatedSprite2D' como hijo directo." % name)

func _initialize_stats() -> void:
	if not data:
		push_warning("%s: CharacterData no asignada. Usando valores por defecto." % name)
		return
	current_health = data.max_health
	current_energy = data.max_energy

## Método abstracto: cada subclase llama state_machine.init() aquí.
func _setup_state_machine() -> void:
	pass

# ---------------------------------------------------------------------------
# API pública de combate
# ---------------------------------------------------------------------------

func take_damage(amount: float) -> void:
	if not data:
		return

	var effective: float = amount * 0.5 if is_blocked else amount
	current_health = maxf(0.0, current_health - effective)
	emit_signal("health_changed", current_health, data.max_health)

	gain_energy(data.energy_on_hit_taken)

	if current_health <= 0.0:
		emit_signal("character_died")
		if state_machine:
			state_machine.transition_to("KO")
	else:
		if state_machine and state_machine.current_state.name != "KO":
			state_machine.transition_to("Hurt")

func gain_energy(amount: float) -> void:
	if not data:
		return
	current_energy = minf(data.max_energy, current_energy + amount)
	emit_signal("energy_changed", current_energy, data.max_energy)

func spend_energy(amount: float) -> bool:
	if current_energy < amount:
		return false
	current_energy -= amount
	emit_signal("energy_changed", current_energy, data.max_energy)
	return true

# ---------------------------------------------------------------------------
# API de transformación
# ---------------------------------------------------------------------------

func try_transform() -> bool:
	if not data or is_transformed:
		return false
	if not spend_energy(data.energy_cost_transform):
		return false

	is_transformed = true
	_transform_timer = data.transform_duration
	_speed_mult = data.transform_speed_mult
	_damage_mult = data.transform_damage_mult

	if _aura_particles:
		_aura_particles.set("emitting", true)

	emit_signal("transformation_started", data.transform_name)
	if state_machine:
		state_machine.transition_to("Transformed")
	return true

func end_transformation() -> void:
	is_transformed = false
	_speed_mult = 1.0
	_damage_mult = 1.0
	_transform_timer = 0.0

	if _aura_particles:
		_aura_particles.set("emitting", false)

	emit_signal("transformation_ended")
	if state_machine:
		state_machine.transition_to("Idle")

# ---------------------------------------------------------------------------
# Helpers para los estados
# ---------------------------------------------------------------------------

func get_effective_speed() -> float:
	return (data.move_speed if data else 180.0) * _speed_mult

func get_effective_damage(base_damage: float) -> float:
	return base_damage * _damage_mult

## Reproduce una animación de forma segura (evita errores con placeholders).
func play_animation(anim_name: String) -> void:
	if not _animated_sprite:
		return
	if not _animated_sprite.sprite_frames:
		return
	if not _animated_sprite.sprite_frames.has_animation(anim_name):
		push_warning("%s: Animación '%s' no encontrada en SpriteFrames." % [name, anim_name])
		return
	if _animated_sprite.animation == anim_name and _animated_sprite.is_playing():
		return  # Ya está reproduciendo esta animación; no reiniciar
	_animated_sprite.play(anim_name)

func set_facing(facing_right: bool) -> void:
	is_facing_right = facing_right
	if _animated_sprite:
		_animated_sprite.flip_h = not facing_right

## madara_fireball_state.gd
## Estado de ataque especial de Madara: Katon: Goukakyuu no Jutsu (Gran Bola de Fuego).
## Ejecuta la postura de sellos/carga ígnea e instancia el proyectil MadaraFireball frente a él.
class_name MadaraFireballState
extends CharacterState

const GRAVITY: float = 980.0
const FIREBALL_SCENE_PATH: String = "res://scenes/effects/madara_fireball.tscn"

@export var ki_cost: float = 20.0
@export var cast_delay: float = 0.16
@export var total_duration: float = 0.44

var _elapsed: float = 0.0
var _has_spawned: bool = false

func enter() -> void:
	_elapsed = 0.0
	_has_spawned = false

	character.velocity.x = 0.0

	var cost: float = ki_cost
	if character.data and character.data.energy_cost_special > 0.0:
		cost = character.data.energy_cost_special

	if not character.spend_energy(cost):
		state_machine.transition_to("Idle")
		return

	# Reproducir animación de lanzamiento de fuego
	if character.has_method("play_animation"):
		character.play_animation("fireball")

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# Instanciar bola de fuego al alcanzar el fotograma clave
	if _elapsed >= cast_delay and not _has_spawned:
		_has_spawned = true
		_spawn_fireball()

	if _elapsed >= total_duration:
		state_machine.transition_to("Idle")
		return

func _spawn_fireball() -> void:
	if not ResourceLoader.exists(FIREBALL_SCENE_PATH):
		push_warning("MadaraFireballState: No se encontró la escena de fuego en %s" % FIREBALL_SCENE_PATH)
		return

	var scene := load(FIREBALL_SCENE_PATH) as PackedScene
	if not scene:
		return

	var proj: Area2D = scene.instantiate()
	var dir_x: float = 1.0 if character.is_facing_right else -1.0
	proj.scale = character.scale
	var offset: Vector2 = Vector2(38.0 * dir_x, -4.0)

	proj.owner_character = character
	proj.direction = Vector2(dir_x, 0.0)
	proj.global_position = character.global_position + offset

	# Si está en modo Sharingan, la bola de fuego es aún más rápida y devastadora
	if character.is_transformed:
		proj.speed = 540.0
		proj.damage = 28.0

	# Hook de audio si está disponible
	if character.has_method("on_fireball_spawned"):
		character.on_fireball_spawned()

	character.get_parent().add_child(proj)

func exit() -> void:
	_has_spawned = false

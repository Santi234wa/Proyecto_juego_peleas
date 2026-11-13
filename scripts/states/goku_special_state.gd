## goku_special_state.gd
## Estado de ataque especial de Goku: Ráfaga Kamehameha Azul.
## Ejecuta la postura de ataque de Ki y lanza el proyectil GokuKamehameha.
class_name GokuSpecialState
extends CharacterState

const GRAVITY: float = 980.0
const KAMEHAMEHA_SCENE_PATH: String = "res://scenes/effects/goku_kamehameha.tscn"

@export var ki_cost: float = 20.0
@export var cast_delay: float = 0.14
@export var total_duration: float = 0.42

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

	# Animación adecuada según transformación
	var anim: String = "ssj_attack" if character.is_transformed else "attack"
	if character.has_method("play_animation"):
		character.play_animation(anim)

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# Instanciar el proyectil al alcanzar el fotograma de lanzamiento
	if _elapsed >= cast_delay and not _has_spawned:
		_has_spawned = true
		_spawn_kamehameha()

	if _elapsed >= total_duration:
		state_machine.transition_to("Idle")
		return

func _spawn_kamehameha() -> void:
	if not ResourceLoader.exists(KAMEHAMEHA_SCENE_PATH):
		push_warning("GokuSpecialState: No se encontró la escena de Kamehameha en %s" % KAMEHAMEHA_SCENE_PATH)
		return

	var scene := load(KAMEHAMEHA_SCENE_PATH) as PackedScene
	if not scene:
		return

	var proj: Area2D = scene.instantiate()
	var dir_x: float = 1.0 if character.is_facing_right else -1.0
	proj.scale = character.scale
	var offset: Vector2 = Vector2(38.0 * dir_x, -4.0)

	proj.owner_character = character
	proj.direction = Vector2(dir_x, 0.0)
	proj.global_position = character.global_position + offset

	if character.get_parent():
		character.get_parent().add_child(proj)
	else:
		character.add_sibling(proj)

func exit() -> void:
	_has_spawned = false


## vegetto_ki_state.gd
## Estado de ataque especial de Vegetto: Disparo de ráfaga de Ki.
## Gasta energía, prepara la animación de lanzamiento e instancia el proyectil VegettoKiBlast.
class_name VegettoKiState
extends CharacterState

const GRAVITY: float = 980.0
const KI_SCENE_PATH: String = "res://scenes/effects/vegetto_ki_blast.tscn"

@export var ki_cost: float = 20.0
@export var cast_delay: float = 0.12
@export var total_duration: float = 0.38

var _elapsed: float = 0.0
var _has_spawned: bool = false

func enter() -> void:
	_elapsed = 0.0
	_has_spawned = false

	# Detener movimiento para disparar
	character.velocity.x = 0.0

	var cost: float = ki_cost
	if character.data and character.data.energy_cost_special > 0.0:
		cost = character.data.energy_cost_special

	if not character.spend_energy(cost):
		# Sin energía suficiente, volver a Idle de inmediato
		state_machine.transition_to("Idle")
		return

	# Animación de lanzamiento de ki (usa punch_2 o pose de ataque)
	var anim: String = "ssj_punch" if character.is_transformed else "punch_2"
	if character.has_method("play_animation"):
		character.play_animation(anim)

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

	character.velocity.x = 0.0
	_elapsed += delta

	# Instanciar el proyectil al alcanzar el fotograma clave
	if _elapsed >= cast_delay and not _has_spawned:
		_has_spawned = true
		_spawn_ki_projectile()

	if _elapsed >= total_duration:
		state_machine.transition_to("Idle")
		return

func _spawn_ki_projectile() -> void:
	if not ResourceLoader.exists(KI_SCENE_PATH):
		push_warning("VegettoKiState: No se encontró la escena de ki en %s" % KI_SCENE_PATH)
		return

	var scene := load(KI_SCENE_PATH) as PackedScene
	if not scene:
		return

	var proj: Area2D = scene.instantiate()
	var dir_x: float = 1.0 if character.is_facing_right else -1.0
	proj.scale = character.scale
	var offset: Vector2 = Vector2(36.0 * dir_x, -4.0)

	proj.owner_character = character
	proj.direction = Vector2(dir_x, 0.0)
	proj.global_position = character.global_position + offset

	# Notificar hook de audio si está presente en Vegetto
	if character.has_method("on_ki_projectile_spawned"):
		character.on_ki_projectile_spawned()

	character.get_parent().add_child(proj)

func exit() -> void:
	_has_spawned = false


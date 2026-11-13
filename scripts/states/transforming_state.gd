## transforming_state.gd
## Estado de transición FSM: se ejecuta al presionar la tecla de transformación
## si se cumplen las condiciones (Ki suficiente, sin cooldown). Dura ~1.0 s.
## Al terminar, aplica los buffs de daño y velocidad, y regresa a Idle transformado.
##
## Secuencia:
##   1) Hitstop (micro-pausa dramática)
##   2) Temblor del sprite + aura de partículas + temblor de cámara
##   3) Destello blanco de pantalla completa (Flash) + cambio de forma (finish_transform)
##   4) Retorno a Idle con buffs y sprites de Super Saiyajin activos.
class_name TransformingState
extends CharacterState

@export var duration: float = 1.0                 ## Duración total de la cinemática (~1s)
@export var transformed_frames: SpriteFrames      ## Opcional: SpriteFrames separado de SSJ
@export var use_particles: bool = true            ## Aura de partículas ascendente

var _active: bool = false
var _particles: CPUParticles2D = null

func enter() -> void:
	_active = true
	character.velocity = Vector2.ZERO
	character.invulnerable = true
	character.begin_transform()
	_play_intro()

func exit() -> void:
	_active = false
	Engine.time_scale = 1.0                        # Seguridad si se interrumpe el hitstop
	if character:
		character.invulnerable = false
	if _particles and is_instance_valid(_particles):
		_particles.queue_free()
		_particles = null

func physics_update(_delta: float) -> void:
	# Sin movimiento ni ataques durante la transición
	character.velocity.x = 0.0
	if not character.is_on_floor():
		character.velocity.y += 980.0 * _delta
	character.move_and_slide()

func _play_intro() -> void:
	var sprite: AnimatedSprite2D = character.get_node_or_null("AnimatedSprite2D")
	var base_pos: Vector2 = sprite.position if sprite else Vector2.ZERO
	if sprite:
		character.play_animation("idle")

	# 1) Pausa breve (hitstop dramático)
	await _hitstop(0.1)
	if not _active or not is_instance_valid(self):
		return

	# 2) Temblor del sprite + aura + temblor de cámara
	if use_particles:
		_start_particles()

	var shake_time: float = duration * 0.7
	if sprite:
		var tw: Tween = create_tween()
		var steps: int = 12
		for i in steps:
			var dx: float = 2.0 if i % 2 == 0 else -2.0
			tw.tween_property(sprite, "position:x", base_pos.x + dx, shake_time / float(steps))
		tw.tween_property(sprite, "position", base_pos, 0.02)

	_shake_camera(2.5, shake_time)
	await get_tree().create_timer(shake_time).timeout
	if not _active or not is_instance_valid(self):
		return

	# 3) Destello blanco cinemático de pantalla completa y cambio de forma
	_flash(duration * 0.3)

	# Si se configuró un recurso SpriteFrames separado, se asigna al AnimatedSprite2D
	if transformed_frames and sprite:
		sprite.sprite_frames = transformed_frames

	# Aplica buffs de daño y velocidad, y cambia la animación
	character.finish_transform()
	_shake_camera(6.0, 0.25)
	await get_tree().create_timer(duration * 0.3).timeout

	# 4) Volver a Idle con la forma transformada activa
	if _active and state_machine:
		state_machine.transition_to("Idle")

func _hitstop(time: float) -> void:
	Engine.time_scale = 0.05
	# El temporizador ignora el time_scale (4º parámetro ignore_time_scale = true)
	await get_tree().create_timer(time, true, false, true).timeout
	Engine.time_scale = 1.0

func _flash(time: float) -> void:
	# Destello blanco de pantalla completa (procedimental, sin tocar escenas .tscn)
	var scene_root = get_tree().current_scene
	if not scene_root:
		return
	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(1.0, 1.0, 1.0, 0.9)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	scene_root.add_child(layer)

	var tw := layer.create_tween()
	tw.tween_property(rect, "color:a", 0.0, time)
	tw.tween_callback(layer.queue_free)

func _shake_camera(intensity: float, time: float) -> void:
	var cam: Camera2D = get_viewport().get_camera_2d()
	if cam == null:
		return
	var tw := create_tween()
	var steps := int(time / 0.03)
	for i in steps:
		var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * intensity
		tw.tween_property(cam, "offset", off, 0.03)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.03)

func _start_particles() -> void:
	_particles = CPUParticles2D.new()
	_particles.amount = 24
	_particles.lifetime = 0.8
	_particles.direction = Vector2.UP
	_particles.spread = 25.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 40.0
	_particles.initial_velocity_max = 90.0
	_particles.scale_amount_min = 2.0
	_particles.scale_amount_max = 4.0
	_particles.color = Color(1.0, 0.85, 0.2)
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = Vector2(10, 2)
	_particles.position = Vector2(0, 20)            # Ajustado a la altura de los pies de Goku
	character.add_child(_particles)
	_particles.emitting = true

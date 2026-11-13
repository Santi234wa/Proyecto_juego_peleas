## transforming_state.gd (Versión 2: Épica)
## Secuencia cinemática de transformación procedimental (~2.0 s):
##   Fase 0: Hitstop + la pantalla se oscurece (solo el personaje queda iluminado a z_index 100).
##   Fase 1: Carga: temblor creciente, aura de partículas, rayos en zigzag (Line2D),
##           ondas expansivas en el suelo (Line2D) y zoom lento de cámara.
##   Fase 2: Explosión: micro-hitstop, flash blanco de pantalla completa, ondas masivas,
##           explosión radial de 60 partículas, sacudida fuerte de cámara (shake),
##           cambio inmediato a los sprites y buffs de Super Saiyajin.
##   Fase 3: Pose: "pop" elástico del sprite (TRANS_ELASTIC), la luz regresa gradualmente y
##           vuelve a Idle transformado.
class_name TransformingState
extends CharacterState

@export_group("Duraciones y Zoom")
@export var charge_time: float = 1.1               ## Duración de la fase de carga de energía
@export var hold_time: float = 0.5                 ## Duración de la pose final con efecto elástico
@export var zoom_in: float = 1.25                  ## Nivel de zoom de cámara durante la carga
@export var dim_amount: float = 0.55               ## Nivel de oscurecimiento del escenario (0 a 1)

@export_group("Sprites y Efectos")
@export var transformed_frames: SpriteFrames       ## SpriteFrames alternativo (opcional)
@export var use_particles: bool = true             ## Emisión de aura y explosión de chispas
@export var use_lightning: bool = true             ## Rayos procedimentales durante la carga
@export var aura_color: Color = Color(1.0, 0.85, 0.2) ## Color dorado del aura y energía
@export var body_center: Vector2 = Vector2(0, -6)  ## Centro del torso de Goku
@export var feet_offset: Vector2 = Vector2(0, 20)  ## Base de los pies de Goku en el suelo

var _active: bool = false
var _sprite: AnimatedSprite2D = null
var _cam: Camera2D = null
var _cam_zoom0: Vector2 = Vector2.ONE
var _sprite_pos0: Vector2 = Vector2.ZERO
var _sprite_scale0: Vector2 = Vector2.ONE
var _z0: int = 0
var _temp: Array[Node] = []
var _tweens: Array[Tween] = []

func enter() -> void:
	_active = true
	character.velocity = Vector2.ZERO
	character.invulnerable = true
	character.begin_transform()

	_sprite = character.get_node_or_null("AnimatedSprite2D")
	if _sprite:
		_sprite_pos0 = _sprite.position
		_sprite_scale0 = _sprite.scale

	_z0 = character.z_index
	_cam = get_viewport().get_camera_2d()
	if _cam:
		_cam_zoom0 = _cam.zoom

	_play_sequence()

func exit() -> void:
	_active = false
	_cleanup()
	if character:
		character.invulnerable = false

func physics_update(_delta: float) -> void:
	# Sin movimiento ni ataques durante la cinemática
	character.velocity.x = 0.0
	if not character.is_on_floor():
		character.velocity.y += 980.0 * _delta
	character.move_and_slide()

# ---------------------------------------------------------------------------
# Secuencia Cinemática
# ---------------------------------------------------------------------------

func _play_sequence() -> void:
	if not _sprite:
		_sprite = character.get_node_or_null("AnimatedSprite2D")
	if not _sprite:
		return

	character.play_animation("idle")
	character.z_index = 100                        # El personaje resalta sobre la oscuridad

	# FASE 0: Hitstop y oscurecer el escenario
	var dark: ColorRect = _make_dim()
	await _hitstop(0.12)
	if not _active or not is_instance_valid(self):
		return

	if is_instance_valid(dark):
		_tween().tween_property(dark, "color:a", dim_amount, 0.25)

	# FASE 1: Carga de poder con aura, zoom y temblor
	if use_particles:
		_start_aura()

	if _cam and is_instance_valid(_cam):
		var zt: Tween = _tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		zt.tween_property(_cam, "zoom", _cam_zoom0 * zoom_in, charge_time)

	_charge_shake()

	var elapsed: float = 0.0
	var next_ring: float = 0.0
	while elapsed < charge_time:
		if use_lightning:
			var bolts: int = 1 + int(elapsed / charge_time * 3.0)  # Más rayos al acumular energía
			for i in bolts:
				_spawn_lightning()
		if elapsed >= next_ring:
			_spawn_ring(1.6, 0.5)
			next_ring += 0.35
		await get_tree().create_timer(0.1).timeout
		if not _active or not is_instance_valid(self):
			return
		elapsed += 0.1

	# FASE 2: Explosión de Ki y despertar del Super Saiyajin
	await _hitstop(0.08)
	if not _active or not is_instance_valid(self):
		return

	_flash(0.45)
	if _sprite and is_instance_valid(_sprite):
		_sprite.position = _sprite_pos0
		if transformed_frames:
			_sprite.sprite_frames = transformed_frames
			_sprite.play("idle")

	# Aplicar buffs y actualizar sprite a Super Saiyajin
	character.finish_transform()

	_spawn_ring(7.0, 0.5)
	_spawn_ring(10.0, 0.7)
	if use_particles:
		_burst_particles()

	_shake_camera(8.0, 0.4)

	if _cam and is_instance_valid(_cam):
		var zt2: Tween = _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		zt2.tween_property(_cam, "zoom", _cam_zoom0, 0.35)

	# FASE 3: Pose final con "pop" elástico y retorno de la iluminación
	if _sprite and is_instance_valid(_sprite):
		_sprite.scale = _sprite_scale0 * 1.25
		var st: Tween = _tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		st.tween_property(_sprite, "scale", _sprite_scale0, hold_time)

	await get_tree().create_timer(hold_time).timeout
	if not _active or not is_instance_valid(self):
		return

	if is_instance_valid(dark):
		var out: Tween = _tween()
		out.tween_property(dark, "color:a", 0.0, 0.3)
		await out.finished

	# Retornar el control en estado Idle ya transformado
	if _active and state_machine:
		state_machine.transition_to("Idle")

# ---------------------------------------------------------------------------
# Efectos Visuales Procedimentales
# ---------------------------------------------------------------------------

func _hitstop(time: float) -> void:
	Engine.time_scale = 0.05
	# ignore_time_scale = true en el timer
	await get_tree().create_timer(time, true, false, true).timeout
	Engine.time_scale = 1.0

func _make_dim() -> ColorRect:
	# Capa oscura que envuelve el mundo por debajo del personaje (z_index 90 < 100)
	var r := ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.size = Vector2(6000, 6000)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.z_as_relative = false
	r.z_index = 90

	var scene_root: Node = get_tree().current_scene
	if scene_root:
		scene_root.add_child(r)
	else:
		character.get_parent().add_child(r)

	r.global_position = character.global_position - r.size / 2.0
	_temp.append(r)
	return r

func _charge_shake() -> void:
	# Temblor horizontal del sprite con amplitud creciente
	if not _sprite:
		return
	var tw: Tween = _tween()
	var steps: int = int(charge_time / 0.04)
	for i in steps:
		var amp: float = lerpf(1.0, 4.0, float(i) / steps)
		var dx: float = amp if i % 2 == 0 else -amp
		tw.tween_property(_sprite, "position:x", _sprite_pos0.x + dx, 0.04)

func _flash(time: float) -> void:
	# Destello blanco de pantalla completa (óptimo para Compatibility)
	var scene_root: Node = get_tree().current_scene
	if not scene_root:
		scene_root = character.get_tree().root

	var layer := CanvasLayer.new()
	layer.layer = 100
	var rect := ColorRect.new()
	rect.color = Color(1.0, 1.0, 1.0, 1.0)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(rect)
	scene_root.add_child(layer)
	_temp.append(layer)

	var tw: Tween = _tween()
	tw.tween_property(rect, "color:a", 0.0, time)
	tw.tween_callback(func():
		if is_instance_valid(layer):
			layer.queue_free()
	)

func _shake_camera(intensity: float, time: float) -> void:
	if _cam == null:
		_cam = get_viewport().get_camera_2d()
	if _cam == null:
		return

	var tw: Tween = _tween()
	var steps: int = int(time / 0.03)
	for i in steps:
		var off := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * intensity
		tw.tween_property(_cam, "offset", off, 0.03)
	tw.tween_property(_cam, "offset", Vector2.ZERO, 0.03)

func _spawn_ring(max_scale: float, time: float) -> void:
	# Onda elíptica de energía en el suelo (Line2D expandiéndose)
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in 33:
		var a: float = TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	ring.points = pts
	ring.width = 1.5
	ring.default_color = aura_color
	ring.scale = Vector2(0.2, 0.06)
	ring.position = feet_offset
	character.add_child(ring)
	_temp.append(ring)

	var tw: Tween = _tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(max_scale, max_scale * 0.3), time)
	tw.tween_property(ring, "modulate:a", 0.0, time)
	tw.chain().tween_callback(func():
		if is_instance_valid(ring):
			ring.queue_free()
	)

func _spawn_lightning() -> void:
	# Rayos procedimentales en zigzag alrededor del cuerpo
	var bolt := Line2D.new()
	bolt.width = 1.5
	bolt.default_color = Color(1.0, 1.0, 0.6)
	var start: Vector2 = body_center + Vector2.from_angle(randf() * TAU) * randf_range(30.0, 50.0)
	var tip: Vector2 = body_center + Vector2(randf_range(-6.0, 6.0), randf_range(-12.0, 12.0))
	var pts := PackedVector2Array([start])
	for i in range(1, 5):
		var p: Vector2 = start.lerp(tip, i / 5.0)
		pts.append(p + Vector2(randf_range(-6.0, 6.0), randf_range(-6.0, 6.0)))
	pts.append(tip)
	bolt.points = pts
	character.add_child(bolt)
	_temp.append(bolt)

	get_tree().create_timer(0.07).timeout.connect(func():
		if is_instance_valid(bolt):
			bolt.queue_free()
	)

func _start_aura() -> void:
	# Aura continua de chispas ascendentes desde los pies
	var p := CPUParticles2D.new()
	p.amount = 28
	p.lifetime = 0.8
	p.direction = Vector2.UP
	p.spread = 25.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = aura_color
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(10, 2)
	p.position = feet_offset
	character.add_child(p)
	p.emitting = true
	_temp.append(p)

func _burst_particles() -> void:
	# Gran explosión radial de 60 partículas en todas direcciones
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 60
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 120.0
	p.initial_velocity_max = 280.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color = aura_color
	p.position = body_center
	character.add_child(p)
	p.emitting = true
	_temp.append(p)

# ---------------------------------------------------------------------------
# Gestión de Tweens y Limpieza
# ---------------------------------------------------------------------------

func _tween() -> Tween:
	var t: Tween = create_tween()
	_tweens.append(t)
	return t

func _cleanup() -> void:
	Engine.time_scale = 1.0
	for t in _tweens:
		if t and t.is_valid():
			t.kill()
	_tweens.clear()

	for n in _temp:
		if is_instance_valid(n):
			n.queue_free()
	_temp.clear()

	if _sprite and is_instance_valid(_sprite):
		_sprite.position = _sprite_pos0
		_sprite.scale = _sprite_scale0

	if character and is_instance_valid(character):
		character.z_index = _z0

	if _cam and is_instance_valid(_cam):
		_cam.zoom = _cam_zoom0
		_cam.offset = Vector2.ZERO

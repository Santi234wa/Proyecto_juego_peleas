## sharingan_transforming_state.gd
## Secuencia cinematográfica de transformación de Madara Uchiha: Despertar del Sharingan.
## Hereda de TransformingState y personaliza la cinemática:
##   - Madara levanta la cabeza lentamente (animación 'sharingan_transform').
##   - La pantalla se oscurece con un tinte carmesí.
##   - Se concentran partículas de chakra carmesí oscuro y se genera un destello ocular.
##   - Explosión de energía Sharingan con ondas en el suelo y flash rojo.
##   - Activación de buffs y aura de combate.
class_name SharinganTransformingState
extends TransformingState

@export var eye_offset: Vector2 = Vector2(3.0, -14.0) ## Posición aproximada de los ojos en el sprite
@export var sharingan_color: Color = Color(0.95, 0.12, 0.18) ## Rojo Sharingan brillante
@export var dark_chakra_color: Color = Color(0.35, 0.05, 0.12) ## Rojo sangre profundo

func enter() -> void:
	charge_time = 1.25
	hold_time = 0.50
	zoom_in = 1.20
	dim_amount = 0.50
	aura_color = sharingan_color
	flash_color = Color(0.88, 0.10, 0.15)
	use_lightning = false
	super.enter()

func _play_sequence() -> void:
	if not _sprite:
		_sprite = character.get_node_or_null("AnimatedSprite2D")
	if not _sprite:
		return

	# Madara levanta lentamente la cabeza
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("sharingan_transform"):
		_sprite.play("sharingan_transform")
	elif _sprite.sprite_frames and _sprite.sprite_frames.has_animation("transform"):
		_sprite.play("transform")
	else:
		character.play_animation("idle")

	character.z_index = 100

	# FASE 0: Oscurecer el escenario con viñeta sombría
	var dark: ColorRect = _make_dim()
	if is_instance_valid(dark):
		_tween().tween_property(dark, "color", Color(0.04, 0.01, 0.02, dim_amount), 0.3)

	# FASE 1: Concentración de chakra Sharingan y zoom a los ojos
	if _cam and is_instance_valid(_cam):
		var zt: Tween = _tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		zt.tween_property(_cam, "zoom", _cam_zoom0 * zoom_in, charge_time)

	# Temblor concentrado
	_charge_shake()

	var elapsed: float = 0.0
	var next_ring: float = 0.0
	while elapsed < charge_time:
		if use_particles:
			_spawn_sharingan_spark()
		if elapsed >= next_ring:
			_spawn_ring(1.5, 0.45)
			next_ring += 0.35
		await get_tree().create_timer(0.08).timeout
		if not _active or not is_instance_valid(self):
			return
		elapsed += 0.08

	# Destello en los ojos (Eye flare)
	_spawn_eye_flare()

	# FASE 2: Despertar instantáneo del Sharingan
	await _hitstop(0.12)
	if not _active or not is_instance_valid(self):
		return

	_flash(0.40)
	if _sprite and is_instance_valid(_sprite):
		_sprite.position = _sprite_pos0
		if transformed_frames:
			_sprite.sprite_frames = transformed_frames
		_sprite.play("idle")

	# Aplicar buffs y activar estado transformado en CharacterBase
	character.finish_transform()

	_spawn_ring(8.5, 0.5)
	_spawn_ring(12.0, 0.7)

	if use_particles:
		_burst_sharingan_chakra()
		_start_aura()

	_shake_camera(7.0, 0.35)

	if _cam and is_instance_valid(_cam):
		var zt2: Tween = _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		zt2.tween_property(_cam, "zoom", _cam_zoom0, 0.35)

	# FASE 3: Pose final con "pop" elástico y retorno de la luz normal
	if _sprite and is_instance_valid(_sprite):
		_sprite.scale = _sprite_scale0 * 1.2
		var st: Tween = _tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		st.tween_property(_sprite, "scale", _sprite_scale0, hold_time)

	await get_tree().create_timer(hold_time).timeout
	if not _active or not is_instance_valid(self):
		return

	if is_instance_valid(dark):
		var out: Tween = _tween()
		out.tween_property(dark, "color:a", 0.0, 0.3)
		await out.finished

	# Retornar control en estado Idle ya con Sharingan activo
	if _active and state_machine:
		state_machine.transition_to("Idle")

# ---------------------------------------------------------------------------
# Efectos Propios del Sharingan
# ---------------------------------------------------------------------------

func _spawn_sharingan_spark() -> void:
	# Partículas de chakra carmesí que giran y convergen hacia el rostro
	var p := ColorRect.new()
	p.size = Vector2(2.5, 2.5)
	p.color = sharingan_color if randf() < 0.65 else dark_chakra_color
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rad: float = randf_range(40.0, 75.0)
	var ang: float = randf() * TAU
	p.position = body_center + Vector2(cos(ang), sin(ang)) * rad
	character.add_child(p)
	_temp.append(p)

	var dur: float = randf_range(0.45, 0.75)
	var tw: Tween = _tween().set_parallel(true)
	tw.tween_property(p, "position", body_center + eye_offset, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(p, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _spawn_eye_flare() -> void:
	# Resplandor ocular brillante rojo justo antes de la explosión
	var flare := Line2D.new()
	flare.width = 2.0
	flare.default_color = Color(1.0, 0.2, 0.2, 1.0)
	var eye_pt: Vector2 = body_center + eye_offset
	var dir_x: float = 1.0 if character.is_facing_right else -1.0
	flare.points = PackedVector2Array([
		eye_pt - Vector2(8.0 * dir_x, 0.0),
		eye_pt + Vector2(16.0 * dir_x, 0.0)
	])
	character.add_child(flare)
	_temp.append(flare)

	var tw: Tween = _tween().set_parallel(true)
	tw.tween_property(flare, "scale:x", 1.8, 0.15)
	tw.tween_property(flare, "modulate:a", 0.0, 0.2)
	tw.chain().tween_callback(func():
		if is_instance_valid(flare):
			flare.queue_free()
	)

func _burst_sharingan_chakra() -> void:
	# Explosión radial de chakra carmesí
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 50
	p.lifetime = 0.6
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2(0, 40)
	p.initial_velocity_min = 100.0
	p.initial_velocity_max = 240.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.5
	p.color = sharingan_color
	p.position = body_center
	character.add_child(p)
	p.emitting = true
	_temp.append(p)


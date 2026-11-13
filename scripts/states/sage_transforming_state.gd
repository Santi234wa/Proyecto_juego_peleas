## sage_transforming_state.gd
## Transformación de Naruto (Modo Sabio / Kurama).
## Hereda de TransformingState y personaliza la secuencia:
##   Goku = explosión violenta de Ki.
##   Naruto = calma, concentración de energía natural y liberación controlada.
##
## Secuencia:
##   1. El escenario se oscurece suavemente (dim 0.35); Naruto "respira" concentrado.
##   2. Partículas naranjas y verdes (energía natural) convergen hacia él.
##   3. Silencio breve (hitstop 0.15s) y liberación: pilar de luz, flash cálido,
##      ondas en el suelo y hojas de energía cayendo.
##   4. Pose final con "pop" elástico y retorno de la luz normal.
class_name SageTransformingState
extends TransformingState

@export var gather_color_b: Color = Color(0.55, 0.9, 0.4)  ## Verde de energía natural

func _init() -> void:
	charge_time = 1.5
	hold_time = 0.6
	zoom_in = 1.15
	dim_amount = 0.35
	aura_color = Color(1.0, 0.55, 0.1)      # Naranja chakra de Naruto
	flash_color = Color(1.0, 0.85, 0.5)     # Destello cálido ámbar
	use_lightning = false

func _play_sequence() -> void:
	if not _sprite:
		_sprite = character.get_node_or_null("AnimatedSprite2D")
	if not _sprite:
		return

	character.play_animation("idle")
	character.z_index = 100

	# FASE 0: Oscurecer suave
	var dark: ColorRect = _make_dim()
	if is_instance_valid(dark):
		_tween().tween_property(dark, "color:a", dim_amount, 0.4)

	# FASE 1: Concentración (respiración, partículas convergentes, ondas lentas)
	if _cam and is_instance_valid(_cam):
		var zt: Tween = _tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		zt.tween_property(_cam, "zoom", _cam_zoom0 * zoom_in, charge_time)

	_breathe()

	var elapsed: float = 0.0
	var next_ring: float = 0.0
	while elapsed < charge_time:
		if use_particles:
			for i in 3:
				_spawn_gather_particle()
		if elapsed >= next_ring:
			_spawn_ring(1.2, 0.8)
			next_ring += 0.5
		await get_tree().create_timer(0.08).timeout
		if not _active or not is_instance_valid(self):
			return
		elapsed += 0.08

	# FASE 2: Silencio y liberación de energía
	await _hitstop(0.15)
	if not _active or not is_instance_valid(self):
		return

	_flash(0.5)
	if _sprite and is_instance_valid(_sprite):
		_sprite.position = _sprite_pos0
		if transformed_frames:
			_sprite.sprite_frames = transformed_frames
			_sprite.play("idle")

	character.finish_transform()
	_spawn_light_pillar()
	_spawn_ring(8.0, 0.6)
	_spawn_ring(11.0, 0.8)

	if use_particles:
		_burst_leaves()
		_start_aura()

	_shake_camera(5.0, 0.35)
	if _cam and is_instance_valid(_cam):
		var zt2: Tween = _tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		zt2.tween_property(_cam, "zoom", _cam_zoom0, 0.4)

	# FASE 3: Pose final con "pop" elástico
	if _sprite and is_instance_valid(_sprite):
		_sprite.scale = _sprite_scale0 * 1.15
		var st: Tween = _tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		st.tween_property(_sprite, "scale", _sprite_scale0, hold_time)

	await get_tree().create_timer(hold_time).timeout
	if not _active or not is_instance_valid(self):
		return

	if is_instance_valid(dark):
		var out: Tween = _tween()
		out.tween_property(dark, "color:a", 0.0, 0.3)
		await out.finished

	# Retorno al estado Idle transformado
	if _active and state_machine:
		state_machine.transition_to("Idle")

# ---------------------------------------------------------------------------
# Efectos Propios de Modo Sabio
# ---------------------------------------------------------------------------

func _breathe() -> void:
	if not _sprite:
		return
	var tw: Tween = _tween()
	tw.set_loops(maxi(1, int(charge_time / 0.6)))
	tw.tween_property(_sprite, "position:y", _sprite_pos0.y - 1.5, 0.3).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_sprite, "position:y", _sprite_pos0.y + 1.0, 0.3).set_trans(Tween.TRANS_SINE)

func _spawn_gather_particle() -> void:
	# Cuadrito de energía natural que viaja desde lejos hacia el cuerpo
	var p := ColorRect.new()
	p.size = Vector2(3, 3)
	p.color = aura_color if randf() < 0.5 else gather_color_b
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.position = body_center + Vector2.from_angle(randf() * TAU) * randf_range(55.0, 85.0)
	character.add_child(p)
	_temp.append(p)

	var t: float = randf_range(0.6, 0.9)
	var tw: Tween = _tween().set_parallel(true)
	tw.tween_property(p, "position", body_center, t).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(p, "modulate:a", 0.0, t)
	tw.chain().tween_callback(func():
		if is_instance_valid(p):
			p.queue_free()
	)

func _spawn_light_pillar() -> void:
	# Columna vertical de luz natural ascendente
	var r := ColorRect.new()
	r.color = Color(aura_color.r, aura_color.g, aura_color.b, 0.55)
	r.size = Vector2(28, 400)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.position = Vector2(-14, -400) + feet_offset
	r.pivot_offset = Vector2(14, 400)
	character.add_child(r)
	_temp.append(r)

	var tw: Tween = _tween().set_parallel(true)
	tw.tween_property(r, "scale:x", 0.0, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tw.tween_property(r, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(func():
		if is_instance_valid(r):
			r.queue_free()
	)

func _burst_leaves() -> void:
	# Explosión de energía naranja y verde que desciende suavemente
	for c in [aura_color, gather_color_b]:
		var p := CPUParticles2D.new()
		p.one_shot = true
		p.explosiveness = 1.0
		p.amount = 36
		p.lifetime = 0.9
		p.direction = Vector2.UP
		p.spread = 180.0
		p.gravity = Vector2(0, 120)
		p.initial_velocity_min = 80.0
		p.initial_velocity_max = 220.0
		p.scale_amount_min = 2.0
		p.scale_amount_max = 4.0
		p.color = c
		p.position = body_center
		character.add_child(p)
		p.emitting = true
		_temp.append(p)

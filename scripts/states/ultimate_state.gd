## ultimate_state.gd
## Ultimate "Rayo del amanecer". Hereda de TransformingState para reutilizar
## sus efectos (hitstop, oscurecer, flash, temblor de cámara, limpieza).
##
## Secuencia (~3.5 s):
##   1. Hitstop, tinte verde azulado, bandas de cine
##   2. Primer plano del rostro con líneas de velocidad
##   3. Esfera de carga y rayo dorado cruzando la pantalla, con astillas
##   4. Impacto: flash, ondas, daño y empuje al rival, banner con el nombre
class_name UltimateState
extends TransformingState

@export_group("Ultimate - Configuración")
@export var ultimate_name: String = "Rayo del amanecer"
@export var portrait: Texture2D                 ## Imagen del primer plano (PixelLab / retrato frontal)
@export var font: Font                          ## Fuente del banner (Pixelify Sans con inclinación)
@export var damage: float = 40.0
@export var knockback: float = 500.0
@export var tint_color: Color = Color(0.12, 0.43, 0.47)
@export var beam_color: Color = Color(1.0, 0.82, 0.25)
@export var beam_core_color: Color = Color(1.0, 0.97, 0.8)
@export var shard_color_a: Color = Color(0.18, 0.5, 0.53)
@export var shard_color_b: Color = Color(1.0, 0.94, 0.63)
@export var hand_offset: Vector2 = Vector2(26, -8)    ## Punto de origen relativo del rayo (altura de manos/pecho)
@export var beam_length: float = 2200.0
@export var closeup_time: float = 0.9
@export var orb_time: float = 0.6
@export var beam_time: float = 0.9
@export var banner_time: float = 0.7
@export var bar_height: float = 40.0

var _dir: float = 1.0
var _rival: Node2D = null
var _beam: Node2D = null
var _orb: Node2D = null

func enter() -> void:
	_active = true
	character.velocity = Vector2.ZERO
	character.invulnerable = true
	character.begin_ultimate()
	_sprite = character.get_node_or_null("AnimatedSprite2D")
	if _sprite:
		_sprite_pos0 = _sprite.position
		_sprite_scale0 = _sprite.scale
	_z0 = character.z_index
	_cam = get_viewport().get_camera_2d()
	if _cam:
		_cam_zoom0 = _cam.zoom
	_dir = 1.0 if character.is_facing_right else -1.0
	_rival = _get_rival()
	_ensure_resources()
	_play_sequence()

func _get_rival() -> Node2D:
	if character.has_method("get_opponent"):
		var opp: Node2D = character.get_opponent()
		if opp and is_instance_valid(opp):
			return opp
	var r = character.get("opponent")
	if r and is_instance_valid(r):
		return r
	for n in get_tree().get_nodes_in_group("fighters"):
		if n != character and n is Node2D:
			return n
	return null

func _load_texture(p_path: String) -> Texture2D:
	if ResourceLoader.exists(p_path):
		var res = load(p_path)
		if res is Texture2D:
			return res
	var global_p := ProjectSettings.globalize_path(p_path)
	if FileAccess.file_exists(global_p):
		var img := Image.new()
		if img.load(global_p) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _ensure_resources() -> void:
	# 1. Asignar imagen del primer plano cuando exista (retrato frontal SSJ si es Goku, o retrato normal)
	if not portrait and character and character.data:
		var p_path := ""
		if character.data.id == "goku":
			var ssj_p := "res://assets/sprites/goku/ssj_select_idle/ssj_select_idle_00.png"
			if ResourceLoader.exists(ssj_p) or FileAccess.file_exists(ProjectSettings.globalize_path(ssj_p)):
				p_path = ssj_p
		if p_path == "":
			if "sprite_dir_select" in character.data and character.data.sprite_dir_select != "":
				p_path = character.data.sprite_dir_select.path_join("select_idle_00.png")
			if p_path == "" or (not ResourceLoader.exists(p_path) and not FileAccess.file_exists(ProjectSettings.globalize_path(p_path))):
				p_path = "res://assets/sprites/%s/select_idle/select_idle_00.png" % character.data.id

		portrait = _load_texture(p_path)

	# 2. Asignar fuente estilizada del menú si no se asignó manualmente
	if not font:
		var font_file := "res://assets/fonts/PixelifySans-Regular.ttf"
		if ResourceLoader.exists(font_file):
			var f = load(font_file)
			if f is Font:
				var fv := FontVariation.new()
				fv.base_font = f
				fv.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(0.2, 1.0), Vector2.ZERO)
				font = fv

func _ensure_ssj_animations() -> void:
	if not _sprite or not _sprite.sprite_frames:
		return
	if character and character.data and character.data.id != "goku":
		return
	var frames: SpriteFrames = _sprite.sprite_frames
	
	if not frames.has_animation("ssj_charge"):
		_add_animation_from_dir(frames, "ssj_charge", "res://assets/sprites/goku/ssj_charge_south", "ssj_charge_south", 9, 10.0, true)
	
	if not frames.has_animation("ssj_ultimate"):
		_add_animation_from_dir(frames, "ssj_ultimate", "res://assets/sprites/goku/ssj_ultimate_east", "ssj_ultimate_east", 9, 10.0, true)

	if not frames.has_animation("ssj_select_idle"):
		_add_animation_from_dir(frames, "ssj_select_idle", "res://assets/sprites/goku/ssj_select_idle", "ssj_select_idle", 8, 8.0, true)

func _add_animation_from_dir(frames: SpriteFrames, anim_name: String, dir_path: String, prefix: String, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for i in range(count):
		var filename := "%s_%02d.png" % [prefix, i]
		var file_path := dir_path.path_join(filename)
		var tex := _load_texture(file_path)
		if tex:
			frames.add_frame(anim_name, tex)

# ---------------------------------------------------------------------------
# Secuencia Cinemática
# ---------------------------------------------------------------------------

func _play_sequence() -> void:
	_ensure_ssj_animations()
	character.z_index = 100
	var vp := get_viewport().get_visible_rect().size

	# FASE 1: Despertar & Transformación Épica en Super Saiyajin
	var dark := _make_dim()
	dark.color = Color(tint_color.r, tint_color.g, tint_color.b, 0.0)
	await _hitstop(0.12)
	if not _active or not is_instance_valid(self):
		return
	_tween().tween_property(dark, "color:a", 0.7, 0.2)
	var bars := _make_letterbox(vp)

	# Transformación inmediata a SSJ con buffs y aura:
	if character.has_method("finish_transform"):
		character.finish_transform()
		character.invulnerable = true
	
	# Reproducir animación de carga frontal con chispas de poder
	if _sprite:
		if _sprite.sprite_frames.has_animation("ssj_charge"):
			_sprite.play("ssj_charge")
		else:
			_sprite.play("ssj_idle")

	_flash(0.35)
	_shake_camera(4.0, 0.5)

	# Tiempo de acumulación de poder
	await get_tree().create_timer(0.55).timeout
	if not _active or not is_instance_valid(self):
		return

	# FASE 2: Primer plano (Close-up) con líneas de velocidad y rostro SSJ
	await _closeup(vp)
	if not _active or not is_instance_valid(self):
		return

	# FASE 3: Postura de combate este ("ssj_ultimate"), esfera y rayo
	if _sprite:
		if _sprite.sprite_frames.has_animation("ssj_ultimate"):
			_sprite.play("ssj_ultimate")
		elif _sprite.sprite_frames.has_animation("ssj_attack"):
			_sprite.play("ssj_attack")
		_sprite.flip_h = (_dir < 0.0)

	await _fire_beam()
	if not _active or not is_instance_valid(self):
		return

	# FASE 4: Impacto, ondas masivas, daño, knockback y banner del ataque
	await _impact(vp, dark, bars)

	# Al culminar el Ultimate, Goku permanece transformado en Super Saiyajin
	# con Ki asignado para permitir seguir peleando en modo SSJ
	if character:
		var ssj_ki: float = character.data.energy_cost_transform if character.data else 40.0
		character.current_energy = maxf(character.current_energy, ssj_ki)
		var max_e: float = character.data.max_energy if character.data else 100.0
		character.emit_signal("energy_changed", character.current_energy, max_e)

	if _active and state_machine:
		state_machine.transition_to("Idle")

func _make_letterbox(vp: Vector2) -> Array[ColorRect]:
	var layer := CanvasLayer.new()
	layer.layer = 90
	var top := ColorRect.new()
	top.color = Color.BLACK
	top.size = Vector2(vp.x, bar_height)
	top.position = Vector2(0, -bar_height)
	var bottom := ColorRect.new()
	bottom.color = Color.BLACK
	bottom.size = Vector2(vp.x, bar_height)
	bottom.position = Vector2(0, vp.y)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top)
	layer.add_child(bottom)
	get_tree().current_scene.add_child(layer)
	_temp.append(layer)
	var tw := _tween().set_parallel(true)
	tw.tween_property(top, "position:y", 0.0, 0.25)
	tw.tween_property(bottom, "position:y", vp.y - bar_height, 0.25)
	var out: Array[ColorRect] = [top, bottom]
	return out

func _closeup(vp: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 95
	get_tree().current_scene.add_child(layer)
	_temp.append(layer)

	# Líneas de velocidad hacia el centro
	var center := vp * 0.5
	for i in 16:
		var start := center + Vector2.from_angle(randf() * TAU) * vp.length() * 0.6
		var line := Line2D.new()
		line.width = 2.0
		line.default_color = Color(0.81, 0.94, 0.94, 0.5)
		line.points = PackedVector2Array([start, start.lerp(center, 0.45)])
		layer.add_child(line)

	# Recuadro inclinado con el retrato (el UV recorta la imagen al polígono)
	var pw := vp.x * 0.5
	var ph := vp.y * 0.5
	var s := ph * 0.25
	var pts := PackedVector2Array([Vector2(s, 0), Vector2(pw, 0), Vector2(pw - s, ph), Vector2(0, ph)])
	var panel := Node2D.new()
	var face := Polygon2D.new()
	face.polygon = pts
	face.color = tint_color
	if portrait:
		var ts := portrait.get_size()
		var uvs := PackedVector2Array()
		for p in pts:
			uvs.append(Vector2(p.x / pw * ts.x, p.y / ph * ts.y))
		face.texture = portrait
		face.uv = uvs
		face.color = Color.WHITE
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var outline := Line2D.new()
	outline.points = pts
	outline.closed = true
	outline.width = 4.0
	outline.default_color = Color(0.08, 0.08, 0.08)
	panel.add_child(face)
	panel.add_child(outline)
	layer.add_child(panel)

	var final_pos := Vector2((vp.x - pw) * 0.5, (vp.y - ph) * 0.5)
	var off_x := -pw if _dir > 0.0 else vp.x
	panel.position = Vector2(off_x, final_pos.y)
	var tw := _tween()
	tw.tween_property(panel, "position:x", final_pos.x, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Temblor creciente mientras dura el primer plano
	var steps := int(closeup_time / 0.04)
	for i in steps:
		var amp := lerpf(1.0, 6.0, float(i) / steps)
		var dy := amp if i % 2 == 0 else -amp
		tw.tween_property(panel, "position:y", final_pos.y + dy, 0.04)
	await get_tree().create_timer(closeup_time).timeout
	if not _active or not is_instance_valid(self):
		return
	var out := _tween()
	out.tween_property(panel, "position:x", off_x, 0.15)
	await out.finished
	if is_instance_valid(layer):
		layer.queue_free()

func _fire_beam() -> void:
	var origin: Vector2 = character.global_position + Vector2(hand_offset.x * _dir, hand_offset.y)
	var scene := get_tree().current_scene

	# Esfera de carga con partículas que convergen
	_orb = _make_circle(6.0, beam_color)
	_orb.global_position = origin
	_orb.z_as_relative = false
	_orb.z_index = 96
	scene.add_child(_orb)
	_temp.append(_orb)
	_tween().tween_property(_orb, "scale", Vector2(3.0, 3.0), orb_time).set_trans(Tween.TRANS_QUAD)
	var t := 0.0
	while t < orb_time:
		_spawn_converge(origin)
		await get_tree().create_timer(0.06).timeout
		if not _active or not is_instance_valid(self):
			return
		t += 0.06

	# Rayo: cuña dorada con núcleo blanco que se estira hacia el rival
	_beam = Node2D.new()
	_beam.global_position = origin
	_beam.scale = Vector2(0.0, 1.0)
	_beam.z_as_relative = false
	_beam.z_index = 95
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([Vector2(0, -5), Vector2(beam_length, -46), Vector2(beam_length, 46), Vector2(0, 5)])
	outer.color = beam_color
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -2), Vector2(beam_length, -18), Vector2(beam_length, 18), Vector2(0, 2)])
	core.color = beam_core_color
	_beam.add_child(outer)
	_beam.add_child(core)
	scene.add_child(_beam)
	_temp.append(_beam)
	_tween().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT).tween_property(_beam, "scale:x", _dir, 0.15)
	_shake_camera(7.0, beam_time)

	# Pulso del grosor del rayo
	var pulse := _tween()
	pulse.set_loops(maxi(1, int(beam_time / 0.12)))
	pulse.tween_property(_beam, "scale:y", 1.15, 0.06)
	pulse.tween_property(_beam, "scale:y", 0.85, 0.06)

	# Astillas de escombros
	var e := 0.0
	while e < beam_time:
		for i in 3:
			_spawn_shard(origin)
		await get_tree().create_timer(0.05).timeout
		if not _active or not is_instance_valid(self):
			return
		e += 0.05

func _impact(vp: Vector2, dark: ColorRect, bars: Array[ColorRect]) -> void:
	var hit_pos: Vector2 = character.global_position + Vector2(300.0 * _dir, hand_offset.y)
	if _rival and is_instance_valid(_rival):
		hit_pos = _rival.global_position
	_flash(0.5)
	_shake_camera(10.0, 0.45)
	_ring_world(hit_pos, 6.0, 0.5)
	_ring_world(hit_pos, 9.0, 0.7)
	if use_particles:
		_burst_at(hit_pos)

	# El rayo y la esfera se desvanecen
	if _beam and is_instance_valid(_beam) and _orb and is_instance_valid(_orb):
		var fade := _tween().set_parallel(true)
		fade.tween_property(_beam, "modulate:a", 0.0, 0.25)
		fade.tween_property(_orb, "modulate:a", 0.0, 0.25)

	# Daño y empuje al rival
	if _rival and is_instance_valid(_rival):
		if _rival.has_method("take_damage"):
			_rival.take_damage(damage)
		if _rival.has_method("apply_knockback"):
			_rival.apply_knockback(Vector2(_dir * knockback, -150.0))
		else:
			var kb := _tween()
			kb.tween_property(_rival, "global_position:x", _rival.global_position.x + _dir * knockback * 0.4, 0.35).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)

	await _show_banner(vp)
	if not _active or not is_instance_valid(self):
		return

	# Vuelve la luz y se retiran las bandas
	if is_instance_valid(dark) and bars.size() >= 2:
		var out := _tween().set_parallel(true)
		out.tween_property(dark, "color:a", 0.0, 0.3)
		if is_instance_valid(bars[0]):
			out.tween_property(bars[0], "position:y", -bar_height, 0.25)
		if is_instance_valid(bars[1]):
			out.tween_property(bars[1], "position:y", vp.y, 0.25)
		await out.finished

func _show_banner(vp: Vector2) -> void:
	var layer := CanvasLayer.new()
	layer.layer = 99
	get_tree().current_scene.add_child(layer)
	_temp.append(layer)
	var bw := vp.x * 0.6
	var bh := 56.0
	var s := 18.0
	var pts := PackedVector2Array([Vector2(s, 0), Vector2(bw, 0), Vector2(bw - s, bh), Vector2(0, bh)])
	var banner := Node2D.new()
	var bg := Polygon2D.new()
	bg.polygon = pts
	bg.color = Color("#FFD23F")
	var ol := Line2D.new()
	ol.points = pts
	ol.closed = true
	ol.width = 3.0
	ol.default_color = Color("#151515")
	var label := Label.new()
	label.text = ultimate_name
	label.size = Vector2(bw, bh)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", Color("#151515"))
	label.add_theme_font_size_override("font_size", 28)
	if font:
		label.add_theme_font_override("font", font)
	banner.add_child(bg)
	banner.add_child(ol)
	banner.add_child(label)
	layer.add_child(banner)
	var final_pos := Vector2((vp.x - bw) * 0.5, vp.y * 0.62)
	banner.position = Vector2(-bw, final_pos.y)
	var tw := _tween()
	tw.tween_property(banner, "position", final_pos, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(banner_time)
	tw.tween_property(banner, "position:x", vp.x, 0.2)
	await tw.finished

# ---------------------------------------------------------------------------
# Efectos Propios
# ---------------------------------------------------------------------------

func _make_circle(radius: float, color: Color) -> Polygon2D:
	var p := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(Vector2(cos(a), sin(a)) * radius)
	p.polygon = pts
	p.color = color
	return p

func _spawn_converge(origin: Vector2) -> void:
	var p := Polygon2D.new()
	p.polygon = PackedVector2Array([Vector2(-2, -2), Vector2(2, -2), Vector2(2, 2), Vector2(-2, 2)])
	p.color = beam_color
	p.global_position = origin + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 80.0)
	p.z_as_relative = false
	p.z_index = 96
	get_tree().current_scene.add_child(p)
	_temp.append(p)
	var tw := _tween().set_parallel(true)
	tw.tween_property(p, "global_position", origin, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(p, "modulate:a", 0.0, 0.3)
	tw.chain().tween_callback(p.queue_free)

func _spawn_shard(origin: Vector2) -> void:
	var shard := Polygon2D.new()
	var sz := randf_range(6.0, 16.0)
	shard.polygon = PackedVector2Array([Vector2(0, -sz), Vector2(sz * 0.6, sz * 0.5), Vector2(-sz * 0.4, sz * 0.4)])
	shard.color = shard_color_a if randf() < 0.7 else shard_color_b
	var along := randf_range(80.0, beam_length * 0.5)
	shard.global_position = origin + Vector2(along * _dir, randf_range(-30.0, 30.0))
	shard.rotation = randf() * TAU
	shard.z_as_relative = false
	shard.z_index = 94
	get_tree().current_scene.add_child(shard)
	_temp.append(shard)
	var drift := Vector2(randf_range(60.0, 160.0) * _dir, randf_range(-140.0, 140.0))
	var tw := _tween().set_parallel(true)
	tw.tween_property(shard, "global_position", shard.global_position + drift, 0.5)
	tw.tween_property(shard, "rotation", shard.rotation + randf_range(-6.0, 6.0), 0.5)
	tw.tween_property(shard, "modulate:a", 0.0, 0.5)
	tw.chain().tween_callback(shard.queue_free)

func _ring_world(pos: Vector2, max_scale: float, time: float) -> void:
	var ring := Line2D.new()
	var pts := PackedVector2Array()
	for i in 33:
		var a := TAU * i / 32.0
		pts.append(Vector2(cos(a), sin(a)) * 20.0)
	ring.points = pts
	ring.width = 3.0
	ring.default_color = beam_color
	ring.global_position = pos
	ring.scale = Vector2(0.2, 0.2)
	ring.z_as_relative = false
	ring.z_index = 97
	get_tree().current_scene.add_child(ring)
	_temp.append(ring)
	var tw := _tween().set_parallel(true)
	tw.tween_property(ring, "scale", Vector2(max_scale, max_scale), time)
	tw.tween_property(ring, "modulate:a", 0.0, time)
	tw.chain().tween_callback(ring.queue_free)

func _burst_at(pos: Vector2) -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = 70
	p.lifetime = 0.7
	p.direction = Vector2.UP
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 140.0
	p.initial_velocity_max = 320.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 5.0
	p.color = beam_color
	p.global_position = pos
	p.z_as_relative = false
	p.z_index = 97
	get_tree().current_scene.add_child(p)
	_temp.append(p)
	p.emitting = true


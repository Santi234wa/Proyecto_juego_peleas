## main_menu.gd
## Menú Principal de DRAGON BALL: ECOS (Fase 9 · Módulo A1 - Rediseño Visual Definitivo).
## Dirección Artística: Manga japonés + Dragon Ball + Arcade de lucha 2D + Pixel Art.
## Canvas base: 680x400 con escalado proporcional controlado y filtrado Nearest.
class_name MainMenu
extends Control

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------
signal start_local_mode()
signal option_selected(option_name: String)
signal menu_exited()

# ---------------------------------------------------------------------------
# Variables Exportadas
# ---------------------------------------------------------------------------
@export_group("Textos y Título")
@export var game_title: String = "DRAGON BALL: ECOS"
@export var local_map_scene_path: String = "res://scenes/maps/valle_del_fin.tscn"

@export_group("Tipografía")
@export var font_path: String = "res://assets/fonts/PixelifySans-Regular.ttf"
@export var font_shear: float = 0.2 ## Inclinación para efecto cursiva manga

@export_group("Personaje")
@export var character_scale: Vector2 = Vector2(6.0, 6.0)   ## Escala entera 6x para encaje perfecto
@export var character_ground_x: float = 105.0              ## Centro horizontal sobre la barra
@export var feet_y_offset: float = 23.0                    ## Ajuste del centro de la textura al suelo
@export var char_exit_time: float = 0.10                   ## Salida rápida (0.10s)
@export var char_enter_time: float = 0.16                  ## Entrada fluida (0.16s, TRANS_BACK)
@export var char_slide_offset: float = 35.0                ## Desplazamiento horizontal de transición
@export var breath_cycle_time: float = 0.75                ## Tiempo de respiración sutil

@export_group("Duraciones de Animación")
@export var bg_transition_time: float = 0.40        ## Fundido cruzado de escenarios (0.40 s)
@export var bg_parallax_offset: float = 4.0         ## Desplazamiento sutil de paralaje (4 px)
@export var option_slide_time: float = 0.10         ## Tiempo de respuesta del panel seleccionado

@export_group("Paleta de Color Manga")
@export var color_panel_orange: Color = Color(0.949, 0.549, 0.157)  ## #F28C28 Naranja manga
@export var color_dot_pattern: Color = Color(0.851, 0.451, 0.102)   ## #D9731A Halftone dots
@export var color_speed_lines: Color = Color(1.0, 0.761, 0.400)     ## #FFC266 Rayos / velocidad
@export var color_stripe_black: Color = Color(0.082, 0.082, 0.082)  ## #151515 Negro puro
@export var color_stripe_yellow: Color = Color(1.0, 0.824, 0.247)  ## #FFD23F Amarillo Dragon Ball
@export var color_ball_orange: Color = Color(0.96, 0.48, 0.08)     ## Naranja esfera del dragón
@export var color_ball_star: Color = Color(0.88, 0.15, 0.15)       ## Rojo estrella esfera
@export var color_panel_dark: Color = Color(0.18, 0.12, 0.28)      ## #2D1F47 Morado oscuro reposo
@export var color_panel_dark_border: Color = Color(0.10, 0.06, 0.16)
@export var color_text_disabled: Color = Color("b8b0c8")            ## Gris lila deshabilitado
@export var color_badge_bg: Color = Color(0.082, 0.082, 0.082)
@export var color_badge_text: Color = Color(1.0, 0.824, 0.247)

# ---------------------------------------------------------------------------
# Constantes de Diseño y Layout
# ---------------------------------------------------------------------------
const BASE_W: float = 680.0
const BASE_H: float = 400.0
const BG_NEUTRAL_X: float = -8.0

const OPTIONS_DEF: Array[Dictionary] = [
	{"id": "story",    "label": "Modo historia", "enabled": true},
	{"id": "local",    "label": "Modo local",    "enabled": true},
	{"id": "vs_ai",    "label": "VS IA",         "enabled": true},
	{"id": "training", "label": "Entrenamiento", "enabled": false},
	{"id": "shop",     "label": "Tienda",        "enabled": false},
	{"id": "options",  "label": "Opciones",      "enabled": false},
	{"id": "exit",     "label": "Salir",         "enabled": true},
]

const STORY_SUBMENU_DEF: Array[Dictionary] = [
	{"id": "continue", "label": "Continuar"},
	{"id": "chapters", "label": "Capítulos"},
]

const MAP_ASSOCIATIONS: Dictionary = {
	"story": "res://assets/maps/valle_del_fin.png",
	"local": "res://assets/maps/torneo_artes_marciales.png",
	"vs_ai": "res://assets/maps/dimension_ecos.png",
}

# ---------------------------------------------------------------------------
# Estado Interno y Referencias
# ---------------------------------------------------------------------------
var _current_index: int = 0
var _in_story_submenu: bool = false
var _story_sub_index: int = 0

var _content: Control = null
var _bg_layer: Control = null
var _bg_current: TextureRect = null
var _bg_incoming: TextureRect = null
var _bg_dimmer: ColorRect = null
var _bg_tween: Tween = null
var _active_map_path: String = ""
var _map_texture_cache: Dictionary = {}

var _panel_manga: Control = null
var _logo_container: Control = null
var _options_container: Control = null
var _story_submenu_panel: Control = null
var _story_sub_nodes: Array[Control] = []

var _char_holder: Control = null
var _char_slider: Node2D = null
var _character_sprite: AnimatedSprite2D = null
var _char_shadow: Control = null
var _char_tween: Tween = null
var _breath_tween: Tween = null
var _displayed_char_idx: int = -1
var _default_frames_cache: Dictionary = {}

var _option_nodes: Array[Control] = []
var _sfx_move: AudioStreamPlayer = null
var _sfx_choose: AudioStreamPlayer = null
var _sfx_error: AudioStreamPlayer = null
var _italic_font: FontVariation = null
var _mouse_has_moved: bool = false

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Contenedor raíz proporcional 680x400
	_content = Control.new()
	_content.name = "CanvasBase"
	_content.custom_minimum_size = Vector2(BASE_W, BASE_H)
	_content.size = Vector2(BASE_W, BASE_H)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_setup_italic_font()

	# Construir las capas visuales
	_build_layer_1_background()
	_build_layer_2_diagonal_manga_panel()
	_build_layer_3_character()
	_build_layer_4_logo()
	_build_layer_5_options_column()
	_build_layer_6_story_submenu()
	_build_layer_7_bottom_bar()
	_setup_audio_players()

	_rescale_canvas()

	# Estado inicial: Modo historia (Goku en Valle del Fin)
	_current_index = 0
	_in_story_submenu = false
	_story_sub_index = 0
	_update_selection_visuals(false)
	_set_initial_character(0)
	_init_initial_background(0)
	_update_story_submenu_visibility(false)

	_play_intro_animations()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rescale_canvas()

func _rescale_canvas() -> void:
	if not _content:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var s: float = minf(vp_size.x / BASE_W, vp_size.y / BASE_H)
	_content.scale = Vector2(s, s)
	_content.position = (vp_size - Vector2(BASE_W, BASE_H) * s) / 2.0

func _setup_italic_font() -> void:
	_italic_font = FontVariation.new()
	if ResourceLoader.exists(font_path):
		var res = load(font_path)
		if res is Font:
			_italic_font.base_font = res
	_italic_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-font_shear, 1.0), Vector2.ZERO)

# ---------------------------------------------------------------------------
# CAPA 1: Fondos Dinámicos de Escenarios
# ---------------------------------------------------------------------------
func _build_layer_1_background() -> void:
	_bg_layer = Control.new()
	_bg_layer.name = "Layer1_Background"
	_bg_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_bg_layer)

	var bg_size := Vector2(BASE_W + 16.0, BASE_H)

	_bg_current = TextureRect.new()
	_bg_current.name = "BgCurrent"
	_bg_current.position = Vector2(BG_NEUTRAL_X, 0.0)
	_bg_current.size = bg_size
	_bg_current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_current.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_current.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_current.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_layer.add_child(_bg_current)

	_bg_incoming = TextureRect.new()
	_bg_incoming.name = "BgIncoming"
	_bg_incoming.position = Vector2(BG_NEUTRAL_X, 0.0)
	_bg_incoming.size = bg_size
	_bg_incoming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_incoming.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_bg_incoming.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_incoming.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_incoming.modulate.a = 0.0
	_bg_layer.add_child(_bg_incoming)

	# Atenuador lateral derecho para garantizar legibilidad óptima de los textos
	_bg_dimmer = ColorRect.new()
	_bg_dimmer.name = "BgDimmer"
	_bg_dimmer.position = Vector2(240.0, 0.0)
	_bg_dimmer.size = Vector2(BASE_W - 240.0, BASE_H)
	_bg_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_dimmer.color = Color(0.06, 0.04, 0.10, 0.32)
	_bg_layer.add_child(_bg_dimmer)

func _get_map_texture(path: String) -> Texture2D:
	if _map_texture_cache.has(path):
		return _map_texture_cache[path]
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			_map_texture_cache[path] = tex
			return tex
	return null

func _init_initial_background(option_idx: int) -> void:
	var opt_id: String = OPTIONS_DEF[option_idx]["id"] if option_idx >= 0 and option_idx < OPTIONS_DEF.size() else "story"
	var target_path: String = MAP_ASSOCIATIONS.get(opt_id, "res://assets/maps/valle_del_fin.png")
	_active_map_path = target_path
	var tex := _get_map_texture(target_path)
	if tex and _bg_current:
		_bg_current.texture = tex
		_bg_current.modulate.a = 1.0
		_bg_current.position.x = BG_NEUTRAL_X

func _change_background_for_option(option_idx: int) -> void:
	if option_idx < 0 or option_idx >= OPTIONS_DEF.size():
		return
	var opt_id: String = OPTIONS_DEF[option_idx]["id"]
	if not MAP_ASSOCIATIONS.has(opt_id):
		return # Mantener último fondo activo

	var target_path: String = MAP_ASSOCIATIONS[opt_id]
	if target_path == _active_map_path:
		return

	var next_tex: Texture2D = _get_map_texture(target_path)
	if not next_tex:
		return

	if _bg_tween and _bg_tween.is_valid():
		_bg_tween.kill()
		if _bg_incoming.texture:
			_bg_current.texture = _bg_incoming.texture
		_bg_current.modulate.a = 1.0
		_bg_current.position.x = BG_NEUTRAL_X
		_bg_incoming.modulate.a = 0.0

	_active_map_path = target_path
	_bg_incoming.texture = next_tex
	_bg_incoming.modulate.a = 0.0
	_bg_incoming.position.x = BG_NEUTRAL_X - bg_parallax_offset

	_bg_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_bg_tween.tween_property(_bg_current, "modulate:a", 0.0, bg_transition_time)
	_bg_tween.tween_property(_bg_current, "position:x", BG_NEUTRAL_X + bg_parallax_offset, bg_transition_time)
	_bg_tween.tween_property(_bg_incoming, "modulate:a", 1.0, bg_transition_time)
	_bg_tween.tween_property(_bg_incoming, "position:x", BG_NEUTRAL_X, bg_transition_time)

	_bg_tween.chain().tween_callback(func():
		_bg_current.texture = next_tex
		_bg_current.modulate.a = 1.0
		_bg_current.position.x = BG_NEUTRAL_X
		_bg_incoming.modulate.a = 0.0
	)

# ---------------------------------------------------------------------------
# CAPA 2: Panel Manga Diagonal (Zona Izquierda)
# ---------------------------------------------------------------------------
func _build_layer_2_diagonal_manga_panel() -> void:
	_panel_manga = Control.new()
	_panel_manga.name = "Layer2_DiagonalPanel"
	_panel_manga.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_manga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_panel_manga)
	_panel_manga.draw.connect(_on_draw_diagonal_panel)

func _on_draw_diagonal_panel() -> void:
	# 1. Polígono base naranja #F28C28
	var pts_panel := PackedVector2Array([
		Vector2(0, 0),
		Vector2(295, 0),
		Vector2(205, BASE_H),
		Vector2(0, BASE_H)
	])
	_panel_manga.draw_colored_polygon(pts_panel, color_panel_orange)

	# 2. Silueta decorativa manga de fondo
	var pts_silueta := PackedVector2Array([
		Vector2(30, 20),
		Vector2(140, 35),
		Vector2(195, 95),
		Vector2(165, 170),
		Vector2(200, 240),
		Vector2(130, 320),
		Vector2(40, 380),
		Vector2(0, 380),
		Vector2(0, 40)
	])
	_panel_manga.draw_colored_polygon(pts_silueta, Color(0.78, 0.35, 0.05, 0.40))

	# 3. Trama de puntos halftone #D9731A
	var step: float = 12.0
	var dot_r: float = 1.6
	for y in range(8, int(BASE_H), int(step)):
		var edge_x: float = 295.0 - 90.0 * (float(y) / BASE_H)
		var off_x: float = 6.0 if (int(y / step) % 2 == 1) else 0.0
		for x in range(int(off_x + 6), int(edge_x - 6), int(step)):
			_panel_manga.draw_circle(Vector2(x, y), dot_r, color_dot_pattern)

	# 4. Líneas diagonales de velocidad / impacto
	_panel_manga.draw_line(Vector2(0, 75), Vector2(210, 52), color_speed_lines, 2.5)
	_panel_manga.draw_line(Vector2(0, 155), Vector2(230, 128), color_speed_lines, 3.0)
	_panel_manga.draw_line(Vector2(0, 235), Vector2(175, 212), color_speed_lines, 2.5)

	# 5. Franjas diagonales de separación manga
	var pts_black := PackedVector2Array([
		Vector2(295, 0),
		Vector2(303, 0),
		Vector2(213, BASE_H),
		Vector2(205, BASE_H)
	])
	_panel_manga.draw_colored_polygon(pts_black, color_stripe_black)

	var pts_yellow := PackedVector2Array([
		Vector2(303, 0),
		Vector2(313, 0),
		Vector2(223, BASE_H),
		Vector2(213, BASE_H)
	])
	_panel_manga.draw_colored_polygon(pts_yellow, color_stripe_yellow)

	# Borde exterior negro fino
	_panel_manga.draw_line(Vector2(313, 0), Vector2(223, BASE_H), color_stripe_black, 2.0)

# ---------------------------------------------------------------------------
# CAPA 3: Personaje Pixel Art con Sombra Sólida
# ---------------------------------------------------------------------------
func _build_layer_3_character() -> void:
	_char_holder = Control.new()
	_char_holder.name = "Layer3_CharacterHolder"
	_char_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_holder.z_index = 5
	_char_holder.position = Vector2(character_ground_x, BASE_H - 28.0)
	_content.add_child(_char_holder)

	# Sombra sólida en el suelo bajo los pies
	_char_shadow = Control.new()
	_char_shadow.name = "CharShadow"
	_char_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_holder.add_child(_char_shadow)
	_char_shadow.draw.connect(func():
		var pts_shadow := PackedVector2Array([
			Vector2(-36, -3),
			Vector2(36, -3),
			Vector2(46, 3),
			Vector2(-26, 3)
		])
		_char_shadow.draw_colored_polygon(pts_shadow, Color(0.08, 0.08, 0.08, 0.70))
	)

	_char_slider = Node2D.new()
	_char_slider.name = "CharSlider"
	_char_holder.add_child(_char_slider)

	_character_sprite = AnimatedSprite2D.new()
	_character_sprite.name = "CharacterSprite"
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.scale = character_scale
	_character_sprite.centered = true
	_character_sprite.position = Vector2(0.0, -feet_y_offset * character_scale.y)
	_char_slider.add_child(_character_sprite)

func _set_initial_character(option_idx: int) -> void:
	_displayed_char_idx = option_idx
	var frames := _get_sprite_frames_for_option(option_idx)
	_set_character_frames(frames)
	_char_slider.position.x = 0.0
	_char_slider.modulate.a = 1.0
	_start_breathing_loop()

func _set_character_frames(frames: SpriteFrames) -> void:
	if not _character_sprite or not frames:
		return
	_character_sprite.sprite_frames = frames
	if frames.has_animation("idle"):
		_character_sprite.play("idle")
	elif frames.get_animation_names().size() > 0:
		_character_sprite.play(frames.get_animation_names()[0])

func _start_breathing_loop() -> void:
	if _breath_tween and _breath_tween.is_valid():
		_breath_tween.kill()
	var base_y: float = -feet_y_offset * character_scale.y
	_character_sprite.position.y = base_y
	_breath_tween = create_tween().set_loops()
	_breath_tween.tween_property(_character_sprite, "position:y", base_y - 2.0, breath_cycle_time).set_trans(Tween.TRANS_SINE)
	_breath_tween.tween_property(_character_sprite, "position:y", base_y, breath_cycle_time).set_trans(Tween.TRANS_SINE)

func _change_character_for_option(option_idx: int) -> void:
	if option_idx == _displayed_char_idx:
		return
	_displayed_char_idx = option_idx

	if _char_tween and _char_tween.is_valid():
		_char_tween.kill()

	var target_frames: SpriteFrames = _get_sprite_frames_for_option(option_idx)
	_char_tween = create_tween()
	_char_tween.set_parallel(true)
	_char_tween.tween_property(_char_slider, "position:x", -char_slide_offset, char_exit_time)
	_char_tween.tween_property(_char_slider, "modulate:a", 0.0, char_exit_time)

	_char_tween.chain().set_parallel(false)
	_char_tween.tween_callback(func():
		_set_character_frames(target_frames)
		_char_slider.position.x = -char_slide_offset
		_char_slider.modulate.a = 0.0
	)

	_char_tween.chain().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_char_tween.tween_property(_char_slider, "position:x", 0.0, char_enter_time)
	_char_tween.tween_property(_char_slider, "modulate:a", 1.0, char_enter_time)

func _get_sprite_frames_for_option(index: int) -> SpriteFrames:
	if _default_frames_cache.has(index):
		return _default_frames_cache[index]

	var opt_id: String = OPTIONS_DEF[index]["id"] if index >= 0 and index < OPTIONS_DEF.size() else "story"
	var frames: SpriteFrames = null
	match opt_id:
		"story":
			frames = _load_character_frames("res://scenes/characters/goku.tscn", "res://resources/characters/goku.tscn", "idle")
		"local":
			frames = _load_character_frames("res://scenes/characters/naruto.tscn", "res://resources/characters/naruto.tscn", "idle")
		"vs_ai":
			frames = _load_character_frames("res://scenes/characters/madara.tscn", "res://resources/characters/madara.tscn", "idle")
		"training":
			frames = _load_character_frames("res://scenes/characters/vegetto.tscn", "res://resources/characters/vegetto.tscn", "idle")
		"shop":
			frames = _load_character_frames("res://scenes/characters/goku.tscn", "res://resources/characters/goku.tscn", "ssj_idle")
		"options":
			frames = _load_character_frames("res://scenes/characters/naruto.tscn", "res://resources/characters/naruto.tscn", "transformed_idle")
		"exit":
			frames = _load_character_frames("res://scenes/characters/goku.tscn", "res://resources/characters/goku.tscn", "idle")

	if not frames:
		frames = _load_character_frames("res://resources/characters/goku.tscn", "res://scenes/characters/goku.tscn", "idle")

	_default_frames_cache[index] = frames
	return frames

func _load_character_frames(primary_path: String, alt_path: String, anim_name: String) -> SpriteFrames:
	var path := primary_path
	if not ResourceLoader.exists(path) and ResourceLoader.exists(alt_path):
		path = alt_path
	if not ResourceLoader.exists(path):
		return null
	var scene := (load(path) as PackedScene).instantiate()
	var sprite: AnimatedSprite2D = scene.get_node_or_null("AnimatedSprite2D")
	var result_frames: SpriteFrames = null
	if sprite and sprite.sprite_frames:
		var src: SpriteFrames = sprite.sprite_frames
		if anim_name == "idle" and src.has_animation("idle"):
			result_frames = src.duplicate()
		elif src.has_animation(anim_name):
			result_frames = SpriteFrames.new()
			result_frames.add_animation("idle")
			result_frames.set_animation_loop("idle", true)
			result_frames.set_animation_speed("idle", src.get_animation_speed(anim_name))
			var count: int = src.get_frame_count(anim_name)
			for i in range(count):
				result_frames.add_frame("idle", src.get_frame_texture(anim_name, i), src.get_frame_duration(anim_name, i))
		elif src.has_animation("idle"):
			result_frames = src.duplicate()
	scene.queue_free()
	return result_frames

# ---------------------------------------------------------------------------
# CAPA 4: Logotipo Oficial DRAGON BALL: ECOS
# ---------------------------------------------------------------------------
func _build_layer_4_logo() -> void:
	_logo_container = Control.new()
	_logo_container.name = "Layer4_TitleBanner"
	_logo_container.position = Vector2(250.0, 14.0)
	_logo_container.size = Vector2(380.0, 50.0)
	_logo_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_logo_container)
	_logo_container.draw.connect(_on_draw_logo)

func _on_draw_logo() -> void:
	# 1. Sombra irregular manga del banner
	var pts_shadow := PackedVector2Array([
		Vector2(12, 4),
		Vector2(375, 4),
		Vector2(358, 48),
		Vector2(0, 48)
	])
	_logo_container.draw_colored_polygon(pts_shadow, Color(0.06, 0.04, 0.08, 0.85))

	# 2. Placa base morada oscura con corte angular
	var pts_base := PackedVector2Array([
		Vector2(8, 0),
		Vector2(370, 0),
		Vector2(352, 44),
		Vector2(-4, 44)
	])
	_logo_container.draw_colored_polygon(pts_base, Color(0.12, 0.08, 0.20))

	# Borde amarillo con acento manga
	var pts_border := PackedVector2Array([
		Vector2(8, 0), Vector2(370, 0), Vector2(352, 44), Vector2(-4, 44), Vector2(8, 0)
	])
	_logo_container.draw_polyline(pts_border, color_stripe_yellow, 2.5)

	# 3. Textos tipográficos de DRAGON BALL: ECOS
	var font_to_use: Font = _italic_font if _italic_font else ThemeDB.fallback_font

	# "DRAGON" en amarillo intenso
	_logo_container.draw_string_outline(font_to_use, Vector2(16, 32), "DRAGON", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, 4, color_stripe_black)
	_logo_container.draw_string(font_to_use, Vector2(16, 32), "DRAGON", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, color_stripe_yellow)

	# Esfera del Dragón vectorizada (O en bola o icono central)
	var ball_center := Vector2(122, 23)
	_logo_container.draw_circle(ball_center, 9.5, color_ball_orange)
	_logo_container.draw_arc(ball_center, 9.5, 0.0, TAU, 16, color_stripe_black, 1.5)
	# 4 estrellas rojas
	_logo_container.draw_circle(ball_center + Vector2(-3, -3), 1.5, color_ball_star)
	_logo_container.draw_circle(ball_center + Vector2(3, -3), 1.5, color_ball_star)
	_logo_container.draw_circle(ball_center + Vector2(-3, 3), 1.5, color_ball_star)
	_logo_container.draw_circle(ball_center + Vector2(3, 3), 1.5, color_ball_star)

	# "BALL:" en rojo/naranja llameante
	_logo_container.draw_string_outline(font_to_use, Vector2(140, 32), "BALL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, 4, color_stripe_black)
	_logo_container.draw_string(font_to_use, Vector2(140, 32), "BALL:", HORIZONTAL_ALIGNMENT_LEFT, -1, 23, Color(0.95, 0.22, 0.18))

	# "ECOS" en blanco con resplandor energético
	_logo_container.draw_string_outline(font_to_use, Vector2(234, 33), "ECOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, 5, color_stripe_black)
	_logo_container.draw_string_outline(font_to_use, Vector2(234, 33), "ECOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, 2, Color(0.9, 0.5, 1.0))
	_logo_container.draw_string(font_to_use, Vector2(234, 33), "ECOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 27, Color(1.0, 1.0, 1.0))

# ---------------------------------------------------------------------------
# CAPA 5: Menú de Opciones en Paneles Inclinados
# ---------------------------------------------------------------------------
func _build_layer_5_options_column() -> void:
	_options_container = Control.new()
	_options_container.name = "Layer5_MenuOptions"
	_options_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_options_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_options_container)

	var start_x: float = 330.0
	var start_y: float = 72.0
	var step_y: float = 40.0
	var item_w: float = 230.0
	var item_h: float = 32.0

	_option_nodes.clear()

	for i in range(OPTIONS_DEF.size()):
		var opt_data: Dictionary = OPTIONS_DEF[i]
		var ox: float = start_x + (i * 12.0)
		var oy: float = start_y + (i * step_y)

		var btn_holder := Control.new()
		btn_holder.name = "Option_%s" % opt_data["id"]
		btn_holder.position = Vector2(ox, oy)
		btn_holder.size = Vector2(item_w, item_h)
		btn_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		_options_container.add_child(btn_holder)
		_option_nodes.append(btn_holder)

		var idx: int = i
		btn_holder.draw.connect(func():
			_draw_option_panel(btn_holder, idx)
		)

		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = opt_data["label"]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(24.0, 0.0)
		lbl.size = Vector2(item_w - 30.0, item_h)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _italic_font:
			lbl.add_theme_font_override("font", _italic_font)
		btn_holder.add_child(lbl)

		# Etiqueta "Próximamente" para opciones bloqueadas
		if not opt_data["enabled"] and opt_data["id"] != "exit":
			var badge := PanelContainer.new()
			badge.name = "Badge"
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var b_box := StyleBoxFlat.new()
			b_box.bg_color = color_badge_bg
			b_box.set_corner_radius_all(2)
			b_box.content_margin_left = 5
			b_box.content_margin_right = 5
			b_box.content_margin_top = 1
			b_box.content_margin_bottom = 1
			badge.add_theme_stylebox_override("panel", b_box)

			var b_lbl := Label.new()
			b_lbl.name = "BadgeLabel"
			b_lbl.text = "Próximamente"
			b_lbl.add_theme_font_size_override("font_size", 9)
			b_lbl.add_theme_color_override("font_color", color_badge_text)
			if _italic_font:
				b_lbl.add_theme_font_override("font", _italic_font)
			badge.add_child(b_lbl)
			badge.position = Vector2(item_w - 82.0, (item_h - 18.0) / 2.0)
			btn_holder.add_child(badge)

		btn_holder.mouse_entered.connect(func():
			if _mouse_has_moved:
				_set_selection(idx)
		)
		btn_holder.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var vp := get_viewport()
				if vp:
					vp.set_input_as_handled()
				_set_selection(idx)
				_activate_current_option()
		)

	_update_selection_visuals(false)

func _draw_option_panel(holder: Control, idx: int) -> void:
	var w: float = holder.size.x
	var h: float = holder.size.y
	var slant: float = 14.0
	var is_selected: bool = (idx == _current_index and not _in_story_submenu)

	var p1 := Vector2(slant, 0.0)
	var p2 := Vector2(w, 0.0)
	var p3 := Vector2(w - slant, h)
	var p4 := Vector2(0.0, h)

	# 1. Sombra desplazada hacia abajo-derecha
	var shadow_off := Vector2(4.0, 4.0)
	var pts_shadow := PackedVector2Array([p1 + shadow_off, p2 + shadow_off, p3 + shadow_off, p4 + shadow_off])
	holder.draw_colored_polygon(pts_shadow, Color(0.04, 0.04, 0.06, 0.85))

	if is_selected:
		# Panel seleccionado: Amarillo brillante #FFD23F
		var pts_body := PackedVector2Array([p1, p2, p3, p4])
		holder.draw_colored_polygon(pts_body, color_stripe_yellow)

		# Contorno negro grueso
		var outline := PackedVector2Array([p1, p2, p3, p4, p1])
		holder.draw_polyline(outline, color_stripe_black, 3.0)

		# Flecha negra de selección '▶' en la izquierda
		var arrow_pts := PackedVector2Array([
			Vector2(8.0, h * 0.28),
			Vector2(16.0, h * 0.50),
			Vector2(8.0, h * 0.72)
		])
		holder.draw_colored_polygon(arrow_pts, color_stripe_black)

		# Franjas diagonales negras de velocidad en el extremo derecho
		holder.draw_line(Vector2(w - 24, 6), Vector2(w - 34, h - 6), color_stripe_black, 2.5)
		holder.draw_line(Vector2(w - 17, 6), Vector2(w - 27, h - 6), color_stripe_black, 2.5)
		holder.draw_line(Vector2(w - 10, 6), Vector2(w - 20, h - 6), color_stripe_black, 2.5)
	else:
		# Panel en reposo: Morado oscuro #2D1F47
		var pts_body := PackedVector2Array([p1, p2, p3, p4])
		holder.draw_colored_polygon(pts_body, color_panel_dark)

		var outline := PackedVector2Array([p1, p2, p3, p4, p1])
		holder.draw_polyline(outline, color_panel_dark_border, 2.0)

# ---------------------------------------------------------------------------
# CAPA 6: Submenú Lateral de Historia
# ---------------------------------------------------------------------------
func _build_layer_6_story_submenu() -> void:
	_story_submenu_panel = Control.new()
	_story_submenu_panel.name = "Layer6_StorySubmenu"
	_story_submenu_panel.position = Vector2(480.0, 80.0)
	_story_submenu_panel.size = Vector2(175.0, 95.0)
	_story_submenu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_story_submenu_panel)

	_story_submenu_panel.draw.connect(_on_draw_story_submenu_bg)

	_story_sub_nodes.clear()
	var sub_h: float = 24.0
	for i in range(STORY_SUBMENU_DEF.size()):
		var sub_data: Dictionary = STORY_SUBMENU_DEF[i]
		var sub_holder := Control.new()
		sub_holder.name = "SubOption_%s" % sub_data["id"]
		sub_holder.position = Vector2(12.0, 36.0 + (i * 28.0))
		sub_holder.size = Vector2(150.0, sub_h)
		sub_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		_story_submenu_panel.add_child(sub_holder)
		_story_sub_nodes.append(sub_holder)

		var sub_idx := i
		sub_holder.draw.connect(func():
			_draw_story_sub_item(sub_holder, sub_idx)
		)

		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = "%s %s" % [("▶" if i == 0 else "☰"), sub_data["label"]]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(10.0, 0.0)
		lbl.size = Vector2(130.0, sub_h)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _italic_font:
			lbl.add_theme_font_override("font", _italic_font)
		sub_holder.add_child(lbl)

		sub_holder.mouse_entered.connect(func():
			if _mouse_has_moved and _current_index == 0:
				_in_story_submenu = true
				_story_sub_index = sub_idx
				_update_selection_visuals(true)
		)
		sub_holder.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var vp := get_viewport()
				if vp: vp.set_input_as_handled()
				_in_story_submenu = true
				_story_sub_index = sub_idx
				_activate_story_submenu_action()
		)

func _on_draw_story_submenu_bg() -> void:
	var w: float = _story_submenu_panel.size.x
	var h: float = _story_submenu_panel.size.y
	var slant: float = 12.0

	var pts_s := PackedVector2Array([
		Vector2(slant + 4, 4), Vector2(w + 4, 4), Vector2(w - slant + 4, h + 4), Vector2(4, h + 4)
	])
	_story_submenu_panel.draw_colored_polygon(pts_s, Color(0.04, 0.04, 0.06, 0.85))

	var pts := PackedVector2Array([
		Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(0, h)
	])
	_story_submenu_panel.draw_colored_polygon(pts, Color(0.14, 0.09, 0.22, 0.95))

	var outline := PackedVector2Array([
		Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(0, h), Vector2(slant, 0)
	])
	_story_submenu_panel.draw_polyline(outline, color_stripe_yellow, 2.0)

	var font_to_use: Font = _italic_font if _italic_font else ThemeDB.fallback_font
	_story_submenu_panel.draw_string(font_to_use, Vector2(16, 22), "HISTORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, color_stripe_yellow)

func _draw_story_sub_item(holder: Control, idx: int) -> void:
	var w: float = holder.size.x
	var h: float = holder.size.y
	var slant: float = 8.0
	var is_active: bool = (_in_story_submenu and idx == _story_sub_index)

	var p1 := Vector2(slant, 0.0)
	var p2 := Vector2(w, 0.0)
	var p3 := Vector2(w - slant, h)
	var p4 := Vector2(0.0, h)

	if is_active:
		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), color_stripe_yellow)
		holder.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), color_stripe_black, 2.0)
	else:
		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(0.24, 0.16, 0.36))
		holder.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(0.12, 0.08, 0.18), 1.5)

func _update_story_submenu_visibility(animate: bool) -> void:
	if not _story_submenu_panel:
		return
	var should_be_visible: bool = (_current_index == 0)
	if animate:
		var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if should_be_visible:
			_story_submenu_panel.visible = true
			tw.tween_property(_story_submenu_panel, "modulate:a", 1.0, 0.15)
		else:
			tw.tween_property(_story_submenu_panel, "modulate:a", 0.0, 0.12)
			tw.tween_callback(func(): _story_submenu_panel.visible = false)
	else:
		_story_submenu_panel.visible = should_be_visible
		_story_submenu_panel.modulate.a = 1.0 if should_be_visible else 0.0

# ---------------------------------------------------------------------------
# CAPA 7: Barra Inferior de Controles
# ---------------------------------------------------------------------------
func _build_layer_7_bottom_bar() -> void:
	var bar_h: float = 26.0
	var bar := Control.new()
	bar.name = "Layer6_BottomBar"
	bar.position = Vector2(0.0, BASE_H - bar_h)
	bar.size = Vector2(BASE_W, bar_h)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(bar)

	var bg := ColorRect.new()
	bg.color = color_stripe_black
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg)

	bar.draw.connect(func():
		for k in range(4):
			bar.draw_line(Vector2(6.0 + k * 6.0, 24.0), Vector2(16.0 + k * 6.0, 2.0), color_stripe_yellow, 2.0)
			bar.draw_line(Vector2(BASE_W - 32.0 + k * 6.0, 24.0), Vector2(BASE_W - 22.0 + k * 6.0, 2.0), color_stripe_yellow, 2.0)
	)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	bar.add_child(hbox)

	_add_bottom_key_prompt(hbox, "↑↓", "Navegar")
	_add_bottom_key_prompt(hbox, "Enter", "Confirmar")
	_add_bottom_key_prompt(hbox, "Esc", "Volver")

func _add_bottom_key_prompt(parent: HBoxContainer, key_text: String, label_text: String) -> void:
	var item_box := HBoxContainer.new()
	item_box.add_theme_constant_override("separation", 6)
	parent.add_child(item_box)

	var key_panel := PanelContainer.new()
	var kbox := StyleBoxFlat.new()
	kbox.bg_color = color_stripe_yellow
	kbox.set_corner_radius_all(2)
	kbox.content_margin_left = 5
	kbox.content_margin_right = 5
	kbox.content_margin_top = 1
	kbox.content_margin_bottom = 1
	key_panel.add_theme_stylebox_override("panel", kbox)
	item_box.add_child(key_panel)

	var lbl_key := Label.new()
	lbl_key.text = key_text
	lbl_key.add_theme_font_size_override("font_size", 10)
	lbl_key.add_theme_color_override("font_color", color_stripe_black)
	if _italic_font:
		lbl_key.add_theme_font_override("font", _italic_font)
	key_panel.add_child(lbl_key)

	var lbl_action := Label.new()
	lbl_action.text = label_text
	lbl_action.add_theme_font_size_override("font_size", 11)
	lbl_action.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if _italic_font:
		lbl_action.add_theme_font_override("font", _italic_font)
	item_box.add_child(lbl_action)

# ---------------------------------------------------------------------------
# Navegación y Selección
# ---------------------------------------------------------------------------
func _set_selection(new_index: int) -> void:
	if new_index == _current_index and not _in_story_submenu:
		return
	_current_index = clampi(new_index, 0, OPTIONS_DEF.size() - 1)
	_in_story_submenu = false
	_play_sfx(_sfx_move)
	_update_selection_visuals(true)
	_change_character_for_option(_current_index)
	_change_background_for_option(_current_index)
	_update_story_submenu_visibility(true)

func _update_selection_visuals(animate: bool) -> void:
	var start_x: float = 330.0
	for i in range(_option_nodes.size()):
		var holder: Control = _option_nodes[i]
		var is_selected: bool = (i == _current_index and not _in_story_submenu)
		var base_x: float = start_x + (i * 12.0)
		var target_x: float = (base_x - 14.0) if is_selected else base_x

		if animate:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(holder, "position:x", target_x, option_slide_time)
		else:
			holder.position.x = target_x

		var lbl: Label = holder.get_node_or_null("Label")
		if lbl:
			if is_selected:
				lbl.add_theme_font_size_override("font_size", 16)
				lbl.add_theme_color_override("font_color", color_stripe_black)
				lbl.remove_theme_constant_override("outline_size")
			else:
				lbl.add_theme_font_size_override("font_size", 15)
				var is_enabled: bool = OPTIONS_DEF[i]["enabled"]
				lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if is_enabled else color_text_disabled)
				lbl.add_theme_constant_override("outline_size", 2)
				lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08))

		holder.queue_redraw()

	for i in range(_story_sub_nodes.size()):
		var sub_holder: Control = _story_sub_nodes[i]
		var is_sub_active: bool = (_in_story_submenu and i == _story_sub_index)
		var sub_lbl: Label = sub_holder.get_node_or_null("Label")
		if sub_lbl:
			sub_lbl.add_theme_font_size_override("font_size", 12)
			sub_lbl.add_theme_color_override("font_color", color_stripe_black if is_sub_active else Color(1.0, 1.0, 1.0))
		sub_holder.queue_redraw()

# ---------------------------------------------------------------------------
# Entrada por Teclado e Interacción
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if event.relative.length_squared() > 4.0:
			_mouse_has_moved = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			_navigate_vertical(-1)
		elif event.is_action_pressed("ui_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			_navigate_vertical(1)
		elif event.is_action_pressed("ui_right") or event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			if _current_index == 0 and not _in_story_submenu:
				var vp := get_viewport()
				if vp: vp.set_input_as_handled()
				_in_story_submenu = true
				_play_sfx(_sfx_move)
				_update_selection_visuals(true)
		elif event.is_action_pressed("ui_left") or event.keycode == KEY_LEFT or event.keycode == KEY_A:
			if _in_story_submenu:
				var vp := get_viewport()
				if vp: vp.set_input_as_handled()
				_in_story_submenu = false
				_play_sfx(_sfx_move)
				_update_selection_visuals(true)
		elif event.is_action_pressed("ui_accept") or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			if _in_story_submenu:
				_activate_story_submenu_action()
			else:
				_activate_current_option()
		elif event.is_action_pressed("ui_cancel") or event.keycode == KEY_ESCAPE:
			var vp := get_viewport()
			if vp: vp.set_input_as_handled()
			if _in_story_submenu:
				_in_story_submenu = false
				_play_sfx(_sfx_move)
				_update_selection_visuals(true)
			else:
				_set_selection(OPTIONS_DEF.size() - 1)

func _navigate_vertical(dir: int) -> void:
	if _in_story_submenu:
		var total_sub: int = STORY_SUBMENU_DEF.size()
		_story_sub_index = (_story_sub_index + dir + total_sub) % total_sub
		_play_sfx(_sfx_move)
		_update_selection_visuals(true)
	else:
		var total: int = OPTIONS_DEF.size()
		var next_idx: int = (_current_index + dir + total) % total
		_set_selection(next_idx)

func _activate_current_option() -> void:
	var opt: Dictionary = OPTIONS_DEF[_current_index]
	var opt_id: String = opt["id"]

	if not opt["enabled"]:
		print("[Menú] 🔒 La opción '%s' está deshabilitada (Próximamente)." % opt["label"])
		_play_sfx(_sfx_error)
		return

	_play_sfx(_sfx_choose)
	emit_signal("option_selected", opt_id)

	match opt_id:
		"story":
			_start_story_gameplay(false)
		"local":
			print("[Menú] ⚔️ Iniciando Selección de Personaje (LOCAL)...")
			var gdata = get_node_or_null("/root/GameData")
			if gdata:
				gdata.current_mode = gdata.GameMode.LOCAL
			emit_signal("start_local_mode")
			var target_scene := "res://scenes/ui/character_select.tscn"
			if not ResourceLoader.exists(target_scene):
				target_scene = local_map_scene_path
			if ResourceLoader.exists(target_scene):
				get_tree().change_scene_to_file(target_scene)
			else:
				push_error("MainMenu: No se encontró la escena '%s'." % target_scene)
		"vs_ai":
			print("[Menú] 🤖 Iniciando Selección de Personaje (VS IA)...")
			var gdata = get_node_or_null("/root/GameData")
			if gdata:
				gdata.current_mode = gdata.GameMode.VS_AI
			var target_scene := "res://scenes/ui/character_select.tscn"
			if ResourceLoader.exists(target_scene):
				get_tree().change_scene_to_file(target_scene)
			else:
				push_error("MainMenu: No se encontró la escena '%s'." % target_scene)
		"exit":
			print("[Menú] 🚪 Saliendo del juego...")
			emit_signal("menu_exited")
			get_tree().quit()

func _activate_story_submenu_action() -> void:
	_play_sfx(_sfx_choose)
	var sub_act: String = STORY_SUBMENU_DEF[_story_sub_index]["id"]
	match sub_act:
		"continue":
			_start_story_gameplay(false)
		"chapters":
			print("[Menú] 📖 Capítulos de Historia seleccionados.")
			_start_story_gameplay(false)

func _start_story_gameplay(from_beginning: bool) -> void:
	print("[Menú] 📖 Iniciando Modo Historia: ECOS (desde inicio: %s)..." % str(from_beginning))
	var sm = get_node_or_null("/root/StoryManager")
	if sm:
		sm.start_story(from_beginning)
	var target_scene := "res://scenes/story/story_stage.tscn"
	if ResourceLoader.exists(target_scene):
		get_tree().change_scene_to_file(target_scene)
	else:
		push_error("MainMenu: No se encontró la escena '%s'." % target_scene)

# ---------------------------------------------------------------------------
# Animaciones de Entrada (Tweens)
# ---------------------------------------------------------------------------
func _play_intro_animations() -> void:
	if _panel_manga:
		_panel_manga.position.x = -320.0
		var tw_panel := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_panel.tween_property(_panel_manga, "position:x", 0.0, 0.32)

	if _logo_container:
		var target_y: float = _logo_container.position.y
		_logo_container.position.y = -70.0
		var tw_title := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_title.tween_property(_logo_container, "position:y", target_y, 0.35)

	for i in range(_option_nodes.size()):
		var holder: Control = _option_nodes[i]
		var fx: float = holder.position.x
		holder.position.x = fx + 160.0
		holder.modulate.a = 0.0
		var tw_opt := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_opt.tween_interval(0.08 + (i * 0.04))
		tw_opt.tween_property(holder, "position:x", fx, 0.20)
		tw_opt.parallel().tween_property(holder, "modulate:a", 1.0, 0.20)

# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------
func _setup_audio_players() -> void:
	_sfx_move = AudioStreamPlayer.new()
	_sfx_move.name = "SFX_Move"
	add_child(_sfx_move)

	_sfx_choose = AudioStreamPlayer.new()
	_sfx_choose.name = "SFX_Choose"
	add_child(_sfx_choose)

	_sfx_error = AudioStreamPlayer.new()
	_sfx_error.name = "SFX_Error"
	add_child(_sfx_error)

	if ResourceLoader.exists("res://assets/sounds/sfx/menu_move.wav"):
		_sfx_move.stream = load("res://assets/sounds/sfx/menu_move.wav")
	if ResourceLoader.exists("res://assets/sounds/sfx/menu_select.wav"):
		_sfx_choose.stream = load("res://assets/sounds/sfx/menu_select.wav")
	if ResourceLoader.exists("res://assets/sounds/sfx/menu_error.wav"):
		_sfx_error.stream = load("res://assets/sounds/sfx/menu_error.wav")
	elif ResourceLoader.exists("res://assets/sounds/sfx/error.wav"):
		_sfx_error.stream = load("res://assets/sounds/sfx/error.wav")

func _play_sfx(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player) and player.stream:
		player.play()

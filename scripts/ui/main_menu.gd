## main_menu.gd
## Menú Principal del juego de peleas 2D (Fase 5 - Paso 1).
## Construido siguiendo fielmente la maqueta (Canvas base 680x400 con escalado proporcional).
## Capas (de atrás hacia adelante):
##   1. Fondo (#3A2F55) + Sol (#E8915A) + 2 capas de montañas escalonadas (#5D3F63 y #46304F).
##   2. Panel diagonal naranja (#F28C28) con trama halftone (#D9731A), líneas de velocidad (#FFC266)
##      y franjas diagonales negra (#151515) y amarilla (#FFD23F).
##   3. Personaje pixel art grande (Escala 7x Nearest) anclado en la base sobre la barra inferior con respiración y transición fluida.
##   4. Banner de título en paralelogramo amarillo (#FFD23F) con borde negro de 3 px.
##   5. Opciones escalonadas hacia la derecha con franja deslizante, sombra y cursiva.
##   6. Barra inferior negra de 28 px con botones de ayuda ("↑↓ Navegar", "Enter Elegir", "Esc Volver").
class_name MainMenu
extends Control

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------
signal start_local_mode()
signal option_selected(option_name: String)
signal menu_exited()

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables e Inspector)
# ---------------------------------------------------------------------------
@export_group("Textos y Título")
@export var game_title: String = "Nombre del juego"
@export var local_map_scene_path: String = "res://scenes/maps/valle_del_fin.tscn"

@export_group("Tipografía")
@export var font_path: String = "res://assets/fonts/PixelifySans-Regular.ttf" ## Ruta preferida de la fuente .ttf
@export var font_shear: float = 0.2 ## Inclinación requerida (variation_transform)

@export_group("Personajes por Opción")
## SpriteFrames en el orden de las opciones:
## 0: Modo historia (Goku)
## 1: Modo local (Naruto)
## 2: Tienda (Goku SSJ)
## 3: Opciones (Naruto Sabio)
## 4: Salir (Goku)
## Si una opción no tiene SpriteFrames asignado (o está vacío), se usa el personaje de Goku de reserva.
@export var option_sprite_frames: Array[SpriteFrames] = []
@export var character_scale: Vector2 = Vector2(7.0, 7.0)   ## Escala entera 7x
@export var character_ground_x: float = 120.0              ## Centro horizontal sobre la barra inferior
@export var feet_y_offset: float = 23.0                    ## Distancia en px desde el centro de la textura (68x68) a los pies
@export var char_exit_time: float = 0.12                   ## Tiempo de salida hacia la izquierda (0.12 s)
@export var char_enter_time: float = 0.18                  ## Tiempo de entrada desde la izquierda (0.18 s, TRANS_BACK)
@export var char_slide_offset: float = 40.0                ## Desplazamiento horizontal de transición (40 px)
@export var breath_cycle_time: float = 0.8                 ## Tiempo de ciclo de respiración suave

@export_group("Dimensiones y Layout")
@export var ribbon_width: float = 280.0
@export var ribbon_height: float = 34.0
@export var ribbon_offset_x: float = -18.0
@export var ribbon_offset_y: float = 0.0                   ## Centrado vertical exacto con el texto
@export var badge_separation: float = 16.0                 ## 16 px de separación desde el final del texto real
@export var badge_font_size: int = 12
@export var outline_size_normal: int = 4
@export var outline_size_disabled: int = 2

@export_group("Duraciones de Animación (Tweens)")
@export var panel_enter_time: float = 0.35          ## Entrada del panel naranja desde la izquierda
@export var title_enter_time: float = 0.35          ## Caída del banner de título desde arriba
@export var option_stagger_delay: float = 0.06      ## Retraso escalonado entre opciones
@export var option_slide_time: float = 0.12         ## Deslizamiento de la franja amarilla de selección
@export var bg_transition_time: float = 0.45        ## Transición suave entre fondos de escenario (0.45 s)
@export var bg_parallax_offset: float = 4.0         ## Desplazamiento sutil de profundidad (4 px)

@export_group("Colores")
@export var color_sky: Color = Color(0.227, 0.184, 0.333)           ## #3A2F55 Fondo púrpura
@export var color_sun: Color = Color(0.910, 0.569, 0.353)           ## #E8915A Sol poniente
@export var color_mountain_back: Color = Color(0.365, 0.247, 0.388) ## #5D3F63 Montañas atrás
@export var color_mountain_front: Color = Color(0.275, 0.188, 0.310)## #46304F Montañas frente
@export var color_panel_orange: Color = Color(0.949, 0.549, 0.157)  ## #F28C28 Panel diagonal
@export var color_dot_pattern: Color = Color(0.851, 0.451, 0.102)   ## #D9731A Puntos de trama
@export var color_speed_lines: Color = Color(1.0, 0.761, 0.400)     ## #FFC266 Líneas de velocidad
@export var color_stripe_black: Color = Color(0.082, 0.082, 0.082)  ## #151515 Franja negra
@export var color_stripe_yellow: Color = Color(1.0, 0.824, 0.247)  ## #FFD23F Franja amarilla
@export var color_text_disabled: Color = Color("b8b0c8")            ## #B8B0C8 Gris lila claro
@export var color_badge_bg: Color = Color(0.082, 0.082, 0.082)      ## #151515 Fondo etiqueta
@export var color_badge_text: Color = Color(1.0, 0.824, 0.247)      ## #FFD23F Texto etiqueta

# ---------------------------------------------------------------------------
# Constantes del Canvas Base y Fondos Dinámicos
# ---------------------------------------------------------------------------
const BASE_W: float = 680.0
const BASE_H: float = 400.0
const BG_NEUTRAL_X: float = -8.0

# Definición de opciones del menú (nombre, habilitada)
const OPTIONS_DEF: Array[Dictionary] = [
	{"id": "story",    "label": "Modo historia", "enabled": true},
	{"id": "local",    "label": "Modo local",    "enabled": true},
	{"id": "vs_ai",    "label": "VS IA",         "enabled": true},
	{"id": "training", "label": "Entrenamiento", "enabled": false},
	{"id": "shop",     "label": "Tienda",        "enabled": false},
	{"id": "options",  "label": "Opciones",      "enabled": false},
	{"id": "exit",     "label": "Salir",         "enabled": true},
]

# Asociación estricta entre opciones y escenarios existentes (Fase 9 - A1)
const MAP_ASSOCIATIONS: Dictionary = {
	"story": "res://assets/maps/valle_del_fin.png",
	"local": "res://assets/maps/torneo_artes_marciales.png",
	"vs_ai": "res://assets/maps/dimension_ecos.png",
}

# ---------------------------------------------------------------------------
# Estado Interno y Nodos
# ---------------------------------------------------------------------------
var _current_index: int = 0 # "Modo historia" (Goku / Valle del Fin) por defecto al abrir
var _content: Control = null
var _bg_layer: Control = null
var _bg_current: TextureRect = null
var _bg_incoming: TextureRect = null
var _bg_dimmer: ColorRect = null
var _bg_canvas_fallback: Control = null
var _bg_tween: Tween = null
var _active_map_path: String = ""
var _map_texture_cache: Dictionary = {}

var _panel_container: Control = null
var _title_banner: Control = null
var _options_container: Control = null
var _selector_ribbon: Control = null
var _selector_shadow: Control = null

# Nodos de Personaje
var _char_holder: Control = null
var _char_slider: Node2D = null
var _character_sprite: AnimatedSprite2D = null
var _char_tween: Tween = null
var _breath_tween: Tween = null
var _displayed_char_idx: int = -1
var _default_frames_cache: Dictionary = {}

var _option_nodes: Array[Control] = []
var _sfx_move: AudioStreamPlayer = null
var _sfx_choose: AudioStreamPlayer = null
var _sfx_error: AudioStreamPlayer = null
var _italic_font: FontVariation = null

# Control de hover por movimiento real del mouse
var _mouse_has_moved: bool = false
var _searched_font_paths: Array[String] = []

func _ready() -> void:
	# Ajustar layout para ocupar la pantalla completa
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Crear contenedor de contenido escalable a 680x400
	_content = Control.new()
	_content.name = "CanvasBase"
	_content.custom_minimum_size = Vector2(BASE_W, BASE_H)
	_content.size = Vector2(BASE_W, BASE_H)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	# FontVariation para el efecto itálica/cursiva de las opciones y título
	_setup_italic_font()

	# Construir las 6 capas
	_build_layer_1_background()
	_build_layer_2_diagonal_panel()
	_build_layer_3_character()
	_build_layer_4_title_banner()
	_build_layer_5_menu_options()
	_build_layer_6_bottom_bar()
	_setup_audio_players()

	# Ajustar escala inicial al tamaño de ventana
	_rescale_canvas()

	# Selección inicial "Modo historia" (índice 0 -> Goku con fondo Valle del Fin)
	_current_index = 0
	_update_selection_visuals(false)
	_set_initial_character(0)
	_init_initial_background(0)

	# Ejecutar animaciones de entrada
	_play_intro_animations()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_rescale_canvas()

## Escala proporcionalmente el lienzo base (680x400) a la resolución actual del juego
func _rescale_canvas() -> void:
	if not _content:
		return
	var vp_size: Vector2 = get_viewport_rect().size
	var s: float = minf(vp_size.x / BASE_W, vp_size.y / BASE_H)
	_content.scale = Vector2(s, s)
	_content.position = (vp_size - Vector2(BASE_W, BASE_H) * s) / 2.0

func _setup_italic_font() -> void:
	_italic_font = FontVariation.new()
	var custom_font := _resolve_menu_font()
	if custom_font:
		_italic_font.base_font = custom_font
	# Inclinación requerida del FontVariation (variation_transform) a 0.2
	_italic_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-font_shear, 1.0), Vector2.ZERO)

func _resolve_menu_font() -> Font:
	_searched_font_paths.clear()

	# 1. Probar ruta exportada directa
	_searched_font_paths.append(font_path)
	if ResourceLoader.exists(font_path):
		var res = load(font_path)
		if res is Font:
			print("[Menú] Fuente .ttf cargada desde: %s" % font_path)
			return res

	# 2. Explorar dinámicamente res://assets/fonts/ por cualquier archivo .ttf
	var dir := DirAccess.open("res://assets/fonts/")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.get_extension().to_lower() == "ttf":
				var full_path := "res://assets/fonts/" + file_name
				_searched_font_paths.append(full_path)
				if ResourceLoader.exists(full_path):
					var res = load(full_path)
					if res is Font:
						print("[Menú] Fuente .ttf detectada y cargada desde: %s" % full_path)
						return res
			file_name = dir.get_next()

	print("[Menú] ℹ️ No se encontró fuente .ttf en res://assets/fonts/. Rutas consultadas: ", _searched_font_paths)
	return null

# ---------------------------------------------------------------------------
# CAPA 1: Fondos Dinámicos de Escenarios (Fase 9 - A1)
# ---------------------------------------------------------------------------
func _build_layer_1_background() -> void:
	_bg_layer = Control.new()
	_bg_layer.name = "Layer1_Background"
	_bg_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_bg_layer)

	# 1. Fallback procedural de respaldo si faltase alguna textura
	_bg_canvas_fallback = Control.new()
	_bg_canvas_fallback.name = "FallbackCanvas"
	_bg_canvas_fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas_fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_layer.add_child(_bg_canvas_fallback)
	_bg_canvas_fallback.draw.connect(_on_draw_background)

	# 2. Dos capas visuales con TextureRect (Fondo actual y Fondo entrante)
	# Se les añade 16 px de ancho extra y se centran en BG_NEUTRAL_X (-8.0)
	# para permitir un desplazamiento de +-4 px sin bordes vacíos.
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

	# 3. Oscurecimiento localizado detrás del contenido para asegurar contraste manga y legibilidad
	_bg_dimmer = ColorRect.new()
	_bg_dimmer.name = "BgDimmer"
	_bg_dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_dimmer.color = Color(0.08, 0.06, 0.12, 0.28)
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
		# ENTRENAMIENTO, TIENDA, OPCIONES y SALIR: Mantener el último fondo activo
		return

	var target_path: String = MAP_ASSOCIATIONS[opt_id]
	if target_path == _active_map_path:
		return

	var next_tex: Texture2D = _get_map_texture(target_path)
	if not next_tex:
		return

	# Si se produce una selección rápida, cancelar la transición anterior sin acumulación
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

	# 1. Desvanecer fondo anterior y desplazarlo levemente (+4 px) para crear profundidad
	_bg_tween.tween_property(_bg_current, "modulate:a", 0.0, bg_transition_time)
	_bg_tween.tween_property(_bg_current, "position:x", BG_NEUTRAL_X + bg_parallax_offset, bg_transition_time)

	# 2. Mostrar nuevo fondo y deslizarlo a su posición neutra (-8 px)
	_bg_tween.tween_property(_bg_incoming, "modulate:a", 1.0, bg_transition_time)
	_bg_tween.tween_property(_bg_incoming, "position:x", BG_NEUTRAL_X, bg_transition_time)

	# 3. Al terminar, consolidar el fondo entrante como actual
	_bg_tween.chain().tween_callback(func():
		_bg_current.texture = next_tex
		_bg_current.modulate.a = 1.0
		_bg_current.position.x = BG_NEUTRAL_X
		_bg_incoming.modulate.a = 0.0
	)

func _on_draw_background() -> void:
	# Rectángulo base púrpura #3A2F55
	if not _bg_canvas_fallback:
		return
	_bg_canvas_fallback.draw_rect(Rect2(0, 0, BASE_W, BASE_H), color_sky)

	# Sol circular #E8915A en la mitad derecha (x ~ 585, y ~ 215, r = 48)
	var sun_pos := Vector2(585.0, 215.0)
	_bg_canvas_fallback.draw_circle(sun_pos, 48.0, color_sun)

	# Capa de montañas trasera #5D3F63
	var pts_back := PackedVector2Array([
		Vector2(370, BASE_H),
		Vector2(370, 265),
		Vector2(420, 265),
		Vector2(420, 235),
		Vector2(480, 235),
		Vector2(480, 255),
		Vector2(550, 255),
		Vector2(550, 225),
		Vector2(630, 225),
		Vector2(630, 245),
		Vector2(BASE_W, 245),
		Vector2(BASE_W, BASE_H),
	])
	_bg_canvas_fallback.draw_colored_polygon(pts_back, color_mountain_back)

	# Capa de montañas frontal #46304F
	var pts_front := PackedVector2Array([
		Vector2(340, BASE_H),
		Vector2(340, 295),
		Vector2(400, 295),
		Vector2(400, 275),
		Vector2(460, 275),
		Vector2(460, 288),
		Vector2(520, 288),
		Vector2(520, 265),
		Vector2(590, 265),
		Vector2(590, 285),
		Vector2(BASE_W, 285),
		Vector2(BASE_W, BASE_H),
	])
	_bg_canvas_fallback.draw_colored_polygon(pts_front, color_mountain_front)

# ---------------------------------------------------------------------------
# CAPA 2: Panel Diagonal Naranja con Trama de Puntos y Líneas de Velocidad
# ---------------------------------------------------------------------------
func _build_layer_2_diagonal_panel() -> void:
	_panel_container = Control.new()
	_panel_container.name = "Layer2_DiagonalPanel"
	_panel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_panel_container)

	_panel_container.draw.connect(_on_draw_diagonal_panel)

func _on_draw_diagonal_panel() -> void:
	# 1. Polígono del panel naranja: (0,0) -> (360,0) -> (250,400) -> (0,400)
	var pts_panel := PackedVector2Array([
		Vector2(0, 0),
		Vector2(360, 0),
		Vector2(250, BASE_H),
		Vector2(0, BASE_H)
	])
	_panel_container.draw_colored_polygon(pts_panel, color_panel_orange)

	# 2. Tramado de puntos halftone #D9731A (cuadrícula de 12 px, alternados cada 6 px)
	var step: float = 12.0
	var dot_radius: float = 1.6
	for y in range(6, int(BASE_H), int(step)):
		var edge_x: float = 360.0 - 110.0 * (float(y) / BASE_H)
		var offset_x: float = 6.0 if (int(y / step) % 2 == 1) else 0.0
		for x in range(int(offset_x + 6), int(edge_x - 4), int(step)):
			_panel_container.draw_circle(Vector2(x, y), dot_radius, color_dot_pattern)

	# 3. Tres líneas de velocidad #FFC266 de 3 px
	_panel_container.draw_line(Vector2(145, 100), Vector2(250, 82), color_speed_lines, 3.0)
	_panel_container.draw_line(Vector2(0, 185), Vector2(220, 153), color_speed_lines, 3.0)
	_panel_container.draw_line(Vector2(0, 245), Vector2(180, 218), color_speed_lines, 3.0)

	# 4. Franjas diagonales en el borde derecho (negra de 10 px y amarilla de 10 px)
	var pts_stripe_black := PackedVector2Array([
		Vector2(360, 0),
		Vector2(370, 0),
		Vector2(260, BASE_H),
		Vector2(250, BASE_H)
	])
	_panel_container.draw_colored_polygon(pts_stripe_black, color_stripe_black)

	var pts_stripe_yellow := PackedVector2Array([
		Vector2(370, 0),
		Vector2(380, 0),
		Vector2(270, BASE_H),
		Vector2(260, BASE_H)
	])
	_panel_container.draw_colored_polygon(pts_stripe_yellow, color_stripe_yellow)

# ---------------------------------------------------------------------------
# CAPA 3: Personaje Grande en Pixel Art (Escala entera 7x, Nearest, Anclaje en la base)
# ---------------------------------------------------------------------------
func _build_layer_3_character() -> void:
	_char_holder = Control.new()
	_char_holder.name = "Layer3_CharacterHolder"
	_char_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# z_index = 5 para que quede encima de la barra inferior (no detrás)
	_char_holder.z_index = 5
	# Punto de anclaje base: justo en el borde superior de la barra inferior (y = 372.0)
	_char_holder.position = Vector2(character_ground_x, BASE_H - 28.0)
	_content.add_child(_char_holder)

	_char_slider = Node2D.new()
	_char_slider.name = "CharSlider"
	_char_holder.add_child(_char_slider)

	_character_sprite = AnimatedSprite2D.new()
	_character_sprite.name = "CharacterSprite"
	_character_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_character_sprite.scale = character_scale
	_character_sprite.centered = true
	# Pies apoyados exactamente en y = 0 relativo al deslizador
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

## Transición con Tween para cambiar el personaje según la opción seleccionada
func _change_character_for_option(option_idx: int) -> void:
	if option_idx == _displayed_char_idx:
		return
	_displayed_char_idx = option_idx

	# Cancelar Tween anterior para evitar acumulaciones al cambiar rápido
	if _char_tween and _char_tween.is_valid():
		_char_tween.kill()

	var target_frames: SpriteFrames = _get_sprite_frames_for_option(option_idx)

	_char_tween = create_tween()
	# 1. El personaje actual sale desplazándose unos 40 px a la izquierda mientras se desvanece (0.12 s)
	_char_tween.set_parallel(true)
	_char_tween.tween_property(_char_slider, "position:x", -char_slide_offset, char_exit_time)
	_char_tween.tween_property(_char_slider, "modulate:a", 0.0, char_exit_time)

	# 2. Cambiar frames e inicializar posición para entrada
	_char_tween.chain().set_parallel(false)
	_char_tween.tween_callback(func():
		_set_character_frames(target_frames)
		_char_slider.position.x = -char_slide_offset
		_char_slider.modulate.a = 0.0
	)

	# 3. El nuevo entra desde la izquierda con desvanecimiento (0.18 s, TRANS_BACK)
	_char_tween.chain().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_char_tween.tween_property(_char_slider, "position:x", 0.0, char_enter_time)
	_char_tween.tween_property(_char_slider, "modulate:a", 1.0, char_enter_time)

## Obtiene el SpriteFrames para una opción dada:
## Usa la variable exportada option_sprite_frames si existe; en caso contrario,
## carga dinámicamente los recursos por defecto o Goku como respaldo general.
func _get_sprite_frames_for_option(index: int) -> SpriteFrames:
	if index >= 0 and index < option_sprite_frames.size():
		if option_sprite_frames[index] != null:
			return option_sprite_frames[index]

	if _default_frames_cache.has(index):
		return _default_frames_cache[index]

	var opt_id: String = OPTIONS_DEF[index]["id"] if index >= 0 and index < OPTIONS_DEF.size() else "story"
	var frames: SpriteFrames = null
	match opt_id:
		"story": # Modo historia -> Goku
			frames = _load_character_frames("res://scenes/characters/goku.tscn", "res://resources/characters/goku.tscn", "idle")
		"local": # Modo local -> Naruto
			frames = _load_character_frames("res://scenes/characters/naruto.tscn", "res://resources/characters/naruto.tscn", "idle")
		"vs_ai": # VS IA -> Madara
			frames = _load_character_frames("res://scenes/characters/madara.tscn", "res://resources/characters/madara.tscn", "idle")
		"training": # Entrenamiento -> Vegetto
			frames = _load_character_frames("res://scenes/characters/vegetto.tscn", "res://resources/characters/vegetto.tscn", "idle")
		"shop": # Tienda -> Goku Super Saiyajin
			frames = _load_character_frames("res://scenes/characters/goku.tscn", "res://resources/characters/goku.tscn", "ssj_idle")
		"options": # Opciones -> Naruto Modo Sabio
			frames = _load_character_frames("res://scenes/characters/naruto.tscn", "res://resources/characters/naruto.tscn", "transformed_idle")
		"exit": # Salir -> Goku
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
			var spd: float = src.get_animation_speed(anim_name)
			result_frames.set_animation_speed("idle", spd)
			var count: int = src.get_frame_count(anim_name)
			for i in range(count):
				var tex: Texture2D = src.get_frame_texture(anim_name, i)
				var dur: float = src.get_frame_duration(anim_name, i)
				result_frames.add_frame("idle", tex, dur)
		elif src.has_animation("idle"):
			result_frames = src.duplicate()

	scene.queue_free()
	return result_frames

# ---------------------------------------------------------------------------
# CAPA 4: Banner del Título (Paralelogramo Amarillo)
# ---------------------------------------------------------------------------
func _build_layer_4_title_banner() -> void:
	_title_banner = Control.new()
	_title_banner.name = "Layer4_TitleBanner"
	_title_banner.position = Vector2(300.0, 22.0)
	_title_banner.size = Vector2(365.0, 52.0)
	_title_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_title_banner)

	_title_banner.draw.connect(_on_draw_title_banner)

	# Texto del título
	var lbl := Label.new()
	lbl.name = "TitleText"
	lbl.text = game_title
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	if _italic_font:
		lbl.add_theme_font_override("font", _italic_font)
	_title_banner.add_child(lbl)

func _on_draw_title_banner() -> void:
	# Paralelogramo inclinado con borde negro de 3 px
	var pts := PackedVector2Array([
		Vector2(18.0, 0.0),
		Vector2(365.0, 0.0),
		Vector2(345.0, 50.0),
		Vector2(0.0, 50.0)
	])
	_title_banner.draw_colored_polygon(pts, color_stripe_yellow)

	var outline := PackedVector2Array([
		Vector2(18.0, 0.0),
		Vector2(365.0, 0.0),
		Vector2(345.0, 50.0),
		Vector2(0.0, 50.0),
		Vector2(18.0, 0.0)
	])
	_title_banner.draw_polyline(outline, color_stripe_black, 3.0)

# ---------------------------------------------------------------------------
# CAPA 5: Opciones Escalonadas hacia la Derecha
# ---------------------------------------------------------------------------
func _build_layer_5_menu_options() -> void:
	_options_container = Control.new()
	_options_container.name = "Layer5_MenuOptions"
	_options_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_options_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_options_container)

	# Sombra negra de la selección desplazada 5 px abajo-derecha
	_selector_shadow = Control.new()
	_selector_shadow.name = "SelectorShadow"
	_selector_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_container.add_child(_selector_shadow)
	_selector_shadow.draw.connect(_on_draw_selector_shadow)

	# Franja amarilla inclinada de la opción seleccionada
	_selector_ribbon = Control.new()
	_selector_ribbon.name = "SelectorRibbon"
	_selector_ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_options_container.add_child(_selector_ribbon)
	_selector_ribbon.draw.connect(_on_draw_selector_ribbon)

	var start_x: float = 340.0
	var start_y: float = 80.0
	var step_y: float = 38.0
	var holder_h: float = ribbon_height # 34.0 para centrado vertical exacto
	_option_nodes.clear()

	for i in OPTIONS_DEF.size():
		var opt_data: Dictionary = OPTIONS_DEF[i]
		var ox: float = start_x + i * 14.0
		var oy: float = start_y + i * step_y

		var btn_holder := Control.new()
		btn_holder.name = "Option_%s" % opt_data["id"]
		btn_holder.position = Vector2(ox, oy)
		btn_holder.size = Vector2(320.0, holder_h)
		btn_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		_options_container.add_child(btn_holder)
		_option_nodes.append(btn_holder)

		# Label de texto de la opción
		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = opt_data["label"]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _italic_font:
			lbl.add_theme_font_override("font", _italic_font)
		btn_holder.add_child(lbl)

		# Etiqueta "Próximamente" en opciones bloqueadas:
		# Rectángulo negro (#151515) con texto amarillo (#FFD23F) tamaño 12,
		# colocada 16 px después del final del texto real para no taparlo.
		if not opt_data["enabled"] and opt_data["id"] != "exit":
			var badge_panel := PanelContainer.new()
			badge_panel.name = "Badge"
			badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

			var badge_box := StyleBoxFlat.new()
			badge_box.bg_color = color_badge_bg # #151515
			badge_box.set_corner_radius_all(2)
			badge_box.content_margin_left = 6
			badge_box.content_margin_right = 6
			badge_box.content_margin_top = 2
			badge_box.content_margin_bottom = 2
			badge_panel.add_theme_stylebox_override("panel", badge_box)

			var badge_lbl := Label.new()
			badge_lbl.name = "BadgeLabel"
			badge_lbl.text = "Próximamente"
			badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			badge_lbl.add_theme_font_size_override("font_size", badge_font_size) # 12
			badge_lbl.add_theme_color_override("font_color", color_badge_text) # #FFD23F
			if _italic_font:
				badge_lbl.add_theme_font_override("font", _italic_font)
			badge_panel.add_child(badge_lbl)

			# Ancho real del texto medido en tamaño 26 (tamaño máximo al seleccionarse)
			var font_to_measure: Font = _italic_font if _italic_font else ThemeDB.fallback_font
			var text_w: float = font_to_measure.get_string_size(opt_data["label"], HORIZONTAL_ALIGNMENT_LEFT, -1, 26).x
			badge_panel.position = Vector2(text_w + badge_separation, (holder_h - 20.0) / 2.0)
			btn_holder.add_child(badge_panel)

		# Detección de mouse: solo cambia selección si el mouse se movió de verdad
		var idx: int = i
		btn_holder.mouse_entered.connect(func():
			if _mouse_has_moved:
				_set_selection(idx)
		)
		btn_holder.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseMotion and _mouse_has_moved:
				if _current_index != idx:
					_set_selection(idx)
			elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var vp := get_viewport()
				if vp:
					vp.set_input_as_handled()
				_set_selection(idx)
				_activate_current_option()
		)

	# Actualizar posición visual inicial de la selección
	_update_selection_visuals(false)

func _on_draw_selector_shadow() -> void:
	# Sombra negra paralelogramo desplazada 5 px abajo-derecha
	var w: float = ribbon_width
	var h: float = ribbon_height
	var pts := PackedVector2Array([
		Vector2(14.0 + 5.0, 0.0 + 5.0),
		Vector2(w + 5.0, 0.0 + 5.0),
		Vector2(w - 14.0 + 5.0, h + 5.0),
		Vector2(0.0 + 5.0, h + 5.0)
	])
	_selector_shadow.draw_colored_polygon(pts, Color(0.06, 0.06, 0.08, 0.95))

func _on_draw_selector_ribbon() -> void:
	# Franja amarilla #FFD23F paralelogramo
	var w: float = ribbon_width
	var h: float = ribbon_height
	var pts := PackedVector2Array([
		Vector2(14.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w - 14.0, h),
		Vector2(0.0, h)
	])
	_selector_ribbon.draw_colored_polygon(pts, color_stripe_yellow)

func _set_selection(new_index: int) -> void:
	if new_index == _current_index:
		return
	_current_index = clampi(new_index, 0, OPTIONS_DEF.size() - 1)
	_play_sfx(_sfx_move)
	_update_selection_visuals(true)
	_change_character_for_option(_current_index)
	_change_background_for_option(_current_index)

func _update_selection_visuals(animate: bool) -> void:
	if _current_index < 0 or _current_index >= _option_nodes.size():
		return

	var target_holder: Control = _option_nodes[_current_index]
	var target_pos: Vector2 = target_holder.position + Vector2(ribbon_offset_x, ribbon_offset_y)

	# Mover franja amarilla y sombra con Tween suave (0.12 s, TRANS_BACK)
	if animate:
		var tw: Tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(_selector_ribbon, "position", target_pos, option_slide_time)
		tw.tween_property(_selector_shadow, "position", target_pos, option_slide_time)
	else:
		_selector_ribbon.position = target_pos
		_selector_shadow.position = target_pos

	_selector_ribbon.queue_redraw()
	_selector_shadow.queue_redraw()

	# Actualizar estilo de texto de cada opción
	for i in _option_nodes.size():
		var holder: Control = _option_nodes[i]
		var lbl: Label = holder.get_node_or_null("Label")
		if not lbl:
			continue

		var is_selected: bool = (i == _current_index)
		var is_enabled: bool = OPTIONS_DEF[i]["enabled"]

		if is_selected:
			# Seleccionada: texto negro tamaño 21 centrado en la franja
			lbl.add_theme_font_size_override("font_size", 21)
			lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
			lbl.remove_theme_constant_override("outline_size")
			lbl.remove_theme_color_override("font_outline_color")
		else:
			# No seleccionada: tamaño 18
			lbl.add_theme_font_size_override("font_size", 18)
			if is_enabled:
				# Habilitada no seleccionada: texto blanco con contorno negro de 4 px
				lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
				lbl.add_theme_constant_override("outline_size", outline_size_normal)
			else:
				# Deshabilitada no seleccionada: gris lila claro (#B8B0C8) con contorno negro de 2 px
				lbl.add_theme_color_override("font_color", color_text_disabled)
				lbl.add_theme_constant_override("outline_size", outline_size_disabled)

			lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08))

# ---------------------------------------------------------------------------
# CAPA 6: Barra Inferior Negra con Teclas Amarillas y Etiquetas Blancas
# ---------------------------------------------------------------------------
func _build_layer_6_bottom_bar() -> void:
	var bar_h: float = 28.0
	var bar := Control.new()
	bar.name = "Layer6_BottomBar"
	bar.position = Vector2(0.0, BASE_H - bar_h)
	bar.size = Vector2(BASE_W, bar_h)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(bar)

	# Fondo negro #151515
	var bg_rect := ColorRect.new()
	bg_rect.color = color_stripe_black
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg_rect)

	# Contenedor de teclas
	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	bar.add_child(hbox)

	_add_bottom_key_prompt(hbox, "↑↓", "Navegar")
	_add_bottom_key_prompt(hbox, "Enter", "Elegir")
	_add_bottom_key_prompt(hbox, "Esc", "Volver")

func _add_bottom_key_prompt(parent: HBoxContainer, key_text: String, label_text: String) -> void:
	var item_box := HBoxContainer.new()
	item_box.add_theme_constant_override("separation", 6)
	parent.add_child(item_box)

	# Rectángulo amarillo con texto negro
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
	lbl_key.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		lbl_key.add_theme_font_override("font", _italic_font)
	key_panel.add_child(lbl_key)

	# Etiqueta blanca descriptiva
	var lbl_action := Label.new()
	lbl_action.text = label_text
	lbl_action.add_theme_font_size_override("font_size", 11)
	lbl_action.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if _italic_font:
		lbl_action.add_theme_font_override("font", _italic_font)
	item_box.add_child(lbl_action)

# ---------------------------------------------------------------------------
# Entrada por Teclado e Interacción
# ---------------------------------------------------------------------------
func _input(event: InputEvent) -> void:
	# Detectar movimiento intencional del ratón (ignorar si el ratón estaba quieto al abrir)
	if event is InputEventMouseMotion:
		if event.relative.length_squared() > 4.0:
			_mouse_has_moved = true

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.is_action_pressed("ui_up") or event.keycode == KEY_UP or event.keycode == KEY_W:
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_navigate(-1)
		elif event.is_action_pressed("ui_down") or event.keycode == KEY_DOWN or event.keycode == KEY_S:
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_navigate(1)
		elif event.is_action_pressed("ui_accept") or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_activate_current_option()
		elif event.is_action_pressed("ui_cancel") or event.keycode == KEY_ESCAPE:
			var vp := get_viewport()
			if vp:
				vp.set_input_as_handled()
			_on_back_pressed()

func _navigate(dir: int) -> void:
	var total: int = OPTIONS_DEF.size()
	var next_idx: int = (_current_index + dir + total) % total
	_set_selection(next_idx)

func _activate_current_option() -> void:
	var opt: Dictionary = OPTIONS_DEF[_current_index]
	var opt_id: String = opt["id"]

	# Si la opción está deshabilitada, no ejecutar acción y reproducir sonido de error
	if not opt["enabled"]:
		print("[Menú] 🔒 La opción '%s' está deshabilitada (Próximamente)." % opt["label"])
		_play_sfx(_sfx_error)
		return

	_play_sfx(_sfx_choose)
	emit_signal("option_selected", opt_id)

	match opt_id:
		"story":
			print("[Menú] 📖 Iniciando Modo Historia: ECOS...")
			var sm = get_node_or_null("/root/StoryManager")
			if sm:
				sm.start_story(false)
			var target_scene := "res://scenes/story/story_stage.tscn"
			if ResourceLoader.exists(target_scene):
				get_tree().change_scene_to_file(target_scene)
			else:
				push_error("MainMenu: No se encontró la escena '%s'." % target_scene)
		"local":
			print("[Menú] ⚔️ Iniciando Selección de Personaje (LOCAL)...")
			var gdata = get_node_or_null("/root/GameData")
			if gdata:
				gdata.current_mode = gdata.GameMode.LOCAL
			emit_signal("start_local_mode")
			var target_scene := "res://scenes/ui/character_select.tscn"
			if not ResourceLoader.exists(target_scene):
				target_scene = local_map_scene_path
				if not ResourceLoader.exists(target_scene) and ResourceLoader.exists("res://scenes/maps/test_map.tscn"):
					target_scene = "res://scenes/maps/test_map.tscn"
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

func _on_back_pressed() -> void:
	_play_sfx(_sfx_move)
	_set_selection(OPTIONS_DEF.size() - 1)

# ---------------------------------------------------------------------------
# Animaciones de Entrada (Tweens)
# ---------------------------------------------------------------------------
func _play_intro_animations() -> void:
	# 1. Panel diagonal naranja entra desde la izquierda
	if _panel_container:
		_panel_container.position.x = -380.0
		var tw_panel: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_panel.tween_property(_panel_container, "position:x", 0.0, panel_enter_time)

	# 2. Banner de título cae desde arriba
	if _title_banner:
		var target_y: float = _title_banner.position.y
		_title_banner.position.y = -80.0
		var tw_title: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_title.tween_property(_title_banner, "position:y", target_y, title_enter_time)

	# 3. Opciones escalonadas entran desde la derecha una tras otra
	for i in _option_nodes.size():
		var holder: Control = _option_nodes[i]
		var final_x: float = holder.position.x
		holder.position.x = final_x + 180.0
		holder.modulate.a = 0.0

		var tw_opt: Tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		var delay: float = 0.1 + i * option_stagger_delay
		tw_opt.tween_interval(delay)
		tw_opt.tween_property(holder, "position:x", final_x, 0.22)
		tw_opt.parallel().tween_property(holder, "modulate:a", 1.0, 0.22)

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

	# Si existen archivos de sonido en assets/sounds/, enlazarlos de forma segura
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

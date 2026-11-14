## main_menu.gd
## Menú Principal de DRAGON BALL: ECOS
## Fase 9 · Módulo A1 — Composición Definitiva con Assets Oficiales (Logos, Banderas e Iconos).
##
## Esquema de Distribución (Canvas base 680 × 400):
## ┌─────────────────────────────────────────────────────────────────────────┐
## │ [ZONA IZQUIERDA ~33%]     │ [ZONA SUPERIOR: LOGO OFICIAL FREESTANDING]  │
## │ Banderas Manga Oficiales  │ DRAGON BALL: ECOS Oficial (2125 x 710)      │
## │ Goku / Naruto / Madara /  │ x: 235 - 525, y: 8 - 80                     │
## │ Vegetto + Trama Halftone  ├───────────────────────┬─────────────────────┤
## │ Luchador Pixel Art 6x     │ [COLUMNA DE BOTONES]  │ [SUBMENÚ HISTORIA]  │
## │ Sombra sólida de suelo    │ Paralelogramos 236 px │ Espacio reservado   │
## │ x: 0..330 (con corte)     │ x: 220 / 228          │ x: 472 - 666        │
## │                           │ y: 86 - 354           │ y: 90 - 220         │
## ├───────────────────────────┴───────────────────────┴─────────────────────┤
## │ [BARRA INFERIOR DE CONTROLES (26 px)]                                   │
## │ x: 0 - 680, y: 374 - 400. Teclas: ▲▼ Navegar | Enter | Esc              │
## └─────────────────────────────────────────────────────────────────────────┘
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
@export_group("Textos y Rutas")
@export var local_map_scene_path: String = "res://scenes/maps/valle_del_fin.tscn"

@export_group("Tipografía")
@export var font_path: String = "res://assets/fonts/PixelifySans-Regular.ttf"
@export var font_shear: float = 0.2 ## Inclinación para itálica manga

@export_group("Personaje")
@export var character_scale: Vector2 = Vector2(6.0, 6.0)
@export var character_ground_x: float = 95.0
@export var feet_y_offset: float = 23.0
@export var char_exit_time: float = 0.10
@export var char_enter_time: float = 0.16
@export var char_slide_offset: float = 35.0
@export var breath_cycle_time: float = 0.75

@export_group("Fondos y Animaciones")
@export var bg_transition_time: float = 0.40
@export var bg_parallax_offset: float = 4.0
@export var banner_transition_time: float = 0.25
@export var option_slide_time: float = 0.10

@export_group("Paleta de Color Manga")
@export var color_panel_orange: Color = Color(0.949, 0.549, 0.157)  ## #F28C28
@export var color_dot_pattern: Color = Color(0.851, 0.451, 0.102)   ## #D9731A
@export var color_speed_lines: Color = Color(1.0, 0.761, 0.400)     ## #FFC266
@export var color_stripe_black: Color = Color(0.082, 0.082, 0.082)  ## #151515
@export var color_stripe_yellow: Color = Color(1.0, 0.824, 0.247)  ## #FFD23F
@export var color_ball_orange: Color = Color(0.96, 0.48, 0.08)
@export var color_ball_star: Color = Color(0.88, 0.15, 0.15)
@export var color_panel_dark: Color = Color(0.15, 0.10, 0.24)      ## #261A3D Morado oscuro
@export var color_panel_dark_border: Color = Color(0.08, 0.05, 0.14)
@export var color_text_disabled: Color = Color("b8b0c8")
@export var color_badge_bg: Color = Color(0.082, 0.082, 0.082)
@export var color_badge_text: Color = Color(1.0, 0.824, 0.247)

# ---------------------------------------------------------------------------
# Constantes de Distribución
# ---------------------------------------------------------------------------
const BASE_W: float = 680.0
const BASE_H: float = 400.0
const BG_NEUTRAL_X: float = -8.0

const OPTIONS_DEF: Array[Dictionary] = [
	{"id": "story",    "label": "Modo historia", "icon": "res://assets/ui/menu/icon_story.png",    "icon_tag": "BOOK",  "enabled": true},
	{"id": "local",    "label": "Modo local",    "icon": "res://assets/ui/menu/icon_local.png",    "icon_tag": "SWORD", "enabled": true},
	{"id": "vs_ai",    "label": "Vs IA",         "icon": "res://assets/ui/menu/icon_vs_ai.png",    "icon_tag": "VS",    "enabled": true},
	{"id": "training", "label": "Entrenamiento", "icon": "res://assets/ui/menu/icon_training.png", "icon_tag": "BELL",  "enabled": false},
	{"id": "shop",     "label": "Tienda",        "icon": "res://assets/ui/menu/icon_shop.png",     "icon_tag": "CART",  "enabled": false},
	{"id": "options",  "label": "Opciones",      "icon": "res://assets/ui/menu/icon_options.png",  "icon_tag": "GEAR",  "enabled": false},
	{"id": "exit",     "label": "Salir",         "icon": "res://assets/ui/menu/icon_exit.png",     "icon_tag": "EXIT",  "enabled": true},
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

const BANNER_ASSOCIATIONS: Dictionary = {
	"story": "res://assets/ui/menu/banner_goku.png",
	"local": "res://assets/ui/menu/banner_naruto.png",
	"vs_ai": "res://assets/ui/menu/banner_madara.png",
	"training": "res://assets/ui/menu/banner_vegetto.png",
	"shop": "res://assets/ui/menu/banner_goku.png",
	"options": "res://assets/ui/menu/banner_naruto.png",
	"exit": "res://assets/ui/menu/banner_goku.png",
}

# ---------------------------------------------------------------------------
# Estado Interno
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
var _banner_current: TextureRect = null
var _banner_incoming: TextureRect = null
var _banner_tween: Tween = null
var _active_banner_path: String = ""
var _banner_texture_cache: Dictionary = {}

var _logo_node: Control = null
var _logo_rect: TextureRect = null

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

	# Contenedor raíz proporcional 680 × 400
	_content = Control.new()
	_content.name = "CanvasBase"
	_content.custom_minimum_size = Vector2(BASE_W, BASE_H)
	_content.size = Vector2(BASE_W, BASE_H)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_setup_italic_font()

	# Construir las capas del menú principal
	_build_layer_1_background()
	_build_layer_2_diagonal_manga_panel()
	_build_layer_3_character()
	_build_layer_4_logo()
	_build_layer_5_options_column()
	_build_layer_6_story_submenu()
	_build_layer_7_bottom_bar()
	_setup_audio_players()

	_rescale_canvas()

	# Estado inicial: Historia con Valle del Fin y Goku
	_current_index = 0
	_in_story_submenu = false
	_story_sub_index = 0
	_update_selection_visuals(false)
	_set_initial_character(0)
	_init_initial_background(0)
	_init_initial_banner(0)
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
# CAPA 1: Escenario Dinámico (Fondo Principal)
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

	# Atenuador lateral derecho suave para proteger contraste de opciones
	_bg_dimmer = ColorRect.new()
	_bg_dimmer.name = "BgDimmer"
	_bg_dimmer.position = Vector2(210.0, 0.0)
	_bg_dimmer.size = Vector2(BASE_W - 210.0, BASE_H)
	_bg_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg_dimmer.color = Color(0.06, 0.04, 0.10, 0.25)
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
		return

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
# CAPA 2: Banderas Manga Oficiales (Tercio Izquierdo con Corte Relámpago)
# ---------------------------------------------------------------------------
func _build_layer_2_diagonal_manga_panel() -> void:
	_panel_manga = Control.new()
	_panel_manga.name = "Layer2_DiagonalPanel"
	_panel_manga.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_manga.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_panel_manga)

	var banner_size := Vector2(335.0, BASE_H)

	_banner_current = TextureRect.new()
	_banner_current.name = "BannerCurrent"
	_banner_current.position = Vector2(0.0, 0.0)
	_banner_current.size = banner_size
	_banner_current.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_current.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_banner_current.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_current.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_panel_manga.add_child(_banner_current)

	_banner_incoming = TextureRect.new()
	_banner_incoming.name = "BannerIncoming"
	_banner_incoming.position = Vector2(0.0, 0.0)
	_banner_incoming.size = banner_size
	_banner_incoming.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_banner_incoming.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_banner_incoming.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_banner_incoming.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_banner_incoming.modulate.a = 0.0
	_panel_manga.add_child(_banner_incoming)

	# Dibujo procedural de respaldo si falta textura
	_panel_manga.draw.connect(_on_draw_diagonal_panel_fallback)

func _get_banner_texture(path: String) -> Texture2D:
	if _banner_texture_cache.has(path):
		return _banner_texture_cache[path]
	if ResourceLoader.exists(path):
		var tex = load(path) as Texture2D
		if tex:
			_banner_texture_cache[path] = tex
			return tex
	return null

func _init_initial_banner(option_idx: int) -> void:
	var opt_id: String = OPTIONS_DEF[option_idx]["id"] if option_idx >= 0 and option_idx < OPTIONS_DEF.size() else "story"
	var target_path: String = BANNER_ASSOCIATIONS.get(opt_id, "res://assets/ui/menu/banner_goku.png")
	_active_banner_path = target_path
	var tex := _get_banner_texture(target_path)
	if tex and _banner_current:
		_banner_current.texture = tex
		_banner_current.modulate.a = 1.0

func _change_banner_for_option(option_idx: int) -> void:
	if option_idx < 0 or option_idx >= OPTIONS_DEF.size():
		return
	var opt_id: String = OPTIONS_DEF[option_idx]["id"]
	var target_path: String = BANNER_ASSOCIATIONS.get(opt_id, "res://assets/ui/menu/banner_goku.png")
	if target_path == _active_banner_path:
		return

	var next_tex: Texture2D = _get_banner_texture(target_path)
	if not next_tex:
		return

	if _banner_tween and _banner_tween.is_valid():
		_banner_tween.kill()
		if _banner_incoming.texture:
			_banner_current.texture = _banner_incoming.texture
		_banner_current.modulate.a = 1.0
		_banner_incoming.modulate.a = 0.0

	_active_banner_path = target_path
	_banner_incoming.texture = next_tex
	_banner_incoming.modulate.a = 0.0
	_banner_incoming.position.x = -15.0

	_banner_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_banner_tween.tween_property(_banner_current, "modulate:a", 0.0, banner_transition_time)
	_banner_tween.tween_property(_banner_incoming, "modulate:a", 1.0, banner_transition_time)
	_banner_tween.tween_property(_banner_incoming, "position:x", 0.0, banner_transition_time)

	_banner_tween.chain().tween_callback(func():
		_banner_current.texture = next_tex
		_banner_current.modulate.a = 1.0
		_banner_incoming.modulate.a = 0.0
	)

func _on_draw_diagonal_panel_fallback() -> void:
	if _banner_current and _banner_current.texture:
		return
	var pts_panel := PackedVector2Array([
		Vector2(0, 0), Vector2(215, 0), Vector2(155, BASE_H - 26.0), Vector2(0, BASE_H - 26.0)
	])
	_panel_manga.draw_colored_polygon(pts_panel, color_panel_orange)

# ---------------------------------------------------------------------------
# CAPA 3: Personaje Pixel Art con Sombra Sólida
# ---------------------------------------------------------------------------
func _build_layer_3_character() -> void:
	_char_holder = Control.new()
	_char_holder.name = "Layer3_CharacterHolder"
	_char_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_holder.z_index = 5
	_char_holder.position = Vector2(character_ground_x, BASE_H - 26.0)
	_content.add_child(_char_holder)

	# Sombra sólida elíptica en el suelo
	_char_shadow = Control.new()
	_char_shadow.name = "CharShadow"
	_char_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_char_holder.add_child(_char_shadow)
	_char_shadow.draw.connect(func():
		var pts_shadow := PackedVector2Array([
			Vector2(-38, -3), Vector2(38, -3), Vector2(48, 3), Vector2(-28, 3)
		])
		_char_shadow.draw_colored_polygon(pts_shadow, Color(0.08, 0.08, 0.08, 0.75))
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
# CAPA 4: Logotipo Oficial DRAGON BALL: ECOS (Zona Superior)
# ---------------------------------------------------------------------------
func _build_layer_4_logo() -> void:
	_logo_node = Control.new()
	_logo_node.name = "Layer4_TitleBanner" # Compatible con suites y animaciones
	_logo_node.position = Vector2(235.0, 8.0)
	_logo_node.size = Vector2(285.0, 74.0)
	_logo_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_logo_node)

	var logo_path := "res://assets/ui/menu/logo_dragon_ball_ecos.png"
	if ResourceLoader.exists(logo_path):
		_logo_rect = TextureRect.new()
		_logo_rect.name = "LogoImage"
		_logo_rect.texture = load(logo_path)
		_logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_logo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_logo_rect.position = Vector2(0.0, 0.0)
		_logo_rect.size = Vector2(285.0, 74.0)
		_logo_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_logo_node.add_child(_logo_rect)
	else:
		_logo_node.draw.connect(_on_draw_freestanding_logo_fallback)

func _on_draw_freestanding_logo_fallback() -> void:
	var font_to_use: Font = _italic_font if _italic_font else ThemeDB.fallback_font
	_logo_node.draw_string(font_to_use, Vector2(10, 44), "DRAGON BALL: ECOS", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, color_stripe_yellow)

# ---------------------------------------------------------------------------
# CAPA 5: Columna de Opciones con Iconos Oficiales
# ---------------------------------------------------------------------------
func _build_layer_5_options_column() -> void:
	_options_container = Control.new()
	_options_container.name = "Layer5_MenuOptions"
	_options_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_options_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_options_container)

	var start_x: float = 228.0
	var start_y: float = 86.0
	var step_y: float = 39.0
	var item_w: float = 236.0
	var item_h: float = 33.0

	_option_nodes.clear()

	for i in range(OPTIONS_DEF.size()):
		var opt_data: Dictionary = OPTIONS_DEF[i]
		var oy: float = start_y + (i * step_y)

		var btn_holder := Control.new()
		btn_holder.name = "Option_%s" % opt_data["id"]
		btn_holder.position = Vector2(start_x, oy)
		btn_holder.size = Vector2(item_w, item_h)
		btn_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		_options_container.add_child(btn_holder)
		_option_nodes.append(btn_holder)

		var idx: int = i
		btn_holder.draw.connect(func():
			_draw_option_panel(btn_holder, idx)
		)

		# Icono oficial estilizado
		var icon_path: String = opt_data.get("icon", "")
		if ResourceLoader.exists(icon_path):
			var icon_rect := TextureRect.new()
			icon_rect.name = "IconRect"
			icon_rect.texture = load(icon_path)
			icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			icon_rect.position = Vector2(16.0, (item_h - 22.0) / 2.0)
			icon_rect.size = Vector2(30.0, 22.0)
			icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_holder.add_child(icon_rect)

		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = opt_data["label"]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(52.0, 0.0)
		lbl.size = Vector2(item_w - 52.0 - 74.0, item_h)
		lbl.clip_text = false
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _italic_font:
			lbl.add_theme_font_override("font", _italic_font)
		btn_holder.add_child(lbl)

		# Insignia "Próximamente" para opciones no disponibles
		if not opt_data["enabled"] and opt_data["id"] != "exit":
			var badge := PanelContainer.new()
			badge.name = "Badge"
			badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			var b_box := StyleBoxFlat.new()
			b_box.bg_color = color_badge_bg
			b_box.set_corner_radius_all(2)
			b_box.content_margin_left = 4
			b_box.content_margin_right = 4
			b_box.content_margin_top = 1
			b_box.content_margin_bottom = 1
			badge.add_theme_stylebox_override("panel", b_box)

			var b_lbl := Label.new()
			b_lbl.name = "BadgeLabel"
			b_lbl.text = "Próximamente"
			b_lbl.add_theme_font_size_override("font_size", 8)
			b_lbl.add_theme_color_override("font_color", color_badge_text)
			if _italic_font:
				b_lbl.add_theme_font_override("font", _italic_font)
			badge.add_child(b_lbl)
			badge.position = Vector2(item_w - 74.0, (item_h - 17.0) / 2.0)
			btn_holder.add_child(badge)

		btn_holder.mouse_entered.connect(func():
			if _mouse_has_moved:
				_set_selection(idx)
		)
		btn_holder.gui_input.connect(func(event: InputEvent):
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
				var vp := get_viewport()
				if vp: vp.set_input_as_handled()
				_set_selection(idx)
				_activate_current_option()
		)

	_update_selection_visuals(false)

func _draw_option_panel(holder: Control, idx: int) -> void:
	var w: float = holder.size.x
	var h: float = holder.size.y
	var slant: float = 14.0
	var is_selected: bool = (idx == _current_index and not _in_story_submenu)
	var opt_def: Dictionary = OPTIONS_DEF[idx]

	var p1 := Vector2(slant, 0.0)
	var p2 := Vector2(w, 0.0)
	var p3 := Vector2(w - slant, h)
	var p4 := Vector2(0.0, h)

	# 1. Sombra sólida proyectada 4 px hacia abajo-derecha
	var shadow_off := Vector2(4.0, 4.0)
	var pts_shadow := PackedVector2Array([p1 + shadow_off, p2 + shadow_off, p3 + shadow_off, p4 + shadow_off])
	holder.draw_colored_polygon(pts_shadow, Color(0.04, 0.02, 0.08, 0.85))

	if is_selected:
		# Panel seleccionado: Gradiente Amarillo brillante Manga Dragon Ball
		var p_mid_left := Vector2(slant * 0.5, h * 0.5)
		var p_mid_right := Vector2(w - slant * 0.5, h * 0.5)

		# Mitad superior
		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p_mid_right, p_mid_left]), Color(1.0, 0.95, 0.40))
		# Mitad inferior
		holder.draw_colored_polygon(PackedVector2Array([p_mid_left, p_mid_right, p3, p4]), Color(1.0, 0.70, 0.0))

		# Trama halftone sutil en la mitad derecha del botón
		for y in range(4, int(h - 4), 6):
			for x in range(int(w * 0.55), int(w - slant - 6), 8):
				holder.draw_circle(Vector2(x, y), 1.0, Color(0.85, 0.55, 0.0, 0.45))

		# Borde negro grueso de 2.5 px
		var outline := PackedVector2Array([p1, p2, p3, p4, p1])
		holder.draw_polyline(outline, Color(0.08, 0.05, 0.02), 2.5)

		# Triángulo de selección '▶' saliente en la izquierda
		var arrow_pts := PackedVector2Array([
			Vector2(-12.0, h * 0.18),
			Vector2(4.0, h * 0.50),
			Vector2(-12.0, h * 0.82)
		])
		holder.draw_colored_polygon(arrow_pts, color_stripe_yellow)
		holder.draw_polyline(PackedVector2Array([arrow_pts[0], arrow_pts[1], arrow_pts[2], arrow_pts[0]]), color_stripe_black, 2.5)

		# Franjas diagonales de velocidad en el extremo derecho
		holder.draw_line(Vector2(w - 24, 6), Vector2(w - 34, h - 6), color_stripe_black, 2.5)
		holder.draw_line(Vector2(w - 17, 6), Vector2(w - 27, h - 6), color_stripe_black, 2.5)
		holder.draw_line(Vector2(w - 10, 6), Vector2(w - 20, h - 6), color_stripe_black, 2.5)
	else:
		# Panel en reposo: Morado oscuro manga biselado
		var p_mid_left := Vector2(slant * 0.5, h * 0.5)
		var p_mid_right := Vector2(w - slant * 0.5, h * 0.5)

		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p_mid_right, p_mid_left]), Color(0.18, 0.11, 0.28))
		holder.draw_colored_polygon(PackedVector2Array([p_mid_left, p_mid_right, p3, p4]), Color(0.10, 0.06, 0.18))

		# Línea de bisel superior de brillo
		holder.draw_line(p1 + Vector2(2, 2), p2 + Vector2(-2, 2), Color(0.48, 0.32, 0.68, 0.85), 1.5)

		var outline := PackedVector2Array([p1, p2, p3, p4, p1])
		holder.draw_polyline(outline, Color(0.07, 0.04, 0.12), 2.0)

# ---------------------------------------------------------------------------
# CAPA 6: Submenú de Historia (Espacio Reservado a la Derecha)
# ---------------------------------------------------------------------------
func _build_layer_6_story_submenu() -> void:
	_story_submenu_panel = Control.new()
	_story_submenu_panel.name = "Layer6_StorySubmenu"
	_story_submenu_panel.position = Vector2(472.0, 90.0)
	_story_submenu_panel.size = Vector2(194.0, 128.0)
	_story_submenu_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_story_submenu_panel)

	_story_submenu_panel.draw.connect(_on_draw_story_submenu_bg)

	_story_sub_nodes.clear()
	var sub_h: float = 30.0
	for i in range(STORY_SUBMENU_DEF.size()):
		var sub_data: Dictionary = STORY_SUBMENU_DEF[i]
		var sub_holder := Control.new()
		sub_holder.name = "SubOption_%s" % sub_data["id"]
		sub_holder.position = Vector2(14.0, 44.0 + (i * 38.0))
		sub_holder.size = Vector2(165.0, sub_h)
		sub_holder.mouse_filter = Control.MOUSE_FILTER_STOP
		_story_submenu_panel.add_child(sub_holder)
		_story_sub_nodes.append(sub_holder)

		var sub_idx := i
		sub_holder.draw.connect(func():
			_draw_story_sub_item(sub_holder, sub_idx)
		)

		var lbl := Label.new()
		lbl.name = "Label"
		lbl.text = sub_data["label"]
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.position = Vector2(28.0, 0.0)
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
	var slant: float = 14.0

	# 1. Sombra
	var pts_s := PackedVector2Array([
		Vector2(slant + 4, 4), Vector2(w + 4, 4), Vector2(w - slant + 4, h + 4), Vector2(4, h + 4)
	])
	_story_submenu_panel.draw_colored_polygon(pts_s, Color(0.04, 0.03, 0.06, 0.85))

	# 2. Cuerpo morado cósmico #1E1330
	var pts := PackedVector2Array([
		Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(0, h)
	])
	_story_submenu_panel.draw_colored_polygon(pts, Color(0.12, 0.08, 0.20, 0.95))

	# Trama halftone en cabecera
	for y in range(4, 32, 6):
		for x in range(int(slant + 6), int(w - 6), 8):
			_story_submenu_panel.draw_circle(Vector2(x, y), 1.0, Color(0.40, 0.25, 0.60, 0.50))

	# Contorno amarillo manga
	var outline := PackedVector2Array([
		Vector2(slant, 0), Vector2(w, 0), Vector2(w - slant, h), Vector2(0, h), Vector2(slant, 0)
	])
	_story_submenu_panel.draw_polyline(outline, color_stripe_yellow, 2.5)

	# Cabecera "📖 Historia"
	var font_to_use: Font = _italic_font if _italic_font else ThemeDB.fallback_font
	_story_submenu_panel.draw_string(font_to_use, Vector2(24, 26), "📖  HISTORIA", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color(1.0, 1.0, 1.0))

func _draw_story_sub_item(holder: Control, idx: int) -> void:
	var w: float = holder.size.x
	var h: float = holder.size.y
	var slant: float = 10.0
	var is_active: bool = (_in_story_submenu and idx == _story_sub_index)

	var p1 := Vector2(slant, 0.0)
	var p2 := Vector2(w, 0.0)
	var p3 := Vector2(w - slant, h)
	var p4 := Vector2(0.0, h)

	if is_active:
		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), color_stripe_yellow)
		holder.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), color_stripe_black, 2.5)

		# Flecha negra de selección
		var arr := PackedVector2Array([
			Vector2(10.0, h * 0.28), Vector2(18.0, h * 0.50), Vector2(10.0, h * 0.72)
		])
		holder.draw_colored_polygon(arr, color_stripe_black)
	else:
		holder.draw_colored_polygon(PackedVector2Array([p1, p2, p3, p4]), Color(0.22, 0.15, 0.33))
		holder.draw_polyline(PackedVector2Array([p1, p2, p3, p4, p1]), Color(0.12, 0.08, 0.18), 1.5)

		# Icono indicador neutro
		if idx == 0:
			holder.draw_colored_polygon(PackedVector2Array([
				Vector2(12.0, h * 0.30), Vector2(18.0, h * 0.50), Vector2(12.0, h * 0.70)
			]), color_stripe_yellow)
		else:
			holder.draw_line(Vector2(11, h * 0.35), Vector2(19, h * 0.35), color_stripe_yellow, 2.0)
			holder.draw_line(Vector2(11, h * 0.50), Vector2(19, h * 0.50), color_stripe_yellow, 2.0)
			holder.draw_line(Vector2(11, h * 0.65), Vector2(19, h * 0.65), color_stripe_yellow, 2.0)

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
# CAPA 7: Barra Inferior de Controles (Discreta)
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
		# Acentos diagonales amarillos en esquinas
		for k in range(4):
			bar.draw_line(Vector2(6.0 + k * 6.0, 24.0), Vector2(16.0 + k * 6.0, 2.0), color_stripe_yellow, 2.0)
			bar.draw_line(Vector2(BASE_W - 32.0 + k * 6.0, 24.0), Vector2(BASE_W - 22.0 + k * 6.0, 2.0), color_stripe_yellow, 2.0)
	)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 24)
	bar.add_child(hbox)

	_add_bottom_key_prompt(hbox, "▲▼", "Navegar")
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
	_change_banner_for_option(_current_index)
	_change_background_for_option(_current_index)
	_update_story_submenu_visibility(true)

func _update_selection_visuals(animate: bool) -> void:
	var base_x: float = 228.0
	for i in range(_option_nodes.size()):
		var holder: Control = _option_nodes[i]
		var is_selected: bool = (i == _current_index and not _in_story_submenu)
		var is_enabled: bool = OPTIONS_DEF[i]["enabled"]
		var target_x: float = (base_x - 8.0) if is_selected else base_x

		if animate:
			var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(holder, "position:x", target_x, option_slide_time)
		else:
			holder.position.x = target_x

		var icon_rect: TextureRect = holder.get_node_or_null("IconRect")
		if icon_rect:
			if is_selected:
				icon_rect.modulate = Color(1.0, 1.0, 1.0, 1.0)
				icon_rect.scale = Vector2(1.10, 1.10)
			elif is_enabled:
				icon_rect.modulate = Color(0.90, 0.86, 0.98, 0.90)
				icon_rect.scale = Vector2(1.0, 1.0)
			else:
				icon_rect.modulate = Color(0.55, 0.50, 0.65, 0.60)
				icon_rect.scale = Vector2(1.0, 1.0)

		var lbl: Label = holder.get_node_or_null("Label")
		if lbl:
			if is_selected:
				lbl.add_theme_font_size_override("font_size", 15)
				lbl.add_theme_color_override("font_color", Color(0.08, 0.04, 0.02))
				lbl.remove_theme_constant_override("outline_size")
			else:
				lbl.add_theme_font_size_override("font_size", 14)
				lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0) if is_enabled else color_text_disabled)
				lbl.add_theme_constant_override("outline_size", 2)
				lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.04, 0.12))

		holder.queue_redraw()

	for i in range(_story_sub_nodes.size()):
		var sub_holder: Control = _story_sub_nodes[i]
		var is_sub_active: bool = (_in_story_submenu and i == _story_sub_index)
		var sub_lbl: Label = sub_holder.get_node_or_null("Label")
		if sub_lbl:
			sub_lbl.add_theme_font_size_override("font_size", 13)
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
		_panel_manga.position.x = -240.0
		var tw_panel := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_panel.tween_property(_panel_manga, "position:x", 0.0, 0.30)

	if _logo_node:
		var target_y: float = _logo_node.position.y
		_logo_node.position.y = -80.0
		var tw_title := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw_title.tween_property(_logo_node, "position:y", target_y, 0.35)

	for i in range(_option_nodes.size()):
		var holder: Control = _option_nodes[i]
		var fx: float = holder.position.x
		holder.position.x = fx + 140.0
		holder.modulate.a = 0.0
		var tw_opt := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_opt.tween_interval(0.06 + (i * 0.03))
		tw_opt.tween_property(holder, "position:x", fx, 0.18)
		tw_opt.parallel().tween_property(holder, "modulate:a", 1.0, 0.18)

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

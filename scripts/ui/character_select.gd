## character_select.gd
## Pantalla de Selección de Personaje (Fase 5 - Paso 2).
## Estilo manga idéntico al menú principal: colores planos, bordes rectos, sin degradados ni brillos.
## Canvas base 680x400 con escalado proporcional a cualquier resolución.
class_name CharacterSelect
extends Control

# ---------------------------------------------------------------------------
# Señales
# ---------------------------------------------------------------------------
signal characters_confirmed(p1_data: CharacterData, p2_data: CharacterData)
signal back_to_menu_requested()

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables en el Inspector)
# ---------------------------------------------------------------------------
@export_group("Escenas y Navegación")
@export var combat_scene_path: String = "res://resources/characters/test_map.tscn"
@export var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

@export_group("Tipografía")
@export var font_path: String = "res://assets/fonts/PixelifySans-Regular.ttf"
@export var font_shear: float = 0.2 ## Inclinación en cursiva (variation_transform)

@export_group("Cuadrícula de Retratos")
@export var show_empty_slots: bool = true ## Muestra casillas vacías (#2A2240) solo si es true
@export var grid_columns: int = 4
@export var grid_min_rows: int = 3
@export var slot_size: float = 40.0
@export var slot_gap: float = 6.0
@export var slot_border_width: float = 3.0

@export_group("Luchadores en Pantalla")
@export var character_scale: Vector2 = Vector2(4.0, 4.0) ## Escala entera 4x
@export var ground_y: float = 290.0                      ## Línea común horizontal donde apoyan los pies
@export var feet_y_offset: float = 23.0                  ## Distancia centro-pies en sprites 68x68
@export var p1_x: float = 110.0                          ## Centro X de P1
@export var p2_x: float = 570.0                          ## Centro X de P2
@export var breath_cycle_time: float = 0.8               ## Duración del ciclo de respiración
@export var p2_facing_front: bool = true                 ## Si es true, ambos personajes miran al frente (sin flip)

@export_group("Colores")
@export var color_bg_purple: Color = Color(0.227, 0.184, 0.333)       ## #3A2F55 Fondo púrpura
@export var color_bg_dots: Color = Color(0.290, 0.239, 0.420)         ## #4A3D6B Puntos de trama derecha
@export var color_panel_orange: Color = Color(0.949, 0.549, 0.157)     ## #F28C28 Naranja mitad izquierda
@export var color_dot_pattern: Color = Color(0.851, 0.451, 0.102)      ## #D9731A Puntos naranja
@export var color_stripe_black: Color = Color(0.082, 0.082, 0.082)     ## #151515 Negro
@export var color_stripe_yellow: Color = Color(1.0, 0.824, 0.247)     ## #FFD23F Amarillo
@export var color_slot_bg: Color = Color(0.275, 0.188, 0.310)          ## #46304F Fondo casilla personaje
@export var color_empty_slot: Color = Color(0.165, 0.133, 0.251)       ## #2A2240 Fondo casilla vacía
@export var color_p1_cursor: Color = Color(1.0, 0.824, 0.247)         ## #FFD23F Cursor P1
@export var color_p2_cursor: Color = Color(1.0, 1.0, 1.0)              ## #FFFFFF Cursor P2

# ---------------------------------------------------------------------------
# Constantes del Canvas Base (680x400)
# ---------------------------------------------------------------------------
const BASE_W: float = 680.0
const BASE_H: float = 400.0

# ---------------------------------------------------------------------------
# Estado Interno
# ---------------------------------------------------------------------------
var _content: Control = null
var _bg_canvas: Control = null
var _grid_container: Control = null
var _slots: Array[Dictionary] = [] # {"type": "char"|"random"|"empty", "data": CharacterData, "pos": Vector2, "control": Control}
var _characters: Array[CharacterData] = []
var _character_frames_cache: Dictionary = {}

# Cursores y selección
var _p1_index: int = 0
var _p2_index: int = 1
var _p1_ready: bool = false
var _p2_ready: bool = false
var _match_starting: bool = false

# Modo de Oponente (VS Jugador / VS IA)
var _vs_ai_mode: bool = false
var _btn_mode_toggle: Button = null
var _lbl_mode_hint: Label = null

# Nodos de Luchadores y UI
var _p1_container: Control = null
var _p2_container: Control = null
var _p1_sprite: AnimatedSprite2D = null
var _p2_sprite: AnimatedSprite2D = null
var _p1_name_label: Label = null
var _p2_name_label: Label = null
var _p1_stat_bars: Dictionary = {}
var _p2_stat_bars: Dictionary = {}
var _badge_j1: PanelContainer = null
var _badge_j2: PanelContainer = null
var _lbl_j1_status: Label = null
var _lbl_j2_status: Label = null
var _p1_cursor_draw: Control = null
var _p2_cursor_draw: Control = null

# Audio
var _sfx_move: AudioStreamPlayer = null
var _sfx_choose: AudioStreamPlayer = null
var _sfx_cancel: AudioStreamPlayer = null
var _sfx_start: AudioStreamPlayer = null
var _italic_font: FontVariation = null

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Contenedor escalable 680x400
	_content = Control.new()
	_content.name = "CanvasBase"
	_content.custom_minimum_size = Vector2(BASE_W, BASE_H)
	_content.size = Vector2(BASE_W, BASE_H)
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)

	_setup_italic_font()
	_load_available_characters()

	_build_layer_1_background()
	_build_layer_2_title_banner()
	_build_layer_3_fighters()
	_build_layer_4_name_and_stats()
	_build_layer_5_grid()
	_build_layer_6_status_badges()
	_build_layer_mode_toggle()
	_build_layer_7_bottom_bar()
	_setup_audio_players()

	_rescale_canvas()

	# Configurar posiciones iniciales (P1 en 0 = Goku, P2 en 1 = Naruto)
	_p1_index = 0
	_p2_index = 1 if _slots.size() > 1 else 0
	_update_cursors_visuals()
	_update_p1_display()
	_update_p2_display()

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
		var f = load(font_path)
		if f is Font:
			_italic_font.base_font = f
	else:
		var dir := DirAccess.open("res://assets/fonts/")
		if dir:
			dir.list_dir_begin()
			var fn := dir.get_next()
			while fn != "":
				if not dir.current_is_dir() and fn.get_extension().to_lower() == "ttf":
					var f = load("res://assets/fonts/" + fn)
					if f is Font:
						_italic_font.base_font = f
						break
				fn = dir.get_next()
	_italic_font.variation_transform = Transform2D(Vector2(1.0, 0.0), Vector2(-font_shear, 1.0), Vector2.ZERO)

# ---------------------------------------------------------------------------
# Carga de Personajes
# ---------------------------------------------------------------------------
func _load_available_characters() -> void:
	_characters.clear()
	var gdata = get_node_or_null("/root/GameData")
	if gdata and gdata.all_characters.size() > 0:
		_characters = gdata.all_characters.duplicate()
	else:
		var dir := DirAccess.open("res://resources/characters/")
		if dir:
			dir.list_dir_begin()
			var fn := dir.get_next()
			while fn != "":
				if not dir.current_is_dir() and fn.ends_with(".tres"):
					var res = load("res://resources/characters/" + fn)
					if res is CharacterData:
						_characters.append(res)
				fn = dir.get_next()
		if gdata:
			gdata.all_characters = _characters.duplicate()

	# Orden prioritario: Goku, luego Naruto, luego Madara, luego Vegetto, luego el resto por ID
	_characters.sort_custom(func(a, b):
		if a.id == "goku": return true
		if b.id == "goku": return false
		if a.id == "naruto": return true
		if b.id == "naruto": return false
		if a.id == "madara": return true
		if b.id == "madara": return false
		if a.id == "vegetto": return true
		if b.id == "vegetto": return false
		return a.id < b.id
	)

# ---------------------------------------------------------------------------
# CAPA 1: Fondo manga dividido (Naranja J1 izquierda, Púrpura J2 derecha)
# ---------------------------------------------------------------------------
func _build_layer_1_background() -> void:
	_bg_canvas = Control.new()
	_bg_canvas.name = "Layer1_Background"
	_bg_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_bg_canvas)

	_bg_canvas.draw.connect(_on_draw_background)

func _on_draw_background() -> void:
	# 1. Fondo base púrpura para J2 (#3A2F55)
	_bg_canvas.draw_rect(Rect2(0, 0, BASE_W, BASE_H), color_bg_purple)

	# Tramado de puntos halftone púrpura claro (#4A3D6B) en la mitad derecha
	var step: float = 12.0
	var dot_radius: float = 1.5
	for y in range(6, int(BASE_H), int(step)):
		var offset_x: float = 6.0 if (int(y / step) % 2 == 1) else 0.0
		# Inicio en el borde diagonal: x_edge = 300 - 60 * (y / 400)
		var edge_x: float = 300.0 - 60.0 * (float(y) / BASE_H)
		for x in range(int(edge_x + 10.0 + offset_x), int(BASE_W - 4), int(step)):
			_bg_canvas.draw_circle(Vector2(x, y), dot_radius, color_bg_dots)

	# 2. Panel diagonal naranja de J1: (0,0) -> (300,0) -> (240,400) -> (0,400)
	var pts_panel := PackedVector2Array([
		Vector2(0, 0),
		Vector2(300, 0),
		Vector2(240, BASE_H),
		Vector2(0, BASE_H)
	])
	_bg_canvas.draw_colored_polygon(pts_panel, color_panel_orange)

	# Tramado halftone naranja (#D9731A) dentro de la mitad izquierda
	for y in range(6, int(BASE_H), int(step)):
		var edge_x: float = 300.0 - 60.0 * (float(y) / BASE_H)
		var offset_x: float = 6.0 if (int(y / step) % 2 == 1) else 0.0
		for x in range(int(offset_x + 6), int(edge_x - 6), int(step)):
			_bg_canvas.draw_circle(Vector2(x, y), dot_radius, color_dot_pattern)

	# 3. Franjas diagonales en el borde divisorio
	# Franja negra #151515 (~8 px)
	var pts_black := PackedVector2Array([
		Vector2(300, 0),
		Vector2(308, 0),
		Vector2(248, BASE_H),
		Vector2(240, BASE_H)
	])
	_bg_canvas.draw_colored_polygon(pts_black, color_stripe_black)

	# Franja amarilla #FFD23F (~8 px)
	var pts_yellow := PackedVector2Array([
		Vector2(308, 0),
		Vector2(316, 0),
		Vector2(256, BASE_H),
		Vector2(248, BASE_H)
	])
	_bg_canvas.draw_colored_polygon(pts_yellow, color_stripe_yellow)

# ---------------------------------------------------------------------------
# CAPA 2: Banner de Título ("Elige tu luchador")
# ---------------------------------------------------------------------------
func _build_layer_2_title_banner() -> void:
	var banner := Control.new()
	banner.name = "Layer2_TitleBanner"
	banner.position = Vector2(215.0, 14.0)
	banner.size = Vector2(250.0, 42.0)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(banner)

	banner.draw.connect(func():
		var w: float = 250.0
		var h: float = 40.0
		var pts := PackedVector2Array([
			Vector2(14.0, 0.0),
			Vector2(w, 0.0),
			Vector2(w - 14.0, h),
			Vector2(0.0, h)
		])
		banner.draw_colored_polygon(pts, color_stripe_yellow)

		var outline := PackedVector2Array([
			Vector2(14.0, 0.0),
			Vector2(w, 0.0),
			Vector2(w - 14.0, h),
			Vector2(0.0, h),
			Vector2(14.0, 0.0)
		])
		banner.draw_polyline(outline, color_stripe_black, 3.0)
	)

	var lbl := Label.new()
	lbl.name = "TitleText"
	lbl.text = "Elige tu luchador"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 22)
	lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		lbl.add_theme_font_override("font", _italic_font)
	banner.add_child(lbl)

# ---------------------------------------------------------------------------
# CAPA 3: Luchadores Grandes en Pantalla (P1 y P2)
# ---------------------------------------------------------------------------
func _build_layer_3_fighters() -> void:
	var fighters_holder := Control.new()
	fighters_holder.name = "Layer3_Fighters"
	fighters_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(fighters_holder)

	# P1 Container y Sprite (Izquierda, mirando al frente)
	_p1_container = Control.new()
	_p1_container.name = "P1_Container"
	_p1_container.position = Vector2(p1_x, 0.0)
	_p1_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fighters_holder.add_child(_p1_container)

	_p1_sprite = AnimatedSprite2D.new()
	_p1_sprite.name = "P1_FighterSprite"
	_p1_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p1_sprite.scale = character_scale
	_p1_sprite.centered = true
	_p1_sprite.position = Vector2(0.0, ground_y - feet_y_offset * character_scale.y)
	_p1_container.add_child(_p1_sprite)

	# P2 Container y Sprite (Derecha, mirando al frente)
	_p2_container = Control.new()
	_p2_container.name = "P2_Container"
	_p2_container.position = Vector2(p2_x, 0.0)
	_p2_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fighters_holder.add_child(_p2_container)

	_p2_sprite = AnimatedSprite2D.new()
	_p2_sprite.name = "P2_FighterSprite"
	_p2_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_p2_sprite.scale = character_scale
	_p2_sprite.centered = true
	_p2_sprite.flip_h = not p2_facing_front # Ambos mirando al frente
	_p2_sprite.position = Vector2(0.0, ground_y - feet_y_offset * character_scale.y)
	_p2_container.add_child(_p2_sprite)

	# Animación de respiración sincronizada suave sobre los contenedores
	var tw: Tween = create_tween().set_loops()
	tw.tween_property(_p1_container, "position:y", -2.0, breath_cycle_time).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_p2_container, "position:y", -2.0, breath_cycle_time).set_trans(Tween.TRANS_SINE)
	tw.tween_property(_p1_container, "position:y", 0.0, breath_cycle_time).set_trans(Tween.TRANS_SINE)
	tw.parallel().tween_property(_p2_container, "position:y", 0.0, breath_cycle_time).set_trans(Tween.TRANS_SINE)

# ---------------------------------------------------------------------------
# CAPA 4: Banners de Nombre y Tres Barras de Stats (Vida, Vel., Daño)
# ---------------------------------------------------------------------------
func _build_layer_4_name_and_stats() -> void:
	# --- JUGADOR 1 (Izquierda) ---
	var p1_panel := Control.new()
	p1_panel.name = "P1_StatsPanel"
	p1_panel.position = Vector2(16.0, 292.0)
	p1_panel.size = Vector2(180.0, 76.0)
	p1_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(p1_panel)

	# Banner amarillo con nombre
	var p1_name_banner := Control.new()
	p1_name_banner.size = Vector2(175.0, 26.0)
	p1_panel.add_child(p1_name_banner)
	p1_name_banner.draw.connect(func():
		_draw_slanted_banner(p1_name_banner, 175.0, 26.0, color_stripe_yellow, color_stripe_black, 3.0)
	)

	_p1_name_label = Label.new()
	_p1_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p1_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p1_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p1_name_label.add_theme_font_size_override("font_size", 16)
	_p1_name_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		_p1_name_label.add_theme_font_override("font", _italic_font)
	p1_name_banner.add_child(_p1_name_label)

	# Barras de stats
	_p1_stat_bars["health"] = _create_stat_row(p1_panel, Vector2(6.0, 32.0), "Vida")
	_p1_stat_bars["speed"]  = _create_stat_row(p1_panel, Vector2(6.0, 46.0), "Vel.")
	_p1_stat_bars["damage"] = _create_stat_row(p1_panel, Vector2(6.0, 60.0), "Daño")

	# --- JUGADOR 2 (Derecha) ---
	var p2_panel := Control.new()
	p2_panel.name = "P2_StatsPanel"
	p2_panel.position = Vector2(484.0, 292.0)
	p2_panel.size = Vector2(180.0, 76.0)
	p2_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(p2_panel)

	# Banner amarillo con nombre
	var p2_name_banner := Control.new()
	p2_name_banner.size = Vector2(175.0, 26.0)
	p2_panel.add_child(p2_name_banner)
	p2_name_banner.draw.connect(func():
		_draw_slanted_banner(p2_name_banner, 175.0, 26.0, color_stripe_yellow, color_stripe_black, 3.0)
	)

	_p2_name_label = Label.new()
	_p2_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_p2_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_p2_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_p2_name_label.add_theme_font_size_override("font_size", 16)
	_p2_name_label.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		_p2_name_label.add_theme_font_override("font", _italic_font)
	p2_name_banner.add_child(_p2_name_label)

	# Barras de stats
	_p2_stat_bars["health"] = _create_stat_row(p2_panel, Vector2(6.0, 32.0), "Vida")
	_p2_stat_bars["speed"]  = _create_stat_row(p2_panel, Vector2(6.0, 46.0), "Vel.")
	_p2_stat_bars["damage"] = _create_stat_row(p2_panel, Vector2(6.0, 60.0), "Daño")

func _draw_slanted_banner(c: Control, w: float, h: float, fill_col: Color, border_col: Color, border_w: float) -> void:
	var pts := PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w - 10.0, h),
		Vector2(0.0, h)
	])
	c.draw_colored_polygon(pts, fill_col)
	var outline := PackedVector2Array([
		Vector2(10.0, 0.0),
		Vector2(w, 0.0),
		Vector2(w - 10.0, h),
		Vector2(0.0, h),
		Vector2(10.0, 0.0)
	])
	c.draw_polyline(outline, border_col, border_w)

func _create_stat_row(parent: Control, pos: Vector2, title: String) -> Control:
	var row := Control.new()
	row.position = pos
	row.size = Vector2(170.0, 12.0)
	parent.add_child(row)

	var lbl := Label.new()
	lbl.text = title
	lbl.position = Vector2(0.0, -2.0)
	lbl.size = Vector2(36.0, 14.0)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	lbl.add_theme_constant_override("outline_size", 2)
	lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		lbl.add_theme_font_override("font", _italic_font)
	row.add_child(lbl)

	# Barra de stat (marco negro, relleno amarillo plano)
	var bar_canvas := Control.new()
	bar_canvas.name = "BarCanvas"
	bar_canvas.position = Vector2(40.0, 1.0)
	bar_canvas.size = Vector2(125.0, 9.0)
	row.add_child(bar_canvas)

	# Se guarda el ratio (0.0 a 1.0) en metadata
	bar_canvas.set_meta("ratio", 0.5)
	bar_canvas.draw.connect(func():
		var bw: float = 125.0
		var bh: float = 8.0
		var r: float = clampf(bar_canvas.get_meta("ratio", 0.5), 0.0, 1.0)
		# Fondo oscuro
		bar_canvas.draw_rect(Rect2(0, 0, bw, bh), color_stripe_black)
		# Relleno amarillo plano sin degradados
		if r > 0.0:
			bar_canvas.draw_rect(Rect2(1, 1, (bw - 2.0) * r, bh - 2.0), color_stripe_yellow)
	)

	return bar_canvas

func _set_stat_bar(bar_canvas: Control, ratio: float) -> void:
	if not is_instance_valid(bar_canvas):
		return
	bar_canvas.set_meta("ratio", ratio)
	bar_canvas.queue_redraw()

# ---------------------------------------------------------------------------
# CAPA 5: Cuadrícula Central de Retratos (4 Columnas) y Cursores
# ---------------------------------------------------------------------------
func _build_layer_5_grid() -> void:
	_grid_container = Control.new()
	_grid_container.name = "Layer5_GridContainer"
	_grid_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(_grid_container)

	_slots.clear()

	# 1. Definir lista de casillas
	# Cantidad de casillas: mínimo 3 filas x 4 columnas (12) si show_empty_slots está activo
	var char_count := _characters.size()
	var total_slots: int = 0
	if show_empty_slots:
		total_slots = maxi(grid_min_rows * grid_columns, int(ceil((char_count + 1) / float(grid_columns))) * grid_columns)
	else:
		total_slots = char_count + 1

	var grid_w: float = grid_columns * slot_size + (grid_columns - 1) * slot_gap
	var start_x: float = (BASE_W - grid_w) / 2.0
	var start_y: float = 72.0

	for i in range(total_slots):
		var col: int = i % grid_columns
		var row: int = i / grid_columns
		var slot_pos := Vector2(start_x + col * (slot_size + slot_gap), start_y + row * (slot_size + slot_gap))

		var slot_ctrl := Control.new()
		slot_ctrl.name = "Slot_%d" % i
		slot_ctrl.position = slot_pos
		slot_ctrl.size = Vector2(slot_size, slot_size)
		_grid_container.add_child(slot_ctrl)

		var slot_type := "empty"
		var char_data: CharacterData = null

		if i < char_count:
			slot_type = "char"
			char_data = _characters[i]
		elif i == total_slots - 1:
			slot_type = "random"

		var slot_info := {
			"index": i,
			"type": slot_type,
			"data": char_data,
			"pos": slot_pos,
			"control": slot_ctrl
		}
		_slots.append(slot_info)

		# Dibujar el contenido visual del slot
		_setup_slot_visuals(slot_info)

	# 2. Dibujado de Cursores P1 y P2 sobre la cuadrícula
	_p1_cursor_draw = Control.new()
	_p1_cursor_draw.name = "P1_Cursor"
	_p1_cursor_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(_p1_cursor_draw)
	_p1_cursor_draw.draw.connect(_on_draw_p1_cursor)

	_p2_cursor_draw = Control.new()
	_p2_cursor_draw.name = "P2_Cursor"
	_p2_cursor_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grid_container.add_child(_p2_cursor_draw)
	_p2_cursor_draw.draw.connect(_on_draw_p2_cursor)

func _setup_slot_visuals(slot_info: Dictionary) -> void:
	var ctrl: Control = slot_info["control"]
	var type: String = slot_info["type"]
	var char_data: CharacterData = slot_info["data"]

	ctrl.draw.connect(func():
		var s := slot_size
		# Fondo de la casilla
		var bg_col := color_slot_bg if type != "empty" else color_empty_slot
		ctrl.draw_rect(Rect2(0, 0, s, s), bg_col)

		# Marco negro de 3 px
		ctrl.draw_rect(Rect2(0, 0, s, s), color_stripe_black, false, slot_border_width)

		# Si es Aleatorio: signo "?"
		if type == "random":
			var font: Font = _italic_font if _italic_font else ThemeDB.fallback_font
			ctrl.draw_string(font, Vector2(13, 28), "?", HORIZONTAL_ALIGNMENT_CENTER, -1, 24, color_stripe_yellow)
	)

	# Si es personaje, colocar su sprite / retrato enmarcado en el centro
	if type == "char" and char_data:
		ctrl.clip_contents = true
		var face_sprite := AnimatedSprite2D.new()
		face_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		face_sprite.centered = true
		face_sprite.position = Vector2(slot_size / 2.0, slot_size / 2.0 + 6.0)
		face_sprite.scale = Vector2(0.95, 0.95)
		var frames := _get_character_frames(char_data.id)
		if frames:
			face_sprite.sprite_frames = frames
			face_sprite.play("idle")
		ctrl.add_child(face_sprite)

func _on_draw_p1_cursor() -> void:
	if _p1_index < 0 or _p1_index >= _slots.size():
		return
	var slot_pos: Vector2 = _slots[_p1_index]["pos"]
	var s := slot_size

	# Si P1 y P2 están en la misma casilla: P1 es el marco exterior de 3 px
	if _p1_index == _p2_index:
		_p1_cursor_draw.draw_rect(Rect2(slot_pos.x - 2.0, slot_pos.y - 2.0, s + 4.0, s + 4.0), color_p1_cursor, false, 3.0)
	else:
		_p1_cursor_draw.draw_rect(Rect2(slot_pos.x - 1.0, slot_pos.y - 1.0, s + 2.0, s + 2.0), color_p1_cursor, false, 3.0)

func _on_draw_p2_cursor() -> void:
	if _p2_index < 0 or _p2_index >= _slots.size():
		return
	var slot_pos: Vector2 = _slots[_p2_index]["pos"]
	var s := slot_size

	# Si P1 y P2 están en la misma casilla: P2 es el marco interior de 2.5 px
	if _p1_index == _p2_index:
		_p2_cursor_draw.draw_rect(Rect2(slot_pos.x + 2.0, slot_pos.y + 2.0, s - 4.0, s - 4.0), color_p2_cursor, false, 2.5)
	else:
		_p2_cursor_draw.draw_rect(Rect2(slot_pos.x - 1.0, slot_pos.y - 1.0, s + 2.0, s + 2.0), color_p2_cursor, false, 3.0)

# ---------------------------------------------------------------------------
# CAPA 6: Etiquetas de Estado ("J1 eligiendo" / "J2 listo")
# ---------------------------------------------------------------------------
func _build_layer_6_status_badges() -> void:
	var status_container := Control.new()
	status_container.name = "Layer6_StatusBadges"
	status_container.position = Vector2(245.0, 222.0)
	status_container.size = Vector2(190.0, 26.0)
	status_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(status_container)

	# Badge J1
	_badge_j1 = PanelContainer.new()
	_badge_j1.position = Vector2(0.0, 0.0)
	_badge_j1.size = Vector2(90.0, 24.0)
	status_container.add_child(_badge_j1)

	_lbl_j1_status = Label.new()
	_lbl_j1_status.text = "J1 eligiendo"
	_lbl_j1_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_j1_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_j1_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lbl_j1_status.add_theme_font_size_override("font_size", 12)
	if _italic_font:
		_lbl_j1_status.add_theme_font_override("font", _italic_font)
	_badge_j1.add_child(_lbl_j1_status)

	# Badge J2
	_badge_j2 = PanelContainer.new()
	_badge_j2.position = Vector2(100.0, 0.0)
	_badge_j2.size = Vector2(90.0, 24.0)
	status_container.add_child(_badge_j2)

	_lbl_j2_status = Label.new()
	_lbl_j2_status.text = "J2 eligiendo"
	_lbl_j2_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_j2_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_j2_status.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lbl_j2_status.add_theme_font_size_override("font_size", 12)
	if _italic_font:
		_lbl_j2_status.add_theme_font_override("font", _italic_font)
	_badge_j2.add_child(_lbl_j2_status)

	_update_badges_appearance()

func _update_badges_appearance() -> void:
	# J1 Badge
	var b1 := StyleBoxFlat.new()
	b1.set_corner_radius_all(0) # Sin esquinas redondeadas (estilo manga plano)
	if _p1_ready:
		b1.bg_color = color_stripe_black
		b1.border_color = color_stripe_yellow
		b1.set_border_width_all(2)
		_lbl_j1_status.text = "J1 listo"
		_lbl_j1_status.add_theme_color_override("font_color", color_stripe_yellow)
	else:
		b1.bg_color = color_stripe_yellow
		b1.border_color = color_stripe_black
		b1.set_border_width_all(1)
		_lbl_j1_status.text = "J1 eligiendo"
		_lbl_j1_status.add_theme_color_override("font_color", color_stripe_black)
	_badge_j1.add_theme_stylebox_override("panel", b1)

	# J2 / IA Badge
	var b2 := StyleBoxFlat.new()
	b2.set_corner_radius_all(0)
	if _vs_ai_mode:
		if _p2_ready:
			b2.bg_color = color_stripe_yellow
			b2.border_color = color_stripe_black
			b2.set_border_width_all(2)
			_lbl_j2_status.text = "IA lista"
			_lbl_j2_status.add_theme_color_override("font_color", color_stripe_black)
		else:
			b2.bg_color = color_stripe_black
			b2.border_color = color_stripe_yellow
			b2.set_border_width_all(2)
			_lbl_j2_status.text = "IA eligiendo"
			_lbl_j2_status.add_theme_color_override("font_color", color_stripe_yellow)
	else:
		if _p2_ready:
			b2.bg_color = Color(1.0, 1.0, 1.0)
			b2.border_color = color_stripe_black
			b2.set_border_width_all(1)
			_lbl_j2_status.text = "J2 listo"
			_lbl_j2_status.add_theme_color_override("font_color", color_stripe_black)
		else:
			b2.bg_color = color_stripe_black
			b2.border_color = Color(1.0, 1.0, 1.0)
			b2.set_border_width_all(2)
			_lbl_j2_status.text = "J2 eligiendo"
			_lbl_j2_status.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_badge_j2.add_theme_stylebox_override("panel", b2)

# ---------------------------------------------------------------------------
# Botón Selector de Modo de Oponente (VS Jugador / VS IA)
# ---------------------------------------------------------------------------
func _build_layer_mode_toggle() -> void:
	var mode_container := Control.new()
	mode_container.name = "Layer_ModeToggle"
	mode_container.position = Vector2(230.0, 252.0)
	mode_container.size = Vector2(220.0, 36.0)
	_content.add_child(mode_container)

	_btn_mode_toggle = Button.new()
	_btn_mode_toggle.size = Vector2(220.0, 24.0)
	_btn_mode_toggle.position = Vector2(0.0, 0.0)
	_btn_mode_toggle.focus_mode = Control.FOCUS_NONE
	_btn_mode_toggle.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_btn_mode_toggle.pressed.connect(_toggle_vs_ai_mode)
	if _italic_font:
		_btn_mode_toggle.add_theme_font_override("font", _italic_font)
	_btn_mode_toggle.add_theme_font_size_override("font_size", 12)
	mode_container.add_child(_btn_mode_toggle)

	_lbl_mode_hint = Label.new()
	_lbl_mode_hint.text = "[ Tab o Clic para alternar ]"
	_lbl_mode_hint.position = Vector2(0.0, 25.0)
	_lbl_mode_hint.size = Vector2(220.0, 12.0)
	_lbl_mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_mode_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lbl_mode_hint.add_theme_font_size_override("font_size", 9)
	_lbl_mode_hint.add_theme_color_override("font_color", Color("#B8B0C8"))
	if _italic_font:
		_lbl_mode_hint.add_theme_font_override("font", _italic_font)
	mode_container.add_child(_lbl_mode_hint)

	_update_mode_button_visuals()

func _toggle_vs_ai_mode() -> void:
	if _match_starting:
		return
	_vs_ai_mode = not _vs_ai_mode
	_play_sfx(_sfx_move)
	_update_mode_button_visuals()
	_update_badges_appearance()

func _update_mode_button_visuals() -> void:
	if not _btn_mode_toggle:
		return
	var sb := StyleBoxFlat.new()
	sb.set_corner_radius_all(0)
	sb.set_border_width_all(2)

	if _vs_ai_mode:
		sb.bg_color = color_stripe_yellow
		sb.border_color = color_stripe_black
		_btn_mode_toggle.text = "🤖 LUCHAR CONTRA IA"
		_btn_mode_toggle.add_theme_color_override("font_color", color_stripe_black)
		_btn_mode_toggle.add_theme_color_override("font_hover_color", color_stripe_black)
	else:
		sb.bg_color = color_stripe_black
		sb.border_color = Color.WHITE
		_btn_mode_toggle.text = "👥 VS OTRO JUGADOR"
		_btn_mode_toggle.add_theme_color_override("font_color", Color.WHITE)
		_btn_mode_toggle.add_theme_color_override("font_hover_color", color_stripe_yellow)

	_btn_mode_toggle.add_theme_stylebox_override("normal", sb)
	_btn_mode_toggle.add_theme_stylebox_override("hover", sb)
	_btn_mode_toggle.add_theme_stylebox_override("pressed", sb)
	_btn_mode_toggle.add_theme_stylebox_override("focus", sb)

# ---------------------------------------------------------------------------
# CAPA 7: Barra Inferior Negra con Controles Leídos de InputMap
# ---------------------------------------------------------------------------
func _build_layer_7_bottom_bar() -> void:
	var bar_h: float = 28.0
	var bar := Control.new()
	bar.name = "Layer7_BottomBar"
	bar.position = Vector2(0.0, BASE_H - bar_h)
	bar.size = Vector2(BASE_W, bar_h)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(bar)

	var bg_rect := ColorRect.new()
	bg_rect.color = color_stripe_black
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.add_child(bg_rect)

	# Leer teclas de InputMap para P1 y P2
	var p1_key_action := _get_key_for_action("p1_attack", "F")
	var p2_key_action := _get_key_for_action("p2_attack", "K")

	# Contenedor P1 (Izquierda)
	var hbox_p1 := HBoxContainer.new()
	hbox_p1.position = Vector2(16.0, 4.0)
	hbox_p1.add_theme_constant_override("separation", 6)
	bar.add_child(hbox_p1)

	var p1_badge := PanelContainer.new()
	var b1 := StyleBoxFlat.new()
	b1.bg_color = color_stripe_yellow
	b1.set_corner_radius_all(0)
	b1.content_margin_left = 6
	b1.content_margin_right = 6
	p1_badge.add_theme_stylebox_override("panel", b1)
	hbox_p1.add_child(p1_badge)

	var p1_badge_lbl := Label.new()
	p1_badge_lbl.text = "J1"
	p1_badge_lbl.add_theme_font_size_override("font_size", 11)
	p1_badge_lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		p1_badge_lbl.add_theme_font_override("font", _italic_font)
	p1_badge.add_child(p1_badge_lbl)

	var p1_text := Label.new()
	p1_text.text = "WASD Mover · %s Elegir" % p1_key_action
	p1_text.add_theme_font_size_override("font_size", 11)
	p1_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if _italic_font:
		p1_text.add_theme_font_override("font", _italic_font)
	hbox_p1.add_child(p1_text)

	# Centro: Esc Volver
	var lbl_center := Label.new()
	lbl_center.text = "Esc Volver"
	lbl_center.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_center.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl_center.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl_center.add_theme_font_size_override("font_size", 11)
	lbl_center.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75))
	if _italic_font:
		lbl_center.add_theme_font_override("font", _italic_font)
	bar.add_child(lbl_center)

	# Contenedor P2 (Derecha)
	var hbox_p2 := HBoxContainer.new()
	hbox_p2.position = Vector2(BASE_W - 225.0, 4.0)
	hbox_p2.add_theme_constant_override("separation", 6)
	bar.add_child(hbox_p2)

	var p2_badge := PanelContainer.new()
	var b2 := StyleBoxFlat.new()
	b2.bg_color = Color(1.0, 1.0, 1.0)
	b2.set_corner_radius_all(0)
	b2.content_margin_left = 6
	b2.content_margin_right = 6
	p2_badge.add_theme_stylebox_override("panel", b2)
	hbox_p2.add_child(p2_badge)

	var p2_badge_lbl := Label.new()
	p2_badge_lbl.text = "J2"
	p2_badge_lbl.add_theme_font_size_override("font_size", 11)
	p2_badge_lbl.add_theme_color_override("font_color", Color(0.08, 0.08, 0.08))
	if _italic_font:
		p2_badge_lbl.add_theme_font_override("font", _italic_font)
	p2_badge.add_child(p2_badge_lbl)

	var p2_text := Label.new()
	p2_text.text = "Flechas Mover · %s Elegir" % p2_key_action
	p2_text.add_theme_font_size_override("font_size", 11)
	p2_text.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	if _italic_font:
		p2_text.add_theme_font_override("font", _italic_font)
	hbox_p2.add_child(p2_text)

func _get_key_for_action(action: String, fallback: String) -> String:
	if not InputMap.has_action(action):
		return fallback
	var evs := InputMap.action_get_events(action)
	for ev in evs:
		if ev is InputEventKey:
			var code: Key = ev.physical_keycode if ev.physical_keycode != KEY_NONE else ev.keycode
			var name_str := OS.get_keycode_string(code)
			if name_str != "":
				return name_str
	return fallback

# ---------------------------------------------------------------------------
# Entrada por Teclado (Navegación y Confirmación Independiente P1 y P2)
# ---------------------------------------------------------------------------
func _unhandled_input(event: InputEvent) -> void:
	if _match_starting:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var vp := get_viewport()

		# Volver al menú con Escape
		if event.is_action_pressed("ui_cancel") or event.keycode == KEY_ESCAPE:
			if vp: vp.set_input_as_handled()
			_on_back_pressed()
			return

		# Alternar modo VS IA / VS Jugador con Tab
		if event.keycode == KEY_TAB:
			if vp: vp.set_input_as_handled()
			_toggle_vs_ai_mode()
			return

		# --- NAVEGACIÓN Y CONFIRMACIÓN JUGADOR 1 (WASD / F / Enter) ---
		if not _p1_ready:
			if event.keycode == KEY_A or event.is_action_pressed("p1_left"):
				if vp: vp.set_input_as_handled()
				_navigate_player(1, -1, 0)
			elif event.keycode == KEY_D or event.is_action_pressed("p1_right"):
				if vp: vp.set_input_as_handled()
				_navigate_player(1, 1, 0)
			elif event.keycode == KEY_W or event.is_action_pressed("p1_jump"):
				if vp: vp.set_input_as_handled()
				_navigate_player(1, 0, -1)
			elif event.keycode == KEY_S or event.is_action_pressed("p1_block"):
				if vp: vp.set_input_as_handled()
				_navigate_player(1, 0, 1)
			elif event.keycode == KEY_F or event.is_action_pressed("p1_attack") or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
				if vp: vp.set_input_as_handled()
				_confirm_player(1)
		else:
			# Desconfirmar P1 (S, Bloqueo o Backspace)
			if event.keycode == KEY_S or event.is_action_pressed("p1_block") or event.keycode == KEY_BACKSPACE:
				if vp: vp.set_input_as_handled()
				_cancel_player(1)

		# --- NAVEGACIÓN Y CONFIRMACIÓN JUGADOR 2 (Flechas / K / Numpad 1) ---
		if not _p2_ready:
			if event.keycode == KEY_LEFT or event.is_action_pressed("p2_left"):
				if vp: vp.set_input_as_handled()
				_navigate_player(2, -1, 0)
			elif event.keycode == KEY_RIGHT or event.is_action_pressed("p2_right"):
				if vp: vp.set_input_as_handled()
				_navigate_player(2, 1, 0)
			elif event.keycode == KEY_UP or event.is_action_pressed("p2_jump"):
				if vp: vp.set_input_as_handled()
				_navigate_player(2, 0, -1)
			elif event.keycode == KEY_DOWN or event.is_action_pressed("p2_block"):
				if vp: vp.set_input_as_handled()
				_navigate_player(2, 0, 1)
			elif event.keycode == KEY_K or event.is_action_pressed("p2_attack") or event.keycode == KEY_KP_1 or event.keycode == KEY_KP_ENTER:
				if vp: vp.set_input_as_handled()
				_confirm_player(2)
		else:
			# Desconfirmar P2 (Flecha Abajo o Bloqueo)
			if event.keycode == KEY_DOWN or event.is_action_pressed("p2_block"):
				if vp: vp.set_input_as_handled()
				_cancel_player(2)

func _navigate_player(pid: int, dir_x: int, dir_y: int) -> void:
	var total_slots := _slots.size()
	if total_slots == 0:
		return

	var current_idx := _p1_index if pid == 1 else _p2_index
	var col := current_idx % grid_columns
	var row := current_idx / grid_columns
	var total_rows := int(ceil(total_slots / float(grid_columns)))

	# Vuelta al otro extremo (wrap-around horizontal y vertical)
	if dir_x != 0:
		col = (col + dir_x + grid_columns) % grid_columns
	if dir_y != 0:
		row = (row + dir_y + total_rows) % total_rows

	var next_idx := row * grid_columns + col
	# Si cae fuera del array, ajustar a la última casilla disponible
	if next_idx >= total_slots:
		next_idx = total_slots - 1

	if pid == 1:
		_p1_index = next_idx
		_update_p1_display()
	else:
		_p2_index = next_idx
		_update_p2_display()

	_play_sfx(_sfx_move)
	_update_cursors_visuals()
	_check_mirror_match_tint()

func _confirm_player(pid: int) -> void:
	var target_slot := _slots[_p1_index] if pid == 1 else _slots[_p2_index]
	if target_slot["type"] == "empty":
		# Casilla vacía: no se puede confirmar
		return

	_play_sfx(_sfx_choose)
	if pid == 1:
		_p1_ready = true
		if _vs_ai_mode and not _p2_ready:
			_p2_ready = true # La IA se confirma automáticamente
	else:
		_p2_ready = true

	_update_badges_appearance()
	_check_both_ready()

func _cancel_player(pid: int) -> void:
	_play_sfx(_sfx_cancel)
	if pid == 1:
		_p1_ready = false
		if _vs_ai_mode:
			_p2_ready = false
	else:
		_p2_ready = false

	_update_badges_appearance()

func _update_cursors_visuals() -> void:
	if _p1_cursor_draw:
		_p1_cursor_draw.queue_redraw()
	if _p2_cursor_draw:
		_p2_cursor_draw.queue_redraw()

# ---------------------------------------------------------------------------
# Actualización Visual de Luchadores y Stats
# ---------------------------------------------------------------------------
func _update_p1_display() -> void:
	if _p1_index < 0 or _p1_index >= _slots.size():
		return
	var slot := _slots[_p1_index]
	var type: String = slot["type"]
	var data: CharacterData = slot["data"]

	if type == "char" and data:
		_p1_sprite.visible = true
		_p1_sprite.modulate = Color.WHITE
		_set_fighter_sprite(_p1_sprite, data.id)
		_p1_sprite.position.y = ground_y - _get_feet_offset(data.id) * character_scale.y
		_p1_name_label.text = data.display_name
		_update_stat_bars(_p1_stat_bars, data)
	elif type == "random":
		_p1_sprite.visible = true
		_p1_sprite.modulate = Color(0.2, 0.2, 0.3, 0.75) # Silueta
		_set_fighter_sprite(_p1_sprite, "goku")
		_p1_sprite.position.y = ground_y - _get_feet_offset("goku") * character_scale.y
		_p1_name_label.text = "Aleatorio"
		_set_stat_bar(_p1_stat_bars["health"], 0.7)
		_set_stat_bar(_p1_stat_bars["speed"], 0.7)
		_set_stat_bar(_p1_stat_bars["damage"], 0.7)
	else:
		_p1_sprite.visible = false
		_p1_name_label.text = "---"
		_set_stat_bar(_p1_stat_bars["health"], 0.0)
		_set_stat_bar(_p1_stat_bars["speed"], 0.0)
		_set_stat_bar(_p1_stat_bars["damage"], 0.0)

	_check_mirror_match_tint()

func _update_p2_display() -> void:
	if _p2_index < 0 or _p2_index >= _slots.size():
		return
	var slot := _slots[_p2_index]
	var type: String = slot["type"]
	var data: CharacterData = slot["data"]

	if type == "char" and data:
		_p2_sprite.visible = true
		_set_fighter_sprite(_p2_sprite, data.id)
		_p2_sprite.position.y = ground_y - _get_feet_offset(data.id) * character_scale.y
		_p2_sprite.flip_h = not p2_facing_front
		_p2_name_label.text = data.display_name
		_update_stat_bars(_p2_stat_bars, data)
	elif type == "random":
		_p2_sprite.visible = true
		_p2_sprite.modulate = Color(0.2, 0.2, 0.3, 0.75)
		_set_fighter_sprite(_p2_sprite, "naruto")
		_p2_sprite.position.y = ground_y - _get_feet_offset("naruto") * character_scale.y
		_p2_sprite.flip_h = not p2_facing_front
		_p2_name_label.text = "Aleatorio"
		_set_stat_bar(_p2_stat_bars["health"], 0.7)
		_set_stat_bar(_p2_stat_bars["speed"], 0.7)
		_set_stat_bar(_p2_stat_bars["damage"], 0.7)
	else:
		_p2_sprite.visible = false
		_p2_name_label.text = "---"
		_set_stat_bar(_p2_stat_bars["health"], 0.0)
		_set_stat_bar(_p2_stat_bars["speed"], 0.0)
		_set_stat_bar(_p2_stat_bars["damage"], 0.0)

	_check_mirror_match_tint()

func _check_mirror_match_tint() -> void:
	# Paleta alternativa en P2 si ambos eligen el mismo personaje
	var s1 := _slots[_p1_index]
	var s2 := _slots[_p2_index]
	if s1["type"] == "char" and s2["type"] == "char" and s1["data"] and s2["data"]:
		if s1["data"].id == s2["data"].id:
			var alt: Color = s2["data"].get("alt_tint") if s2["data"].get("alt_tint") != null else Color(0.7, 0.9, 1.2, 1.0)
			_p2_sprite.modulate = alt
			return

	if s2["type"] == "char":
		_p2_sprite.modulate = Color.WHITE

func _update_stat_bars(bars: Dictionary, data: CharacterData) -> void:
	if not data:
		return
	# Normalización de stats a escala 0.0 - 1.0
	var health_ratio := clampf(data.max_health / 130.0, 0.15, 1.0)
	var speed_ratio  := clampf(data.move_speed / 250.0, 0.15, 1.0)
	var damage_ratio := clampf(data.damage_basic / 12.0, 0.15, 1.0)

	_set_stat_bar(bars["health"], health_ratio)
	_set_stat_bar(bars["speed"], speed_ratio)
	_set_stat_bar(bars["damage"], damage_ratio)

func _set_fighter_sprite(sprite: AnimatedSprite2D, char_id: String) -> void:
	var frames := _get_character_frames(char_id)
	if frames and sprite:
		sprite.sprite_frames = frames
		if frames.has_animation("idle"):
			sprite.play("idle")
		elif frames.get_animation_names().size() > 0:
			sprite.play(frames.get_animation_names()[0])

func _get_character_frames(char_id: String) -> SpriteFrames:
	if _character_frames_cache.has(char_id):
		return _character_frames_cache[char_id]

	# 1. Intentar cargar desde sprite_dir_select de CharacterData
	var char_data := _find_character_data(char_id)
	if char_data and "sprite_dir_select" in char_data and char_data.sprite_dir_select != "":
		var sf_custom := _build_frames_from_directory(char_data.sprite_dir_select, 5.0)
		if sf_custom:
			_character_frames_cache[char_id] = sf_custom
			return sf_custom

	# 2. Intentar carpeta estándar de selección res://assets/sprites/{char_id}/select_idle
	var default_select_dir := "res://assets/sprites/%s/select_idle" % char_id
	var sf_default := _build_frames_from_directory(default_select_dir, 5.0)
	if sf_default:
		_character_frames_cache[char_id] = sf_default
		return sf_default

	# 3. Fallback: cargar del PackedScene de combate
	var scene_path := "res://resources/characters/%s.tscn" % char_id
	if not ResourceLoader.exists(scene_path):
		scene_path = "res://scenes/characters/%s.tscn" % char_id

	if ResourceLoader.exists(scene_path):
		var scn := (load(scene_path) as PackedScene).instantiate()
		var sp: AnimatedSprite2D = scn.get_node_or_null("AnimatedSprite2D")
		if sp and sp.sprite_frames:
			_character_frames_cache[char_id] = sp.sprite_frames.duplicate()
		scn.queue_free()

	return _character_frames_cache.get(char_id, null)

func _find_character_data(char_id: String) -> CharacterData:
	for c in _characters:
		if c and c.id == char_id:
			return c
	return null

func _get_feet_offset(char_id: String) -> float:
	match char_id:
		"goku":
			return 23.0
		"naruto":
			return 21.0
		"madara":
			return 23.0
		_:
			return feet_y_offset

func _build_frames_from_directory(dir_path: String, fps: float = 5.0) -> SpriteFrames:
	var png_files: Array[String] = []
	var global_dir := ProjectSettings.globalize_path(dir_path)

	# 1. Intentar con res://
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png") and not file_name.ends_with(".import"):
				png_files.append(dir_path.path_join(file_name))
			file_name = dir.get_next()
		dir.list_dir_end()

	# 2. Si no encontró (archivos aún no indexados por Godot), usar ruta global absoluta
	if png_files.is_empty() and DirAccess.dir_exists_absolute(global_dir):
		var d_abs := DirAccess.open(global_dir)
		if d_abs:
			d_abs.list_dir_begin()
			var fn := d_abs.get_next()
			while fn != "":
				if not d_abs.current_is_dir() and fn.ends_with(".png") and not fn.ends_with(".import"):
					png_files.append(global_dir.path_join(fn))
				fn = d_abs.get_next()
			d_abs.list_dir_end()

	if png_files.is_empty():
		return null

	png_files.sort()
	var sf := SpriteFrames.new()
	sf.add_animation("idle")
	sf.set_animation_speed("idle", fps)
	sf.set_animation_loop("idle", true)

	for p in png_files:
		var tex: Texture2D = null
		if p.begins_with("res://") and ResourceLoader.exists(p):
			var r = load(p)
			if r is Texture2D:
				tex = r
		if not tex:
			var img := Image.new()
			var abs_path := ProjectSettings.globalize_path(p) if p.begins_with("res://") else p
			if img.load(abs_path) == OK:
				tex = ImageTexture.create_from_image(img)
		if tex:
			sf.add_frame("idle", tex)

	return sf if sf.get_frame_count("idle") > 0 else null

# ---------------------------------------------------------------------------
# Fin de Selección y Transición a Combate
# ---------------------------------------------------------------------------
func _check_both_ready() -> void:
	if _p1_ready and _p2_ready and not _match_starting:
		_match_starting = true
		_play_sfx(_sfx_start)

		# Resolver personaje final (manejando casilla Aleatorio)
		var p1_final := _resolve_final_character(_p1_index)
		var p2_final := _resolve_final_character(_p2_index)

		# Guardar en GameData
		var gdata = get_node_or_null("/root/GameData")
		if gdata:
			gdata.player1_data = p1_final
			gdata.player2_data = p2_final
			if _vs_ai_mode:
				gdata.current_mode = gdata.GameMode.VS_AI
				print("[Selección] 🤖 Modo guardado: VS_AI. P1: %s vs IA: %s" % [p1_final.display_name, p2_final.display_name])
			else:
				gdata.current_mode = gdata.GameMode.LOCAL
				print("[Selección] 👥 Modo guardado: LOCAL (2 Jugadores). P1: %s vs P2: %s" % [p1_final.display_name, p2_final.display_name])

		emit_signal("characters_confirmed", p1_final, p2_final)

		# Efecto visual de inicio: parpadeo suave y transición
		var tw := create_tween()
		tw.tween_interval(0.7)
		tw.tween_callback(func():
			var target_scene := combat_scene_path
			var factory = get_node_or_null("/root/CharacterFactory")
			if gdata and factory and factory.has_method("get_map_scene_path"):
				target_scene = factory.get_map_scene_path(gdata.selected_map_id)
			elif not ResourceLoader.exists(target_scene) and ResourceLoader.exists("res://scenes/maps/valle_del_fin.tscn"):
				target_scene = "res://scenes/maps/valle_del_fin.tscn"
			elif not ResourceLoader.exists(target_scene) and ResourceLoader.exists("res://scenes/maps/test_map.tscn"):
				target_scene = "res://scenes/maps/test_map.tscn"
			if ResourceLoader.exists(target_scene):
				get_tree().change_scene_to_file(target_scene)
			else:
				push_error("CharacterSelect: No se encontró la escena '%s'." % target_scene)
		)

func _resolve_final_character(slot_idx: int) -> CharacterData:
	var slot := _slots[slot_idx]
	if slot["type"] == "char" and slot["data"]:
		return slot["data"]
	elif slot["type"] == "random" and _characters.size() > 0:
		# Elegir personaje desbloqueado al azar
		var gdata = get_node_or_null("/root/GameData")
		var pool: Array[CharacterData] = []
		for c in _characters:
			if not gdata or gdata.is_character_unlocked(c.id):
				pool.append(c)
		if pool.is_empty():
			pool = _characters
		return pool[randi() % pool.size()]

	# Fallback a Goku
	return _characters[0] if _characters.size() > 0 else null

func _on_back_pressed() -> void:
	_play_sfx(_sfx_cancel)
	emit_signal("back_to_menu_requested")
	if ResourceLoader.exists(main_menu_scene_path):
		get_tree().change_scene_to_file(main_menu_scene_path)
	else:
		push_error("CharacterSelect: no se encontró la escena de menú '%s'." % main_menu_scene_path)

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

	_sfx_cancel = AudioStreamPlayer.new()
	_sfx_cancel.name = "SFX_Cancel"
	add_child(_sfx_cancel)

	_sfx_start = AudioStreamPlayer.new()
	_sfx_start.name = "SFX_Start"
	add_child(_sfx_start)

	if ResourceLoader.exists("res://assets/sounds/sfx/menu_move.wav"):
		_sfx_move.stream = load("res://assets/sounds/sfx/menu_move.wav")
	if ResourceLoader.exists("res://assets/sounds/sfx/menu_select.wav"):
		_sfx_choose.stream = load("res://assets/sounds/sfx/menu_select.wav")
		_sfx_start.stream = load("res://assets/sounds/sfx/menu_select.wav")
	if ResourceLoader.exists("res://assets/sounds/sfx/menu_back.wav"):
		_sfx_cancel.stream = load("res://assets/sounds/sfx/menu_back.wav")

func _play_sfx(player: AudioStreamPlayer) -> void:
	if is_instance_valid(player) and player.stream:
		player.play()

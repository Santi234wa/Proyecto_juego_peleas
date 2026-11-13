## health_bar_ui.gd
## Barra de vida con estela de daño (damage ghost trail), marco oscuro, borde blanco,
## modo espejado para Jugador 2, retrato cuadrado y nombre del personaje.
## Patrón Observer: Se actualiza en tiempo real mediante la señal 'health_changed'.
class_name HealthBarUI
extends ProgressBar

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables desde Inspector)
# ---------------------------------------------------------------------------
@export_group("Vinculación")
@export var character_path: NodePath = NodePath("")
@export var is_player_2: bool = false                ## Si es true, se vacía hacia el lado contrario (espejado)

@export_group("Colores")
@export var health_color: Color = Color(0.18, 0.82, 0.35)           ## Verde: vida actual del luchador
@export var ghost_color: Color = Color(0.95, 0.78, 0.15)            ## Amarillo: estela de daño retardada
@export var frame_bg_color: Color = Color(0.08, 0.08, 0.08, 0.92)    ## Fondo oscuro del marco
@export var frame_border_color: Color = Color(1.0, 1.0, 1.0, 0.85)   ## Borde blanco fino
@export var portrait_bg_color: Color = Color(0.14, 0.14, 0.18, 0.95) ## Fondo del retrato
@export var portrait_border_color: Color = Color(1.0, 1.0, 1.0, 0.8) ## Borde del retrato

@export_group("Tiempos de Animación")
@export var ghost_delay: float = 0.4            ## Pausa antes de que la estela amarilla empiece a descender
@export var ghost_tween_speed: float = 0.45     ## Duración del Tween suave de la estela

@export_group("Dimensiones y Elementos")
@export var border_width: int = 1               ## Grosor del borde blanco fino
@export var corner_radius: int = 2              ## Esquinas ligeramente redondeadas
@export var portrait_size: Vector2 = Vector2(36.0, 36.0) ## Tamaño del retrato cuadrado
@export var name_offset_y: float = 30.0         ## Desplazamiento vertical del nombre debajo de las barras
@export var show_portrait: bool = true          ## Mostrar retrato junto a la barra
@export var show_name: bool = true              ## Mostrar nombre del personaje debajo
@export var auto_spawn_timer: bool = true       ## P1 instancia automáticamente el reloj central si falta

# ---------------------------------------------------------------------------
# Nodos Hijos Creados por Código
# ---------------------------------------------------------------------------
var _ghost_bar: ProgressBar = null
var _portrait_panel: Panel = null
var _name_label: Label = null
var _ghost_tween: Tween = null
var _character_node: Node = null

func _ready() -> void:
	min_value = 0.0
	show_percentage = false

	# Conexión con el personaje objetivo
	_connect_to_character()

	# Configuración visual y barras superpuestas
	_setup_styles()
	_build_ghost_bar()

	if show_portrait:
		_build_portrait()

	if show_name:
		_build_name_label()

	# P1 genera el temporizador central si no existe en la escena
	if auto_spawn_timer and not is_player_2:
		call_deferred("_ensure_round_timer")

func bind_character(target: Node) -> void:
	if not target:
		return
	_character_node = target
	character_path = target.get_path()
	if target.get("player_id") == 2:
		is_player_2 = true

	if _character_node.has_signal("health_changed") and not _character_node.health_changed.is_connected(_on_health_changed):
		_character_node.health_changed.connect(_on_health_changed)

	max_value = _character_node.data.max_health if (_character_node.get("data") and _character_node.data) else 100.0
	value = _character_node.get("current_health") if _character_node.get("current_health") != null else max_value

	if _ghost_bar:
		_ghost_bar.max_value = max_value
		_ghost_bar.value = value
		_ghost_bar.fill_mode = ProgressBar.FILL_END_TO_BEGIN if is_player_2 else ProgressBar.FILL_BEGIN_TO_END

	fill_mode = ProgressBar.FILL_END_TO_BEGIN if is_player_2 else ProgressBar.FILL_BEGIN_TO_END

	# Actualizar inicial en retrato
	if _portrait_panel:
		var py: float = (size.y - portrait_size.y) / 2.0
		if is_player_2:
			_portrait_panel.position = Vector2(size.x + 8.0, py)
		else:
			_portrait_panel.position = Vector2(-portrait_size.x - 8.0, py)

		var lbl: Label = null
		for c in _portrait_panel.get_children():
			if c is Label:
				lbl = c
				break
		if lbl:
			var dname: String = _character_node.data.display_name if (_character_node.get("data") and _character_node.data) else _character_node.name
			lbl.text = dname.substr(0, 1).to_upper() if dname.length() > 0 else "?"
			lbl.modulate = Color(1.0, 0.9, 0.3) if not is_player_2 else Color(1.0, 0.55, 0.2)

	# Actualizar nombre
	if _name_label:
		var dname: String = _character_node.data.display_name if (_character_node.get("data") and _character_node.data) else _character_node.name
		_name_label.text = dname.to_upper()
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_player_2 else HORIZONTAL_ALIGNMENT_LEFT

func _connect_to_character() -> void:
	if character_path.is_empty():
		return

	_character_node = get_node_or_null(character_path)
	if not _character_node:
		push_error("HealthBarUI: No se encontró nodo en character_path '%s'." % character_path)
		return

	# Autodetectar si es Player 2 por su propiedad player_id si no se forzó en el inspector
	if not is_player_2 and _character_node.get("player_id") == 2:
		is_player_2 = true

	if not _character_node.has_signal("health_changed"):
		push_error("HealthBarUI: El nodo en character_path no tiene la señal 'health_changed'.")
		return

	max_value = _character_node.data.max_health if (_character_node.get("data") and _character_node.data) else 100.0
	value = _character_node.get("current_health") if _character_node.get("current_health") != null else max_value

	_character_node.health_changed.connect(_on_health_changed)

func _setup_styles() -> void:
	# Orientación: P1 se vacía hacia la izquierda; P2 se vacía hacia la derecha (espejada)
	fill_mode = ProgressBar.FILL_END_TO_BEGIN if is_player_2 else ProgressBar.FILL_BEGIN_TO_END

	# Fondo transparente en la barra delantera (el marco lo dibuja la barra fantasma de fondo)
	var empty_bg := StyleBoxEmpty.new()
	add_theme_stylebox_override("background", empty_bg)

	# Relleno verde de vida actual
	var front_fill := StyleBoxFlat.new()
	front_fill.bg_color = health_color
	front_fill.set_corner_radius_all(corner_radius)
	add_theme_stylebox_override("fill", front_fill)

func _build_ghost_bar() -> void:
	_ghost_bar = ProgressBar.new()
	_ghost_bar.name = "GhostDamageBar"
	_ghost_bar.show_percentage = false
	_ghost_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ghost_bar.fill_mode = fill_mode
	_ghost_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ghost_bar.show_behind_parent = true
	_ghost_bar.min_value = 0.0
	_ghost_bar.max_value = max_value
	_ghost_bar.value = value

	# Marco oscuro con borde blanco fino de fondo
	var frame_box := StyleBoxFlat.new()
	frame_box.bg_color = frame_bg_color
	frame_box.border_color = frame_border_color
	frame_box.set_border_width_all(border_width)
	frame_box.set_corner_radius_all(corner_radius)
	_ghost_bar.add_theme_stylebox_override("background", frame_box)

	# Relleno amarillo de la estela de daño
	var ghost_fill := StyleBoxFlat.new()
	ghost_fill.bg_color = ghost_color
	ghost_fill.set_corner_radius_all(corner_radius)
	_ghost_bar.add_theme_stylebox_override("fill", ghost_fill)

	add_child(_ghost_bar)

func _build_portrait() -> void:
	_portrait_panel = Panel.new()
	_portrait_panel.name = "Portrait"
	_portrait_panel.custom_minimum_size = portrait_size
	_portrait_panel.size = portrait_size
	_portrait_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var port_box := StyleBoxFlat.new()
	port_box.bg_color = portrait_bg_color
	port_box.border_color = portrait_border_color
	port_box.set_border_width_all(border_width)
	port_box.set_corner_radius_all(corner_radius)
	_portrait_panel.add_theme_stylebox_override("panel", port_box)

	# Posicionar junto a la barra: P1 a la izquierda, P2 a la derecha
	var py: float = (size.y - portrait_size.y) / 2.0
	if is_player_2:
		_portrait_panel.position = Vector2(size.x + 8.0, py)
	else:
		_portrait_panel.position = Vector2(-portrait_size.x - 8.0, py)

	# Inicial o letra distintiva del personaje en el centro del marco
	var char_initial: String = "?"
	if _character_node:
		var dname: String = _character_node.data.display_name if (_character_node.get("data") and _character_node.data) else _character_node.name
		if dname.length() > 0:
			char_initial = dname.substr(0, 1).to_upper()

	var lbl := Label.new()
	lbl.text = char_initial
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.modulate = Color(1.0, 0.9, 0.3) if not is_player_2 else Color(1.0, 0.55, 0.2)
	_portrait_panel.add_child(lbl)

	add_child(_portrait_panel)

func _build_name_label() -> void:
	_name_label = Label.new()
	_name_label.name = "NameLabel"
	_name_label.size = Vector2(size.x, 16.0)
	_name_label.position = Vector2(0.0, size.y + name_offset_y)
	_name_label.add_theme_font_size_override("font_size", 12)
	_name_label.modulate = Color(0.95, 0.95, 0.95)

	var dname: String = "Luchador"
	if _character_node:
		dname = _character_node.data.display_name if (_character_node.get("data") and _character_node.data) else _character_node.name

	_name_label.text = dname.to_upper()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_player_2 else HORIZONTAL_ALIGNMENT_LEFT
	add_child(_name_label)

func _on_health_changed(current: float, maximum: float) -> void:
	max_value = maximum
	if _ghost_bar:
		_ghost_bar.max_value = maximum

	var previous_val: float = value

	if current < previous_val:
		# Daño recibido: la barra verde baja de inmediato
		value = current

		# La estela amarilla espera ghost_delay y luego baja suavemente con un Tween
		if _ghost_bar:
			if _ghost_tween and _ghost_tween.is_valid():
				_ghost_tween.kill()

			_ghost_tween = create_tween()
			_ghost_tween.tween_interval(ghost_delay)
			_ghost_tween.tween_property(_ghost_bar, "value", current, ghost_tween_speed).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		# Recuperación de vida o reinicio: ambas suben al instante
		value = current
		if _ghost_bar:
			if _ghost_tween and _ghost_tween.is_valid():
				_ghost_tween.kill()
			_ghost_bar.value = current

func _ensure_round_timer() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return
	if parent_node.has_node("RoundTimerUI"):
		return

	var timer_ui := RoundTimerUI.new()
	timer_ui.name = "RoundTimerUI"
	parent_node.add_child(timer_ui)

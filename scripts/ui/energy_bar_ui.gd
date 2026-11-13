## energy_bar_ui.gd
## Barra de Ki / Chakra delgada, con divisiones cada 25%, marcador dinámico de costo
## de transformación leído del Resource, parpadeo suave y aviso de transformación ("H/P · Transformar"),
## y cambio de color a dorado mientras está transformado mostrando el drenaje en tiempo real.
## Patrón Observer: Se actualiza en tiempo real mediante la señal 'energy_changed'.
class_name EnergyBarUI
extends ProgressBar

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables desde Inspector)
# ---------------------------------------------------------------------------
@export_group("Vinculación")
@export var character_path: NodePath = NodePath("")
@export var is_player_2: bool = false                    ## Si es true, la barra se orienta para P2

@export_group("Colores")
@export var base_energy_color: Color = Color(0.18, 0.65, 1.0)       ## Azul brillante Ki estándar
@export var transformed_color: Color = Color(1.0, 0.85, 0.2)       ## Dorado brillante al estar transformado
@export var frame_bg_color: Color = Color(0.08, 0.08, 0.08, 0.88)  ## Fondo oscuro del marco
@export var frame_border_color: Color = Color(0.85, 0.85, 0.85, 0.7) ## Borde fino del marco
@export var divider_color: Color = Color(1.0, 1.0, 1.0, 0.3)        ## Divisores al 25%, 50%, 75%
@export var threshold_marker_color: Color = Color(1.0, 0.9, 0.25)   ## Marcador de Ki mínimo para transformar

@export_group("Dimensiones y Estilo")
@export var bar_height: float = 11.0               ## Más delgada que la barra de vida
@export var border_width: int = 1                  ## Borde fino
@export var corner_radius: int = 2                 ## Radio de esquinas
@export var auto_align_below_health: bool = true   ## Posicionar automáticamente debajo de la barra de vida

@export_group("Avisos de Transformación")
@export var key_hint_p1: String = "H · Transformar"
@export var key_hint_p2: String = "P · Transformar"

# ---------------------------------------------------------------------------
# Estado Interno y Nodos
# ---------------------------------------------------------------------------
var _character_node: Node = null
var _fill_style: StyleBoxFlat = null
var _pulse_tween: Tween = null
var _hint_label: Label = null
var _dividers_container: Control = null
var _threshold_marker: ColorRect = null
var _cost_transform: float = 40.0
var _is_transformed: bool = false

func _ready() -> void:
	min_value = 0.0
	show_percentage = false

	# Conexión con el personaje
	_connect_to_character()

	# Configuración de tamaño y estilo
	_setup_styles()

	# Elementos visuales propios de la barra de Ki
	_build_dividers()
	_build_threshold_marker()
	_build_hint_label()

	# Alinear bajo la barra de vida
	if auto_align_below_health:
		call_deferred("_align_below_health_bar")

func _connect_to_character() -> void:
	if character_path.is_empty():
		push_warning("EnergyBarUI: 'character_path' no asignado en el Inspector.")
		return

	_character_node = get_node_or_null(character_path)
	if not _character_node:
		push_error("EnergyBarUI: No se encontró nodo en character_path '%s'." % character_path)
		return

	# Autodetectar si es Player 2
	if not is_player_2 and _character_node.get("player_id") == 2:
		is_player_2 = true

	# Leer el costo mínimo de transformación directamente desde el CharacterData
	if _character_node.get("data") and _character_node.data:
		_cost_transform = _character_node.data.energy_cost_transform
		max_value = _character_node.data.max_energy
	else:
		_cost_transform = 40.0
		max_value = 100.0

	value = _character_node.get("current_energy") if _character_node.get("current_energy") != null else 0.0

	# Conectar señales Observer
	if _character_node.has_signal("energy_changed"):
		_character_node.energy_changed.connect(_on_energy_changed)

	if _character_node.has_signal("transformation_started"):
		_character_node.transformation_started.connect(_on_transformation_started)

	if _character_node.has_signal("transformation_ended"):
		_character_node.transformation_ended.connect(_on_transformation_ended)

func _setup_styles() -> void:
	# Ajustar altura más delgada que la de vida
	custom_minimum_size = Vector2(size.x, bar_height)
	size = Vector2(size.x, bar_height)

	# Orientación: P1 izquierda a derecha, P2 derecha a izquierda
	fill_mode = ProgressBar.FILL_END_TO_BEGIN if is_player_2 else ProgressBar.FILL_BEGIN_TO_END

	# Marco oscuro con borde fino
	var frame_box := StyleBoxFlat.new()
	frame_box.bg_color = frame_bg_color
	frame_box.border_color = frame_border_color
	frame_box.set_border_width_all(border_width)
	frame_box.set_corner_radius_all(corner_radius)
	add_theme_stylebox_override("background", frame_box)

	# Relleno de energía
	_fill_style = StyleBoxFlat.new()
	_fill_style.bg_color = base_energy_color
	_fill_style.set_corner_radius_all(corner_radius)
	add_theme_stylebox_override("fill", _fill_style)

func _build_dividers() -> void:
	_dividers_container = Control.new()
	_dividers_container.name = "Dividers"
	_dividers_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dividers_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dividers_container)

	# 3 divisiones visibles al 25%, 50% y 75%
	for fraction in [0.25, 0.50, 0.75]:
		var div := ColorRect.new()
		div.mouse_filter = Control.MOUSE_FILTER_IGNORE
		div.color = divider_color
		div.size = Vector2(1.0, bar_height)
		div.position = Vector2(size.x * fraction, 0.0)
		_dividers_container.add_child(div)

func _build_threshold_marker() -> void:
	# Marca visual del nivel de Ki requerido para transformar
	var ratio: float = clampf(_cost_transform / maxf(1.0, max_value), 0.0, 1.0)
	var mark_x: float = size.x * (1.0 - ratio) if is_player_2 else size.x * ratio

	_threshold_marker = ColorRect.new()
	_threshold_marker.name = "TransformMarker"
	_threshold_marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_threshold_marker.color = threshold_marker_color
	_threshold_marker.size = Vector2(2.0, bar_height + 4.0)
	_threshold_marker.position = Vector2(mark_x - 1.0, -2.0)
	add_child(_threshold_marker)

func _build_hint_label() -> void:
	_hint_label = Label.new()
	_hint_label.name = "TransformHint"
	_hint_label.text = key_hint_p2 if is_player_2 else key_hint_p1
	_hint_label.add_theme_font_size_override("font_size", 10)
	_hint_label.modulate = Color(1.0, 0.88, 0.3)
	_hint_label.size = Vector2(100.0, 14.0)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT if is_player_2 else HORIZONTAL_ALIGNMENT_LEFT
	_hint_label.position = Vector2(size.x - 100.0 if is_player_2 else 0.0, bar_height + 3.0)
	_hint_label.visible = false
	add_child(_hint_label)

func _on_energy_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current

	# Verificar si el personaje está actualmente transformado
	if _character_node and _character_node.get("is_transformed") != null:
		_is_transformed = _character_node.is_transformed

	# Mientras está transformado: barra dorada que muestra cómo se drena
	if _is_transformed:
		_set_bar_color(transformed_color)
		_stop_pulse()
		if _hint_label:
			_hint_label.visible = false
		return

	# Si no está transformado y tiene Ki suficiente para transformar:
	if current >= _cost_transform:
		_start_pulse()
		if _hint_label:
			_hint_label.visible = true
	else:
		_stop_pulse()
		_set_bar_color(base_energy_color)
		if _hint_label:
			_hint_label.visible = false

func _on_transformation_started(_tname: String) -> void:
	_is_transformed = true
	_stop_pulse()
	_set_bar_color(transformed_color)
	if _hint_label:
		_hint_label.visible = false

func _on_transformation_ended() -> void:
	_is_transformed = false
	_set_bar_color(base_energy_color)
	if value >= _cost_transform:
		_start_pulse()
		if _hint_label:
			_hint_label.visible = true
	else:
		if _hint_label:
			_hint_label.visible = false

func _set_bar_color(c: Color) -> void:
	if _fill_style:
		_fill_style.bg_color = c

func _start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		return

	_pulse_tween = create_tween().set_loops()
	_pulse_tween.tween_property(self, "modulate", Color(1.35, 1.35, 1.35, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	_pulse_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)

func _stop_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
		_pulse_tween = null
	modulate = Color(1.0, 1.0, 1.0, 1.0)

func _align_below_health_bar() -> void:
	var parent_node := get_parent()
	if not parent_node:
		return

	for child in parent_node.get_children():
		if child is HealthBarUI and child != self and child.get("character_path") == character_path:
			# Encontrada la barra de vida correspondiente: alinear justo debajo
			global_position.x = child.global_position.x
			global_position.y = child.global_position.y + child.size.y + 4.0
			size.x = child.size.x
			custom_minimum_size.x = child.size.x

			# Actualizar divisores y marcador de umbral al nuevo ancho
			_refresh_mark_positions()
			break

func _refresh_mark_positions() -> void:
	if _dividers_container:
		var children = _dividers_container.get_children()
		var fractions := [0.25, 0.50, 0.75]
		for i in mini(children.size(), fractions.size()):
			children[i].position.x = size.x * fractions[i]

	if _threshold_marker:
		var ratio: float = clampf(_cost_transform / maxf(1.0, max_value), 0.0, 1.0)
		var mark_x: float = size.x * (1.0 - ratio) if is_player_2 else size.x * ratio
		_threshold_marker.position.x = mark_x - 1.0

	if _hint_label:
		_hint_label.position.x = size.x - 100.0 if is_player_2 else 0.0

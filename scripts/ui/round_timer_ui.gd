## round_timer_ui.gd
## Temporizador central de ronda, número de ronda y marcadores de victoria.
## Construido completamente por código (nodos Control).
class_name RoundTimerUI
extends Control

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables desde Inspector)
# ---------------------------------------------------------------------------
@export_group("Tiempo de Ronda")
@export var round_time: float = 99.0                ## Tiempo inicial de la ronda en segundos
@export var warning_time: float = 10.0              ## Umbral donde el reloj parpadea en rojo
@export var is_timer_active: bool = true            ## Control de cuenta regresiva

@export_group("Colores")
@export var frame_bg_color: Color = Color(0.08, 0.08, 0.08, 0.9)     ## Fondo oscuro del marco central
@export var frame_border_color: Color = Color(1.0, 1.0, 1.0, 0.85)   ## Borde blanco fino
@export var timer_normal_color: Color = Color(1.0, 1.0, 1.0)         ## Color dígitos normal
@export var timer_warning_color: Color = Color(1.0, 0.22, 0.22)      ## Color dígitos en cuenta regresiva crítica
@export var round_label_color: Color = Color(1.0, 0.85, 0.3)         ## Color texto de la ronda
@export var win_dot_empty_color: Color = Color(0.2, 0.2, 0.2, 0.9)    ## Punto de ronda no ganada
@export var win_dot_won_color: Color = Color(1.0, 0.85, 0.2)          ## Punto dorado de ronda ganada

@export_group("Dimensiones y Estilo")
@export var frame_size: Vector2 = Vector2(76.0, 48.0)  ## Tamaño del marco del reloj
@export var border_width: int = 1                      ## Grosor del marco blanco
@export var corner_radius: int = 3                     ## Redondeo de esquinas
@export var dot_size: Vector2 = Vector2(9.0, 9.0)      ## Tamaño de los puntos de victoria
@export var auto_center_between_bars: bool = true      ## Centrar automáticamente entre barras de P1 y P2

# ---------------------------------------------------------------------------
# Estado Interno
# ---------------------------------------------------------------------------
var _time_remaining: float = 99.0
var _timer_label: Label = null
var _round_label: Label = null
var _p1_dots: Array[ColorRect] = []
var _p2_dots: Array[ColorRect] = []
var _warning_tween: Tween = null

func _ready() -> void:
	_time_remaining = round_time
	_build_ui()
	_update_round_info()
	_update_win_dots()

	# Posicionar automáticamente en el centro de las barras de vida
	if auto_center_between_bars:
		call_deferred("_auto_position")

	# Escuchar cambios de ronda desde GameData si existe
	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_signal("round_ended"):
		game_data.round_ended.connect(_on_round_ended)

func _process(delta: float) -> void:
	if not is_timer_active or _time_remaining <= 0.0:
		return

	_time_remaining = maxf(0.0, _time_remaining - delta)
	if _timer_label:
		_timer_label.text = "%02d" % int(ceil(_time_remaining))

		if _time_remaining <= warning_time and not _warning_tween:
			_start_warning_pulse()
		elif _time_remaining > warning_time and _warning_tween:
			_stop_warning_pulse()

	if _time_remaining <= 0.0:
		_on_time_over()

func _on_time_over() -> void:
	is_timer_active = false
	_stop_warning_pulse()
	print("[Temporizador] ⏰ ¡TIME OVER!")

	var p1_hp: float = 0.0
	var p2_hp: float = 0.0

	var tree := get_tree()
	if tree and tree.current_scene:
		for node in tree.current_scene.find_children("*", "CharacterBase", true, false):
			if node.name.to_lower().begins_with("dummy"):
				continue
			var pid: int = node.get("player_id") if node.get("player_id") != null else 1
			if pid == 1:
				p1_hp = node.get("current_health") if node.get("current_health") != null else 0.0
			elif pid == 2:
				p2_hp = node.get("current_health") if node.get("current_health") != null else 0.0

	var winner_key: String = "player1" if p1_hp >= p2_hp else "player2"
	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("report_round_winner"):
		game_data.report_round_winner(winner_key)

func _build_ui() -> void:
	custom_minimum_size = frame_size
	size = frame_size

	# 1. Marco central oscuro con borde blanco fino
	var frame := Panel.new()
	frame.name = "TimerFrame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var box := StyleBoxFlat.new()
	box.bg_color = frame_bg_color
	box.border_color = frame_border_color
	box.set_border_width_all(border_width)
	box.set_corner_radius_all(corner_radius)
	frame.add_theme_stylebox_override("panel", box)
	add_child(frame)

	# 2. Dígitos del temporizador (99)
	_timer_label = Label.new()
	_timer_label.name = "TimerLabel"
	_timer_label.text = "%02d" % int(round_time)
	_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_timer_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_timer_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_timer_label.add_theme_font_size_override("font_size", 28)
	_timer_label.modulate = timer_normal_color
	frame.add_child(_timer_label)

	# 3. Etiqueta de Ronda debajo del marco ("ROUND 1")
	_round_label = Label.new()
	_round_label.name = "RoundLabel"
	_round_label.text = "ROUND 1"
	_round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_round_label.position = Vector2(0, frame_size.y + 4)
	_round_label.size = Vector2(frame_size.x, 18)
	_round_label.add_theme_font_size_override("font_size", 11)
	_round_label.modulate = round_label_color
	add_child(_round_label)

	# 4. Puntos de victoria para Jugador 1 (a la izquierda del marco)
	var p1_box := HBoxContainer.new()
	p1_box.name = "P1WinDots"
	p1_box.alignment = BoxContainer.ALIGNMENT_END
	p1_box.position = Vector2(-28, (frame_size.y - dot_size.y) / 2.0)
	p1_box.size = Vector2(24, dot_size.y)
	p1_box.add_theme_constant_override("separation", 4)
	add_child(p1_box)

	for i in 2:
		var dot := _create_dot()
		p1_box.add_child(dot)
		_p1_dots.append(dot)

	# 5. Puntos de victoria para Jugador 2 (a la derecha del marco)
	var p2_box := HBoxContainer.new()
	p2_box.name = "P2WinDots"
	p2_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	p2_box.position = Vector2(frame_size.x + 4, (frame_size.y - dot_size.y) / 2.0)
	p2_box.size = Vector2(24, dot_size.y)
	p2_box.add_theme_constant_override("separation", 4)
	add_child(p2_box)

	for i in 2:
		var dot := _create_dot()
		p2_box.add_child(dot)
		_p2_dots.append(dot)

func _create_dot() -> ColorRect:
	var dot := ColorRect.new()
	dot.custom_minimum_size = dot_size
	dot.size = dot_size
	dot.color = win_dot_empty_color
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return dot

func _update_round_info() -> void:
	var game_data = get_node_or_null("/root/GameData")
	var wins_p1: int = 0
	var wins_p2: int = 0
	var target_wins: int = 2

	if game_data:
		var rw = game_data.get("round_wins")
		if rw is Dictionary:
			wins_p1 = rw.get("player1", 0)
			wins_p2 = rw.get("player2", 0)
		var tw = game_data.get("rounds_to_win")
		if tw != null:
			target_wins = int(tw)

	var current_round: int = wins_p1 + wins_p2 + 1
	if _round_label:
		if wins_p1 == target_wins - 1 and wins_p2 == target_wins - 1:
			_round_label.text = "FINAL ROUND"
		else:
			_round_label.text = "ROUND %d" % current_round

func _update_win_dots() -> void:
	var game_data = get_node_or_null("/root/GameData")
	var wins_p1: int = 0
	var wins_p2: int = 0

	if game_data:
		var rw = game_data.get("round_wins")
		if rw is Dictionary:
			wins_p1 = rw.get("player1", 0)
			wins_p2 = rw.get("player2", 0)

	for i in _p1_dots.size():
		_p1_dots[i].color = win_dot_won_color if (i < wins_p1) else win_dot_empty_color

	for i in _p2_dots.size():
		_p2_dots[i].color = win_dot_won_color if (i < wins_p2) else win_dot_empty_color

func _on_round_ended(_winner: String) -> void:
	_update_round_info()
	_update_win_dots()

func _start_warning_pulse() -> void:
	if _warning_tween:
		_warning_tween.kill()
	_warning_tween = create_tween().set_loops()
	_warning_tween.tween_property(_timer_label, "modulate", timer_warning_color, 0.25)
	_warning_tween.tween_property(_timer_label, "modulate", Color(1.0, 0.6, 0.6), 0.25)

func _stop_warning_pulse() -> void:
	if _warning_tween:
		_warning_tween.kill()
		_warning_tween = null
	if _timer_label:
		_timer_label.modulate = timer_normal_color

func _auto_position() -> void:
	var p1_bar: ProgressBar = null
	var p2_bar: ProgressBar = null

	var parent_node := get_parent()
	if parent_node:
		for child in parent_node.get_children():
			if child is HealthBarUI and child.get("character_path"):
				var node_char = child.get_node_or_null(child.get("character_path"))
				if node_char and not node_char.name.to_lower().begins_with("dummy"):
					var pid: int = node_char.get("player_id") if node_char.get("player_id") != null else 1
					if pid == 1 and not p1_bar:
						p1_bar = child
					elif pid == 2 and not p2_bar:
						p2_bar = child

	if p1_bar and p2_bar:
		var p1_right: float = p1_bar.global_position.x + p1_bar.size.x
		var p2_left: float = p2_bar.global_position.x
		var mid_x: float = (p1_right + p2_left) / 2.0
		var top_y: float = minf(p1_bar.global_position.y, p2_bar.global_position.y) - 6.0
		global_position = Vector2(mid_x - frame_size.x / 2.0, top_y)
	else:
		# Fallback: centrar respecto al viewport
		var vp_rect := get_viewport_rect()
		position = Vector2((vp_rect.size.x - frame_size.x) / 2.0, 16.0)

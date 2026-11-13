## victory_screen_ui.gd
## Pantalla de fin de partida (Match Over) construida completamente por código.
## Patrón Observer: Escucha la señal 'match_finished' emitida por GameData.
## Muestra el nombre del ganador leído de su Resource, marcador final y botones Revancha y Menú.
class_name VictoryScreenUI
extends CanvasLayer

# ---------------------------------------------------------------------------
# Señales (Patrón Observer)
# ---------------------------------------------------------------------------
signal back_to_menu_requested()

# ---------------------------------------------------------------------------
# Variables Exportadas (Personalizables)
# ---------------------------------------------------------------------------
@export_group("Colores")
@export var overlay_color: Color = Color(0.03, 0.03, 0.06, 0.88)
@export var panel_bg_color: Color = Color(0.09, 0.09, 0.13, 0.96)
@export var panel_border_color: Color = Color(1.0, 0.85, 0.25, 0.95) ## Borde dorado
@export var title_color: Color = Color(1.0, 0.85, 0.2)               ## Dorado ¡VICTORIA!
@export var winner_name_color: Color = Color(1.0, 1.0, 1.0)          ## Blanco brillante
@export var score_color: Color = Color(0.85, 0.88, 0.95)             ## Marcador de rondas
@export var btn_bg_color: Color = Color(0.18, 0.20, 0.28, 0.95)     ## Fondo botones
@export var btn_border_color: Color = Color(0.8, 0.85, 1.0, 0.7)     ## Borde botones

@export_group("Dimensiones")
@export var panel_size: Vector2 = Vector2(460.0, 290.0)
@export var border_width: int = 2
@export var corner_radius: int = 6
@export var main_menu_scene_path: String = "res://scenes/ui/main_menu.tscn"

# ---------------------------------------------------------------------------
# Estado Interno
# ---------------------------------------------------------------------------
var _winner_key: String = ""
var _lbl_winner: Label = null
var _lbl_score: Label = null
var _btn_rematch: Button = null
var _btn_menu: Button = null

func _ready() -> void:
	layer = 130 # Por encima del HUD y de los combatientes
	_connect_to_game_data()

func _connect_to_game_data() -> void:
	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_signal("match_finished"):
		if not game_data.match_finished.is_connected(setup_victory):
			game_data.match_finished.connect(setup_victory)

## Configura y despliega la pantalla de victoria al terminar el combate
func setup_victory(winner_key: String) -> void:
	_winner_key = winner_key

	# 1. Bloquear movimiento y ataques de los personajes
	_freeze_combatants()

	# 2. Construir la interfaz visual
	_build_ui()

func _freeze_combatants() -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return

	for node in tree.current_scene.find_children("*", "CharacterBase", true, false):
		if node is CharacterBody2D:
			node.velocity = Vector2.ZERO
			node.set_physics_process(false)
			node.set_process_unhandled_input(false)

func _restore_combatants() -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return

	for node in tree.current_scene.find_children("*", "CharacterBase", true, false):
		if node is CharacterBody2D:
			node.set_physics_process(true)
			node.set_process_unhandled_input(true)

func _build_ui() -> void:
	# Fondo oscuro completo semitransparente
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.color = overlay_color
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)

	# Panel central con marco dorado
	var panel := Panel.new()
	panel.name = "VictoryCard"
	panel.custom_minimum_size = panel_size
	panel.size = panel_size
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -panel_size.x / 2.0
	panel.offset_top = -panel_size.y / 2.0
	panel.offset_right = panel_size.x / 2.0
	panel.offset_bottom = panel_size.y / 2.0

	var pbox := StyleBoxFlat.new()
	pbox.bg_color = panel_bg_color
	pbox.border_color = panel_border_color
	pbox.set_border_width_all(border_width)
	pbox.set_corner_radius_all(corner_radius)
	panel.add_theme_stylebox_override("panel", pbox)
	overlay.add_child(panel)

	# Contenedor vertical principal
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Título "¡VICTORIA!"
	var lbl_title := Label.new()
	lbl_title.text = "¡ V I C T O R I A !"
	lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_title.add_theme_font_size_override("font_size", 30)
	lbl_title.modulate = title_color
	vbox.add_child(lbl_title)

	# Nombre del ganador (leído de su Resource / CharacterData)
	var game_data = get_node_or_null("/root/GameData")
	var char_name: String = "Luchador"
	if game_data and game_data.has_method("get_character_display_name"):
		char_name = game_data.get_character_display_name(_winner_key)

	_lbl_winner = Label.new()
	_lbl_winner.text = "¡%s ES EL CAMPEÓN!" % char_name.to_upper()
	_lbl_winner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_winner.add_theme_font_size_override("font_size", 18)
	_lbl_winner.modulate = winner_name_color
	vbox.add_child(_lbl_winner)

	# Marcador final de rondas
	var wins_p1: int = 0
	var wins_p2: int = 0
	var name_p1: String = "Goku"
	var name_p2: String = "Naruto"
	if game_data:
		var rw = game_data.get("round_wins")
		if rw is Dictionary:
			wins_p1 = rw.get("player1", 0)
			wins_p2 = rw.get("player2", 0)
		name_p1 = game_data.get_character_display_name("player1")
		name_p2 = game_data.get_character_display_name("player2")

	_lbl_score = Label.new()
	_lbl_score.text = "MARCADOR FINAL\n%s  %d   —   %d  %s" % [name_p1.to_upper(), wins_p1, wins_p2, name_p2.to_upper()]
	_lbl_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_score.add_theme_font_size_override("font_size", 14)
	_lbl_score.modulate = score_color
	vbox.add_child(_lbl_score)

	# Separador vertical
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Contenedor horizontal de botones
	var btn_box := HBoxContainer.new()
	btn_box.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_box.add_theme_constant_override("separation", 24)
	vbox.add_child(btn_box)

	# Botón 1: REVANCHA
	_btn_rematch = _create_styled_button("REVANCHA", Color(1.0, 0.85, 0.2))
	_btn_rematch.pressed.connect(_on_rematch_pressed)
	btn_box.add_child(_btn_rematch)

	# Botón 2: MENÚ
	_btn_menu = _create_styled_button("MENÚ", Color(0.9, 0.9, 0.9))
	_btn_menu.pressed.connect(_on_menu_pressed)
	btn_box.add_child(_btn_menu)

	# Animación de entrada suave del panel (pop elástico)
	panel.scale = Vector2(0.7, 0.7)
	panel.pivot_offset = panel_size / 2.0
	var tw: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.4)

func _create_styled_button(text_label: String, text_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text_label
	btn.custom_minimum_size = Vector2(130.0, 38.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", text_color)

	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = btn_bg_color
	btn_normal.border_color = btn_border_color
	btn_normal.set_border_width_all(1)
	btn_normal.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("normal", btn_normal)

	var btn_hover := StyleBoxFlat.new()
	btn_hover.bg_color = Color(btn_bg_color.r + 0.12, btn_bg_color.g + 0.12, btn_bg_color.b + 0.15, 1.0)
	btn_hover.border_color = Color(1.0, 0.9, 0.4)
	btn_hover.set_border_width_all(1)
	btn_hover.set_corner_radius_all(4)
	btn.add_theme_stylebox_override("hover", btn_hover)

	return btn

## Botón REVANCHA: reinicia la partida desde cero (rondas 0-0, vida, Ki, posiciones y temporizador)
func _on_rematch_pressed() -> void:
	print("[Fin de Partida] 🔁 Revancha seleccionada. Reiniciando partida desde cero...")
	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("reset_match"):
		game_data.reset_match()

	_restore_combatants()
	queue_free()

	var tree := get_tree()
	if tree:
		tree.reload_current_scene()

## Botón MENÚ: vuelve a la escena principal o emite la señal back_to_menu_requested
func _on_menu_pressed() -> void:
	print("[Fin de Partida] 🏠 Menú seleccionado.")
	emit_signal("back_to_menu_requested")

	var game_data = get_node_or_null("/root/GameData")
	if game_data and game_data.has_signal("back_to_menu_requested"):
		game_data.emit_signal("back_to_menu_requested")

	if ResourceLoader.exists(main_menu_scene_path):
		var tree := get_tree()
		if tree:
			_restore_combatants()
			queue_free()
			tree.change_scene_to_file(main_menu_scene_path)
	else:
		print("[Menú] La escena '%s' aún no existe en el proyecto." % main_menu_scene_path)
		print("[Menú] Conexión lista: cuando crees 'res://scenes/ui/main_menu.tscn', el botón redirigirá automáticamente.")


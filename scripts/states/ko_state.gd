## ko_state.gd
## El personaje ha muerto. Permanece en el suelo sin responder a inputs de combate.
## Muestra un aviso provisional de K.O. en pantalla y permite reiniciar con la tecla [R].
class_name KOState
extends CharacterState

const GRAVITY: float = 980.0

var _ko_ui: CanvasLayer = null

func enter() -> void:
	character.velocity = Vector2.ZERO
	character.play_animation("ko")
	character.modulate = Color(0.45, 0.45, 0.45, 1.0) # Tinte grisáceo de derrota

	var char_name: String = character.data.display_name if character.data else character.name
	print("💀💀 ¡K.O.! [%s] HA SIDO DERROTADO 💀💀" % char_name)

	# Si es el Dummy de entrenamiento, no computar como ronda competitiva
	if character.name.to_lower().begins_with("dummy"):
		return

	# Determinar quién ganó la ronda (el oponente del personaje caído)
	var winner_key: String = "player2" if character.player_id == 1 else "player1"

	var game_data = character.get_node_or_null("/root/GameData")
	if game_data and game_data.has_method("report_round_winner"):
		game_data.report_round_winner(winner_key)
		# Si el ganador alcanzó el total de rondas para ganar la partida,
		# la pantalla de victoria (VictoryScreenUI) toma el control automáticamente.
		var rw = game_data.get("round_wins")
		var target_wins: int = int(game_data.get("rounds_to_win")) if game_data.get("rounds_to_win") != null else 2
		if rw is Dictionary and rw.get(winner_key, 0) >= target_wins:
			return

	# Si la partida continúa hacia la siguiente ronda, mostrar banner intermedio
	_show_ko_banner(char_name)

func physics_update(delta: float) -> void:
	if not character.is_on_floor():
		character.velocity.y += GRAVITY * delta
	else:
		character.velocity.y = 0.0

func handle_input(event: InputEvent) -> String:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			print("[Combate] Reiniciando escena por tecla [R]...")
			_restart_match()
	return ""

func _restart_match() -> void:
	if is_instance_valid(_ko_ui):
		_ko_ui.queue_free()
	var tree: SceneTree = get_tree()
	if tree:
		tree.reload_current_scene()

func _show_ko_banner(char_name: String) -> void:
	var tree: SceneTree = get_tree()
	if not tree:
		return

	# Si ya existe un banner previo en la escena, no duplicarlo
	if tree.root.has_node("KOBannerLayer"):
		return

	_ko_ui = CanvasLayer.new()
	_ko_ui.name = "KOBannerLayer"
	_ko_ui.layer = 120

	# Panel central semi-transparente
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.8)
	bg.set_anchors_preset(Control.PRESET_CENTER)
	bg.offset_left = -260
	bg.offset_top = -90
	bg.offset_right = 260
	bg.offset_bottom = 90
	_ko_ui.add_child(bg)

	# Borde decorativo fino
	var border := ReferenceRect.new()
	border.set_anchors_preset(Control.PRESET_FULL_RECT)
	border.border_color = Color(1.0, 0.3, 0.2, 0.9)
	border.border_width = 2.0
	border.editor_only = false
	bg.add_child(border)

	# Contenedor vertical de textos
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bg.add_child(vbox)

	# Título "¡K. O.!"
	var lbl_ko := Label.new()
	lbl_ko.text = "¡K. O.!"
	lbl_ko.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_ko.add_theme_font_size_override("font_size", 36)
	lbl_ko.modulate = Color(1.0, 0.2, 0.2)
	vbox.add_child(lbl_ko)

	# Nombre del personaje derrotado
	var lbl_msg := Label.new()
	lbl_msg.text = "¡%s ha caído en combate!" % char_name
	lbl_msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_msg.add_theme_font_size_override("font_size", 18)
	lbl_msg.modulate = Color(1.0, 1.0, 1.0)
	vbox.add_child(lbl_msg)

	# Separador sutil
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer)

	# Instrucción para pasar a la siguiente ronda
	var lbl_inst := Label.new()
	lbl_inst.text = "Presiona [ R ] para la siguiente ronda"
	lbl_inst.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_inst.add_theme_font_size_override("font_size", 14)
	lbl_inst.modulate = Color(1.0, 0.85, 0.3)
	vbox.add_child(lbl_inst)

	tree.root.add_child(_ko_ui)

func exit() -> void:
	if is_instance_valid(_ko_ui):
		_ko_ui.queue_free()

## story_stage.gd
## Escenario y controlador del Modo Historia ECOS (Capítulo 1: El despertar).
## Administra el flujo narrativo completo:
##   1. Introducción cinematográfica (Valle del Fin, interferencia dimensional, diálogos)
##   2. Combate activo contra el Dummy de entrenamiento (HUD, inputs de Goku)
##   3. Diálogo de victoria (desactivación del Dummy, grieta hacia el Torneo)
##   4. Pantalla final de capítulo completado y desbloqueo del Capítulo 2.
class_name StoryStage
extends Node2D

# ---------------------------------------------------------------------------
# Estados del Escenario
# ---------------------------------------------------------------------------
enum StagePhase {
	INTRO_CINEMATIC,
	COMBAT,
	VICTORY_CINEMATIC,
	CHAPTER_COMPLETE
}

var current_phase: StagePhase = StagePhase.INTRO_CINEMATIC

# ---------------------------------------------------------------------------
# Referencias a Nodos del Mundo 2D
# ---------------------------------------------------------------------------
@onready var camera: Camera2D = $Camera2D
@onready var fighters_container: Node2D = $Fighters
@onready var ground: StaticBody2D = $Ground
@onready var background_canvas: CanvasLayer = $BackgroundLayer
@onready var dimensional_rift: Node2D = $DimensionalRift

# ---------------------------------------------------------------------------
# Referencias a la Capa Cinemática / Manga UI
# ---------------------------------------------------------------------------
@onready var ui_layer: CanvasLayer = $MangaUILayer
@onready var black_overlay: ColorRect = $MangaUILayer/BlackOverlay
@onready var glitch_overlay: ColorRect = $MangaUILayer/GlitchOverlay
@onready var dialogue_box: Control = $MangaUILayer/DialogueBox
@onready var speaker_badge: Panel = $MangaUILayer/DialogueBox/SpeakerBadge
@onready var speaker_label: Label = $MangaUILayer/DialogueBox/SpeakerBadge/SpeakerLabel
@onready var dialogue_label: Label = $MangaUILayer/DialogueBox/DialogueLabel
@onready var portrait_rect: TextureRect = $MangaUILayer/DialogueBox/PortraitFrame/PortraitTexture
@onready var portrait_glitch: Control = $MangaUILayer/DialogueBox/PortraitFrame/GlitchAvatar
@onready var arrow_indicator: Label = $MangaUILayer/DialogueBox/ArrowIndicator
@onready var skip_hint: Label = $MangaUILayer/DialogueBox/SkipHint

# ---------------------------------------------------------------------------
# Referencias al HUD de Combate
# ---------------------------------------------------------------------------
@onready var combat_hud: CanvasLayer = $CombatHUD
@onready var goku_health_bar: ProgressBar = $CombatHUD/GokuHealthBar
@onready var goku_energy_bar: ProgressBar = $CombatHUD/GokuEnergyBar
@onready var dummy_health_bar: ProgressBar = $CombatHUD/DummyHealthBar

# ---------------------------------------------------------------------------
# Pantalla de Capítulo Completado
# ---------------------------------------------------------------------------
@onready var complete_layer: CanvasLayer = $ChapterCompleteLayer
@onready var complete_banner: Control = $ChapterCompleteLayer/BannerPanel
@onready var complete_title: Label = $ChapterCompleteLayer/BannerPanel/TitleLabel
@onready var complete_sub: Label = $ChapterCompleteLayer/BannerPanel/SubLabel
@onready var complete_unlocked: Label = $ChapterCompleteLayer/BannerPanel/UnlockedLabel
@onready var complete_btn: Button = $ChapterCompleteLayer/BannerPanel/ContinueButton

# ---------------------------------------------------------------------------
# Luchadores instanciados
# ---------------------------------------------------------------------------
var goku_instance: CharacterBase = null
var dummy_instance: Dummy = null

# ---------------------------------------------------------------------------
# Control de Diálogos
# ---------------------------------------------------------------------------
var _dialogue_list: Array[Dictionary] = []
var _dialogue_index: int = 0
var _is_typing: bool = false
var _type_speed: float = 0.026
var _type_tween: Tween = null
var _arrow_tween: Tween = null

# ---------------------------------------------------------------------------
# SFX y Audio
# ---------------------------------------------------------------------------
var _audio_wind: AudioStreamPlayer = null
var _audio_glitch: AudioStreamPlayer = null
var _audio_type: AudioStreamPlayer = null

# ---------------------------------------------------------------------------
# Ciclo de Vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	_setup_audio()
	_initialize_story_context()
	_spawn_fighters()
	_setup_combat_hud()
	_start_intro_cinematic()

func _setup_audio() -> void:
	_audio_wind = AudioStreamPlayer.new()
	_audio_wind.name = "AudioWind"
	add_child(_audio_wind)

	_audio_glitch = AudioStreamPlayer.new()
	_audio_glitch.name = "AudioGlitch"
	add_child(_audio_glitch)

	_audio_type = AudioStreamPlayer.new()
	_audio_type.name = "AudioType"
	add_child(_audio_type)

func _initialize_story_context() -> void:
	var sm = get_node_or_null("/root/StoryManager")
	if sm:
		if not sm.current_chapter or sm.current_chapter.chapter_number != 1:
			sm.load_chapter(1)
		sm.prepare_combat_for_current_chapter()
		if not sm.story_match_finished.is_connected(_on_story_match_finished):
			sm.story_match_finished.connect(_on_story_match_finished)

# ---------------------------------------------------------------------------
# Instanciación de Luchadores
# ---------------------------------------------------------------------------

func _spawn_fighters() -> void:
	var factory = get_node_or_null("/root/CharacterFactory")
	var gdata = get_node_or_null("/root/GameData")

	# 1. Instanciar Goku (P1)
	if factory and gdata and gdata.player1_data:
		goku_instance = factory.create_character(gdata.player1_data)
	if not goku_instance:
		var goku_scene = load("res://scenes/characters/goku.tscn") as PackedScene
		if goku_scene:
			goku_instance = goku_scene.instantiate()
	var floor_y: float = 52.0
	if ground:
		var ground_col = ground.get_node_or_null("CollisionShape2D")
		if ground_col and ground_col.shape is RectangleShape2D:
			floor_y = ground.global_position.y - (ground_col.shape.size.y * 0.5)

	if goku_instance:
		goku_instance.player_id = 1
		var goku_offset: float = 25.0 * goku_instance.scale.y
		goku_instance.position = Vector2(160, floor_y - goku_offset)
		fighters_container.add_child(goku_instance)

	# 2. Instanciar Dummy (P2)
	if factory and gdata and gdata.player2_data:
		dummy_instance = factory.create_character(gdata.player2_data) as Dummy
	if not dummy_instance:
		var dummy_scene = load("res://scenes/characters/dummy.tscn") as PackedScene
		if dummy_scene:
			dummy_instance = dummy_scene.instantiate()
	if dummy_instance:
		dummy_instance.player_id = 2
		var dummy_offset: float = 64.0 * dummy_instance.scale.y
		dummy_instance.position = Vector2(430, floor_y - dummy_offset)
		# Inicialmente oculto durante los primeros compases de la intro
		dummy_instance.visible = false
		dummy_instance.set_physics_process(false)
		fighters_container.add_child(dummy_instance)

	# Bloquear control de Goku durante la cinemática
	_set_fighter_input_enabled(false)

func _set_fighter_input_enabled(enabled: bool) -> void:
	if is_instance_valid(goku_instance):
		goku_instance.set_process_unhandled_input(enabled)
		if not enabled:
			goku_instance.velocity = Vector2.ZERO

# ---------------------------------------------------------------------------
# Configuración del HUD de Combate
# ---------------------------------------------------------------------------

func _setup_combat_hud() -> void:
	combat_hud.visible = false
	complete_layer.visible = false
	dimensional_rift.visible = false

	if is_instance_valid(goku_instance):
		if goku_health_bar and goku_health_bar.has_method("set"):
			goku_health_bar.set("character_path", goku_instance.get_path())
		if goku_energy_bar and goku_energy_bar.has_method("set"):
			goku_energy_bar.set("character_path", goku_instance.get_path())

	if is_instance_valid(dummy_instance) and dummy_health_bar:
		if dummy_health_bar.has_method("set"):
			dummy_health_bar.set("character_path", dummy_instance.get_path())

# ---------------------------------------------------------------------------
# FASE 1: Cinemática de Introducción
# ---------------------------------------------------------------------------

func _start_intro_cinematic() -> void:
	current_phase = StagePhase.INTRO_CINEMATIC
	_set_fighter_input_enabled(false)
	combat_hud.visible = false
	dialogue_box.visible = false

	var sm = get_node_or_null("/root/StoryManager")
	if sm and sm.current_chapter:
		_dialogue_list = sm.current_chapter.intro_dialogue
	else:
		_dialogue_list = _get_default_intro_dialogue()

	_dialogue_index = 0

	# Secuencia de entrada:
	# 1. Pantalla negra total
	black_overlay.modulate.a = 1.0
	black_overlay.visible = true

	# 2. Transición tras breve suspenso
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		_trigger_dimensional_glitch(0.5)
	)
	tw.tween_property(black_overlay, "modulate:a", 0.0, 1.2)
	tw.tween_callback(func():
		black_overlay.visible = false
		_show_dialogue_box()
		_display_current_dialogue()
	)

func _get_default_intro_dialogue() -> Array[Dictionary]:
	return [
		{"speaker": "Goku", "text": "¿Mmm...? ¿Dónde estoy?", "portrait": "goku", "event": "fade_in_valley"},
		{"speaker": "Goku", "text": "¡Vaya! Este lugar es increíble. Pero... no recuerdo haber venido aquí.", "portrait": "goku", "event": ""},
		{"speaker": "???", "text": "Registro identificado. Son Goku.", "portrait": "unknown", "event": "glitch_interference"},
		{"speaker": "Goku", "text": "¿Eh? ¿Quién anda ahí?", "portrait": "goku", "event": ""},
		{"speaker": "???", "text": "Memoria conservada. Capacidad de combate pendiente de verificación.", "portrait": "unknown", "event": "glitch_interference"},
		{"speaker": "Goku", "text": "No entiendo nada de lo que dices. ¡Sal de una vez!", "portrait": "goku", "event": ""},
		{"speaker": "Goku", "text": "¿Quieres que pelee contra eso? Je... ¡Bueno, supongo que puedo calentar un poco!", "portrait": "goku", "event": "spawn_dummy"}
	]

# ---------------------------------------------------------------------------
# FASE 2: Transición e Inicio de Combate
# ---------------------------------------------------------------------------

func _start_combat_phase() -> void:
	current_phase = StagePhase.COMBAT
	_hide_dialogue_box()

	# Asegurar que el Dummy esté presente y activo
	if is_instance_valid(dummy_instance):
		dummy_instance.visible = true
		dummy_instance.set_physics_process(true)

	# Mostrar HUD con fundido suave
	combat_hud.visible = true
	combat_hud.offset = Vector2(0, -30)
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(combat_hud, "offset", Vector2.ZERO, 0.4)

	# Activar inputs de Goku
	_set_fighter_input_enabled(true)
	print("[StoryStage] ⚔️ ¡Combate iniciado: Goku vs Dummy!")

# ---------------------------------------------------------------------------
# FASE 3: Cinemática de Victoria
# ---------------------------------------------------------------------------

func _on_story_match_finished(won: bool, _chapter: StoryChapter) -> void:
	if not won:
		print("[StoryStage] Derrota en capítulo 1. Preparando reintento...")
		return

	if current_phase == StagePhase.VICTORY_CINEMATIC or current_phase == StagePhase.CHAPTER_COMPLETE:
		return

	current_phase = StagePhase.VICTORY_CINEMATIC
	print("[StoryStage] 🏆 Combate ganado. Iniciando cinemática de victoria...")

	# Desactivar controles y ocultar HUD
	_set_fighter_input_enabled(false)
	var tw_hud := create_tween()
	tw_hud.tween_property(combat_hud, "offset:y", -60.0, 0.4)
	tw_hud.tween_callback(func(): combat_hud.visible = false)

	# Interferencia que recorre el escenario y desactiva al Dummy
	_trigger_dimensional_glitch(0.6)
	if is_instance_valid(dummy_instance):
		dummy_instance.modulate = Color(0.5, 0.5, 0.5, 0.8)

	var sm = get_node_or_null("/root/StoryManager")
	if sm and sm.current_chapter:
		_dialogue_list = sm.current_chapter.win_dialogue
	else:
		_dialogue_list = _get_default_win_dialogue()

	_dialogue_index = 0

	# Pausa deliberada antes de los diálogos de victoria
	var tw := create_tween()
	tw.tween_interval(0.8)
	tw.tween_callback(func():
		_show_dialogue_box()
		_display_current_dialogue()
	)

func _get_default_win_dialogue() -> Array[Dictionary]:
	return [
		{"speaker": "???", "text": "Verificación completada. Coincidencia: 99,8 %.", "portrait": "unknown", "event": "dummy_deactivated"},
		{"speaker": "Goku", "text": "¡Eso estuvo fácil! Aunque... ¿qué significa ese porcentaje?", "portrait": "goku", "event": ""},
		{"speaker": "???", "text": "La diferencia será estudiada.", "portrait": "unknown", "event": "glitch_interference"},
		{"speaker": "Goku", "text": "¡Oye, espera! ¡Todavía no me has dicho dónde estoy!", "portrait": "goku", "event": ""},
		{"speaker": "Goku", "text": "¿Un torneo de artes marciales? ¡Ahora sí se está poniendo interesante!", "portrait": "goku", "event": "open_rift_stadium"}
	]

# ---------------------------------------------------------------------------
# FASE 4: Pantalla de Capítulo Completado
# ---------------------------------------------------------------------------

func _show_chapter_completed_screen() -> void:
	current_phase = StagePhase.CHAPTER_COMPLETE
	_hide_dialogue_box()

	# Desbloquear Capítulo 2 en StoryManager y guardar en SaveManager
	var sm = get_node_or_null("/root/StoryManager")
	if sm:
		sm.advance_chapter("chapter_02")

	# Fundido a negro y presentación de la tarjeta manga de victoria
	black_overlay.visible = true
	black_overlay.modulate.a = 0.0
	complete_layer.visible = true
	complete_banner.scale = Vector2(0.85, 0.85)
	complete_banner.modulate.a = 0.0

	var tw := create_tween()
	tw.tween_property(black_overlay, "modulate:a", 0.85, 0.4)
	tw.parallel().tween_property(complete_banner, "scale", Vector2.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(complete_banner, "modulate:a", 1.0, 0.45)
	tw.tween_callback(func():
		if complete_btn:
			complete_btn.grab_focus()
	)

func _on_continue_button_pressed() -> void:
	print("[StoryStage] 🚪 Regresando al Menú Principal...")
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")

# ---------------------------------------------------------------------------
# Gestión de Diálogos y Efecto Máquina de Escribir (Typewriter)
# ---------------------------------------------------------------------------

func _show_dialogue_box() -> void:
	dialogue_box.visible = true
	dialogue_box.position.y = 30.0
	dialogue_box.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dialogue_box, "position:y", 0.0, 0.25)
	tw.parallel().tween_property(dialogue_box, "modulate:a", 1.0, 0.25)

func _hide_dialogue_box() -> void:
	if _arrow_tween:
		_arrow_tween.kill()
	var tw := create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(dialogue_box, "position:y", 30.0, 0.2)
	tw.parallel().tween_property(dialogue_box, "modulate:a", 0.0, 0.2)
	tw.tween_callback(func(): dialogue_box.visible = false)

func _display_current_dialogue() -> void:
	if _dialogue_index >= _dialogue_list.size():
		_on_dialogue_sequence_finished()
		return

	var data: Dictionary = _dialogue_list[_dialogue_index]
	var speaker: String = data.get("speaker", "???")
	var text: String = data.get("text", "")
	var event_id: String = data.get("event", "")

	# Ejecutar eventos narrativos asociados a la línea
	_handle_narrative_event(event_id)

	# Actualizar hablante y estilo del badge
	speaker_label.text = speaker.to_upper()
	if speaker == "Goku":
		speaker_badge.self_modulate = Color(1.0, 0.824, 0.247) # Amarillo Goku
		speaker_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		portrait_rect.visible = true
		portrait_glitch.visible = false
	else:
		speaker_badge.self_modulate = Color(0.2, 0.85, 0.95) # Cyan interferencia
		speaker_label.add_theme_color_override("font_color", Color(0.05, 0.05, 0.1))
		portrait_rect.visible = false
		portrait_glitch.visible = true

	# Efecto de escritura progresiva
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	arrow_indicator.visible = false
	_is_typing = true

	if _type_tween:
		_type_tween.kill()

	var duration: float = float(text.length()) * _type_speed
	_type_tween = create_tween()
	_type_tween.tween_property(dialogue_label, "visible_characters", text.length(), duration)
	_type_tween.tween_callback(func():
		_is_typing = false
		_show_blinking_arrow()
	)

func _show_blinking_arrow() -> void:
	arrow_indicator.visible = true
	if _arrow_tween:
		_arrow_tween.kill()
	_arrow_tween = create_tween().set_loops()
	_arrow_tween.tween_property(arrow_indicator, "modulate:a", 0.2, 0.4)
	_arrow_tween.tween_property(arrow_indicator, "modulate:a", 1.0, 0.4)

func _advance_dialogue() -> void:
	if _is_typing:
		# Revelar todo el texto de inmediato
		if _type_tween:
			_type_tween.kill()
		dialogue_label.visible_characters = -1
		_is_typing = false
		_show_blinking_arrow()
	else:
		_dialogue_index += 1
		_display_current_dialogue()

func _skip_cinematic() -> void:
	print("[StoryStage] ⏩ Escena saltada por el jugador.")
	if current_phase == StagePhase.INTRO_CINEMATIC:
		_start_combat_phase()
	elif current_phase == StagePhase.VICTORY_CINEMATIC:
		_show_chapter_completed_screen()

func _on_dialogue_sequence_finished() -> void:
	if current_phase == StagePhase.INTRO_CINEMATIC:
		_start_combat_phase()
	elif current_phase == StagePhase.VICTORY_CINEMATIC:
		# Goku avanza hacia la grieta y atraviesa
		_animate_goku_crossing_rift()

# ---------------------------------------------------------------------------
# Eventos Narrativos Específicos del Capítulo 1
# ---------------------------------------------------------------------------

func _handle_narrative_event(event_id: String) -> void:
	match event_id:
		"glitch_interference":
			_trigger_dimensional_glitch(0.35)
		"spawn_dummy":
			_trigger_dimensional_glitch(0.4)
			if is_instance_valid(dummy_instance):
				dummy_instance.visible = true
				dummy_instance.modulate = Color(2.0, 2.0, 2.0) # Flash de aparición
				var tw := create_tween()
				tw.tween_property(dummy_instance, "modulate", Color(1, 1, 1), 0.3)
		"open_rift_stadium":
			_open_dimensional_rift()

func _trigger_dimensional_glitch(duration: float) -> void:
	glitch_overlay.visible = true
	glitch_overlay.modulate.a = 0.85
	var tw := create_tween()
	tw.tween_property(glitch_overlay, "modulate:a", 0.0, duration)
	tw.tween_callback(func(): glitch_overlay.visible = false)

func _open_dimensional_rift() -> void:
	dimensional_rift.visible = true
	dimensional_rift.scale = Vector2(0.0, 1.0)
	dimensional_rift.modulate.a = 0.0
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(dimensional_rift, "scale:x", 1.0, 0.6)
	tw.parallel().tween_property(dimensional_rift, "modulate:a", 1.0, 0.6)

func _animate_goku_crossing_rift() -> void:
	_hide_dialogue_box()
	if is_instance_valid(goku_instance):
		var target_x: float = dimensional_rift.position.x
		var tw_walk := create_tween()
		tw_walk.tween_property(goku_instance, "position:x", target_x, 1.2)
		tw_walk.parallel().tween_property(goku_instance, "modulate:a", 0.0, 1.2)
		tw_walk.tween_callback(func():
			_show_chapter_completed_screen()
		)
	else:
		_show_chapter_completed_screen()

# ---------------------------------------------------------------------------
# Manejo de Inputs (Avanzar / Saltar)
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if current_phase == StagePhase.INTRO_CINEMATIC or current_phase == StagePhase.VICTORY_CINEMATIC:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and (event.keycode in [KEY_SPACE, KEY_ENTER, KEY_F, KEY_J])):
			get_viewport().set_input_as_handled()
			_advance_dialogue()
		elif event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
			get_viewport().set_input_as_handled()
			_skip_cinematic()
	elif current_phase == StagePhase.CHAPTER_COMPLETE:
		if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_SPACE, KEY_ENTER]):
			get_viewport().set_input_as_handled()
			_on_continue_button_pressed()

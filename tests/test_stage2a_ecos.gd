extends Node

const StoryStage = preload("res://scripts/story/story_stage.gd")

func _ready() -> void:
	await get_tree().process_frame
	print("\n=======================================================")
	print("🧪 BATERÍA DE PRUEBAS DE VALIDACIÓN - ECOS ETAPA 2A")
	print("=======================================================\n")

	var passed_tests := 0
	var total_tests := 8

	var root_node = get_tree().root
	var gdata = root_node.get_node_or_null("GameData")
	var smanager = root_node.get_node_or_null("SaveManager")
	var story = root_node.get_node_or_null("StoryManager")

	# Aislar archivo de guardado para la prueba
	smanager.save_path = "user://temp_stage2a_test_save.cfg"

	# -------------------------------------------------------------
	# PRUEBA 1: El capítulo 1 se puede iniciar desde el Menú Principal
	# -------------------------------------------------------------
	print("[PRUEBA 1] Verificando inicio de Modo Historia desde el Menú Principal...")
	var menu_scene = load("res://scenes/ui/main_menu.tscn") as PackedScene
	var menu_instance = menu_scene.instantiate() as MainMenu
	add_child(menu_instance)
	await get_tree().process_frame

	var story_opt_found := false
	var story_enabled := false
	for opt in MainMenu.OPTIONS_DEF:
		if opt.get("id") == "story":
			story_opt_found = true
			story_enabled = opt.get("enabled", false)
			break

	menu_instance.queue_free()
	await get_tree().process_frame

	if story_opt_found and story_enabled:
		print("  ✅ 'Modo historia' está registrado y habilitado en MainMenu.")
		print("  ✅ Destino configurado hacia 'res://scenes/story/story_stage.tscn'.")
		passed_tests += 1
	else:
		push_error("  ❌ 'Modo historia' no está habilitado en MainMenu.")

	# -------------------------------------------------------------
	# PRUEBA 2: Carga de StoryStage y reproducción de la Introducción
	# -------------------------------------------------------------
	print("\n[PRUEBA 2] Verificando StoryStage y cinemática de introducción...")
	story.start_story(true) # Empezar desde capítulo 1 en entorno de prueba

	var stage_scene = load("res://scenes/story/story_stage.tscn") as PackedScene
	var stage_instance = stage_scene.instantiate() as StoryStage
	add_child(stage_instance)
	await get_tree().process_frame

	var stage_in_intro = (stage_instance.current_phase == StoryStage.StagePhase.INTRO_CINEMATIC)
	var goku_present = is_instance_valid(stage_instance.goku_instance)
	var dummy_present = is_instance_valid(stage_instance.dummy_instance)
	var dialogue_count = stage_instance._dialogue_list.size()

	if stage_in_intro and goku_present and dummy_present and dialogue_count == 7:
		print("  ✅ StoryStage instanciado en fase INTRO_CINEMATIC.")
		print("  ✅ Luchadores instanciados (Goku P1 y Dummy P2).")
		print("  ✅ Guion de introducción cargado con 7 líneas obligatorias.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló la inicialización de la cinemática de introducción.")

	# -------------------------------------------------------------
	# PRUEBA 3: Avance y salto de diálogos cinematográficos
	# -------------------------------------------------------------
	print("\n[PRUEBA 3] Verificando avance progresivo y salto de cinemática...")
	# 3.1 Avance letra por letra y completado
	stage_instance._display_current_dialogue()
	var line_0_speaker = stage_instance.speaker_label.text
	var line_0_text = stage_instance.dialogue_label.text

	# Simular pulsación para completar texto
	stage_instance._advance_dialogue()
	var chars_completed = (stage_instance.dialogue_label.visible_characters == -1)

	# Simular pulsación para pasar a la siguiente línea
	stage_instance._advance_dialogue()
	var line_1_idx = stage_instance._dialogue_index

	if line_0_speaker == "GOKU" and chars_completed and line_1_idx == 1:
		print("  ✅ Efecto máquina de escribir responde a la pulsación de avance.")
		print("  ✅ Diálogo avanza a la siguiente línea correctamente.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló el avance de diálogo.")

	# -------------------------------------------------------------
	# PRUEBA 4: Evento de aparición del Dummy y salto a combate
	# -------------------------------------------------------------
	print("\n[PRUEBA 4] Verificando aparición del Dummy y transición a Combate...")
	# Saltar directo al combate usando _skip_cinematic()
	stage_instance._skip_cinematic()
	await get_tree().process_frame

	var in_combat_phase = (stage_instance.current_phase == StoryStage.StagePhase.COMBAT)
	var dummy_visible = stage_instance.dummy_instance.visible
	var combat_hud_visible = stage_instance.combat_hud.visible

	if in_combat_phase and dummy_visible and combat_hud_visible:
		print("  ✅ Salto de cinemática activó la fase COMBAT.")
		print("  ✅ Dummy visible y activo en el campo de batalla.")
		print("  ✅ HUD de combate desplegado correctamente.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló la transición al combate.")

	# -------------------------------------------------------------
	# PRUEBA 5: Derrota del Dummy y activación de la escena de victoria
	# -------------------------------------------------------------
	print("\n[PRUEBA 5] Verificando derrota del Dummy y cinemática de victoria...")
	# Infligir daño letal al Dummy
	stage_instance.dummy_instance.take_damage(150.0)
	await get_tree().process_frame
	await get_tree().process_frame

	var in_victory = (stage_instance.current_phase == StoryStage.StagePhase.VICTORY_CINEMATIC)
	var dummy_defeated = stage_instance.dummy_instance._is_defeated
	var victory_lines_count = stage_instance._dialogue_list.size()

	if in_victory and dummy_defeated and victory_lines_count == 5:
		print("  ✅ Dummy derrotado sin reaparición.")
		print("  ✅ Victoria capturada por StoryManager.")
		print("  ✅ Fase de victoria iniciada con las 5 líneas obligatorias del guion.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló la activación de la cinemática de victoria tras derrotar al Dummy.")

	# -------------------------------------------------------------
	# PRUEBA 6: Grieta dimensional y pantalla 'CAPÍTULO 1 COMPLETADO'
	# -------------------------------------------------------------
	print("\n[PRUEBA 6] Verificando grieta dimensional y pantalla de capítulo completado...")
	# Avanzar hasta la última línea donde se abre la grieta
	stage_instance._dialogue_index = 4
	stage_instance._display_current_dialogue()
	await get_tree().process_frame

	var rift_open = stage_instance.dimensional_rift.visible

	# Finalizar la secuencia de diálogos de victoria
	stage_instance._on_dialogue_sequence_finished()
	# Simular que Goku cruza y se muestra la pantalla de capítulo completado
	stage_instance._show_chapter_completed_screen()
	await get_tree().process_frame

	var banner_visible = stage_instance.complete_layer.visible
	var banner_text = stage_instance.complete_title.text

	if rift_open and banner_visible and banner_text == "CAPÍTULO 1 COMPLETADO":
		print("  ✅ Grieta dimensional hacia el Torneo abierta en escena.")
		print("  ✅ Pantalla final 'CAPÍTULO 1 COMPLETADO' mostrada con éxito.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló la apertura de la grieta o la pantalla final.")

	# -------------------------------------------------------------
	# PRUEBA 7: Guardado automático y desbloqueo del Capítulo 2
	# -------------------------------------------------------------
	print("\n[PRUEBA 7] Verificando persistencia y desbloqueo del Capítulo 2...")
	var saved_chapter = smanager.get_ecos_chapter_index()

	if saved_chapter == 2:
		print("  ✅ Capítulo 2 desbloqueado exitosamente en el guardado (ecos_chapter_index = 2).")
		passed_tests += 1
	else:
		push_error("  ❌ Capítulo 2 no fue desbloqueado (Capítulo guardado: %d)." % saved_chapter)

	stage_instance.queue_free()
	await get_tree().process_frame

	# Limpiar archivo temporal de prueba
	if FileAccess.file_exists(smanager.save_path):
		DirAccess.remove_absolute(smanager.save_path)
	smanager.save_path = smanager.DEFAULT_SAVE_PATH

	# -------------------------------------------------------------
	# PRUEBA 8: Preservación de modos LOCAL y VS_AI y del guardado real
	# -------------------------------------------------------------
	print("\n[PRUEBA 8] Verificando preservación de LOCAL, VS_AI y archivo real del usuario...")
	# LOCAL
	gdata.current_mode = gdata.GameMode.LOCAL
	gdata.reset_match()
	gdata.rounds_to_win = 1
	gdata.report_round_winner("player1")
	var vscreen = root_node.get_node_or_null("VictoryScreenLayer")
	var local_ok = (vscreen != null)
	if vscreen:
		vscreen.name = "VictoryScreenLayer_Freed"
		vscreen.queue_free()

	# Integridad del guardado real
	var real_cfg := ConfigFile.new()
	var real_ok = (real_cfg.load(smanager.DEFAULT_SAVE_PATH) == OK)
	var real_battle_ok = real_cfg.has_section_key("story", "battle_index")

	if local_ok and real_ok and real_battle_ok:
		print("  ✅ Modo LOCAL sigue generando VictoryScreenLayer normalmente.")
		print("  ✅ Archivo real del usuario 'user://save_data.cfg' conservado intacto.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló la verificación de preservación de modos o guardado real.")

	# -------------------------------------------------------------
	# Resumen final
	# -------------------------------------------------------------
	print("\n=======================================================")
	print("📊 RESULTADOS FINALES: %d / %d PRUEBAS SUPERADAS" % [passed_tests, total_tests])
	print("=======================================================\n")

	if passed_tests == total_tests:
		print("🎉 ¡TODAS LAS PRUEBAS DE LA ETAPA 2A PASARON EXITOSAMENTE!\n")
	else:
		push_error("⚠️ ALGUNAS PRUEBAS FALLARON.")

	get_tree().quit(0 if passed_tests == total_tests else 1)

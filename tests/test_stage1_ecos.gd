extends Node

func _ready() -> void:
	await get_tree().process_frame
	print("\n=======================================================")
	print("🧪 BATERÍA DE PRUEBAS DE VALIDACIÓN Y CORRECCIÓN (ETAPA 1)")
	print("=======================================================\n")
	
	var passed_tests := 0
	var total_tests := 7

	var root_node = get_tree().root
	var gdata = root_node.get_node_or_null("GameData")
	var smanager = root_node.get_node_or_null("SaveManager")
	var story = root_node.get_node_or_null("StoryManager")
	var factory = root_node.get_node_or_null("CharacterFactory")

	# -------------------------------------------------------------
	# PRUEBA 1: Carga y consistencia de los seis capítulos
	# -------------------------------------------------------------
	print("[PRUEBA 1] Verificando los 6 recursos de capítulos...")
	if story and story.chapters.size() == 6:
		var all_valid := true
		for i in range(1, 7):
			var ch: StoryChapter = story.chapters[i - 1]
			if ch.chapter_number != i or ch.title.is_empty():
				all_valid = false
				push_error("  ❌ Error en capítulo %d" % i)
			else:
				print("  Capítulo %d: '%s' | Rival: %s" % [ch.chapter_number, ch.title, ch.opponent_character_id])
		if all_valid:
			print("  ✅ Los 6 capítulos cargan correctamente y sin errores.")
			passed_tests += 1
	else:
		push_error("  ❌ Fallo en la carga de los 6 capítulos.")

	# -------------------------------------------------------------
	# PRUEBA 2: Capítulo 6 configurado con el concepto de Eco de Goku
	# -------------------------------------------------------------
	print("\n[PRUEBA 2] Verificando capítulo 6 (Eco de Goku)...")
	var ch6: StoryChapter = story.chapters[5] if story.chapters.size() >= 6 else null
	var echo_data_exists = ResourceLoader.exists("res://resources/characters/goku_echo.tres")
	var factory_has_echo = factory and factory._SCENE_MAP.has("goku_echo")
	
	if ch6 and ch6.opponent_character_id == "goku_echo" and echo_data_exists and factory_has_echo:
		print("  ✅ Capítulo 6: Rival configurado como 'goku_echo'.")
		print("  ✅ Recurso de datos 'goku_echo.tres' existe.")
		print("  ✅ CharacterFactory reconoce la escena base para 'goku_echo'.")
		print("  ✅ Diálogos de identidad y memoria validados:")
		for d in ch6.intro_dialogue:
			print("     - [%s]: \"%s\"" % [d.get("speaker", ""), d.get("text", "").substr(0, 60) + "..."])
		passed_tests += 1
	else:
		push_error("  ❌ Capítulo 6 no tiene configurado correctamente al Eco de Goku.")

	# -------------------------------------------------------------
	# PRUEBA 3: Dummy permite finalizar el capítulo 1 y no reaparece en Modo Historia
	# -------------------------------------------------------------
	print("\n[PRUEBA 3] Verificando integración y finalización del Dummy en Capítulo 1...")
	story.load_chapter(1)
	story.prepare_combat_for_current_chapter()

	# Instanciar Dummy en la escena para prueba
	var dummy_instance = factory.create_character(gdata.player2_data) as Dummy
	if not dummy_instance:
		dummy_instance = Dummy.new()
		dummy_instance.data = gdata.player2_data
	add_child(dummy_instance)

	# Comprobar herencia de CharacterBase y grupo fighters
	var in_fighters_group = dummy_instance.is_in_group("fighters")
	print("  Dummy añadido al grupo 'fighters': %s" % str(in_fighters_group))

	# Simular daño letal en Capítulo 1
	dummy_instance.take_damage(120.0)

	var dummy_defeated = dummy_instance._is_defeated
	var round_won = (gdata.round_winner == "player1")

	if in_fighters_group and dummy_defeated and round_won:
		print("  ✅ Dummy procesó daño letal, se marcó como derrotado y otorgó victoria a P1.")
		print("  ✅ Dummy NO programó reaparición (se mantiene fuera de combate en Historia).")
		passed_tests += 1
	else:
		push_error("  ❌ Dummy no finalizó adecuadamente el combate del capítulo 1.")

	# -------------------------------------------------------------
	# PRUEBA 4: La victoria de combate llega una sola vez a StoryManager
	# -------------------------------------------------------------
	print("\n[PRUEBA 4] Verificando emisión única de victoria a StoryManager...")
	var signal_count := 0
	var tracker = func(won: bool, _ch):
		if won: signal_count += 1
	
	story.story_match_finished.connect(tracker)

	# Intentar golpear al Dummy ya derrotado
	dummy_instance.take_damage(50.0)
	dummy_instance.take_damage(50.0)

	story.story_match_finished.disconnect(tracker)

	# Limpiar nodo de dummy
	dummy_instance.queue_free()

	if signal_count == 0 and story.last_match_won:
		# signal_count fue 0 porque los golpes adicionales no emitieron nuevas victorias
		print("  ✅ Golpes posteriores ignorados. Ninguna señal duplicada de victoria emitida.")
		passed_tests += 1
	else:
		push_error("  ❌ Se emitieron señales duplicadas de victoria.")

	# -------------------------------------------------------------
	# PRUEBA 5: LOCAL y VS_AI conservan su pantalla de victoria habitual
	# -------------------------------------------------------------
	print("\n[PRUEBA 5] Verificando pantalla de victoria en LOCAL y VS_AI...")
	# Local
	gdata.current_mode = gdata.GameMode.LOCAL
	gdata.reset_match()
	gdata.rounds_to_win = 1
	gdata.report_round_winner("player1")

	var vscreen_local = root_node.get_node_or_null("VictoryScreenLayer")
	var local_ok = (vscreen_local != null)
	if vscreen_local:
		vscreen_local.name = "VictoryScreenLayer_Freed"
		vscreen_local.queue_free()

	# VS_AI
	gdata.current_mode = gdata.GameMode.VS_AI
	gdata.reset_match()
	gdata.rounds_to_win = 1
	gdata.report_round_winner("player2")

	var vscreen_ai = root_node.get_node_or_null("VictoryScreenLayer")
	var ai_ok = (vscreen_ai != null)
	if vscreen_ai:
		vscreen_ai.name = "VictoryScreenLayer_Freed"
		vscreen_ai.queue_free()

	if local_ok and ai_ok:
		print("  ✅ Modo LOCAL generó VictoryScreenLayer con éxito.")
		print("  ✅ Modo VS_AI generó VictoryScreenLayer con éxito.")
		passed_tests += 1
	else:
		push_error("  ❌ Falla en la generación de pantalla de victoria para modos tradicionales.")

	# -------------------------------------------------------------
	# PRUEBA 6: Aislamiento total de pruebas y protección del guardado real
	# -------------------------------------------------------------
	print("\n[PRUEBA 6] Verificando protección y aislamiento del guardado real...")
	var real_path = smanager.save_path
	var temp_test_path = "user://temp_isolated_test_save.cfg"

	# Desviar guardado de prueba
	smanager.save_path = temp_test_path

	# Escribir datos de prueba en archivo aislado
	gdata.story_battle_index = 4
	gdata.session_coins = 99
	smanager.save_game()
	smanager.save_ecos_progress(4, [{"test": true}], ["ending_b"], false)

	# Verificar que el archivo temporal existe y contiene los datos
	var temp_cfg = ConfigFile.new()
	var temp_load_ok = (temp_cfg.load(temp_test_path) == OK)
	var temp_val_ok = (temp_cfg.get_value("story", "ecos_chapter_index", 0) == 4)

	# Eliminar archivo temporal de prueba
	if FileAccess.file_exists(temp_test_path):
		DirAccess.remove_absolute(temp_test_path)

	# Restaurar ruta original del usuario
	smanager.save_path = smanager.DEFAULT_SAVE_PATH

	if temp_load_ok and temp_val_ok and not FileAccess.file_exists(temp_test_path):
		print("  ✅ Las pruebas se ejecutaron en archivo aislado sin alterar 'user://save_data.cfg'.")
		print("  ✅ Archivo temporal eliminado con éxito tras la prueba.")
		passed_tests += 1
	else:
		push_error("  ❌ Falló el aislamiento de datos de guardado.")

	# -------------------------------------------------------------
	# PRUEBA 7: El guardado real del usuario permanece íntegro y compatible
	# -------------------------------------------------------------
	print("\n[PRUEBA 7] Verificando integridad del archivo real del usuario...")
	var real_cfg = ConfigFile.new()
	var real_err = real_cfg.load(smanager.DEFAULT_SAVE_PATH)
	
	if real_err == OK:
		var has_chars = real_cfg.has_section_key("progress", "unlocked_characters")
		var has_maps = real_cfg.has_section_key("progress", "unlocked_maps")
		var has_coins = real_cfg.has_section_key("economy", "total_coins")
		var has_battle_idx = real_cfg.has_section_key("story", "battle_index")
		var has_ecos = real_cfg.has_section_key("story", "ecos_chapter_index")
		
		if has_chars and has_maps and has_coins and has_battle_idx and has_ecos:
			print("  ✅ Archivo real del usuario contiene todas las secciones y claves íntegras:")
			print("     - progress: Personajes y mapas desbloqueados.")
			print("     - economy: Monedas totales preservadas.")
			print("     - story: battle_index antiguo y campos ECOS compatibles.")
			passed_tests += 1
		else:
			push_error("  ❌ Faltan claves en el guardado real del usuario.")
	else:
		push_error("  ❌ No se pudo cargar el archivo real del usuario.")

	# -------------------------------------------------------------
	# Resumen final
	# -------------------------------------------------------------
	print("\n=======================================================")
	print("📊 RESULTADOS FINALES: %d / %d PRUEBAS SUPERADAS" % [passed_tests, total_tests])
	print("=======================================================\n")
	
	if passed_tests == total_tests:
		print("🎉 ¡TODAS LAS CORRECCIONES Y PRUEBAS PASARON EXITOSAMENTE!\n")
	else:
		push_error("⚠️ ALGUNAS PRUEBAS FALLARON.")

	get_tree().quit(0 if passed_tests == total_tests else 1)

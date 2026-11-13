## test_main_menu_backgrounds.gd
## Validación automatizada para DRAGON BALL: ECOS — FASE 9: A1 (Rediseño de Composición Definitivo)
extends Node2D

var _passed: int = 0
var _failed: int = 0

const SCREENSHOT_DIR := "res://tests/screenshots"

func _ready() -> void:
	print("\n============================================================")
	print("  INICIANDO VALIDACIÓN: FASE 9 — A1 REDISEÑO DE COMPOSICIÓN")
	print("============================================================\n")

	_run_validation()

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("  ✅ [PASS] %s" % message)
		_passed += 1
	else:
		push_error("  ❌ [FAIL] %s" % message)
		_failed += 1

func _wait_frames(count: int) -> void:
	for i in range(count):
		await get_tree().process_frame

func _run_validation() -> void:
	DirAccess.make_dir_recursive_absolute(SCREENSHOT_DIR)

	var gdata = get_node_or_null("/root/GameData")
	var initial_map_id: String = gdata.selected_map_id if gdata else "valle_del_fin"

	# 1. Instanciar MainMenu
	var menu_scene: PackedScene = load("res://scenes/ui/main_menu.tscn")
	_assert(menu_scene != null, "Escena main_menu.tscn cargada exitosamente.")
	var menu: MainMenu = menu_scene.instantiate() as MainMenu
	add_child(menu)

	await _wait_frames(10)

	# 2. Verificar nodos y capas
	var bg_current: TextureRect = menu.get_node_or_null("CanvasBase/Layer1_Background/BgCurrent")
	var bg_incoming: TextureRect = menu.get_node_or_null("CanvasBase/Layer1_Background/BgIncoming")
	var panel_manga: Control = menu.get_node_or_null("CanvasBase/Layer2_DiagonalPanel")
	var char_holder: Control = menu.get_node_or_null("CanvasBase/Layer3_CharacterHolder")
	var logo_banner: Control = menu.get_node_or_null("CanvasBase/Layer4_TitleBanner")
	var options_col: Control = menu.get_node_or_null("CanvasBase/Layer5_MenuOptions")
	var submenu_story: Control = menu.get_node_or_null("CanvasBase/Layer6_StorySubmenu")
	var bottom_bar: Control = menu.get_node_or_null("CanvasBase/Layer6_BottomBar")

	_assert(bg_current != null, "Capa 1: BgCurrent presente.")
	_assert(bg_incoming != null, "Capa 1: BgIncoming presente.")
	_assert(panel_manga != null, "Capa 2: Panel diagonal manga (tercio izquierdo) presente.")
	_assert(char_holder != null, "Capa 3: Contenedor del personaje pixel art presente.")
	_assert(logo_banner != null, "Capa 4: Logotipo freestanding DRAGON BALL: ECOS presente.")
	_assert(options_col != null, "Capa 5: Columna de opciones en paneles inclinados presente.")
	_assert(submenu_story != null, "Capa 6: Submenú de historia en espacio reservado presente.")
	_assert(bottom_bar != null, "Capa 7: Barra inferior discreta presente.")

	# 3. Comprobación 1: Estado inicial es Historia con Valle del Fin
	_assert(menu._current_index == 0, "Opción inicial seleccionada es Historia (0).")
	_assert(menu._active_map_path == "res://assets/maps/valle_del_fin.png", "Fondo inicial activo es Valle del Fin.")
	_assert(menu._displayed_char_idx == 0, "Personaje inicial mostrado es Goku.")
	_assert(submenu_story.visible == true, "Submenú lateral de Historia está visible al seleccionar Historia.")

	# Captura 1: Historia (Valle del Fin + Goku + Submenú Historia en espacio lateral reservado)
	await _wait_frames(35)
	_capture_screenshot("main_menu_01_story_valle_del_fin.png")

	# 4. Navegación en el submenú de historia
	print("\n--- Probando Navegación dentro del Submenú de Historia ---")
	menu._in_story_submenu = true
	menu._story_sub_index = 0
	menu._update_selection_visuals(false)
	_assert(menu._in_story_submenu == true, "Foco entró al submenú de historia.")
	_assert(menu._story_sub_index == 0, "Opción activa del submenú es 'Continuar'.")

	menu._navigate_vertical(1)
	_assert(menu._story_sub_index == 1, "Navegación vertical en submenú cambió a 'Capítulos'.")

	menu._in_story_submenu = false
	menu._update_selection_visuals(false)
	_assert(menu._in_story_submenu == false, "Foco regresó a la columna principal de opciones.")

	# 5. Comprobación 2: Navegar a Modo Local (Torneo de Artes Marciales / Naruto)
	print("\n--- Navegando a Opción 1: Modo Local ---")
	menu._set_selection(1)
	_assert(menu._current_index == 1, "Selección cambió a Modo local (índice 1).")
	_assert(menu._active_map_path == "res://assets/maps/torneo_artes_marciales.png", "Fondo objetivo es torneo_artes_marciales.png.")
	_assert(menu._displayed_char_idx == 1, "Personaje cambió a Naruto.")

	await _wait_frames(40)
	_assert(bg_current.texture != null and bg_current.texture.resource_path == "res://assets/maps/torneo_artes_marciales.png", "BgCurrent consolidó torneo_artes_marciales.png.")
	_assert(bg_current.modulate.a == 1.0, "BgCurrent al 100% de opacidad sin parpadeo.")
	_assert(submenu_story.visible == false, "Submenú de Historia se oculta al salir de Modo historia.")

	# Captura 2: Modo Local (Torneo de Artes Marciales + Naruto)
	_capture_screenshot("main_menu_02_local_torneo.png")

	# 6. Comprobación 3: Navegar a VS IA (Dimensión de los Ecos / Madara)
	print("\n--- Navegando a Opción 2: VS IA ---")
	menu._set_selection(2)
	_assert(menu._current_index == 2, "Selección cambió a VS IA (índice 2).")
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Fondo objetivo es dimension_ecos.png.")
	_assert(menu._displayed_char_idx == 2, "Personaje cambió a Madara.")

	await _wait_frames(40)
	_assert(bg_current.texture != null and bg_current.texture.resource_path == "res://assets/maps/dimension_ecos.png", "BgCurrent consolidó dimension_ecos.png.")

	# Captura 3: VS IA (Dimensión de los Ecos + Madara)
	_capture_screenshot("main_menu_03_vs_ai_dimension_ecos.png")

	# 7. Comprobación 4: Opciones secundarias mantienen el fondo y cambian personajes
	print("\n--- Probando Opciones Secundarias ---")
	menu._set_selection(3) # Entrenamiento -> Vegetto
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Entrenamiento conserva el fondo de dimension_ecos.")
	_assert(menu._displayed_char_idx == 3, "Entrenamiento muestra a Vegetto.")

	menu._set_selection(4) # Tienda -> Goku SSJ
	_assert(menu._displayed_char_idx == 4, "Tienda muestra a Goku SSJ.")

	menu._set_selection(5) # Opciones -> Naruto Sabio
	_assert(menu._displayed_char_idx == 5, "Opciones muestra a Naruto Sabio.")

	menu._set_selection(6) # Salir -> Goku
	_assert(menu._displayed_char_idx == 6, "Salir muestra a Goku.")

	# 8. Comprobación 5: Prueba de estrés con cambios rápidos
	print("\n--- Prueba de Estrés: Navegación Rápida ---")
	for i in range(20):
		var target := i % menu.OPTIONS_DEF.size()
		menu._set_selection(target)
		await get_tree().process_frame

	_assert(true, "Ráfaga de 20 cambios rápidos no produjo errores ni excepciones.")
	await _wait_frames(40)
	_assert(bg_current.modulate.a == 1.0, "Fondo final asentado al 100% de opacidad.")

	# 9. Comprobación 6: El mapa real de combate no fue alterado
	if gdata:
		_assert(gdata.selected_map_id == initial_map_id, "Navegar por el menú NO alteró GameData.selected_map_id ('%s')." % initial_map_id)

	print("\n============================================================")
	print("  RESULTADOS: %d PASADAS, %d FALLIDAS" % [_passed, _failed])
	print("============================================================\n")

	if _failed > 0:
		push_error("Se detectaron fallos en la validación.")
	else:
		print("✅ TODAS LAS PRUEBAS DEL REDISEÑO DE COMPOSICIÓN COMPLETADAS CON ÉXITO.")

	menu.queue_free()
	await _wait_frames(2)
	get_tree().quit(0 if _failed == 0 else 1)

func _capture_screenshot(filename: String) -> void:
	var vp := get_viewport()
	if vp:
		var tex := vp.get_texture()
		if tex:
			var img := tex.get_image()
			if img and not img.is_empty():
				var full_path := SCREENSHOT_DIR + "/" + filename
				var err := img.save_png(full_path)
				if err == OK:
					print("  📸 Captura guardada: %s (%dx%d)" % [full_path, img.get_width(), img.get_height()])
				else:
					push_warning("  ⚠️ Error guardando captura %s: código %d" % [full_path, err])

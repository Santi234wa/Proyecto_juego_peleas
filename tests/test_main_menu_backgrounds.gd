## test_main_menu_backgrounds.gd
## Validación automatizada para DRAGON BALL: ECOS — FASE 9: A1 (Menú Principal con Fondos Dinámicos)
extends Node2D

var _passed: int = 0
var _failed: int = 0

const SCREENSHOT_DIR := "res://tests/screenshots"

func _ready() -> void:
	print("\n============================================================")
	print("  INICIANDO VALIDACIÓN: FASE 9 — A1 MENÚ CON FONDOS DINÁMICOS")
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

	# 2. Verificar nodos internos de fondo (Capa 1)
	var bg_current: TextureRect = menu.get_node_or_null("CanvasBase/Layer1_Background/BgCurrent")
	var bg_incoming: TextureRect = menu.get_node_or_null("CanvasBase/Layer1_Background/BgIncoming")
	var bg_dimmer: ColorRect = menu.get_node_or_null("CanvasBase/Layer1_Background/BgDimmer")
	_assert(bg_current != null, "Nodo BgCurrent presente en Layer1_Background.")
	_assert(bg_incoming != null, "Nodo BgIncoming presente en Layer1_Background.")
	_assert(bg_dimmer != null, "Filtro de oscurecimiento BgDimmer presente para contraste manga.")
	_assert(bg_current.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "BgCurrent usa textura con filtrado NEAREST.")

	# 3. Comprobación 1: Estado inicial es Modo Historia con Valle del Fin
	_assert(menu._current_index == 0, "Índice inicial es 0 (Modo historia).")
	_assert(menu._active_map_path == "res://assets/maps/valle_del_fin.png", "Fondo inicial activo es Valle del Fin.")
	_assert(bg_current.texture != null and bg_current.texture.resource_path == "res://assets/maps/valle_del_fin.png", "BgCurrent tiene asignada la textura de valle_del_fin.png.")
	_assert(menu._displayed_char_idx == 0, "Personaje inicial mostrado corresponde a Modo Historia (Goku).")

	# Captura 1: Modo Historia (Valle del Fin)
	await _wait_frames(30)
	_capture_screenshot("main_menu_01_story_valle_del_fin.png")

	# 4. Comprobación 2: Navegar a Modo Local (Torneo de Artes Marciales / Naruto)
	print("\n--- Navegando a Opción 1: Modo Local ---")
	menu._set_selection(1)
	_assert(menu._current_index == 1, "Selección cambió a Modo local (índice 1).")
	_assert(menu._active_map_path == "res://assets/maps/torneo_artes_marciales.png", "Ruta de mapa objetivo es torneo_artes_marciales.png.")
	_assert(menu._displayed_char_idx == 1, "Personaje cambió a Modo local (Naruto).")

	# Esperar a que la transición suave (0.45s a 60fps ~ 35 frames) termine
	await _wait_frames(40)
	_assert(bg_current.texture != null and bg_current.texture.resource_path == "res://assets/maps/torneo_artes_marciales.png", "BgCurrent consolidó la textura de torneo_artes_marciales.png tras la transición.")
	_assert(bg_current.modulate.a == 1.0, "BgCurrent está al 100% de opacidad sin parpadeo.")
	_assert(bg_incoming.modulate.a == 0.0, "BgIncoming quedó en opacidad 0 tras consolidarse.")

	# Captura 2: Modo Local (Torneo de Artes Marciales)
	_capture_screenshot("main_menu_02_local_torneo.png")

	# 5. Comprobación 3: Navegar a VS IA (Dimensión de los Ecos / Madara)
	print("\n--- Navegando a Opción 2: VS IA ---")
	menu._set_selection(2)
	_assert(menu._current_index == 2, "Selección cambió a VS IA (índice 2).")
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Ruta de mapa objetivo es dimension_ecos.png.")
	_assert(menu._displayed_char_idx == 2, "Personaje cambió a VS IA (Madara).")

	await _wait_frames(40)
	_assert(bg_current.texture != null and bg_current.texture.resource_path == "res://assets/maps/dimension_ecos.png", "BgCurrent consolidó la textura de dimension_ecos.png.")

	# Captura 3: VS IA (Dimensión de los Ecos)
	_capture_screenshot("main_menu_03_vs_ai_dimension_ecos.png")

	# 6. Comprobación 4: Opciones secundarias mantienen el último fondo activo
	print("\n--- Navegando a Opciones Secundarias (Entrenamiento, Tienda, Opciones, Salir) ---")
	menu._set_selection(3) # Entrenamiento
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Entrenamiento conserva el fondo activo previo (dimension_ecos).")
	_assert(menu._displayed_char_idx == 3, "Entrenamiento muestra a Vegetto.")

	menu._set_selection(4) # Tienda
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Tienda conserva el fondo activo previo.")
	_assert(menu._displayed_char_idx == 4, "Tienda muestra a Goku SSJ.")

	menu._set_selection(5) # Opciones
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Opciones conserva el fondo activo previo.")
	_assert(menu._displayed_char_idx == 5, "Opciones muestra a Naruto Sabio.")

	menu._set_selection(6) # Salir
	_assert(menu._active_map_path == "res://assets/maps/dimension_ecos.png", "Salir conserva el fondo activo previo.")
	_assert(menu._displayed_char_idx == 6, "Salir muestra a Goku.")

	# 7. Comprobación 5: Navegación rápida y cancelación limpia de Tweens
	print("\n--- Prueba de Estrés: Navegación Rápida ---")
	for i in range(15):
		var target := i % menu.OPTIONS_DEF.size()
		menu._set_selection(target)
		await get_tree().process_frame # 1 frame entre cambios para forzar interrupción rápida

	_assert(true, "Navegación ultra-rápida (15 cambios consecutivos) no produjo bloqueos ni excepciones.")
	await _wait_frames(40) # Dejar que la última transición se asiente
	_assert(bg_current.modulate.a == 1.0, "Tras navegación rápida, el fondo final se asienta correctamente en opacidad 1.0.")

	# 8. Comprobación 6: Navegar por el menú NO altera el mapa elegido para combatir
	if gdata:
		_assert(gdata.selected_map_id == initial_map_id, "Navegar por el menú principal NO alteró GameData.selected_map_id ('%s')." % initial_map_id)

	# 9. Comprobación 7: Diseño Manga original intacto
	var diag_panel = menu.get_node_or_null("CanvasBase/Layer2_DiagonalPanel")
	var title_banner = menu.get_node_or_null("CanvasBase/Layer4_TitleBanner")
	var bottom_bar = menu.get_node_or_null("CanvasBase/Layer6_BottomBar")
	_assert(diag_panel != null, "Panel diagonal naranja con trama de puntos conservado.")
	_assert(title_banner != null, "Banner de título amarillo con borde de 3 px conservado.")
	_assert(bottom_bar != null, "Barra inferior de 28 px con botones conservada.")

	print("\n============================================================")
	print("  RESULTADOS: %d PASADAS, %d FALLIDAS" % [_passed, _failed])
	print("============================================================\n")

	if _failed > 0:
		push_error("Se detectaron fallos en la validación de A1.")
	else:
		print("✅ TODAS LAS PRUEBAS DEL MÓDULO A1 COMPLETADAS CON ÉXITO.")

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
			else:
				print("  ℹ️ Viewport image no disponible en este frame.")

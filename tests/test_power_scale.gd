## test_power_scale.gd
## Validación completa del Sistema Definitivo de Escala de Poder y Mejoras Visuales ECOS
extends Node

var total_passed: int = 0
var total_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("⚡ SISTEMA DEFINITIVO DE ESCALA DE PODER — PRUEBAS DE BALANCE")
	print("=======================================================\n")

	_test_power_scale_stats()
	_test_goku_ssj_visuals_and_mechanics()
	_test_madara_sharingan_visuals_and_mechanics()
	_test_naruto_sage_visuals_and_mechanics()
	_test_vegetto_boss_integrity()
	_test_ki_restrictions_on_specials()
	_test_ai_capabilities()

	print("\n=======================================================")
	print("RESUMEN DE PRUEBAS DE ESCALA DE PODER:")
	print("  Pasadas: %d" % total_passed)
	print("  Falladas: %d" % total_failed)
	print("=======================================================\n")

	if total_failed == 0:
		print(">>> BALANCE DE PODER Y MEJORAS VISUALES 100% VALIDADAS <<<")
	else:
		push_error("Se detectaron fallos en la escala de poder.")

	get_tree().quit(0 if total_failed == 0 else 1)

func _assert(cond: bool, msg: String) -> void:
	if cond:
		total_passed += 1
		print("  ✅ [PASS] %s" % msg)
	else:
		total_failed += 1
		print("  ❌ [FAIL] %s" % msg)

func _test_power_scale_stats() -> void:
	print("--- 1. Jerarquía de Poder y Estadísticas Base ---")
	var v_data = load("res://resources/characters/vegetto.tres") as CharacterData
	var g_data = load("res://resources/characters/goku.tres") as CharacterData
	var m_data = load("res://resources/characters/madara.tres") as CharacterData
	var n_data = load("res://resources/characters/naruto.tres") as CharacterData

	# 1. Vegetto — S+
	_assert(v_data.max_health == 120.0, "Vegetto Vida = 120 (S+)")
	_assert(v_data.move_speed == 215.0, "Vegetto Velocidad = 215 (S+)")
	_assert(v_data.damage_basic == 14.0, "Vegetto Daño básico = 14 (S+)")
	_assert(v_data.damage_special == 28.0, "Vegetto Daño especial = 28 (S+)")
	_assert(v_data.transform_name == "", "Vegetto no posee transformación (poder base supremo)")

	# 2. Goku — S
	_assert(g_data.max_health == 110.0, "Goku Vida = 110 (S)")
	_assert(g_data.move_speed == 200.0, "Goku Velocidad = 200 (S)")
	_assert(g_data.damage_basic == 11.0, "Goku Daño básico = 11 (S)")
	_assert(g_data.damage_special == 24.0, "Goku Daño especial = 24 (S)")

	# 3. Madara — A+
	_assert(m_data.max_health == 105.0, "Madara Vida = 105 (A+)")
	_assert(m_data.move_speed == 195.0, "Madara Velocidad = 195 (A+)")
	_assert(m_data.damage_basic == 10.0, "Madara Daño básico = 10 (A+)")
	_assert(m_data.damage_special == 22.0, "Madara Daño especial = 22 (A+)")

	# 4. Naruto — A
	_assert(n_data.max_health == 100.0, "Naruto Vida = 100 (A)")
	_assert(n_data.move_speed == 210.0, "Naruto Velocidad = 210 (A, ágil)")
	_assert(n_data.damage_basic == 9.0, "Naruto Daño básico = 9 (A)")
	_assert(n_data.damage_special == 20.0, "Naruto Daño especial = 20 (A)")

	# Comparativas de Jerarquía
	_assert(v_data.damage_basic > g_data.damage_basic, "Vegetto supera a Goku en daño base")
	_assert(g_data.damage_basic > m_data.damage_basic, "Goku supera a Madara en daño base")
	_assert(m_data.damage_basic > n_data.damage_basic, "Madara supera a Naruto en daño base")
	_assert(n_data.move_speed > g_data.move_speed, "Naruto supera a Goku y Madara en agilidad/velocidad")

func _test_goku_ssj_visuals_and_mechanics() -> void:
	print("\n--- 2. Goku: Super Saiyan y Mejoras Visuales ECOS ---")
	var g_data = load("res://resources/characters/goku.tres") as CharacterData
	var goku = CharacterFactory.create_character(g_data)
	add_child(goku)

	var trans_state = goku.state_machine.get_node_or_null("Transforming")
	_assert(trans_state is EcosGokuTransformingState, "Goku usa EcosGokuTransformingState")

	# Probar transformación SSJ
	goku.current_energy = 50.0
	goku.begin_transform()
	_assert(goku.is_transforming, "Goku inicia transformación en SSJ")
	goku.finish_transform()
	_assert(goku.is_transformed, "Goku está transformado en SSJ")

	var eff_dmg = goku.get_effective_damage(g_data.damage_basic)
	_assert(eff_dmg > 15.0, "Goku en SSJ alcanza daño competitivo con Vegetto (15.95 dmg)")

	goku.queue_free()

func _test_madara_sharingan_visuals_and_mechanics() -> void:
	print("\n--- 3. Madara: Sharingan y Anillo Ocular ECOS ---")
	var m_data = load("res://resources/characters/madara.tres") as CharacterData
	var madara = CharacterFactory.create_character(m_data)
	add_child(madara)

	var trans_state = madara.state_machine.get_node_or_null("Transforming")
	_assert(trans_state is EcosMadaraTransformingState, "Madara usa EcosMadaraTransformingState")
	_assert(madara.state_machine.get_node("Attack") is MadaraAttackState, "Madara conserva combo táctico de 3 golpes")

	madara.current_energy = 40.0
	madara.begin_transform()
	_assert(madara.is_transforming, "Madara activa el despertar del Sharingan")
	madara.finish_transform()
	_assert(madara.is_transformed, "Madara despierta el Sharingan")

	var eff_dmg = madara.get_effective_damage(m_data.damage_basic)
	_assert(eff_dmg == 14.5, "Sharingan incrementa daño a 14.5 (10.0 * 1.45)")

	madara.queue_free()

func _test_naruto_sage_visuals_and_mechanics() -> void:
	print("\n--- 4. Naruto: Modo Sabio y Aro de Chakra Natural ECOS ---")
	var n_data = load("res://resources/characters/naruto.tres") as CharacterData
	var naruto = CharacterFactory.create_character(n_data)
	add_child(naruto)

	var trans_state = naruto.state_machine.get_node_or_null("Transforming")
	_assert(trans_state is EcosNarutoTransformingState, "Naruto usa EcosNarutoTransformingState")

	naruto.current_energy = 50.0
	naruto.begin_transform()
	_assert(naruto.is_transforming, "Naruto inicia acumulación de energía natural")
	naruto.finish_transform()
	_assert(naruto.is_transformed, "Naruto entra en Modo Sabio")

	var eff_spd = naruto.get_effective_speed()
	_assert(eff_spd == 210.0 * 1.4, "Naruto en Modo Sabio es el personaje más veloz del combate (294 px/s)")

	naruto.queue_free()

func _test_vegetto_boss_integrity() -> void:
	print("\n--- 5. Vegetto: Integridad de Jefe en Capítulo 4 ---")
	var chap_4 = load("res://resources/story/chapter_04.tres") as StoryChapter
	_assert(chap_4 != null, "Capítulo 4 existe")
	_assert(chap_4.opponent_character_id == "vegetto", "Rival del Capítulo 4 es Vegetto")
	_assert(chap_4.ai_difficulty == 2, "Dificultad de Vegetto es Máxima (Difícil / Nivel 2)")

	var v_data = load("res://resources/characters/vegetto.tres") as CharacterData
	_assert(v_data.max_health == 120.0, "Salud de Vegetto se mantiene íntegra al 100% sin nerfs artificiales")

func _test_ki_restrictions_on_specials() -> void:
	print("\n--- 6. Restricciones de Ki en Ataques Especiales ---")
	var g_data = load("res://resources/characters/goku.tres") as CharacterData
	var goku = CharacterFactory.create_character(g_data)
	add_child(goku)

	goku.current_energy = 10.0 # Menos de 20 Ki
	goku.state_machine.transition_to("Special")
	_assert(goku.state_machine.current_state.name == "Idle", "Ataque especial bloqueado cuando Ki < 20")
	_assert(goku.current_energy == 10.0, "No se consumió Ki por ataque fallido")

	goku.queue_free()

func _test_ai_capabilities() -> void:
	print("\n--- 7. Comportamiento de Inteligencia Artificial ---")
	var g_data = load("res://resources/characters/goku.tres") as CharacterData
	var char_host = CharacterFactory.create_character(g_data)
	var ai = EnemyAI.new()
	char_host.add_child(ai)
	add_child(char_host)
	_assert(ai.get("_ultimate_chance") != null, "IA tiene sensor de Ultimate")
	_assert(ai.get("_transform_chance") != null, "IA tiene sensor de Transformación")
	char_host.queue_free()

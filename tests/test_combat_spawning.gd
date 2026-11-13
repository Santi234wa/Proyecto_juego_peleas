extends Node

const MadaraClass = preload("res://scripts/characters/madara.gd")
const NarutoClass = preload("res://scripts/characters/naruto.gd")
const GokuClass = preload("res://scripts/characters/goku.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("⚔️ INICIANDO PRUEBAS DE SPAWN DINÁMICO EN MAPA DE COMBATE")
	print("=======================================================\n")

	test_01_spawn_madara_vs_naruto()
	test_02_spawn_goku_vs_madara()
	test_03_spawn_madara_mirror_match()

	print("\n=======================================================")
	print("RESUMEN DE PRUEBAS SPAWN COMBATE:")
	print("  Pasadas : %d" % tests_passed)
	print("  Falladas: %d" % tests_failed)
	print("=======================================================\n")

	if tests_failed == 0:
		print(">>> TODAS LAS PRUEBAS DE SPAWN DE COMBATE HAN PASADO EXITOSAMENTE <<<\n")
	else:
		push_error(">>> SE REPORTARON FALLOS EN LAS PRUEBAS DE SPAWN <<<")

	get_tree().quit(0 if tests_failed == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		tests_failed += 1
		print("  [FAIL] %s" % test_name)

func test_01_spawn_madara_vs_naruto() -> void:
	print("--- TEST 1: P1=Madara vs P2=Naruto ---")
	var gdata = get_node_or_null("/root/GameData")
	gdata.player1_data = load("res://resources/characters/madara.tres")
	gdata.player2_data = load("res://resources/characters/naruto.tres")
	gdata.current_mode = gdata.GameMode.LOCAL

	var map_scn = load("res://resources/characters/test_map.tscn") as PackedScene
	var map = map_scn.instantiate()
	add_child(map)

	var p1 = map.get_node_or_null("Player1")
	var p2 = map.get_node_or_null("Player2")
	var dummy = map.get_node_or_null("Dummy")

	assert_true(p1 != null and p1 is MadaraClass, "Jugador 1 es Madara")
	assert_true(p2 != null and p2 is NarutoClass, "Jugador 2 es Naruto")
	assert_true(dummy == null, "NO existe muñeco Dummy en el mapa de combate")
	assert_true(p1.position.x < p2.position.x, "P1 ubicado a la izquierda y P2 a la derecha")
	assert_true(p1.opponent == p2 and p2.opponent == p1, "Oponentes mutuos asignados correctamente")

	var p1_hp = map.get_node_or_null("Vida_Goku")
	var p2_hp = map.get_node_or_null("Vida_Naruto")
	if p1_hp and p1_hp._name_label:
		assert_true(p1_hp._name_label.text == "MADARA", "Barra de vida P1 muestra 'MADARA'")
	if p2_hp and p2_hp._name_label:
		assert_true(p2_hp._name_label.text == "NARUTO", "Barra de vida P2 muestra 'NARUTO'")

	map.queue_free()

func test_02_spawn_goku_vs_madara() -> void:
	print("\n--- TEST 2: P1=Goku vs P2=Madara (VS IA) ---")
	var gdata = get_node_or_null("/root/GameData")
	gdata.player1_data = load("res://resources/characters/goku.tres")
	gdata.player2_data = load("res://resources/characters/madara.tres")
	gdata.current_mode = gdata.GameMode.VS_AI

	var map_scn = load("res://resources/characters/test_map.tscn") as PackedScene
	var map = map_scn.instantiate()
	add_child(map)

	var p1 = map.get_node_or_null("Player1")
	var p2 = map.get_node_or_null("Player2")

	assert_true(p1 != null and p1 is GokuClass, "Jugador 1 es Goku")
	assert_true(p2 != null and p2 is MadaraClass, "Jugador 2 es Madara")
	assert_true(p2 != null and p2.is_ai == true, "Madara está gobernado por EnemyAI en modo VS_AI")

	var p1_hp = map.get_node_or_null("Vida_Goku")
	var p2_hp = map.get_node_or_null("Vida_Naruto")
	if p1_hp and p1_hp._name_label:
		assert_true(p1_hp._name_label.text == "GOKU", "Barra de vida P1 muestra 'GOKU'")
	if p2_hp and p2_hp._name_label:
		assert_true(p2_hp._name_label.text == "MADARA", "Barra de vida P2 muestra 'MADARA'")

	map.queue_free()

func test_03_spawn_madara_mirror_match() -> void:
	print("\n--- TEST 3: P1=Madara vs P2=Madara (Mirror Match) ---")
	var gdata = get_node_or_null("/root/GameData")
	gdata.player1_data = load("res://resources/characters/madara.tres")
	gdata.player2_data = load("res://resources/characters/madara.tres")
	gdata.current_mode = gdata.GameMode.LOCAL

	var map_scn = load("res://resources/characters/test_map.tscn") as PackedScene
	var map = map_scn.instantiate()
	add_child(map)

	var p1 = map.get_node_or_null("Player1")
	var p2 = map.get_node_or_null("Player2")

	assert_true(p1 != null and p1 is MadaraClass, "P1 es Madara")
	assert_true(p2 != null and p2 is MadaraClass, "P2 es Madara")
	assert_true(p2.modulate == gdata.player2_data.alt_tint, "P2 tiene alt_tint aplicado para diferenciarlo visualmente")

	map.queue_free()


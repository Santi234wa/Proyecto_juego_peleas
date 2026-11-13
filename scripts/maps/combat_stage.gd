## combat_stage.gd
## Controlador del mapa de combate (Modo Versus Local y VS IA).
## Instancia dinámicamente a los luchadores elegidos por P1 y P2 en GameData
## utilizando CharacterFactory, los posiciona y enlaza el HUD de combate en tiempo real.
class_name CombatStage
extends Node2D

@export var p1_spawn_pos: Vector2 = Vector2(100.0, 27.0)
@export var p2_spawn_pos: Vector2 = Vector2(720.0, 27.0)

var player1: CharacterBase = null
var player2: CharacterBase = null

func _ready() -> void:
	_cleanup_stray_fighters()
	_spawn_selected_fighters()
	_bind_combat_hud()

func _cleanup_stray_fighters() -> void:
	# Eliminar cualquier muñeco o nodo estático residual de prototipos previos
	var stray_names := [
		"Dummy", "DummyHealthBar", "goku", "naruto", "madara", "vegetto",
		"Goku", "Naruto", "Madara", "Vegetto"
	]
	for n_name in stray_names:
		var node = get_node_or_null(n_name)
		if node and is_instance_valid(node):
			node.queue_free()

	for child in get_children():
		if child is CharacterBase:
			child.queue_free()

func _spawn_selected_fighters() -> void:
	var gdata = get_node_or_null("/root/GameData")
	var factory = get_node_or_null("/root/CharacterFactory")

	var p1_data: CharacterData = gdata.player1_data if (gdata and gdata.player1_data) else null
	if not p1_data:
		p1_data = load("res://resources/characters/goku.tres")

	var p2_data: CharacterData = gdata.player2_data if (gdata and gdata.player2_data) else null
	if not p2_data:
		p2_data = load("res://resources/characters/naruto.tres")

	# 1. Instanciar Jugador 1
	if factory:
		player1 = factory.create_character(p1_data)
	if not player1:
		var scn_path := "res://scenes/characters/%s.tscn" % p1_data.id
		if ResourceLoader.exists(scn_path):
			var scn = load(scn_path) as PackedScene
			if scn: player1 = scn.instantiate()

	if player1:
		player1.name = "Player1"
		player1.player_id = 1
		player1.position = p1_spawn_pos
		player1.set_facing(true)
		add_child(player1)

	# 2. Instanciar Jugador 2 (o IA)
	if factory:
		player2 = factory.create_character(p2_data)
	if not player2:
		var scn_path := "res://scenes/characters/%s.tscn" % p2_data.id
		if ResourceLoader.exists(scn_path):
			var scn = load(scn_path) as PackedScene
			if scn: player2 = scn.instantiate()

	if player2:
		player2.name = "Player2"
		player2.player_id = 2
		player2.position = p2_spawn_pos
		player2.set_facing(false)
		if gdata and gdata.current_mode in [gdata.GameMode.VS_AI, gdata.GameMode.STORY]:
			player2.is_ai = true
		add_child(player2)

	# 3. Referencias mutuas de oponentes
	if player1 and player2:
		player1.opponent = player2
		player2.opponent = player1

	print("[CombatStage] ⚔️ Luchadores en combate: P1=%s vs P2=%s (Modo IA: %s)" % [
		p1_data.display_name if p1_data else "Goku",
		p2_data.display_name if p2_data else "Naruto",
		"SÍ" if (player2 and player2.is_ai) else "NO"
	])

func _bind_combat_hud() -> void:
	# Enlazar barras de P1
	var p1_hp = find_child("Vida_Goku", true, false)
	if not p1_hp: p1_hp = find_child("P1_HealthBar", true, false)
	if p1_hp and player1 and p1_hp.has_method("bind_character"):
		p1_hp.bind_character(player1)

	var p1_energy = find_child("GokuEnergyBar", true, false)
	if not p1_energy: p1_energy = find_child("P1_EnergyBar", true, false)
	if p1_energy and player1 and p1_energy.has_method("bind_character"):
		p1_energy.bind_character(player1)

	# Enlazar barras de P2
	var p2_hp = find_child("Vida_Naruto", true, false)
	if not p2_hp: p2_hp = find_child("P2_HealthBar", true, false)
	if p2_hp and player2 and p2_hp.has_method("bind_character"):
		p2_hp.bind_character(player2)

	var p2_energy = find_child("Chacra_Naruto", true, false)
	if not p2_energy: p2_energy = find_child("P2_EnergyBar", true, false)
	if p2_energy and player2 and p2_energy.has_method("bind_character"):
		p2_energy.bind_character(player2)


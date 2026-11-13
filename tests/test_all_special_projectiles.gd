## test_all_special_projectiles.gd
## Batería de pruebas automatizadas para los 4 ataques especiales y proyectiles:
## - Goku: Ráfaga Kamehameha Azul (GokuKamehameha)
## - Naruto: Fūton Rasenshuriken (NarutoRasenshuriken)
## - Madara: Katon Gran Bola de Fuego (MadaraFireball)
## - Vegetto: Ráfaga de Ki / Big Bang Blast (VegettoKiBlast)
extends Node

var total_passed: int = 0
var total_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("🔥 INICIANDO TEST SUITE: 4 PROYECTILES Y ATAQUES ESPECIALES")
	print("=======================================================\n")

	_test_goku_kamehameha()
	_test_naruto_rasenshuriken()
	_test_madara_fireball()
	_test_vegetto_ki_blast()
	_test_character_special_activation()

	print("\n=======================================================")
	print("RESUMEN DE PRUEBAS DE ATAQUES ESPECIALES:")
	print("  Pasadas: %d" % total_passed)
	print("  Falladas: %d" % total_failed)
	print("=======================================================\n")

	if total_failed == 0:
		print(">>> TODOS LOS 4 ATAQUES ESPECIALES FUNCIONAN A LA PERFECCIÓN <<<")
	else:
		push_error("Se detectaron fallos en las pruebas de ataques especiales.")

	get_tree().quit(0 if total_failed == 0 else 1)

func _assert(condition: bool, message: String) -> void:
	if condition:
		total_passed += 1
		print("  ✅ [PASS] %s" % message)
	else:
		total_failed += 1
		print("  ❌ [FAIL] %s" % message)
		push_error("Fallo de aserción: %s" % message)

func _test_goku_kamehameha() -> void:
	print("--- 1. Goku: Ráfaga Kamehameha Azul ---")
	var scene_path := "res://scenes/effects/goku_kamehameha.tscn"
	_assert(ResourceLoader.exists(scene_path), "Escena goku_kamehameha.tscn existe")

	var scene := load(scene_path) as PackedScene
	_assert(scene != null, "Escena goku_kamehameha.tscn se carga correctamente")
	var proj := scene.instantiate() as GokuKamehameha
	_assert(proj != null, "Instancia es de tipo GokuKamehameha")
	_assert(proj.collision_layer == 2, "Capa de colisión es 2 (Hitbox)")
	_assert(proj.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox)")
	_assert(proj.damage == 20.0, "Daño calibrado a 20.0")
	_assert(proj.speed == 520.0, "Velocidad calibrada a 520.0 px/s")

	var spr: AnimatedSprite2D = proj.get_node_or_null("AnimatedSprite2D")
	_assert(spr != null and spr.sprite_frames != null, "AnimatedSprite2D con frames presente")
	_assert(spr.sprite_frames.has_animation("fly"), "Animación 'fly' presente en Kamehameha")
	_assert(spr.sprite_frames.get_frame_count("fly") == 8, "Kamehameha tiene 8 fotogramas")

	add_child(proj)
	var pos_init = proj.position
	proj._physics_process(0.1)
	_assert(proj.position.x > pos_init.x, "Kamehameha avanza horizontalmente a la derecha")
	proj.queue_free()

func _test_naruto_rasenshuriken() -> void:
	print("\n--- 2. Naruto: Fūton Rasenshuriken ---")
	var scene_path := "res://scenes/effects/naruto_rasenshuriken.tscn"
	_assert(ResourceLoader.exists(scene_path), "Escena naruto_rasenshuriken.tscn existe")

	var scene := load(scene_path) as PackedScene
	_assert(scene != null, "Escena naruto_rasenshuriken.tscn se carga correctamente")
	var proj := scene.instantiate() as NarutoRasenshuriken
	_assert(proj != null, "Instancia es de tipo NarutoRasenshuriken")
	_assert(proj.collision_layer == 2, "Capa de colisión es 2 (Hitbox)")
	_assert(proj.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox)")
	_assert(proj.damage == 22.0, "Daño calibrado a 22.0")
	_assert(proj.speed == 470.0, "Velocidad calibrada a 470.0 px/s")

	var spr: AnimatedSprite2D = proj.get_node_or_null("AnimatedSprite2D")
	_assert(spr != null and spr.sprite_frames != null, "AnimatedSprite2D con frames presente")
	_assert(spr.sprite_frames.has_animation("fly"), "Animación 'fly' presente en Rasenshuriken")
	_assert(spr.sprite_frames.get_frame_count("fly") == 8, "Rasenshuriken tiene 8 fotogramas")

	add_child(proj)
	var pos_init = proj.position
	proj._physics_process(0.1)
	_assert(proj.position.x > pos_init.x, "Rasenshuriken avanza horizontalmente a la derecha")
	proj.queue_free()

func _test_madara_fireball() -> void:
	print("\n--- 3. Madara: Katon Gran Bola de Fuego ---")
	var scene_path := "res://scenes/effects/madara_fireball.tscn"
	_assert(ResourceLoader.exists(scene_path), "Escena madara_fireball.tscn existe")

	var scene := load(scene_path) as PackedScene
	_assert(scene != null, "Escena madara_fireball.tscn se carga correctamente")
	var proj := scene.instantiate() as MadaraFireball
	_assert(proj != null, "Instancia es de tipo MadaraFireball")
	_assert(proj.collision_layer == 2, "Capa de colisión es 2 (Hitbox)")
	_assert(proj.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox)")
	_assert(proj.damage == 22.0, "Daño calibrado a 22.0")
	_assert(proj.speed == 460.0, "Velocidad calibrada a 460.0 px/s")

	var spr: AnimatedSprite2D = proj.get_node_or_null("AnimatedSprite2D")
	_assert(spr != null and spr.sprite_frames != null, "AnimatedSprite2D con frames presente")
	_assert(spr.sprite_frames.has_animation("fly"), "Animación 'fly' presente en Bola de fuego")
	_assert(spr.sprite_frames.get_frame_count("fly") == 8, "Bola de fuego tiene 8 fotogramas completos")

	add_child(proj)
	var pos_init = proj.position
	proj._physics_process(0.1)
	_assert(proj.position.x > pos_init.x, "Bola de fuego avanza horizontalmente a la derecha")
	proj.queue_free()

func _test_vegetto_ki_blast() -> void:
	print("\n--- 4. Vegetto: Proyectil de Ki Azul ---")
	var scene_path := "res://scenes/effects/vegetto_ki_blast.tscn"
	_assert(ResourceLoader.exists(scene_path), "Escena vegetto_ki_blast.tscn existe")

	var scene := load(scene_path) as PackedScene
	_assert(scene != null, "Escena vegetto_ki_blast.tscn se carga correctamente")
	var proj := scene.instantiate() as VegettoKiBlast
	_assert(proj != null, "Instancia es de tipo VegettoKiBlast")
	_assert(proj.collision_layer == 2, "Capa de colisión es 2 (Hitbox)")
	_assert(proj.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox)")
	_assert(proj.damage == 25.0, "Daño calibrado a 25.0")
	_assert(proj.speed == 500.0, "Velocidad calibrada a 500.0 px/s")

	var spr: AnimatedSprite2D = proj.get_node_or_null("AnimatedSprite2D")
	_assert(spr != null and spr.sprite_frames != null, "AnimatedSprite2D con frames presente")
	_assert(spr.sprite_frames.has_animation("fly"), "Animación 'fly' presente en Ki de Vegetto")
	_assert(spr.sprite_frames.get_frame_count("fly") == 8, "Ki de Vegetto tiene 8 fotogramas")

	add_child(proj)
	var pos_init = proj.position
	proj._physics_process(0.1)
	_assert(proj.position.x > pos_init.x, "Ki de Vegetto avanza horizontalmente a la derecha")
	proj.queue_free()

func _test_character_special_activation() -> void:
	print("\n--- 5. Activación de Estado Especial en los 4 personajes ---")
	var goku_data = load("res://resources/characters/goku.tres") as CharacterData
	var goku = CharacterFactory.create_character(goku_data)
	_assert(goku != null, "Goku instanciado vía factory")
	add_child(goku)
	_assert(goku.state_machine != null and goku.state_machine.has_node("Special"), "Goku tiene estado 'Special' en su FSM")

	var naruto_data = load("res://resources/characters/naruto.tres") as CharacterData
	var naruto = CharacterFactory.create_character(naruto_data)
	_assert(naruto != null, "Naruto instanciado vía factory")
	add_child(naruto)
	_assert(naruto.state_machine != null and naruto.state_machine.has_node("Special"), "Naruto tiene estado 'Special' en su FSM")

	var madara_data = load("res://resources/characters/madara.tres") as CharacterData
	var madara = CharacterFactory.create_character(madara_data)
	_assert(madara != null, "Madara instanciado vía factory")
	add_child(madara)
	_assert(madara.state_machine != null and madara.state_machine.has_node("Special"), "Madara tiene estado 'Special' en su FSM")

	var vegetto_data = load("res://resources/characters/vegetto.tres") as CharacterData
	var vegetto = CharacterFactory.create_character(vegetto_data)
	_assert(vegetto != null, "Vegetto instanciado vía factory")
	add_child(vegetto)
	_assert(vegetto.state_machine != null and vegetto.state_machine.has_node("Special"), "Vegetto tiene estado 'Special' en su FSM")

	# Probar gasto de energía y transición
	goku.current_energy = 50.0
	goku.state_machine.transition_to("Special")
	_assert(goku.state_machine.current_state.name == "Special", "Goku entra en estado Special exitosamente")
	_assert(goku.current_energy == 30.0, "Goku gastó 20 Ki para su Kamehameha (50 -> 30)")

	naruto.current_energy = 50.0
	naruto.state_machine.transition_to("Special")
	_assert(naruto.state_machine.current_state.name == "Special", "Naruto entra en estado Special exitosamente")
	_assert(naruto.current_energy == 30.0, "Naruto gastó 20 Ki para su Rasenshuriken (50 -> 30)")

	madara.current_energy = 50.0
	madara.state_machine.transition_to("Special")
	_assert(madara.state_machine.current_state.name == "Special", "Madara entra en estado Special exitosamente")
	_assert(madara.current_energy == 30.0, "Madara gastó 20 Ki para su Gran Bola de Fuego (50 -> 30)")

	vegetto.current_energy = 50.0
	vegetto.state_machine.transition_to("Special")
	_assert(vegetto.state_machine.current_state.name == "Special", "Vegetto entra en estado Special exitosamente")
	_assert(vegetto.current_energy == 30.0, "Vegetto gastó 20 Ki para su Ráfaga de Ki (50 -> 30)")

	goku.queue_free()
	naruto.queue_free()
	madara.queue_free()
	vegetto.queue_free()

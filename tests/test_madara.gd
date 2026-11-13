extends Node

const MadaraClass = preload("res://scripts/characters/madara.gd")
const MadaraAttackStateClass = preload("res://scripts/states/madara_attack_state.gd")
const SharinganTransformingStateClass = preload("res://scripts/states/sharingan_transforming_state.gd")

var tests_passed: int = 0
var tests_failed: int = 0

func _ready() -> void:
	print("\n=======================================================")
	print("🥋 INICIANDO BATERÍA DE PRUEBAS TÉCNICAS: MADARA UCHIHA")
	print("=======================================================\n")

	test_01_character_data_resource()
	test_02_factory_instantiation()
	test_03_sprite_frames_and_animations()
	test_04_fsm_initial_state()
	test_05_three_hit_combo_loop()
	test_06_combo_timeout_reset()
	test_07_sharingan_transformation_lifecycle()
	test_08_unlock_and_select_integration()
	test_09_madara_attack_hit_and_knockback()
	test_10_madara_fireball_projectile()

	print("\n=======================================================")
	print("RESUMEN DE PRUEBAS MADARA:")
	print("  Pasadas : %d" % tests_passed)
	print("  Falladas: %d" % tests_failed)
	print("=======================================================\n")

	if tests_failed == 0:
		print(">>> TODAS LAS PRUEBAS DE MADARA HAN PASADO EXITOSAMENTE <<<\n")
	else:
		push_error(">>> SE REPORTARON FALLOS EN LAS PRUEBAS DE MADARA <<<")

	get_tree().quit(0 if tests_failed == 0 else 1)

func assert_true(condition: bool, test_name: String) -> void:
	if condition:
		tests_passed += 1
		print("  [PASS] %s" % test_name)
	else:
		tests_failed += 1
		print("  [FAIL] %s" % test_name)

func test_01_character_data_resource() -> void:
	print("--- TEST 1: CharacterData (madara.tres) ---")
	var data = load("res://resources/characters/madara.tres") as CharacterData
	assert_true(data != null, "El recurso madara.tres existe y es CharacterData")
	if data:
		assert_true(data.id == "madara", "ID del personaje es 'madara'")
		assert_true(data.display_name == "Madara", "Nombre en pantalla es 'Madara'")
		assert_true(data.transform_name == "Sharingan", "Transformación configurada como 'Sharingan'")
		assert_true(data.energy_cost_transform == 35.0, "Costo de transformación es 35 Ki")
		assert_true(data.transform_damage_mult == 1.45, "Multiplicador de daño es 1.45x")
		assert_true(data.transform_speed_mult == 1.35, "Multiplicador de velocidad es 1.35x")
		assert_true(data.ki_drain_per_second == 7.0, "Drenaje de Ki por segundo es 7.0")

func test_02_factory_instantiation() -> void:
	print("\n--- TEST 2: Instanciación vía CharacterFactory ---")
	var data = load("res://resources/characters/madara.tres") as CharacterData
	var char_inst = CharacterFactory.create_character(data)
	assert_true(char_inst != null, "CharacterFactory instanció a Madara correctamente")
	if char_inst:
		assert_true(char_inst is CharacterBase, "La instancia extiende de CharacterBase")
		assert_true(char_inst is MadaraClass, "La instancia es de clase Madara")
		assert_true(char_inst.data == data, "CharacterData inyectado correctamente")
		assert_true(char_inst.has_node("AnimatedSprite2D"), "Tiene AnimatedSprite2D")
		assert_true(char_inst.has_node("StateMachine"), "Tiene StateMachine")
		assert_true(char_inst.has_node("Hitbox"), "Tiene Hitbox (Area2D)")
		assert_true(char_inst.has_node("Hurtbox"), "Tiene Hurtbox (Area2D)")
		char_inst.queue_free()

func test_03_sprite_frames_and_animations() -> void:
	print("\n--- TEST 3: Animaciones y SpriteFrames ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var inst = scene.instantiate()
	add_child(inst)

	var sprite: AnimatedSprite2D = inst.get_node_or_null("AnimatedSprite2D")
	assert_true(sprite != null and sprite.sprite_frames != null, "AnimatedSprite2D y SpriteFrames válidos")
	if sprite and sprite.sprite_frames:
		var sf = sprite.sprite_frames
		assert_true(sf.has_animation("idle"), "Contiene animación 'idle'")
		assert_true(sf.has_animation("walk"), "Contiene animación 'walk'")
		assert_true(sf.has_animation("jump"), "Contiene animación 'jump'")
		assert_true(sf.has_animation("punch_1"), "Contiene animación 'punch_1'")
		assert_true(sf.has_animation("punch_2"), "Contiene animación 'punch_2'")
		assert_true(sf.has_animation("kick"), "Contiene animación 'kick'")
		assert_true(sf.has_animation("sharingan_transform"), "Contiene animación 'sharingan_transform'")
		assert_true(sf.has_animation("select_idle"), "Contiene animación 'select_idle'")
		assert_true(sf.has_animation("fireball"), "Contiene animación 'fireball' (Katon)")
		assert_true(sf.has_animation("hurt"), "Contiene animación 'hurt'")
		assert_true(sf.has_animation("ko"), "Contiene animación 'ko'")
		assert_true(sf.get_frame_count("punch_1") == 8, "punch_1 tiene 8 frames")
		assert_true(sf.get_frame_count("punch_2") == 8, "punch_2 tiene 8 frames")
		assert_true(sf.get_frame_count("kick") == 7, "kick tiene 7 frames")
		assert_true(sf.get_frame_count("sharingan_transform") == 9, "sharingan_transform tiene 9 frames")
		assert_true(sf.get_frame_count("fireball") == 6, "fireball tiene 6 frames")
		assert_true(sf.get_frame_count("hurt") == 6, "hurt tiene 6 frames")
		assert_true(sf.get_frame_count("ko") == 4, "ko tiene 4 frames")

	inst.queue_free()

func test_04_fsm_initial_state() -> void:
	print("\n--- TEST 4: Inicialización de la FSM ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var inst = scene.instantiate()
	add_child(inst)

	var sm = inst.state_machine
	assert_true(sm != null, "StateMachine inicializada")
	if sm:
		assert_true(sm.current_state != null, "Estado actual activo")
		assert_true(sm.current_state.name == "Idle", "Estado inicial es 'Idle'")
		assert_true(sm.has_node("Attack"), "Tiene nodo Attack")
		assert_true(sm.get_node("Attack") is MadaraAttackStateClass, "El nodo Attack es MadaraAttackState")
		assert_true(sm.has_node("Transforming"), "Tiene nodo Transforming")
		assert_true(sm.get_node("Transforming") is SharinganTransformingStateClass, "El nodo Transforming es SharinganTransformingState")

	inst.queue_free()

func test_05_three_hit_combo_loop() -> void:
	print("\n--- TEST 5: Secuencia del combo de 3 golpes (Punch 1 → Punch 2 → Kick → Punch 1) ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var inst = scene.instantiate()
	add_child(inst)

	var atk_state = inst.state_machine.get_node("Attack")
	var sprite: AnimatedSprite2D = inst.get_node("AnimatedSprite2D")

	# Golpe 1: Puño derecho
	atk_state.combo_step = 1
	atk_state.enter()
	assert_true(atk_state.combo_step == 1, "Paso 1 es combo_step 1")
	assert_true(atk_state._step_anim == "punch_1", "Paso 1 usa animación 'punch_1'")
	assert_true(sprite.animation == "punch_1", "Sprite reproduciendo 'punch_1'")
	assert_true(atk_state._step_damage == 8.0, "Daño del puñetazo 1 es 8.0")

	# Simular avance a Golpe 2
	atk_state._advance_combo()
	assert_true(atk_state.combo_step == 2, "Combo avanzó a combo_step 2")
	atk_state.enter()
	assert_true(atk_state._step_anim == "punch_2", "Paso 2 usa animación 'punch_2'")
	assert_true(sprite.animation == "punch_2", "Sprite reproduciendo 'punch_2'")
	assert_true(is_equal_approx(atk_state._step_damage, 8.0 * 1.15), "Daño del puñetazo 2 es 9.2 (+15%)")

	# Simular avance a Golpe 3
	atk_state._advance_combo()
	assert_true(atk_state.combo_step == 3, "Combo avanzó a combo_step 3")
	atk_state.enter()
	assert_true(atk_state._step_anim == "kick", "Paso 3 usa animación 'kick'")
	assert_true(sprite.animation == "kick", "Sprite reproduciendo 'kick'")
	assert_true(is_equal_approx(atk_state._step_damage, 8.0 * 1.65), "Daño de la patada es 13.2 (+65%)")
	assert_true(atk_state._step_knockback.y < 0, "Patada rematadora aplica impulso vertical ascendente")

	# Simular avance tras Golpe 3: Bucle de regreso a Golpe 1
	atk_state._advance_combo()
	assert_true(atk_state.combo_step == 1, "El combo reinició en bucle a combo_step 1")
	atk_state.enter()
	assert_true(atk_state._step_anim == "punch_1", "Vuelve a ejecutar puñetazo 1 en bucle")

	inst.queue_free()

func test_06_combo_timeout_reset() -> void:
	print("\n--- TEST 6: Reseteo del combo por inactividad (Timeout) ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var inst = scene.instantiate()
	add_child(inst)

	var atk_state = inst.state_machine.get_node("Attack")
	# Configurar en paso 2 pero con tiempo de último ataque viejo (> 0.85s)
	atk_state.combo_step = 2
	atk_state._last_attack_time = (Time.get_ticks_msec() / 1000.0) - 2.0
	atk_state.enter()

	assert_true(atk_state.combo_step == 1, "Combo se resetea a 1 tras superar el tiempo límite sin atacar")
	assert_true(atk_state._step_anim == "punch_1", "Ejecuta punch_1 tras el reseteo")

	inst.queue_free()

func test_07_sharingan_transformation_lifecycle() -> void:
	print("\n--- TEST 7: Ciclo completo del Despertar del Sharingan ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var inst = scene.instantiate()
	add_child(inst)

	# 1. Sin energía suficiente
	inst.current_energy = 10.0
	assert_true(not inst.can_transform(), "No puede transformarse con Ki insuficiente (10 < 35)")

	# 2. Con energía suficiente
	inst.current_energy = 50.0
	assert_true(inst.can_transform(), "Puede transformarse con 50 Ki (>= 35)")

	# 3. Iniciar transformación
	var started = inst.begin_transform()
	assert_true(started, "begin_transform() inició correctamente")
	assert_true(inst.is_transforming, "is_transforming activado")
	assert_true(inst.invulnerable, "Madara es invulnerable durante la activación")

	# 4. Culminar transformación (finish_transform)
	inst.finish_transform()
	assert_true(inst.is_transformed, "is_transformed activado")
	assert_true(not inst.is_transforming, "is_transforming desactivado")
	assert_true(not inst.invulnerable, "invulnerable desactivado tras la pose")
	assert_true(is_equal_approx(inst.get_effective_damage(10.0), 14.5), "Buff de daño x1.45 aplicado correctamente")
	assert_true(is_equal_approx(inst.get_effective_speed(), 195.0 * 1.35), "Buff de velocidad x1.35 aplicado correctamente")
	assert_true(inst._sharingan_particles != null and inst._sharingan_particles.emitting, "Partículas de aura Sharingan activadas")

	# 5. Drenaje de Ki y finalización al llegar a 0
	inst._physics_process(1.0) # Drenará 7.0 de Ki
	assert_true(is_equal_approx(inst.current_energy, 43.0), "Drenó 7 Ki en 1 segundo (50 -> 43)")

	inst.current_energy = 0.0
	inst._physics_process(0.1) # Al llegar a 0 debe terminar
	assert_true(not inst.is_transformed, "Transformación terminada automáticamente al agotarse el Ki")
	assert_true(is_equal_approx(inst.get_effective_damage(10.0), 10.0), "Daño restaurado a 1.0x")
	assert_true(inst._cooldown_timer > 0.0, "Cooldown post-transformación iniciado")
	assert_true(inst._sharingan_particles != null and not inst._sharingan_particles.emitting, "Partículas de aura Sharingan desactivadas")

	inst.queue_free()

func test_08_unlock_and_select_integration() -> void:
	print("\n--- TEST 8: Integración en GameData y Menú de Selección ---")
	assert_true(GameData.is_character_unlocked("madara"), "Madara está desbloqueado en GameData")

	var char_data = load("res://resources/characters/madara.tres") as CharacterData
	# Asignar a GameData para validar lectura de nombre
	GameData.player2_data = char_data
	var disp_name = GameData.get_character_display_name("player2")
	assert_true(disp_name == "Madara", "GameData resuelve el nombre 'Madara' correctamente")

func test_09_madara_attack_hit_and_knockback() -> void:
	print("\n--- TEST 9: Golpe efectivo y Knockback sin error de propiedad ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var madara = scene.instantiate()
	add_child(madara)

	var goku_scn = load("res://scenes/characters/goku.tscn") as PackedScene
	var goku = goku_scn.instantiate()
	add_child(goku)

	madara.position = Vector2(100, 0)
	goku.position = Vector2(115, 0)
	madara.set_facing(true)

	var atk_state = madara.state_machine.get_node("Attack")
	atk_state.combo_step = 1
	atk_state.enter()

	# Simular physics_update en el frame activo del golpe
	atk_state.physics_update(0.12)

	assert_true(atk_state._hitbox != null, "Hitbox activo")
	assert_true("knockback_vector" in atk_state._hitbox, "Hitbox tiene propiedad 'knockback_vector'")
	assert_true(atk_state._hitbox.knockback_vector.x > 0, "knockback_vector asignado con dirección positiva a la derecha")

	madara.queue_free()
	goku.queue_free()

func test_10_madara_fireball_projectile() -> void:
	print("\n--- TEST 10: Ataque Especial Katon (Gran Bola de Fuego) ---")
	var scene = load("res://scenes/characters/madara.tscn") as PackedScene
	var madara = scene.instantiate()
	add_child(madara)

	assert_true(madara.state_machine.has_node("Special"), "Estado 'Special' presente en la FSM de Madara")
	var sp_state = madara.state_machine.get_node("Special")
	assert_true(sp_state is MadaraFireballState, "Nodo Special es MadaraFireballState")

	# Probar instanciación de la bola de fuego
	var fb_scn = load("res://scenes/effects/madara_fireball.tscn") as PackedScene
	assert_true(fb_scn != null, "Escena 'madara_fireball.tscn' existe y compila")
	if fb_scn:
		var fb = fb_scn.instantiate() as Area2D
		assert_true(fb is MadaraFireball, "Instancia es de clase MadaraFireball")
		assert_true(fb.collision_layer == 2, "Capa de colisión es 2 (Hitbox)")
		assert_true(fb.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox)")
		assert_true(fb.damage == 22.0, "Daño base de la bola de fuego es 22.0")
		assert_true(fb.speed == 460.0, "Velocidad de la bola de fuego es 460.0 px/s")

		add_child(fb)
		fb._physics_process(0.1)
		assert_true(fb.position.x > 0.0, "Bola de fuego se desplaza horizontalmente hacia adelante")
		fb.queue_free()

	madara.queue_free()

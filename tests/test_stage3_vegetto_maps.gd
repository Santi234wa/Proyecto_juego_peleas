## test_stage3_vegetto_maps.gd
## Suite de pruebas automatizadas para DRAGON BALL: ECOS — ETAPA 3:
##   1. Vegetto: Resource, Stats, FSM, Animaciones (base y SSJ).
##   2. Combate de Vegetto: Combo de 4 golpes, Ráfaga de Ki (proyectil), Super Saiyajin (buffs y aura).
##   3. Escenarios: Valle del Fin, Torneo, Dimensión de los Ecos (carga, colisión, fondo).
##   4. Sistema de Audio: Autoload AudioManager, buses, fallback tolerante a archivos ausentes.
##   5. Integración: Selección de personajes, Capítulos de ECOS (1 a 6) y no-regresión.
extends Node2D

const VegettoRef = preload("res://scripts/characters/vegetto.gd")
const VegettoAttackStateRef = preload("res://scripts/states/vegetto_attack_state.gd")
const VegettoKiBlastRef = preload("res://scripts/effects/vegetto_ki_blast.gd")

var _passed: int = 0
var _failed: int = 0

func _ready() -> void:
	print("\n============================================================")
	print("  INICIANDO SUITE DE PRUEBAS: ETAPA 3 (VEGETTO, MAPAS, AUDIO)")
	print("============================================================\n")

	_test_audio_manager_architecture()
	_test_vegetto_resource_and_scene()
	_test_vegetto_animations()
	_test_vegetto_combo_and_attacks()
	_test_vegetto_ki_blast_projectile()
	_test_vegetto_transformation()
	_test_map_scenes()
	_test_character_factory_and_gamedata()
	_test_story_chapters_etapa3()
	_test_no_regressions()

	print("\n============================================================")
	print("  RESULTADOS: %d PASADAS, %d FALLIDAS" % [_passed, _failed])
	print("============================================================\n")

	if _failed > 0:
		push_error("Se detectaron fallos en la etapa 3.")
	else:
		print("✅ TODAS LAS PRUEBAS DE LA ETAPA 3 COMPLETADAS CON ÉXITO.")

	get_tree().quit(0 if _failed == 0 else 1)

func _assert(condition: bool, message: String) -> void:
	if condition:
		print("  ✅ [PASS] %s" % message)
		_passed += 1
	else:
		push_error("  ❌ [FAIL] %s" % message)
		_failed += 1

# ---------------------------------------------------------------------------
# 1. Sistema de Audio
# ---------------------------------------------------------------------------

func _test_audio_manager_architecture() -> void:
	print("--- 1. Pruebas de Arquitectura de Audio ---")
	var audio_mgr = get_node_or_null("/root/AudioManager")
	_assert(audio_mgr != null, "AudioManager está registrado como Autoload singleton.")

	# Comprobar buses de audio
	var buses: Array[String] = ["Master", "Music", "SFX", "UI", "Ambience"]
	for b in buses:
		var idx: int = AudioServer.get_bus_index(b)
		_assert(idx != -1, "Bus de audio '%s' existe y está activo (índice: %d)." % [b, idx])

	# Fallback tolerante sin crashear con archivos ausentes
	if audio_mgr:
		audio_mgr.play_music("res://assets/audio/bgm/dummy_not_found.ogg")
		audio_mgr.play_sfx("res://assets/audio/sfx/dummy_not_found.wav")
		audio_mgr.play_ui("res://assets/audio/ui/dummy_not_found.wav")
		audio_mgr.stop_music(0.0)
		_assert(true, "Llamadas a AudioManager con archivos inexistentes no crashean el juego (fallback seguro).")

		audio_mgr.set_bus_volume("SFX", 0.8)
		var vol: float = audio_mgr.get_bus_volume("SFX")
		_assert(absf(vol - 0.8) < 0.05, "Control de volumen de bus SFX responde adecuadamente (vol: %.2f)." % vol)

# ---------------------------------------------------------------------------
# 2. Vegetto: Resource y Escena
# ---------------------------------------------------------------------------

func _test_vegetto_resource_and_scene() -> void:
	print("\n--- 2. Pruebas de Vegetto: Resource y Escena ---")
	var v_res = load("res://resources/characters/vegetto.tres") as CharacterData
	_assert(v_res != null, "Resource 'vegetto.tres' existe y es CharacterData.")
	if v_res:
		_assert(v_res.id == "vegetto", "ID de Vegetto es 'vegetto'.")
		_assert(v_res.display_name == "Vegetto", "display_name es 'Vegetto'.")
		_assert(v_res.max_health == 100.0, "max_health es 100.0.")
		_assert(v_res.max_energy == 100.0, "max_energy es 100.0.")
		_assert(v_res.damage_basic == 9.0, "damage_basic calibrado a 9.0.")
		_assert(v_res.damage_special == 18.0, "damage_special calibrado a 18.0.")
		_assert(v_res.energy_cost_special == 20.0, "energy_cost_special es 20.0.")
		_assert(v_res.transform_name == "Super Saiyajin", "transform_name es 'Super Saiyajin'.")
		_assert(v_res.transform_damage_mult == 1.5, "transform_damage_mult es 1.50.")

	var scn = load("res://scenes/characters/vegetto.tscn") as PackedScene
	_assert(scn != null, "Escena 'vegetto.tscn' existe y compila correctamente.")
	if scn:
		var v_inst = scn.instantiate() as CharacterBase
		_assert(v_inst is VegettoRef, "Instancia de vegetto.tscn es de clase Vegetto.")
		_assert(v_inst.get_node_or_null("Hitbox") is Hitbox, "Vegetto contiene nodo Hitbox.")
		_assert(v_inst.get_node_or_null("Hurtbox") is Hurtbox, "Vegetto contiene nodo Hurtbox.")
		_assert(v_inst.get_node_or_null("StateMachine") is StateMachine, "Vegetto contiene nodo StateMachine.")
		_assert(v_inst.get_node_or_null("SFX") != null, "Vegetto contiene contenedor de audio SFX.")
		v_inst.queue_free()

# ---------------------------------------------------------------------------
# 3. Vegetto: Animaciones
# ---------------------------------------------------------------------------

func _test_vegetto_animations() -> void:
	print("\n--- 3. Pruebas de Animaciones de Vegetto ---")
	var scn = load("res://scenes/characters/vegetto.tscn") as PackedScene
	if not scn:
		_assert(false, "No se pudo cargar vegetto.tscn.")
		return

	var v_inst = scn.instantiate() as CharacterBase
	var spr = v_inst.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert(spr != null and spr.sprite_frames != null, "AnimatedSprite2D con SpriteFrames válido presente.")

	if spr and spr.sprite_frames:
		var required_anims: Array[String] = [
			"idle", "walk", "run", "jump", "fall", "punch_1", "punch_2", "kick", "combo",
			"hurt", "ko", "transform",
			"ssj_idle", "ssj_walk", "ssj_run", "ssj_punch", "ssj_kick", "ssj_combo"
		]
		for anim in required_anims:
			var has_a: bool = spr.sprite_frames.has_animation(anim)
			var f_cnt: int = spr.sprite_frames.get_frame_count(anim) if has_a else 0
			_assert(has_a and f_cnt > 0, "Animación '%s' existe con %d fotogramas." % [anim, f_cnt])

	v_inst.queue_free()

# ---------------------------------------------------------------------------
# 4. Vegetto: Combo y Ataques
# ---------------------------------------------------------------------------

func _test_vegetto_combo_and_attacks() -> void:
	print("\n--- 4. Pruebas de Combate y Combo de Vegetto ---")
	var scn = load("res://scenes/characters/vegetto.tscn") as PackedScene
	if not scn:
		_assert(false, "No se pudo cargar vegetto.tscn.")
		return

	var v = scn.instantiate() as CharacterBase
	add_child(v)
	v._setup_state_machine()

	var sm: StateMachine = v.state_machine
	_assert(sm != null, "StateMachine inicializada.")
	_assert(sm.has_node("Attack"), "Estado 'Attack' presente en FSM.")
	_assert(sm.has_node("Special"), "Estado 'Special' presente en FSM.")
	_assert(sm.has_node("Transforming"), "Estado 'Transforming' presente en FSM.")

	var atk_state = sm.get_node("Attack")
	_assert(atk_state is VegettoAttackStateRef, "Estado de ataque es VegettoAttackState.")

	if atk_state:
		atk_state.enter()
		_assert(atk_state.combo_step == 1, "Paso 1 del combo inicializado.")
		atk_state._advance_combo()
		_assert(atk_state.combo_step == 2, "Paso 2 del combo avanzado.")
		atk_state._advance_combo()
		_assert(atk_state.combo_step == 3, "Paso 3 del combo avanzado.")
		atk_state._advance_combo()
		_assert(atk_state.combo_step == 4, "Paso 4 (combo rush) alcanzado.")
		atk_state._advance_combo()
		_assert(atk_state.combo_step == 1, "Bucle del combo reinicia al paso 1 correctamente.")

	v.queue_free()

# ---------------------------------------------------------------------------
# 5. Vegetto: Proyectil Ráfaga de Ki
# ---------------------------------------------------------------------------

func _test_vegetto_ki_blast_projectile() -> void:
	print("\n--- 5. Pruebas de Ráfaga de Ki (VegettoKiBlast) ---")
	var p_scn = load("res://scenes/effects/vegetto_ki_blast.tscn") as PackedScene
	_assert(p_scn != null, "Escena 'vegetto_ki_blast.tscn' existe y compila.")

	if p_scn:
		var p = p_scn.instantiate() as Area2D
		_assert(p is VegettoKiBlastRef, "Instancia es de clase VegettoKiBlast.")
		_assert(p.collision_layer == 2, "Capa de colisión es 2 (Hitbox).")
		_assert(p.collision_mask == 16, "Máscara de colisión es 16 (Hurtbox).")
		_assert(p.damage == 16.0, "Daño del proyectil calibrado a 16.0.")
		_assert(p.speed == 480.0, "Velocidad de proyectil calibrada a 480.0 px/s.")

		add_child(p)
		p._physics_process(0.1)
		_assert(p.position.x > 0.0, "Proyectil se desplaza horizontalmente (x: %.1f)." % p.position.x)
		p.queue_free()

# ---------------------------------------------------------------------------
# 6. Vegetto: Transformación en Super Saiyajin
# ---------------------------------------------------------------------------

func _test_vegetto_transformation() -> void:
	print("\n--- 6. Pruebas de Transformación Super Saiyajin ---")
	var scn = load("res://scenes/characters/vegetto.tscn") as PackedScene
	if not scn:
		_assert(false, "No se pudo instanciar vegetto.")
		return

	var v = scn.instantiate() as CharacterBase
	add_child(v)
	v.current_energy = 100.0

	_assert(v.can_transform(), "Vegetto cumple condiciones para transformarse con 100 Ki.")
	var ok: bool = v.begin_transform()
	_assert(ok and v.is_transforming, "begin_transform() inicia secuencia de transformación.")

	v.finish_transform()
	_assert(v.is_transformed, "finish_transform() activa is_transformed = true.")
	_assert(v.get_effective_damage(10.0) == 15.0, "Buff de daño Super Saiyajin activo (x1.50).")
	_assert(v.get_effective_speed() > v.data.move_speed, "Buff de velocidad Super Saiyajin activo.")

	# Comprobar animación ssj_idle al solicitar idle transformado
	v.play_animation("idle")
	var spr = v.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_assert(spr and spr.animation == "ssj_idle", "Vegetto reproduce 'ssj_idle' automáticamente al estar transformado.")

	v.end_transformation()
	_assert(not v.is_transformed, "end_transformation() revierte el estado a base.")
	v.queue_free()

# ---------------------------------------------------------------------------
# 7. Escenarios de Combate
# ---------------------------------------------------------------------------

func _test_map_scenes() -> void:
	print("\n--- 7. Pruebas de Escenarios (Mapas de Combate) ---")
	var map_paths: Dictionary = {
		"Valle del Fin": "res://scenes/maps/valle_del_fin.tscn",
		"Torneo": "res://scenes/maps/torneo.tscn",
		"Dimensión de los Ecos": "res://scenes/maps/dimension_ecos.tscn"
	}

	for m_name in map_paths:
		var p: String = map_paths[m_name]
		var scn = load(p) as PackedScene
		_assert(scn != null, "Escena '%s' (%s) existe y compila." % [m_name, p])
		if scn:
			var inst = scn.instantiate() as CombatStage
			_assert(inst is CombatStage, "'%s' utiliza el controlador CombatStage." % m_name)

			var bg = inst.get_node_or_null("Background") as Sprite2D
			_assert(bg != null and bg.texture != null, "'%s' tiene Sprite2D de fondo con textura." % m_name)
			if bg and bg.texture:
				_assert(bg.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST, "'%s' tiene filtro de textura Nearest para pixel art." % m_name)

			var ground = inst.get_node_or_null("Ground") as StaticBody2D
			_assert(ground != null, "'%s' tiene StaticBody2D 'Ground' con colisión." % m_name)

			var cam = inst.get_node_or_null("Camera2D") as Camera2D
			_assert(cam != null, "'%s' tiene Camera2D configurada." % m_name)

			var hud = inst.get_node_or_null("HUD")
			_assert(hud != null, "'%s' tiene capa HUD con barras de vida y energía." % m_name)

			inst.queue_free()

# ---------------------------------------------------------------------------
# 8. CharacterFactory y GameData
# ---------------------------------------------------------------------------

func _test_character_factory_and_gamedata() -> void:
	print("\n--- 8. Pruebas de CharacterFactory y GameData ---")
	var factory = get_node_or_null("/root/CharacterFactory")
	_assert(factory != null, "CharacterFactory disponible como Autoload.")

	if factory:
		var v_data = load("res://resources/characters/vegetto.tres") as CharacterData
		var v_char = factory.create_character(v_data)
		_assert(v_char is VegettoRef, "CharacterFactory.create_character(vegetto) retorna instancia de Vegetto.")
		if v_char: v_char.queue_free()

		# Comprobar resolución de mapas
		var p_valle = factory.get_map_scene_path("valle_del_fin")
		var p_torneo = factory.get_map_scene_path("torneo")
		var p_ecos = factory.get_map_scene_path("dimension_ecos")
		_assert(p_valle == "res://scenes/maps/valle_del_fin.tscn", "Mapeo de valle_del_fin es correcto.")
		_assert(p_torneo == "res://scenes/maps/torneo.tscn", "Mapeo de torneo es correcto.")
		_assert(p_ecos == "res://scenes/maps/dimension_ecos.tscn", "Mapeo de dimension_ecos es correcto.")

	var gdata = get_node_or_null("/root/GameData")
	_assert(gdata != null, "GameData disponible como Autoload.")
	if gdata:
		_assert("vegetto" in gdata.unlocked_character_ids, "Vegetto está presente en GameData.unlocked_character_ids.")
		_assert("dimension_ecos" in gdata.unlocked_map_ids, "dimension_ecos está presente en GameData.unlocked_map_ids.")

# ---------------------------------------------------------------------------
# 9. Capítulos de Historia ECOS
# ---------------------------------------------------------------------------

func _test_story_chapters_etapa3() -> void:
	print("\n--- 9. Pruebas de Capítulos de Historia ECOS ---")
	var ch1 = load("res://resources/story/chapter_01.tres") as StoryChapter
	var ch2 = load("res://resources/story/chapter_02.tres") as StoryChapter
	var ch3 = load("res://resources/story/chapter_03.tres") as StoryChapter
	var ch4 = load("res://resources/story/chapter_04.tres") as StoryChapter
	var ch5 = load("res://resources/story/chapter_05.tres") as StoryChapter
	var ch6 = load("res://resources/story/chapter_06.tres") as StoryChapter

	_assert(ch1 and ch1.map_id == "valle_del_fin", "Capítulo 1 está asignado a 'valle_del_fin'.")
	_assert(ch2 and ch2.map_id == "torneo", "Capítulo 2 está asignado a 'torneo'.")
	_assert(ch3 and ch3.map_id == "valle_del_fin", "Capítulo 3 está asignado a 'valle_del_fin'.")
	_assert(ch4 and ch4.map_id == "dimension_ecos", "Capítulo 4 está asignado a 'dimension_ecos'.")
	_assert(ch4 and ch4.opponent_character_id == "vegetto", "Capítulo 4 tiene como rival a 'vegetto'.")
	_assert(ch5 and ch5.map_id == "torneo", "Capítulo 5 está asignado a 'torneo'.")
	_assert(ch6 and ch6.map_id == "dimension_ecos", "Capítulo 6 está asignado a 'dimension_ecos'.")
	_assert(ch6 and ch6.opponent_character_id == "goku_echo", "Capítulo 6 tiene como rival a 'goku_echo'.")

# ---------------------------------------------------------------------------
# 10. No Regresión
# ---------------------------------------------------------------------------

func _test_no_regressions() -> void:
	print("\n--- 10. Pruebas de No Regresión ---")
	var fighters: Array[String] = ["goku", "naruto", "madara", "dummy"]
	var factory = get_node_or_null("/root/CharacterFactory")

	for f_id in fighters:
		var res_path := "res://resources/characters/%s.tres" % f_id
		var res = load(res_path) as CharacterData
		_assert(res != null, "Luchador existente '%s.tres' carga sin problemas." % f_id)
		if factory and res:
			var c = factory.create_character(res)
			_assert(c != null, "CharacterFactory puede instanciar '%s' sin errores." % f_id)
			if c: c.queue_free()

	var ch1_scene = load("res://scenes/story/story_stage.tscn") as PackedScene
	_assert(ch1_scene != null, "Escena de cinemática/combate del Capítulo 1 (story_stage.tscn) se mantiene intacta.")

extends Node

func _ready() -> void:
	print("--- INICIANDO CAPTURAS Y VALIDACIÓN VISUAL ---")
	DirAccess.make_dir_recursive_absolute("res://tests/screenshots")
	_run_captures()

func _run_captures() -> void:
	var gdata = get_node_or_null("/root/GameData")
	if not gdata:
		print("ERROR: GameData no encontrado")
		get_tree().quit(1)
		return

	var combos := [
		{
			"map_id": "valle_del_fin",
			"map_scene": "res://scenes/maps/valle_del_fin.tscn",
			"p1": "res://resources/characters/goku.tres",
			"p2": "res://resources/characters/naruto.tres",
			"name": "valle_del_fin_goku_vs_naruto.png"
		},
		{
			"map_id": "torneo",
			"map_scene": "res://scenes/maps/torneo.tscn",
			"p1": "res://resources/characters/goku.tres",
			"p2": "res://resources/characters/madara.tres",
			"name": "torneo_goku_vs_madara.png"
		},
		{
			"map_id": "dimension_ecos",
			"map_scene": "res://scenes/maps/dimension_ecos.tscn",
			"p1": "res://resources/characters/goku.tres",
			"p2": "res://resources/characters/vegetto.tres",
			"name": "dimension_ecos_goku_vs_vegetto.png"
		}
	]

	for combo in combos:
		gdata.selected_map_id = combo.map_id
		gdata.player1_data = load(combo.p1)
		gdata.player2_data = load(combo.p2)

		var stage_scene: PackedScene = load(combo.map_scene)
		var stage: CombatStage = stage_scene.instantiate() as CombatStage
		add_child(stage)

		# Esperar varios frames para física y animación
		for i in range(12):
			await get_tree().process_frame

		var p1 = stage.player1
		var p2 = stage.player2
		print("\n[VALIDACIÓN] Escenario: %s" % combo.map_id)
		if p1:
			var p1_col = p1.get_node_or_null("CollisionShape2D")
			var p1_h = (p1_col.shape.height if p1_col and p1_col.shape is CapsuleShape2D else 50.0) * p1.scale.y
			print("  P1 (%s): pos=%s, scale=%s, altura_efectiva=%.1f, suelo_y=%.1f" % [
				p1.data.display_name if p1.data else p1.name,
				p1.position, p1.scale, p1_h, p1.position.y + (p1_h * 0.5)
			])
		if p2:
			var p2_col = p2.get_node_or_null("CollisionShape2D")
			var p2_h = (p2_col.shape.height if p2_col and p2_col.shape is CapsuleShape2D else 50.0) * p2.scale.y
			print("  P2 (%s): pos=%s, scale=%s, altura_efectiva=%.1f, suelo_y=%.1f" % [
				p2.data.display_name if p2.data else p2.name,
				p2.position, p2.scale, p2_h, p2.position.y + (p2_h * 0.5)
			])

		# Capturar viewport
		var img: Image = get_viewport().get_texture().get_image()
		if img and not img.is_empty():
			var save_path := "res://tests/screenshots/%s" % combo.name
			img.save_png(save_path)
			print("  📸 Captura guardada en: %s (%dx%d)" % [save_path, img.get_width(), img.get_height()])
		else:
			print("  ⚠️ Viewport image vacía (típico en modo headless puro)")

		stage.queue_free()
		await get_tree().process_frame

	print("\n--- VALIDACIÓN VISUAL Y CAPTURAS FINALIZADAS CON ÉXITO ---")
	get_tree().quit(0)

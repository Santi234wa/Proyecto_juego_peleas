## dimensional_rift.gd
## Efecto visual 2D de la grieta interdimensional hacia el Torneo de Artes Marciales.
extends Node2D

var _pulse: float = 0.0

func _process(delta: float) -> void:
	_pulse += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var width_pulse: float = 16.0 + sin(_pulse) * 4.0
	var height: float = 80.0

	# 1. Halo exterior cósmico (Cyan / Azul etéreo)
	var halo_poly := PackedVector2Array([
		Vector2(0, -height),
		Vector2(width_pulse * 1.5, 0),
		Vector2(0, height),
		Vector2(-width_pulse * 1.5, 0)
	])
	draw_colored_polygon(halo_poly, Color(0.1, 0.8, 1.0, 0.35))

	# 2. Resonancia dorada intermedia
	var mid_poly := PackedVector2Array([
		Vector2(0, -height * 0.85),
		Vector2(width_pulse, 0),
		Vector2(0, height * 0.85),
		Vector2(-width_pulse, 0)
	])
	draw_colored_polygon(mid_poly, Color(1.0, 0.85, 0.2, 0.65))

	# 3. Núcleo blanco incandescente de la grieta
	var core_poly := PackedVector2Array([
		Vector2(0, -height * 0.7),
		Vector2(width_pulse * 0.45, 0),
		Vector2(0, height * 0.7),
		Vector2(-width_pulse * 0.45, 0)
	])
	draw_colored_polygon(core_poly, Color(1.0, 1.0, 1.0, 0.95))

	# 4. Rayas y destellos de energía dimensional
	draw_line(Vector2(0, -height * 1.15), Vector2(0, height * 1.15), Color(1.0, 1.0, 1.0, 0.9), 2.0)
	draw_line(Vector2(-width_pulse * 1.8, 0), Vector2(width_pulse * 1.8, 0), Color(0.2, 0.9, 1.0, 0.5), 1.5)

## glitch_overlay.gd
## Efecto de interferencia dimensional con líneas de barrido manga y ruido de señal.
extends ColorRect

var _timer: float = 0.0

func _process(delta: float) -> void:
	if visible and modulate.a > 0.01:
		_timer += delta * 25.0
		queue_redraw()

func _draw() -> void:
	if modulate.a <= 0.01:
		return

	var rect_size: Vector2 = size
	var line_spacing: float = 4.0
	var offset_y: float = fmod(_timer * 10.0, line_spacing)

	# Dibujar líneas de escaneo / scanlines manga
	var y: float = offset_y
	while y < rect_size.y:
		draw_line(Vector2(0, y), Vector2(rect_size.x, y), Color(0.1, 0.9, 1.0, 0.15), 1.0)
		y += line_spacing * 2.0

	# Franjas aleatorias de ruido dimensional
	var band_y: float = fmod(_timer * 37.0, rect_size.y)
	draw_rect(Rect2(0, band_y, rect_size.x, 6.0), Color(0.2, 0.8, 1.0, 0.2))
	var band_y2: float = fmod(_timer * 61.0, rect_size.y)
	draw_rect(Rect2(0, band_y2, rect_size.x, 3.0), Color(1.0, 0.2, 0.4, 0.15))


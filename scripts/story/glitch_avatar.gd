## glitch_avatar.gd
## Retrato estilizado de señal distorsionada / eco para la entidad desconocida '???'.
extends Control

var _anim: float = 0.0

func _process(delta: float) -> void:
	if visible:
		_anim += delta * 12.0
		queue_redraw()

func _draw() -> void:
	var s: Vector2 = size
	# Fondo oscuro de la señal
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.06, 0.08, 0.12, 1.0))
	
	# Cuadrícula digital
	for x in range(4, int(s.x), 8):
		draw_line(Vector2(x, 0), Vector2(x, s.y), Color(0.12, 0.22, 0.3, 0.4), 1.0)
	for y in range(4, int(s.y), 8):
		draw_line(Vector2(0, y), Vector2(s.x, y), Color(0.12, 0.22, 0.3, 0.4), 1.0)

	# Onda osciloscópica pulsante de ???
	var mid_y: float = s.y * 0.5
	var prev_pt := Vector2(4, mid_y)
	for x in range(4, int(s.x - 4), 3):
		var wave: float = sin(float(x) * 0.25 + _anim) * (s.y * 0.28) * sin(_anim * 0.5)
		var pt := Vector2(x, mid_y + wave)
		draw_line(prev_pt, pt, Color(0.2, 0.9, 1.0, 0.9), 2.0)
		prev_pt = pt

	# Signos de interrogación tenues en el centro
	draw_rect(Rect2(s.x * 0.5 - 2, s.y * 0.5 - 8, 4, 12), Color(1.0, 1.0, 1.0, 0.85))
	draw_rect(Rect2(s.x * 0.5 - 2, s.y * 0.5 + 8, 4, 4), Color(1.0, 1.0, 1.0, 0.85))

	# Borde del cuadro
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.2, 0.85, 0.95), false, 2.0)

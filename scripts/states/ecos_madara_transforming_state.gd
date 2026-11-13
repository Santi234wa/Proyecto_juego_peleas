## ECOS: extensión visual del Sharingan de Madara.
## Preserva la cinematica Sharingan existente y TODAS sus estadísticas.
class_name EcosMadaraTransformingState
extends SharinganTransformingState

var _eye_ring: Line2D = null
var _ring_tween: Tween = null

func enter() -> void:
	super.enter()
	if character:
		_spawn_eye_ring()

func _spawn_eye_ring() -> void:
	# Un anillo tipo Sharingan gira alrededor de la cabeza, sin cubrir el sprite.
	_eye_ring = Line2D.new()
	_eye_ring.width = 1.4
	_eye_ring.antialiased = false
	_eye_ring.default_color = Color(0.95, 0.08, 0.12, 0.80)
	_eye_ring.z_index = 3
	_eye_ring.position = Vector2(0, -14)
	var pts := PackedVector2Array()
	for i in range(33):
		var a: float = TAU * float(i) / 32.0
		pts.append(Vector2(cos(a) * 16.0, sin(a) * 7.0))
	_eye_ring.points = pts
	character.add_child(_eye_ring)
	_ring_tween = create_tween().set_parallel(true)
	_ring_tween.tween_property(_eye_ring, "rotation", TAU * 1.5, 1.2)
	_ring_tween.tween_property(_eye_ring, "modulate:a", 0.0, 1.2)

func exit() -> void:
	if _ring_tween and _ring_tween.is_valid(): _ring_tween.kill()
	if is_instance_valid(_eye_ring): _eye_ring.queue_free()
	_eye_ring = null
	super.exit()

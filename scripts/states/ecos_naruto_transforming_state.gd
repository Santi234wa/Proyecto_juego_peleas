## ECOS: extensión visual del Modo Sabio de Naruto.
## Preserva la cinemática de energía natural y los buffs existentes.
class_name EcosNarutoTransformingState
extends SageTransformingState

var _chakra_ring: Line2D = null
var _ring_tween: Tween = null

func enter() -> void:
	super.enter()
	if character:
		_spawn_chakra_ring()

func _spawn_chakra_ring() -> void:
	# Chakra ambiental controlado, distinto a la explosión Saiyajin.
	_chakra_ring = Line2D.new()
	_chakra_ring.width = 1.4
	_chakra_ring.antialiased = false
	_chakra_ring.default_color = Color(0.53, 0.94, 0.39, 0.75)
	_chakra_ring.z_index = -1
	_chakra_ring.position = Vector2(0, -8)
	var pts := PackedVector2Array()
	for i in range(33):
		var a: float = TAU * float(i) / 32.0
		pts.append(Vector2(cos(a) * 13.0, sin(a) * 22.0))
	_chakra_ring.points = pts
	character.add_child(_chakra_ring)
	_ring_tween = create_tween().set_parallel(true)
	_ring_tween.tween_property(_chakra_ring, "rotation", TAU, 1.45)
	_ring_tween.tween_property(_chakra_ring, "modulate:a", 0.0, 1.45)

func exit() -> void:
	if _ring_tween and _ring_tween.is_valid(): _ring_tween.kill()
	if is_instance_valid(_chakra_ring): _chakra_ring.queue_free()
	_chakra_ring = null
	super.exit()

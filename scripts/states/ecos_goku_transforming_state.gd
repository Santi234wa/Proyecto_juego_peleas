## ECOS: transformación personalizada de Goku (SSJ1).
## Sustituir SOLO la referencia de script del nodo Transforming de goku.tscn.
class_name EcosGokuTransformingState
extends TransformingState

var _extra_fx: Array[Node] = []
var _extra_tweens: Array[Tween] = []

func enter() -> void:
	charge_time = 1.25
	hold_time = 0.45
	zoom_in = 1.26
	dim_amount = 0.56
	aura_color = Color(1.0, 0.76, 0.13)
	flash_color = Color(1.0, 0.97, 0.74)
	use_particles = true
	use_lightning = true
	body_center = Vector2(0, -12)
	feet_offset = Vector2(0, 20)
	super.enter()
	if character:
		_spawn_energy_column()

func _spawn_energy_column() -> void:
	# Columna compacta de Ki, a escala de sprite pixel art 48x48.
	var column := Polygon2D.new()
	column.color = Color(1.0, 0.85, 0.25, 0.22)
	column.polygon = PackedVector2Array([
		Vector2(-12, 20), Vector2(-18, 0), Vector2(-9, -35),
		Vector2(0, -46), Vector2(9, -35), Vector2(18, 0), Vector2(12, 20)
	])
	column.z_index = -2
	character.add_child(column)
	_extra_fx.append(column)
	var tw := create_tween().set_loops(5)
	tw.tween_property(column, "modulate:a", 0.35, 0.12)
	tw.tween_property(column, "modulate:a", 0.9, 0.12)
	_extra_tweens.append(tw)

func exit() -> void:
	for tw in _extra_tweens:
		if tw and tw.is_valid(): tw.kill()
	_extra_tweens.clear()
	for node in _extra_fx:
		if is_instance_valid(node): node.queue_free()
	_extra_fx.clear()
	super.exit()

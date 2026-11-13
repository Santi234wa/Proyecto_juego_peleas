## vegetto_transforming_state.gd
## Secuencia de transformación de Vegetto en Super Saiyajin.
## Hereda de TransformingState y personaliza la carga con aura dorada de ki,
## rayos Saiyajin y animación específica de transformación.
class_name VegettoTransformingState
extends TransformingState

func enter() -> void:
	charge_time = 1.15
	hold_time = 0.45
	zoom_in = 1.25
	dim_amount = 0.50
	aura_color = Color(1.0, 0.88, 0.25) # Dorado brillante Super Saiyajin
	flash_color = Color(1.0, 0.98, 0.80)
	use_lightning = true

	if character and character.has_method("on_transformation_started"):
		character.on_transformation_started()

	super.enter()

func _play_sequence() -> void:
	if not _sprite:
		_sprite = character.get_node_or_null("AnimatedSprite2D")

	if _sprite and _sprite.sprite_frames and _sprite.sprite_frames.has_animation("transform"):
		_sprite.play("transform")

	super._play_sequence()

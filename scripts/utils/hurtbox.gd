## hurtbox.gd
## Área de daño de un personaje: define dónde puede ser golpeado.
## Se agrega al grupo "hurtbox" para que los hitboxes rivales lo detecten.
## En Phase 3 se conecta la señal del hitbox a CharacterBase.take_damage().
class_name Hurtbox
extends Area2D

func _ready() -> void:
	add_to_group("hurtbox")
	monitoring  = false  # El hurtbox no detecta; es detectado
	monitorable = true   # Puede ser encontrado por los hitboxes rivales


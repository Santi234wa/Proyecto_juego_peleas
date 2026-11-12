## hurtbox.gd
## Área vulnerable de un personaje que recibe daño.
## Patrón Observer: Al recibir un impacto, emite señales y aplica daño al personaje dueño.
class_name Hurtbox
extends Area2D

## Señal emitida al ser impactado por un Hitbox
signal hit_received(damage_amount: float, attacker_hitbox: Area2D)

## Personaje dueño de esta hurtbox (quien recibe el daño físico)
@export var owner_character: CharacterBase = null

func _ready() -> void:
	add_to_group("hurtbox")
	monitoring = false   # La hurtbox no busca otras áreas
	monitorable = true   # Permite ser detectada por los hitboxes rivales
	
	if not owner_character and get_parent() is CharacterBase:
		owner_character = get_parent() as CharacterBase

## Recibe el impacto desde un Hitbox activo
func receive_hit(damage_amount: float, attacker_hitbox: Area2D) -> void:
	emit_signal("hit_received", damage_amount, attacker_hitbox)
	
	if owner_character and owner_character.has_method("take_damage"):
		owner_character.take_damage(damage_amount)

## hitbox.gd
## Área de ataque de un personaje. Se activa/desactiva desde los estados de ataque.
## En Phase 2: solo se activa y desactiva visualmente.
## En Phase 3: la señal hit_registered se conecta para aplicar daño al rival.
class_name Hitbox
extends Area2D

## Daño que inflige esta hitbox. Lo asigna AttackState antes de activarla.
var damage: float = 0.0

## Emitida cuando el hitbox detecta un hurtbox válido.
## El receptor (Phase 3) llamará take_damage() en el personaje correspondiente.
signal hit_registered(hurtbox: Area2D, damage_amount: float)

func _ready() -> void:
	monitoring  = false  # Desactivado por defecto; AttackState lo activa
	monitorable = false  # El hitbox no es detectado por otros hitboxes

	# Conectar la detección de áreas
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D) -> void:
	## Solo procesar si el área es un hurtbox.
	## Los hurtboxes se identifican por pertenecer al grupo "hurtbox".
	if area.is_in_group("hurtbox"):
		emit_signal("hit_registered", area, damage)
		# Desactivar inmediatamente: un swing solo puede golpear una vez.
		# AttackState lo reactivará solo si hay otro ataque.
		monitoring = false


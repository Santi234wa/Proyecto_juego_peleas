## hitbox.gd
## Área de ataque de un personaje.
## Se activa y desactiva usando set_deferred según los frames activos del ataque.
## Lleva registro de los objetivos golpeados para no pegar más de una vez por activación.
class_name Hitbox
extends Area2D

## Señal emitida al impactar a un hurtbox válido
signal hit_registered(hurtbox: Area2D, damage_amount: float)

## Personaje dueño de esta hitbox (para evitar autodaño y recompensar energía)
@export var owner_character: CharacterBase = null

## Daño que inflige este golpe (se actualiza en activate)
var damage: float = 0.0

## Vector de empuje (knockback) aplicado a la víctima
var knockback_vector: Vector2 = Vector2.ZERO

## Registro de hurtboxes ya golpeados durante este swing
var _hit_targets: Array[Area2D] = []

func _ready() -> void:
	monitoring = false
	monitorable = false
	collision_layer = 2
	collision_mask = 16
	
	if not owner_character and get_parent() is CharacterBase:
		owner_character = get_parent() as CharacterBase

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

## Activa el hitbox con el daño correspondiente y reinicia las víctimas registradas
func activate(damage_amount: float) -> void:
	damage = damage_amount
	_hit_targets.clear()
	monitoring = true
	# Si ya hay un hurtbox solapado en el momento exacto de golpear, conectarlo de inmediato
	check_overlaps()

## Desactiva el hitbox de forma segura
func deactivate() -> void:
	monitoring = false
	_hit_targets.clear()
	knockback_vector = Vector2.ZERO

## Comprueba manualmente hurtboxes ya solapados
func check_overlaps() -> void:
	if not monitoring:
		return
	for area in get_overlapping_areas():
		_on_area_entered(area)

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("hurtbox"):
		return

	if owner_character and area.get("owner_character") == owner_character:
		return

	if area in _hit_targets:
		return

	_hit_targets.append(area)
	emit_signal("hit_registered", area, damage)

	if area.has_method("receive_hit"):
		area.receive_hit(damage, self)
		if knockback_vector != Vector2.ZERO and area.get("owner_character") and area.owner_character.has_method("apply_knockback"):
			area.owner_character.apply_knockback(knockback_vector)

	# ── Recompensa de energía (Ki/Chakra) al atacante ──────────────────────
	# Si está transformado, gana solo una fracción del Ki (ki_gain_hit_mult_transformed).
	# Si está normal, gana el 100% de energy_on_hit_dealt.
	if owner_character and owner_character.data:
		var base_gain: float = owner_character.data.energy_on_hit_dealt
		if owner_character.is_transformed:
			var mult: float = owner_character.data.ki_gain_hit_mult_transformed
			owner_character.gain_energy(base_gain * mult)
		else:
			owner_character.gain_energy(base_gain)

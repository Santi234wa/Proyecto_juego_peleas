## vegetto_ki_blast.gd
## Proyectil de ráfaga de Ki de Vegetto.
## Se desplaza horizontalmente e impacta en Hurtbox enemigas.
## Aplica daño calibrado, knockback y se destruye al impactar o salir de rango.
class_name VegettoKiBlast
extends Area2D

signal exploded()

@export var speed: float = 500.0
@export var damage: float = 25.0
@export var lifetime: float = 2.2
@export var knockback_force: Vector2 = Vector2(130.0, -25.0)

var owner_character: CharacterBase = null
var direction: Vector2 = Vector2.RIGHT
var _elapsed: float = 0.0
var _has_hit: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	monitoring = true
	monitorable = false
	collision_layer = 2   # Capa de Hitbox
	collision_mask = 16   # Detecta Hurtbox (capa 5 = 16)

	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)

	if _sprite:
		_sprite.flip_h = (direction.x < 0.0)
		if _sprite.sprite_frames and _sprite.sprite_frames.has_animation("fly"):
			_sprite.play("fly")

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	_elapsed += delta
	if _elapsed >= lifetime:
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if _has_hit:
		return
	if not area.is_in_group("hurtbox"):
		return
	if owner_character and area.get("owner_character") == owner_character:
		return

	_has_hit = true
	var eff_dmg: float = damage
	if owner_character and owner_character.has_method("get_effective_damage"):
		eff_dmg = owner_character.get_effective_damage(damage)

	if area.has_method("receive_hit"):
		area.receive_hit(eff_dmg, self)

	# Empuje direccional al rival
	var victim_char = area.get("owner_character")
	if victim_char and victim_char.has_method("apply_knockback"):
		var dir_kb := Vector2(knockback_force.x * direction.x, knockback_force.y)
		victim_char.apply_knockback(dir_kb)

	# Recompensa de energía reducida por impacto de proyectil
	if owner_character and owner_character.data:
		owner_character.gain_energy(owner_character.data.energy_on_hit_dealt * 0.5)

	emit_signal("exploded")
	queue_free()


## naruto_rasenshuriken.gd
## Proyectil de Rasenshuriken de Naruto.
## Se desplaza girando a alta velocidad con vórtice de viento e impacta en Hurtbox enemigas.
## Aplica daño de viento/chakra calibrado (22.0 base, potenciado en Modo Sabio), knockback y explosión.
class_name NarutoRasenshuriken
extends Area2D

signal exploded()

@export var speed: float = 470.0
@export var damage: float = 22.0
@export var lifetime: float = 2.4
@export var knockback_force: Vector2 = Vector2(145.0, -30.0)

var owner_character: CharacterBase = null
var direction: Vector2 = Vector2.RIGHT
var _elapsed: float = 0.0
var _has_hit: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _trail: CPUParticles2D = get_node_or_null("WindTrail")

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

	if _trail:
		_trail.direction = Vector2(-direction.x, 0.0)

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

	var target = area.get("owner_character")
	if target and target.has_method("take_hit"):
		var k_dir = Vector2(direction.x * knockback_force.x, knockback_force.y)
		target.take_hit(eff_dmg, k_dir)

	exploded.emit()
	queue_free()

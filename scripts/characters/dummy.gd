## dummy.gd
## Personaje de entrenamiento estático para probar golpes, daño, bloqueo y energía.
## Tecla B: Alterna el modo guardia (50% daño).
## Tecla K: Golpea a Goku para probar la subida de Ki al recibir daño.
class_name Dummy
extends CharacterBase

@export var start_health: float = 100.0

func _ready() -> void:
	player_id = 2
	current_health = start_health
	current_energy = 0.0
	
	if data:
		current_health = data.max_health

	_find_child_nodes()

func _find_child_nodes() -> void:
	_animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	velocity.x = 0.0
	move_and_slide()

## Controles de prueba en el teclado
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_guard()
		elif event.keycode == KEY_K:
			simulate_attack_on_goku()

func toggle_guard() -> void:
	is_blocked = not is_blocked
	if is_blocked:
		modulate = Color(0.6, 0.85, 1.0)
		print("[Dummy] 🛡️ Modo Guardia: ACTIVADO (El daño se reducirá al 50%)")
	else:
		modulate = Color(1.0, 1.0, 1.0)
		print("[Dummy] Modo Guardia: DESACTIVADO (Daño normal 100%)")

## Simula que el Dummy golpea a Goku para probar la ganancia de Ki al recibir daño
func simulate_attack_on_goku() -> void:
	var goku := get_tree().root.find_child("goku", true, false) as CharacterBase
	if goku:
		print("[Dummy] 👊 Dummy golpea a Goku (-10 de vida). Goku debe ganar +5 de Ki.")
		goku.take_damage(10.0)

## Al recibir daño, aplicar reducción de bloqueo si corresponde
func take_damage(amount: float) -> void:
	var effective: float = amount * 0.5 if is_blocked else amount
	current_health = maxf(0.0, current_health - effective)
	
	var max_hp: float = data.max_health if data else start_health
	emit_signal("health_changed", current_health, max_hp)

	if is_blocked:
		print("[Dummy] 🛡️ ¡GOLPE BLOQUEADO! -%s de daño (50%% reducido) | Vida: %s/%s" % [effective, current_health, max_hp])
	else:
		print("[Dummy] ¡Golpe recibido! -%s de daño (100%%) | Vida: %s/%s" % [effective, current_health, max_hp])

	_flash_hit()

	if current_health <= 0.0:
		emit_signal("character_died")
		print("[Dummy] K.O. - Reiniciando vida...")
		get_tree().create_timer(1.5).timeout.connect(_respawn)

func _flash_hit() -> void:
	var original_color: Color = Color(0.6, 0.85, 1.0) if is_blocked else Color(1.0, 1.0, 1.0)
	modulate = Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	modulate = original_color

func _respawn() -> void:
	var max_hp: float = data.max_health if data else start_health
	current_health = max_hp
	emit_signal("health_changed", current_health, max_hp)
	print("[Dummy] Listo para seguir entrenando.")

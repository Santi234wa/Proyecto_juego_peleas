## dummy.gd
## Personaje de entrenamiento estático para probar golpes, daño, bloqueo y energía.
## Tecla B: Alterna el modo guardia (50% daño).
## Tecla M: Golpea a Goku para probar la subida de Ki al recibir daño.
class_name Dummy
extends CharacterBase

@export var start_health: float = 100.0

var _is_defeated: bool = false

# ---------------------------------------------------------------------------
# Ciclo de vida
# ---------------------------------------------------------------------------

func _ready() -> void:
	player_id = 2
	super._ready()
	
	# Si no se inyectó CharacterData, asegurar valores por defecto del Dummy
	if not data:
		current_health = start_health
		current_energy = 0.0

func _find_child_nodes() -> void:
	super._find_child_nodes()
	_animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

## El Dummy es un personaje de entrenamiento estático; no requiere procesador de IA.
func _check_and_setup_ai() -> void:
	is_ai = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y += GRAVITY * delta
	else:
		velocity.y = 0.0
	
	velocity.x = 0.0
	move_and_slide()

# ---------------------------------------------------------------------------
# Controles de depuración en teclado (B = Guardia, M = Test golpe a Goku)
# ---------------------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B:
			toggle_guard()
		elif event.keycode == KEY_M:
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

# ---------------------------------------------------------------------------
# Sistema de daño y resolución de combate
# ---------------------------------------------------------------------------

## Al recibir daño, aplica reducción de bloqueo si corresponde y gestiona la derrota.
func take_damage(amount: float) -> void:
	if _is_defeated:
		return

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
		_is_defeated = true
		emit_signal("character_died")

		var gdata = get_node_or_null("/root/GameData")
		if gdata and gdata.current_mode == gdata.GameMode.STORY:
			print("[Dummy] 🎯 Objetivo del Capítulo 1 completado. Victoria para el Jugador 1.")
			gdata.report_round_winner("player1")
			# En Modo Historia NO reaparece; el combate concluye aquí de forma definitiva.
		else:
			print("[Dummy] K.O. - Reiniciando vida en 1.5s (Modo entrenamiento)...")
			get_tree().create_timer(1.5).timeout.connect(_respawn)

func _flash_hit() -> void:
	var original_color: Color = Color(0.6, 0.85, 1.0) if is_blocked else Color(1.0, 1.0, 1.0)
	modulate = Color(1.0, 0.3, 0.3)
	await get_tree().create_timer(0.12).timeout
	modulate = original_color

## Reinicia la vida del Dummy tras ser derrotado en modos de entrenamiento libres.
func _respawn() -> void:
	_is_defeated = false
	var max_hp: float = data.max_health if data else start_health
	current_health = max_hp
	emit_signal("health_changed", current_health, max_hp)
	print("[Dummy] Listo para seguir entrenando.")

## Permite reiniciar el estado del Dummy externamente.
func reset_state() -> void:
	_is_defeated = false
	is_blocked = false
	var max_hp: float = data.max_health if data else start_health
	current_health = max_hp
	current_energy = 0.0
	emit_signal("health_changed", current_health, max_hp)

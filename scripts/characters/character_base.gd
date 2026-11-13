## character_base.gd
## Clase base de TODOS los personajes jugables y enemigos.
## Patrón: Template Method.
class_name CharacterBase
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Constantes de física
# ---------------------------------------------------------------------------
const GRAVITY: float = 980.0

# ---------------------------------------------------------------------------
# Señales (Patrón Observer)
# ---------------------------------------------------------------------------
signal health_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)
signal character_died()
signal transformation_started(transform_name: String)
signal transformation_ended()

# ---------------------------------------------------------------------------
# Datos del personaje
# ---------------------------------------------------------------------------
@export var data: CharacterData = null
@export var player_id: int = 1
@export var is_ai: bool = false      ## Si es true, este personaje es gobernado por EnemyAI
@export var opponent: Node2D = null ## Referencia directa al rival de combate

# ---------------------------------------------------------------------------
# Estado en tiempo de ejecución
# ---------------------------------------------------------------------------
var current_health: float = 0.0
var current_energy: float = 0.0
var is_transformed: bool = false
var is_transforming: bool = false
var invulnerable: bool = false
var is_facing_right: bool = true
var is_blocked: bool = false

var _speed_mult: float = 1.0
var _damage_mult: float = 1.0
var _cooldown_timer: float = 0.0  # Temporizador de espera post-transformación

# ---------------------------------------------------------------------------
# Nodos hijos
# ---------------------------------------------------------------------------
var state_machine = null
var _animated_sprite: AnimatedSprite2D = null
var _aura_particles: Node = null

# ---------------------------------------------------------------------------
# Godot lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("fighters")
	_apply_game_data_override()
	_find_child_nodes()
	_initialize_stats()
	_setup_state_machine()
	_check_and_setup_ai()

func _check_and_setup_ai() -> void:
	var gdata = get_node_or_null("/root/GameData")
	var should_be_ai: bool = is_ai
	if gdata and player_id == 2:
		if gdata.current_mode in [gdata.GameMode.VS_AI, gdata.GameMode.STORY]:
			should_be_ai = true

	if should_be_ai:
		_setup_ai()

func _setup_ai() -> void:
	is_ai = true
	if not has_node("EnemyAI"):
		var ai_script = load("res://scripts/ai/enemy_ai.gd")
		if ai_script:
			var ai_node = ai_script.new()
			ai_node.name = "EnemyAI"
			add_child(ai_node)

func _apply_game_data_override() -> void:
	var gdata = get_node_or_null("/root/GameData")
	if not gdata:
		return
	if player_id == 1 and gdata.get("player1_data"):
		data = gdata.player1_data
	elif player_id == 2 and gdata.get("player2_data"):
		data = gdata.player2_data
		if gdata.get("player1_data") and gdata.player1_data.id == gdata.player2_data.id and data:
			modulate = data.alt_tint

func _physics_process(delta: float) -> void:
	if state_machine:
		state_machine.physics_update(delta)
	move_and_slide()

	# ── Drenaje dinámico de Ki mientras está transformado ───────────────
	if is_transformed:
		if not invulnerable:
			var drain: float = (data.ki_drain_per_second if data else 8.0) * delta
			current_energy = maxf(0.0, current_energy - drain)
			var max_e: float = data.max_energy if data else 100.0
			emit_signal("energy_changed", current_energy, max_e)

			# La transformación termina automáticamente cuando el Ki llega a 0
			if current_energy <= 0.0:
				end_transformation()

	# ── Cuenta regresiva de enfriamiento (Cooldown) ─────────────────────
	if _cooldown_timer > 0.0:
		_cooldown_timer = maxf(0.0, _cooldown_timer - delta)

func _process(delta: float) -> void:
	if state_machine:
		state_machine.process_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if state_machine:
		state_machine.handle_input(event)

# ---------------------------------------------------------------------------
# Inicialización interna
# ---------------------------------------------------------------------------

func _find_child_nodes() -> void:
	state_machine    = get_node_or_null("StateMachine")
	_animated_sprite = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	_aura_particles  = get_node_or_null("AuraParticles")

	if not _animated_sprite:
		push_warning("%s: No tiene 'AnimatedSprite2D'." % name)

func _initialize_stats() -> void:
	if not data:
		push_warning("%s: CharacterData no asignada. Usando valores por defecto." % name)
		current_health = 100.0
		current_energy = 0.0
		return
	current_health = data.max_health
	current_energy = 0.0

func _setup_state_machine() -> void:
	if state_machine:
		if not state_machine.has_node("Ultimate"):
			var ult_node := UltimateState.new()
			ult_node.name = "Ultimate"
			state_machine.add_child(ult_node)

func get_opponent() -> Node2D:
	if opponent and is_instance_valid(opponent):
		return opponent
	for n in get_tree().get_nodes_in_group("fighters"):
		if n != self and n is Node2D:
			return n
	return null

## Aplica empuje físico al personaje
func apply_knockback(force: Vector2) -> void:
	velocity = force

# ---------------------------------------------------------------------------
# API pública de combate
# ---------------------------------------------------------------------------

## Aplica daño. Si está bloqueando, reduce al 50%.
func take_damage(amount: float) -> void:
	if invulnerable:
		return

	var max_hp: float = data.max_health if data else 100.0
	var effective: float = amount * 0.5 if is_blocked else amount
	current_health = maxf(0.0, current_health - effective)
	emit_signal("health_changed", current_health, max_hp)

	# Feedback visual de impacto (parpadeo rojo)
	_flash_hit()

	# REGLA: Si está transformado, recibir daño NO suma Ki.
	# Fuera de la transformación, suma energía normalmente.
	if not is_transformed:
		var gain: float = data.energy_on_hit_taken if data else 5.0
		gain_energy(gain)

	if current_health <= 0.0:
		emit_signal("character_died")
		if state_machine:
			state_machine.transition_to("KO")
	else:
		if not is_blocked and state_machine and state_machine.current_state and state_machine.current_state.name != "KO":
			state_machine.transition_to("Hurt")

## Suma energía Ki/Chakra respetando el tope máximo y emite señal Observer
func gain_energy(amount: float) -> void:
	var max_e: float = data.max_energy if data else 100.0
	current_energy = minf(max_e, current_energy + amount)
	emit_signal("energy_changed", current_energy, max_e)
	print("[%s] ⚡ Ki: +%.1f | Total Ki: %.1f/%s" % [name, amount, current_energy, max_e])

## Gasta energía. Retorna false si no hay suficiente.
func spend_energy(amount: float) -> bool:
	if current_energy < amount:
		return false
	current_energy -= amount
	var max_e: float = data.max_energy if data else 100.0
	emit_signal("energy_changed", current_energy, max_e)
	return true

# ---------------------------------------------------------------------------
# API de transformación
# ---------------------------------------------------------------------------

## Valida si el personaje cumple las condiciones para transformarse:
## Ki acumulado >= costo mínimo, sin enfriamiento activo y no transformado actualmente.
func can_transform() -> bool:
	if not data:
		return false
	if is_transformed or is_transforming:
		return false
	if _cooldown_timer > 0.0:
		return false
	var min_cost: float = data.energy_cost_transform if data else 40.0
	return current_energy >= min_cost

## Paso 1 de la transformación (llamado al entrar al estado Transforming):
## Valida condiciones, activa invulnerabilidad y prepara al personaje.
## Nota: El Ki se drena dinámicamente segundo a segundo (ki_drain_per_second) mientras esté activo.
func begin_transform() -> bool:
	if not can_transform():
		var min_cost: float = data.energy_cost_transform if data else 40.0
		print("[%s] ❌ Ki insuficiente o en cooldown (Requiere %.1f Ki, Tienes %.1f Ki, Cooldown: %.1fs)" % [
			name, min_cost, current_energy, _cooldown_timer
		])
		return false

	is_transforming = true
	invulnerable = true
	print("[%s] ⚡ begin_transform(): Iniciando secuencia de transformación en %s..." % [
		name, data.transform_name if data else "SSJ"
	])
	return true

## Paso 2 de la transformación (llamado al culminar el destello en TransformingState):
## Aplica buffs de daño y velocidad, y activa el estado transformado.
func finish_transform() -> void:
	is_transformed = true
	is_transforming = false
	invulnerable = false
	_speed_mult = data.transform_speed_mult if data else 1.35
	_damage_mult = data.transform_damage_mult if data else 1.5

	# Quitar cualquier tinte: colores puros de los sprites reales de Super Saiyajin
	modulate = Color(1.0, 1.0, 1.0, 1.0)

	if _aura_particles:
		_aura_particles.set("emitting", true)

	# Actualizar animación inmediatamente a la versión Super Saiyajin
	play_animation("idle")

	emit_signal("transformation_started", data.transform_name if data else "Super Saiyajin")
	print("[%s] 🔥 finish_transform(): ¡%s activado! Buffs listos (Daño x%.2f, Vel x%.2f). Drenando %.1f Ki/s..." % [
		name, data.transform_name if data else "SSJ", _damage_mult, _speed_mult, data.ki_drain_per_second if data else 8.0
	])

## Helper para activar transformación a través de la StateMachine
func try_transform() -> bool:
	if not can_transform():
		return false
	if state_machine:
		state_machine.transition_to("Transforming")
		return true
	return false

## Termina la transformación y restaura todos los valores a la normalidad
func end_transformation() -> void:
	if not is_transformed:
		return
	is_transformed = false
	is_transforming = false
	invulnerable = false
	_speed_mult = 1.0
	_damage_mult = 1.0
	modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Iniciar temporizador de enfriamiento
	_cooldown_timer = data.transform_cooldown if data else 8.0

	if _aura_particles:
		_aura_particles.set("emitting", false)

	# Restaurar visual inmediatamente a la forma base
	if state_machine and state_machine.current_state:
		play_animation(state_machine.current_state.name.to_lower())

	emit_signal("transformation_ended")
	print("[%s] 💨 Ki agotado (0 Ki). Fin de la transformación. Cooldown de %.1fs iniciado." % [name, _cooldown_timer])

# ---------------------------------------------------------------------------
# API de Ultimate (Ataque Definitivo)
# ---------------------------------------------------------------------------

## Valida si el personaje puede ejecutar su ataque definitivo (Ultimate):
## Ki al 100% (lleno), con vida y no en ejecución de otro ataque cinemático.
func can_ultimate() -> bool:
	if not data:
		return false
	if current_health <= 0.0:
		return false
	var max_e: float = data.max_energy if data else 100.0
	return current_energy >= max_e

## Inicia el Ultimate: gasta todo el Ki, activa invulnerabilidad y emite señal Observer.
func begin_ultimate() -> bool:
	if not can_ultimate():
		var max_e: float = data.max_energy if data else 100.0
		print("[%s] ❌ No puede usar Ultimate (Requiere Ki lleno: %.1f/%.1f)" % [name, current_energy, max_e])
		return false
	var max_e: float = data.max_energy if data else 100.0
	current_energy = 0.0
	emit_signal("energy_changed", current_energy, max_e)
	invulnerable = true
	print("[%s] 💥 begin_ultimate(): Ki consumido por completo (0.0/%.1f). ¡Iniciando Ultimate!" % [name, max_e])
	return true

# ---------------------------------------------------------------------------
# Helpers para los estados
# ---------------------------------------------------------------------------

func get_effective_speed() -> float:
	return (data.move_speed if data else 180.0) * _speed_mult

func get_effective_damage(base_damage: float) -> float:
	return base_damage * _damage_mult

## Reproduce la animación adecuada. Si está transformado, busca prefijos ('transformed_', 'ssj_', 'sage_', 'kurama_').
func play_animation(anim_name: String) -> void:
	if not _animated_sprite or not _animated_sprite.sprite_frames:
		return

	# Si está transformado, intentar buscar versiones transformadas de la animación
	var target_name: String = anim_name
	if is_transformed:
		var candidates: Array[String] = [
			"transformed_" + anim_name,
			"ssj_" + anim_name,
			"sage_" + anim_name,
			"kurama_" + anim_name
		]
		for c in candidates:
			if _animated_sprite.sprite_frames.has_animation(c):
				target_name = c
				break

	# Si la animación no existe en SpriteFrames, no hacer nada para evitar errores
	if not _animated_sprite.sprite_frames.has_animation(target_name):
		return

	# Evitar reiniciar la misma animación si ya se está reproduciendo
	if _animated_sprite.animation == target_name and _animated_sprite.is_playing():
		return

	_animated_sprite.play(target_name)

func _flash_hit() -> void:
	if not _animated_sprite:
		return
	var prev_mod: Color = modulate
	modulate = Color(1.8, 0.4, 0.4, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "modulate", prev_mod, 0.12)

func set_facing(facing_right: bool) -> void:
	is_facing_right = facing_right
	if _animated_sprite:
		_animated_sprite.flip_h = not facing_right
	
	var hitbox := get_node_or_null("Hitbox") as Area2D
	if hitbox:
		# En Godot 2D la escala negativa en Area2D puede romper el cálculo de colisiones.
		# Mantenemos scale.x en 1.0 positivo y reflejamos las posiciones de las formas hijas.
		hitbox.scale = Vector2.ONE
		var dir: float = 1.0 if facing_right else -1.0
		hitbox.position.x = 2.0 * dir
		for child in hitbox.get_children():
			if child is CollisionShape2D:
				child.position.x = absf(child.position.x) * dir

## character_data.gd
## Resource que define TODOS los datos de un personaje.
## Filosofía: agregar un personaje nuevo = crear un .tres nuevo, sin tocar código.
class_name CharacterData
extends Resource

# ---------------------------------------------------------------------------
# Identificación
# ---------------------------------------------------------------------------
@export var id: String = ""
@export var display_name: String = ""

# ---------------------------------------------------------------------------
# Stats base
# ---------------------------------------------------------------------------
@export_group("Stats Base")
@export var max_health: float = 100.0
@export var max_energy: float = 100.0
@export var move_speed: float = 180.0
@export var jump_force: float = -500.0
@export var gravity_scale: float = 1.0

# ---------------------------------------------------------------------------
# Daños
# ---------------------------------------------------------------------------
@export_group("Daños")
@export var damage_basic: float = 8.0
@export var damage_special: float = 20.0
@export var energy_cost_special: float = 25.0
@export var energy_cost_transform: float = 40.0  ## Ki mínimo requerido para activar

# ---------------------------------------------------------------------------
# Timing del ataque (Calibrado con los sprites reales de Goku: 8 frames)
# Frames 0-3 (0.0s - 0.28s): Wind-up (preparación del golpe)
# Frames 4-5 (0.28s - 0.48s): Extensión máxima del puño (Hitbox activa)
# Frames 6-7 (0.48s - 0.65s): Recovery (recogida del brazo)
# ---------------------------------------------------------------------------
@export_group("Timing de Ataque")
@export var attack_duration: float = 0.65
@export var attack_active_start: float = 0.28
@export var attack_active_end: float = 0.48

# ---------------------------------------------------------------------------
# Hitstun
# ---------------------------------------------------------------------------
@export_group("Hitstun")
@export var hurt_duration: float = 0.4

# ---------------------------------------------------------------------------
# Ganancia de Energía (Fuera de transformación)
# ---------------------------------------------------------------------------
@export_group("Ganancia de Energía")
@export var energy_on_hit_dealt: float = 10.0   ## Ki ganado al acertar un golpe
@export var energy_on_hit_taken: float = 5.0    ## Ki ganado al recibir daño

# ---------------------------------------------------------------------------
# Transformación dinámica basada en Ki
# ---------------------------------------------------------------------------
@export_group("Transformación")
@export var transform_name: String = "Super Saiyajin"
@export var transform_speed_mult: float = 1.35             ## Multiplicador de velocidad
@export var transform_damage_mult: float = 1.5             ## Multiplicador de daño
@export var ki_drain_per_second: float = 8.0               ## Ki drenado por segundo mientras está activo
@export var ki_gain_hit_mult_transformed: float = 0.3      ## Fracción de Ki ganado al golpear transformado (30%)
@export var transform_cooldown: float = 8.0                ## Segundos de espera tras destransformarse

# ---------------------------------------------------------------------------
# Sprites y Audio
# ---------------------------------------------------------------------------
@export_group("Sprites")
@export_dir var sprite_dir_normal: String = ""
@export_dir var sprite_dir_transform: String = ""
@export var aura_particle_scene: PackedScene = null

@export_group("Audio")
@export var sfx_basic_attack: AudioStream = null
@export var sfx_special_attack: AudioStream = null
@export var sfx_transform: AudioStream = null
@export var sfx_hurt: AudioStream = null

@export_group("Tienda")
@export var is_locked_by_default: bool = false
@export var unlock_cost: int = 0

@export_group("Historia")
@export var dialogue_key: String = ""

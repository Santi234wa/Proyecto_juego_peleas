## character_data.gd
## Resource que define TODOS los datos de un personaje.
## Filosofía: agregar un personaje nuevo = crear un .tres nuevo, sin tocar código.
## Patrón: Data-Driven Design / Resource Pattern de Godot.
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
@export var energy_cost_transform: float = 50.0

# ---------------------------------------------------------------------------
# Timing del ataque (frames activos del hitbox)
# Se expresan en segundos desde que comienza la animación de ataque.
# ---------------------------------------------------------------------------
@export_group("Timing de Ataque")
@export var attack_duration: float = 0.5       ## Duración total de la animación
@export var attack_active_start: float = 0.1   ## Hitbox se activa en este segundo
@export var attack_active_end: float = 0.35    ## Hitbox se desactiva en este segundo

# ---------------------------------------------------------------------------
# Hitstun
# ---------------------------------------------------------------------------
@export_group("Hitstun")
@export var hurt_duration: float = 0.4   ## Segundos de hitstun al recibir golpe

# ---------------------------------------------------------------------------
# Energía ganada
# ---------------------------------------------------------------------------
@export_group("Ganancia de Energía")
@export var energy_on_hit_dealt: float = 10.0
@export var energy_on_hit_taken: float = 5.0

# ---------------------------------------------------------------------------
# Transformación
# ---------------------------------------------------------------------------
@export_group("Transformación")
@export var transform_duration: float = 15.0
@export var transform_speed_mult: float = 1.3
@export var transform_damage_mult: float = 1.5
@export var transform_name: String = ""

# ---------------------------------------------------------------------------
# Rutas de sprites
# ---------------------------------------------------------------------------
@export_group("Sprites")
@export_dir var sprite_dir_normal: String = ""
@export_dir var sprite_dir_transform: String = ""
@export var aura_particle_scene: PackedScene = null

# ---------------------------------------------------------------------------
# Audio
# ---------------------------------------------------------------------------
@export_group("Audio")
@export var sfx_basic_attack: AudioStream = null
@export var sfx_special_attack: AudioStream = null
@export var sfx_transform: AudioStream = null
@export var sfx_hurt: AudioStream = null

# ---------------------------------------------------------------------------
# Tienda / desbloqueo
# ---------------------------------------------------------------------------
@export_group("Tienda")
@export var is_locked_by_default: bool = false
@export var unlock_cost: int = 0

# ---------------------------------------------------------------------------
# Historia / diálogos
# ---------------------------------------------------------------------------
@export_group("Historia")
@export var dialogue_key: String = ""

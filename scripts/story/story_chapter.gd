## story_chapter.gd
## Resource que define los datos de un capítulo del modo historia ECOS.
## Permite configurar combates, diálogos y bifurcaciones narrativas de forma modular.
class_name StoryChapter
extends Resource

# ---------------------------------------------------------------------------
# Identificación
# ---------------------------------------------------------------------------
@export_group("Identificación")
@export var chapter_id: String = ""
@export var chapter_number: int = 1
@export var title: String = ""
@export_multiline var description: String = ""

# ---------------------------------------------------------------------------
# Configuración del Combate
# ---------------------------------------------------------------------------
@export_group("Combate")
@export var player_character_id: String = "goku"
@export var opponent_character_id: String = "naruto"
@export var map_id: String = "test_map"

## Dificultad de la IA: 0 = Fácil, 1 = Normal, 2 = Difícil
@export_range(0, 2) var ai_difficulty: int = 1

# ---------------------------------------------------------------------------
# Diálogos Narrativos
# ---------------------------------------------------------------------------
@export_group("Diálogos")
## Lista de diálogos previos al combate.
## Estructura por entrada: {"speaker": String, "text": String, "portrait": String, "side": String}
@export var intro_dialogue: Array[Dictionary] = []

## Lista de diálogos tras ganar el combate.
@export var win_dialogue: Array[Dictionary] = []

## Lista de diálogos tras perder el combate.
@export var lose_dialogue: Array[Dictionary] = []

# ---------------------------------------------------------------------------
# Decisiones y Flujo
# ---------------------------------------------------------------------------
@export_group("Bifurcaciones")
@export var has_decision: bool = false
@export var decision_prompt: String = ""

## Opciones disponibles si has_decision es true.
## Estructura: [{"id": String, "text": String, "target_chapter_id": String, "ending_id": String}]
@export var decision_options: Array[Dictionary] = []

## ID del siguiente capítulo en caso de avance lineal.
@export var next_chapter_id: String = ""

# ---------------------------------------------------------------------------
# Métodos de utilidad
# ---------------------------------------------------------------------------

## Verifica si este capítulo es el desenlace (sin siguiente capítulo lineal y sin opciones pendientes).
func is_ending_chapter() -> bool:
	return next_chapter_id.is_empty() and decision_options.is_empty()

## Retorna un resumen legible de la configuración del capítulo.
func get_summary() -> String:
	return "Capítulo %d: '%s' [%s vs %s] - Dificultad: %d" % [
		chapter_number, title, player_character_id, opponent_character_id, ai_difficulty
	]


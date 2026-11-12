## health_bar_ui.gd
## Barra de vida de un personaje. Se actualiza via señal Observer (health_changed).
## Se adjunta a un nodo ProgressBar dentro de la UI del combate.
extends ProgressBar

@export var character_path: NodePath = NodePath("")
@export var bar_color: Color = Color(0.1, 0.9, 0.1)

func _ready() -> void:
	min_value = 0.0
	show_percentage = false

	var style := StyleBoxFlat.new()
	style.bg_color = bar_color
	add_theme_stylebox_override("fill", style)

	_connect_to_character()

func _connect_to_character() -> void:
	if character_path.is_empty():
		push_warning("HealthBarUI: 'character_path' no asignado en el Inspector.")
		return

	var node := get_node_or_null(character_path)
	if not node:
		push_error("HealthBarUI: No se encontró nodo en character_path '%s'." % character_path)
		return

	# Usamos duck typing para evitar referencia circular con CharacterBase
	if not node.has_signal("health_changed"):
		push_error("HealthBarUI: El nodo en character_path no tiene la señal 'health_changed'.")
		return

	# Configurar valores iniciales accediendo por duck typing
	max_value = node.data.max_health if node.data else 100.0
	value     = node.current_health

	node.health_changed.connect(_on_health_changed)

func _on_health_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value     = current

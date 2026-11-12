## energy_bar_ui.gd
## Barra de energía (Ki / Chakra) de un personaje.
## Patrón Observer: Se actualiza en tiempo real al recibir la señal 'energy_changed'.
extends ProgressBar

@export var character_path: NodePath = NodePath("")
@export var bar_color: Color = Color(0.15, 0.65, 1.0)  # Azul Ki brillante

func _ready() -> void:
	min_value = 0.0
	show_percentage = false

	# Estilo visual de la barra de energía
	var style := StyleBoxFlat.new()
	style.bg_color = bar_color
	add_theme_stylebox_override("fill", style)

	_connect_to_character()

func _connect_to_character() -> void:
	if character_path.is_empty():
		push_warning("EnergyBarUI: 'character_path' no asignado en el Inspector.")
		return

	var node := get_node_or_null(character_path)
	if not node:
		push_error("EnergyBarUI: No se encontró nodo en character_path '%s'." % character_path)
		return

	if not node.has_signal("energy_changed"):
		push_error("EnergyBarUI: El nodo no tiene la señal 'energy_changed'.")
		return

	# Inicializar valores con el estado del personaje
	max_value = node.data.max_energy if node.data else 100.0
	value = node.current_energy

	# Suscripción Observer
	node.energy_changed.connect(_on_energy_changed)

func _on_energy_changed(current: float, maximum: float) -> void:
	max_value = maximum
	value = current


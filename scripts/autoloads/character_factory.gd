## character_factory.gd  — AUTOLOAD: "CharacterFactory"
## Crea instancias de personajes a partir de su CharacterData (Resource).
## Patrón: Factory Method — el resto del código nunca hace "preload(escena)" directo.
## Cambiar cómo se instancia un personaje = cambiar solo este archivo.
extends Node

# Mapeo id → PackedScene. Se carga una sola vez.
# Las escenas base son compartidas; los datos los diferencia el Resource.
const _SCENE_MAP: Dictionary = {
	"goku":      "res://scenes/characters/goku.tscn",
	"goku_echo": "res://scenes/characters/goku.tscn",
	"naruto":    "res://scenes/characters/naruto.tscn",
	"madara":    "res://scenes/characters/madara.tscn",
	"vegetto":   "res://scenes/characters/vegetto.tscn",
	"dummy":     "res://scenes/characters/dummy.tscn",
}

# Mapeo id_mapa → PackedScene
const _MAP_SCENE_MAP: Dictionary = {
	"valle_del_fin":  "res://scenes/maps/valle_del_fin.tscn",
	"valley_of_end":  "res://scenes/maps/valle_del_fin.tscn",
	"torneo":         "res://scenes/maps/torneo.tscn",
	"tournament":     "res://scenes/maps/torneo.tscn",
	"dimension_ecos": "res://scenes/maps/dimension_ecos.tscn",
	"test_map":       "res://scenes/maps/test_map.tscn",
}

# Cache de escenas ya cargadas para no recargar del disco en cada combate.
var _scene_cache: Dictionary = {}

# ---------------------------------------------------------------------------
# API pública
# ---------------------------------------------------------------------------

## Instancia un personaje dado su CharacterData.
## Retorna el nodo listo para agregar a la escena, con 'data' ya asignado.
## Si la escena no existe todavía (desarrollo temprano) retorna null con advertencia.
func create_character(char_data: CharacterData) -> CharacterBase:
	if not char_data:
		push_error("CharacterFactory: se recibió CharacterData nula.")
		return null

	var scene := _get_or_load_scene(char_data.id)
	if not scene:
		push_warning("CharacterFactory: escena para '%s' no disponible aún." % char_data.id)
		return null

	var instance: CharacterBase = scene.instantiate()
	instance.data = char_data  # Inyección de dependencia
	return instance

## Precarga todas las escenas del mapa para evitar hitching en medio del combate.
func preload_all() -> void:
	for id in _SCENE_MAP.keys():
		_get_or_load_scene(id)

## Obtiene la ruta de escena correspondiente a un map_id con fallback seguro
func get_map_scene_path(map_id: String) -> String:
	if _MAP_SCENE_MAP.has(map_id):
		var p: String = _MAP_SCENE_MAP[map_id]
		if ResourceLoader.exists(p):
			return p
	if ResourceLoader.exists("res://scenes/maps/test_map.tscn"):
		return "res://scenes/maps/test_map.tscn"
	return "res://resources/characters/test_map.tscn"

# ---------------------------------------------------------------------------
# Interno
# ---------------------------------------------------------------------------

func _get_or_load_scene(id: String) -> PackedScene:
	if _scene_cache.has(id):
		return _scene_cache[id]

	if not _SCENE_MAP.has(id):
		push_error("CharacterFactory: id '%s' no registrado en _SCENE_MAP." % id)
		return null

	var path: String = _SCENE_MAP[id]
	if not ResourceLoader.exists(path):
		var alt_path: String = "res://resources/characters/%s.tscn" % id
		if ResourceLoader.exists(alt_path):
			path = alt_path
		else:
			# Escena aún no creada en esta fase del desarrollo; no es error fatal.
			return null

	var scene := load(path) as PackedScene
	_scene_cache[id] = scene
	return scene


# Decisiones de Diseño — Juego de Pelea 2D

## ¿Por qué Godot 4 con GDScript?
Godot 4 es open-source, ligero y tiene un pipeline de exportación a Windows simple. GDScript es muy parecido a Python, fácil de leer en una evaluación académica, y se integra de forma nativa con el motor (sin binding overhead). El renderizador **Compatibility** garantiza que el juego corra en hardware modesto de cualquier estudiante.

---

## ¿Por qué 2D?

1. **Alcance realista**: 4 semanas con 2D vs 3D es la diferencia entre un producto terminado y una demo rota. Los juegos de pelea 2D tienen una identidad visual fortísima (Street Fighter, Guilty Gear, Dragon Ball FighterZ).
2. **Pixel art**: reduce la dependencia de assets profesionales. Sprites pequeños (64×64 px o similares) se pueden hacer con Libresprite/Aseprite y son fáciles de reemplazar.
3. **Hitboxes simples**: con `Area2D` rectangulares es suficiente para la mecánica de juego de pelea; en 3D habría que gestionar colisiones volumétricas mucho más complejas.

---

## ¿Por qué State Machine (Patrón State)?

Un personaje de juego de pelea tiene **comportamiento radicalmente diferente según el estado**: no puedes atacar mientras saltas (en esta implementación), no puedes moverte mientras bloqueas, etc. Sin FSM, esto termina en un `if/elif` gigantesco e imposible de mantener.

Con el patrón State:
- Cada estado es una clase independiente con entrada, lógica y salida.
- Agregar un estado nuevo (ej. "Agarre") = crear un archivo nuevo, sin tocar los existentes.
- El código base (`StateMachine`) no cambia nunca.

---

## ¿Por qué Resources para datos de personaje?

Godot permite crear subclases de `Resource` que se serializan en archivos `.tres` editables. Esto nos da:

1. **Data-Driven Design**: el diseñador ajusta stats en el Inspector sin abrir código.
2. **Extensibilidad sin modificar código base**: Madara y Vegetto son solo archivos `.tres` nuevos; el sistema los acepta sin cambiar `character_base.gd`.
3. **Separación de responsabilidades**: el código no hardcodea números; los números viven en datos.

---

## ¿Por qué Observer (señales de Godot)?

Las barras de vida y energía de la UI no deben saber nada del personaje internamente. El personaje solo emite `health_changed(current, max)` y la UI lo escucha. Esto:

- Evita acoplamiento UI ↔ Personaje.
- Permite tener múltiples oyentes (barra de vida, efectos de pantalla, IA) sin cambiar el emisor.
- Es el patrón nativo de Godot: las señales son el Observer de la plataforma.

---

## ¿Por qué Singleton con Autoload?

`GameData`, `SaveManager`, `InputManager` y `CharacterFactory` necesitan sobrevivir entre cambios de escena (menú → combate → menú). Los Autoloads de Godot son la solución oficial: se cargan una vez y persisten. Usar 4 Singletons con responsabilidades separadas (en lugar de uno gigantesco) respeta el **Principio de Responsabilidad Única**.

---

## ¿Por qué ConfigFile y no JSON?

ConfigFile es la solución nativa de Godot para guardado simple:
- Tipos de datos nativos (Array, bool, int) sin serialización manual.
- Formato INI legible a mano para debugging.
- Manejo de errores con códigos de retorno claros.
- Para datos más complejos (futuro) se puede migrar a JSON o SQLite sin cambiar la API de `SaveManager`.

---

## ¿Por qué no cinemáticas de video?

Los videos requieren assets de alta calidad, compresión adicional, integración con VideoStreamPlayer y aumentan el tamaño del ejecutable. Los efectos programáticos (freeze frame, zoom, flash, particles, shake) son:
- 100 % en código: fáciles de ajustar y de documentar.
- Más baratos en disco y memoria.
- Evaluables como mecánicas de ingeniería, no solo como arte.

---

## ¿Por qué HUD programático por código y Patrón Observer?

El HUD de combate (`HealthBarUI`, `EnergyBarUI` y `RoundTimerUI`) se construye dinámicamente mediante nodos `Control` desde GDScript sin depender de escenas rígidas:
- **Desacoplamiento total**: La interfaz no modifica variables de los personajes; se suscribe como Observer a `health_changed`, `energy_changed`, `transformation_started` y `transformation_ended`.
- **Estela de daño (Damage Ghost Trail)**: Doble barra superpuesta donde la barra de vida actual (verde) desciende de inmediato y la estela (amarilla) espera un retardo de 0.4 s antes de interpolar suavemente con un `Tween`, emulando el estándar visual de juegos como Street Fighter 6 y Dragon Ball FighterZ.
- **Data-Driven Ki Threshold**: El umbral y aviso de transformación no están fijos en código; se calculan en tiempo de ejecución leyendo `energy_cost_transform` del `CharacterData`.
- **Simetría y Reusabilidad**: El sistema detecta automáticamente `player_id` para invertir la dirección de vaciado (`FILL_END_TO_BEGIN`) en Jugador 2 y centrar el temporizador de ronda y marcadores de victoria entre ambos contendientes.


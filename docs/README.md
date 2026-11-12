# README — Juego de Pelea 2D (Proyecto Universitario)

> **Motor**: Godot 4.x · **Lenguaje**: GDScript · **Renderizador**: Compatibility  
> **Género**: Fighting Game 2D Pixel Art  
> **Personajes**: Goku · Naruto · Madara · Vegetto  
> **Mapas**: Valle del Fin · Torneo de Artes Marciales · Namek (DLC tienda)

---

## Requisitos

| Herramienta | Versión mínima | Notas |
|-------------|---------------|-------|
| Godot Engine | 4.3+ | Descargar en https://godotengine.org |
| Sistema Operativo | Windows 10 / macOS 12 / Ubuntu 22 | |
| RAM | 4 GB | |
| GPU | Compatible con OpenGL 3.3 / Vulkan | El renderizador Compatibility lo garantiza |

---

## Estructura del proyecto

```
peleas/
├── assets/
│   ├── fonts/           # Fuentes pixel art
│   ├── particles/       # Escenas de partículas (.tscn)
│   ├── sounds/
│   │   ├── music/       # Tracks de fondo (.ogg)
│   │   └── sfx/         # Efectos de sonido (.wav)
│   └── sprites/
│       ├── goku/        # normal/ y transform/ (Super Saiyajin)
│       ├── naruto/      # normal/ y transform/ (Modo Sabio)
│       ├── madara/
│       └── vegetto/
├── docs/
│   ├── design_decisions.md
│   ├── diagrams.md      # Diagramas de clases y estados (Mermaid)
│   ├── sprint_plan.md
│   └── user_stories.md
├── resources/
│   ├── characters/      # goku.tres, naruto.tres, madara.tres, vegetto.tres
│   ├── maps/            # Datos de los mapas
│   └── shop/            # Ítems de la tienda
├── scenes/
│   ├── characters/      # goku.tscn, naruto.tscn, …
│   ├── effects/         # flash.tscn, screen_shake.tscn, …
│   ├── maps/            # valley_of_end.tscn, tournament.tscn, namek.tscn
│   └── ui/              # main_menu.tscn, char_select.tscn, hud.tscn, …
├── scripts/
│   ├── autoloads/       # game_data.gd, save_manager.gd, character_factory.gd, input_manager.gd
│   ├── characters/      # character_base.gd, character_data.gd, goku.gd, naruto.gd
│   ├── states/          # character_state.gd, state_machine.gd, idle_state.gd, …
│   ├── ai/              # enemy_ai.gd, estados de IA
│   ├── ui/              # Scripts de UI
│   └── utils/           # Helpers genéricos
└── ui/                  # Temas de UI (.tres), fuentes configuradas
```

---

## Cómo correr el proyecto

1. Abre Godot 4.
2. Haz clic en **Import** → navega a `peleas/project.godot` → **Open**.
3. Espera que importe los recursos (primera vez puede tardar ~30 s).
4. Presiona **F5** o el botón ▶ para ejecutar.

---

## Configurar los Autoloads (obligatorio, solo una vez)

> **Nota**: Si los Autoloads ya están en `project.godot`, omite este paso.

1. Ve a **Project → Project Settings → Autoload**.
2. Agrega los siguientes scripts en este orden:

| Ruta del script | Nombre del Autoload |
|----------------|---------------------|
| `res://scripts/autoloads/game_data.gd` | `GameData` |
| `res://scripts/autoloads/save_manager.gd` | `SaveManager` |
| `res://scripts/autoloads/character_factory.gd` | `CharacterFactory` |
| `res://scripts/autoloads/input_manager.gd` | `InputManager` |

3. Cierra la ventana. Godot los cargará al inicio.

---

## Configurar los controles (obligatorio)

1. Ve a **Project → Project Settings → Input Map**.
2. Agrega las siguientes acciones:

### Jugador 1 (WASD + teclas cercanas)
| Acción | Tecla sugerida |
|--------|---------------|
| `p1_left` | A |
| `p1_right` | D |
| `p1_jump` | W |
| `p1_attack` | F |
| `p1_special` | G |
| `p1_block` | S |
| `p1_transform` | H |

### Jugador 2 (Flechas + numpad)
| Acción | Tecla sugerida |
|--------|---------------|
| `p2_left` | Flecha izquierda |
| `p2_right` | Flecha derecha |
| `p2_jump` | Flecha arriba |
| `p2_attack` | Numpad 1 |
| `p2_special` | Numpad 2 |
| `p2_block` | Flecha abajo |
| `p2_transform` | Numpad 3 |

---

## Exportar el juego (Windows)

1. Instala las plantillas de exportación: **Editor → Manage Export Templates → Download**.
2. Ve a **Project → Export → Add → Windows Desktop**.
3. Configura la ruta de salida (ej. `export/peleas.exe`).
4. Haz clic en **Export Project** (sin depuración para el entregable final).
5. El ejecutable resultante no requiere Godot instalado.

---

## Convenciones de código

- Un script = una responsabilidad.
- Nombres en `snake_case` para variables y funciones, `PascalCase` para clases.
- Señales en español descriptivo: `health_changed`, `character_died`, `round_ended`.
- Comentarios en español para maximizar comprensión del equipo y del evaluador.
- Ningún número mágico en el código: todo en `CharacterData` o como constante nombrada.

---

## Créditos

Proyecto universitario — Ingeniería de Software / Desarrollo de Videojuegos  
Motor: [Godot Engine](https://godotengine.org) (MIT License)  
Sprites: propios / fuentes libres (ver `assets/sprites/CREDITS.txt`)


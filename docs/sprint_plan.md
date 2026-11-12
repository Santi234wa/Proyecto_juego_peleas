# Plan de Sprints — Juego de Pelea 2D

> **Duración**: 4 semanas (1 sprint = 1 semana)  
> **Equipo**: Estudiantes universitarios  
> **Motor**: Godot 4 — GDScript — Renderizador Compatibility

---

## Sprint 1 — Fundamentos y Goku jugable
**Objetivo**: Que un personaje pueda moverse, saltar y atacar en un mapa de prueba.  
**Corresponde a**: Fase 1 y Fase 2 del plan de fases.

| # | Tarea | HU | Prioridad |
|---|-------|----|-----------|
| 1.1 | Estructura de carpetas y autoloads | — | 🔴 |
| 1.2 | `CharacterData` Resource + datos de Goku (.tres) | — | 🔴 |
| 1.3 | `CharacterBase` + `StateMachine` + `CharacterState` | — | 🔴 |
| 1.4 | Estados: Idle, Walk, Jump (física y animación) | HU-01 | 🔴 |
| 1.5 | Estado Attack básico + hitbox temporal | HU-02 | 🔴 |
| 1.6 | Señal `health_changed` + barra de vida en UI de prueba | HU-05 | 🔴 |
| 1.7 | Mapa de prueba (plataforma plana, cámara fija) | — | 🔴 |
| 1.8 | Documentación: README borrador, diagramas iniciales | — | 🟡 |

**Criterio de hecho**: Goku se mueve, salta, ataca y la barra de vida baja.

---

## Sprint 2 — Sistema de combate completo y modo local
**Objetivo**: Dos personajes se enfrentan con sistema de combate real.  
**Corresponde a**: Fases 3, 4 y 5.

| # | Tarea | HU | Prioridad |
|---|-------|----|-----------|
| 2.1 | Hitboxes/Hurtboxes con `Area2D` + daño real | HU-02 | 🔴 |
| 2.2 | Estado Block + reducción de daño | HU-04 | 🔴 |
| 2.3 | Barra de energía + señal `energy_changed` | HU-06 | 🔴 |
| 2.4 | Estado Special + costo de energía | HU-03 | 🔴 |
| 2.5 | Transformación (Goku: Super Saiyajin) + partículas | HU-06 | 🔴 |
| 2.6 | Naruto via nuevo Resource `.tres` | — | 🔴 |
| 2.7 | `InputManager` + mapeo P1 / P2 en el mismo teclado | HU-08 | 🔴 |
| 2.8 | Sistema de rondas + pantalla de victoria de ronda | HU-07 | 🔴 |
| 2.9 | Menú principal + selección de personaje | HU-11, HU-12 | 🟡 |
| 2.10 | Segundo mapa (Torneo de Artes Marciales) | — | 🟡 |
| 2.11 | Documentación: historias de usuario completadas, diagramas actualizados | — | 🟡 |

**Criterio de hecho**: Goku vs Naruto, 2 rondas, modo local funcional.

---

## Sprint 3 — IA, Modo Historia y Tienda
**Objetivo**: El juego es completo en modos principales; hay progresión y guardado.  
**Corresponde a**: Fases 6 y 7.

| # | Tarea | HU | Prioridad |
|---|-------|----|-----------|
| 3.1 | `EnemyAI` con 3 niveles de dificultad | HU-10 | 🟡 |
| 3.2 | Estados de IA (Approach, Attack, Block, Idle) | HU-10 | 🟡 |
| 3.3 | Modo historia: 5 combates definidos en datos | HU-09 | 🟡 |
| 3.4 | Sistema de diálogos entre combates | HU-09 | 🟡 |
| 3.5 | Monedas: lógica de ganancia por ronda/combate | HU-13 | 🟡 |
| 3.6 | `SaveManager`: guardar y cargar progreso | HU-15 | 🟡 |
| 3.7 | Tienda: comprar Madara, Vegetto, Namek | HU-14 | 🟡 |
| 3.8 | Pantalla de selección de mapa con candados | HU-12 | 🟡 |
| 3.9 | Documentación: plan de sprints actualizado, notas de diseño | — | 🟡 |

**Criterio de hecho**: Modo historia completable de inicio a fin; la tienda guarda compras entre sesiones.

---

## Sprint 4 — Contenido extra, Efectos y Pulido
**Objetivo**: Juego pulido, exportable y listo para entrega académica.  
**Corresponde a**: Fases 8 y 9.

| # | Tarea | HU | Prioridad |
|---|-------|----|-----------|
| 4.1 | Madara y Vegetto: solo Resources + assets (sin código nuevo) | — | 🟢 |
| 4.2 | Mapa Namek (desbloqueable) | — | 🟢 |
| 4.3 | Efectos de transformación: freeze, zoom, flash, shake, partículas | HU-16 | 🟢 |
| 4.4 | Efectos de ultimate: secuencia equivalente | HU-16 | 🟢 |
| 4.5 | Pulido de UI: fuentes pixel art, colores, iconos | — | 🟢 |
| 4.6 | Música y SFX en todas las pantallas | — | 🟢 |
| 4.7 | Pruebas de regresión manual (checklist) | — | 🟡 |
| 4.8 | Exportación del proyecto (.exe Windows) | — | 🔴 |
| 4.9 | Documentación final: README completo, decisiones de diseño | — | 🔴 |

**Criterio de hecho**: El .exe corre sin Godot instalado; la documentación está completa.

---

## Resumen de Fases vs Sprints

| Fase | Contenido | Sprint |
|------|-----------|--------|
| 1 | Estructura y arquitectura | S1 |
| 2 | Goku + máquina de estados | S1 |
| 3 | Sistema de combate | S2 |
| 4 | Naruto + modo local | S2 |
| 5 | Menús y selección | S2 |
| 6 | IA y modo historia | S3 |
| 7 | Tienda y guardado | S3 |
| 8 | Madara, Vegetto, Namek | S4 |
| 9 | Efectos, pulido, exportación | S4 |


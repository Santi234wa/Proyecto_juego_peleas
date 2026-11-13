# Historias de Usuario — Juego de Pelea 2D (Proyecto Universitario)

## Convenciones
- **ID**: HU-XX  
- **Formato**: Como *[rol]*, quiero *[acción]*, para *[beneficio]*.  
- **Prioridad**: 🔴 Alta · 🟡 Media · 🟢 Baja  
- **Sprint**: S1–S4

---

## Épica 1 — Personajes y Combate

### HU-01 · Movimiento básico 🔴 · S1
Como **jugador**, quiero mover a mi personaje izquierda/derecha y saltar, para poder posicionarme en el combate.

**Criterios de aceptación**
- [x] El personaje se desplaza horizontalmente al presionar las teclas configuradas.
- [x] El personaje salta con una fuerza definida en su CharacterData.
- [x] El personaje no atraviesa el suelo ni los límites del escenario.
- [x] La animación cambia correctamente entre idle, walk y jump.

---

### HU-02 · Ataque básico 🔴 · S1
Como **jugador**, quiero presionar un botón para realizar un ataque básico, para causar daño al rival.

**Criterios de aceptación**
- [x] Al presionar la tecla de ataque se reproduce la animación de golpe.
- [x] Se activa una hitbox durante los frames activos del ataque (con set_deferred).
- [x] El rival recibe el daño definido en `damage_basic` del CharacterData del atacante.
- [x] Un ataque conecta una sola vez por activación (lista de objetivos golpeados).
- [x] No se puede atacar durante el lag de recuperación del mismo ataque.

---

### HU-03 · Ataque especial 🔴 · S2
Como **jugador**, quiero usar un ataque especial que consuma energía, para hacer más daño estratégicamente.

**Criterios de aceptación**
- [ ] El ataque especial solo se ejecuta si `current_energy >= energy_cost_special`.
- [ ] La barra de energía se reduce visualmente al usarlo.
- [ ] El daño es `damage_special` × multiplicador de transformación si está activo.
- [ ] Si no hay energía suficiente, el ataque no se ejecuta (sin animación de error).

---

### HU-04 · Bloqueo 🔴 · S2
Como **jugador**, quiero presionar un botón para bloquear, para reducir el daño recibido.

**Criterios de aceptación**
- [x] Mientras se mantiene la tecla de bloqueo, el personaje entra al estado `Blocking`.
- [x] Los golpes recibidos mientras se bloquea causan el 50 % del daño normal.
- [x] No se puede atacar ni moverse mientras se bloquea.
- [x] Al soltar la tecla de bloqueo se retorna a Idle.

---

### HU-05 · Barra de vida y muerte 🔴 · S1
Como **jugador**, quiero ver la barra de vida disminuir al recibir daño, para saber cuánta vida me queda.

**Criterios de aceptación**
- [x] La barra se actualiza al recibir la señal Observer `health_changed`.
- [x] Estela de daño (damage ghost trail): barra amarilla retardada que interpola suavemente con Tween tras 0.4 s.
- [x] Modo espejado para Jugador 2 (`FILL_END_TO_BEGIN`) que se vacía hacia el lado opuesto.
- [x] Marco oscuro con borde blanco fino, retrato cuadrado con inicial y nombre del personaje.
- [x] Al llegar a 0 el personaje emite `character_died`, muestra banner de K.O. y permite reiniciar con [R].
- [x] La barra nunca baja de 0 ni sube de `max_health`.

---

### HU-06 · Barra de energía, HUD y transformación dinámica por Ki 🔴 · S2
Como **jugador**, quiero acumular energía dando y recibiendo golpes para poder transformarme y sostener la forma según mi Ki, para tener una mecánica estratégica de gestión de recursos.

**Criterios de aceptación**
- [x] Fuera de transformación: dar un golpe suma `energy_on_hit_dealt` (+10 Ki) y recibir golpe suma `energy_on_hit_taken` (+5 Ki).
- [x] Barra de Ki más delgada debajo de la de vida con divisiones visibles al 25%, 50% y 75%.
- [x] Marcador visual del Ki mínimo necesario para transformar leído dinámicamente del Resource (`CharacterData`).
- [x] Al tener Ki suficiente: parpadeo suave de la barra y aviso contextual ("H · Transformar" / "P · Transformar").
- [x] Al presionar la tecla de transformación con Ki suficiente (≥ `energy_cost_transform`), se inicia la transformación.
- [x] Mientras está transformado: la barra cambia a color dorado y se drena continuamente cada segundo (`ki_drain_per_second`).
- [x] Mientras está transformado, dar golpes suma solo una fracción del Ki (`ki_gain_hit_mult_transformed`) y recibir daño NO suma Ki.
- [x] Temporizador central de ronda en marco superior con cuenta regresiva, número de ronda ("ROUND 1") y marcadores de victorias ganadas por jugador.

---

### HU-07 · Contador de rondas y Fin de Partida (Match Over) 🔴 · S2
Como **jugador**, quiero ver cuántas rondas ha ganado cada jugador y que al alcanzar 2 victorias se termine el combate con una pantalla de victoria, para tener un ciclo completo de partida competitiva.

**Criterios de aceptación**
- [x] Se muestra un marcador de victorias de ronda con puntos dorados (`RoundTimerUI`) a los lados del temporizador central.
- [x] Al terminar una ronda se actualiza el marcador en `GameData`, se muestra el banner de fin de ronda y avanza a la siguiente ronda con [R].
- [x] Al ganar 2 rondas (`rounds_to_win`, configurable en `GameData`), el controlador emite `match_finished(ganador)` vía Observer y se activa la pantalla de victoria (`VictoryScreenUI`).
- [x] La pantalla de victoria muestra el nombre del ganador leído directamente de su Resource (`CharacterData.display_name`) y el marcador final de rondas.
- [x] Los luchadores quedan congelados (sin movimiento ni ataques) mientras la pantalla de victoria está activa.
- [x] Botón "Revancha": reinicia la partida desde cero (rondas 0-0, vida, Ki y reloj reiniciados) con los mismos personajes.
- [x] Botón "Menú": emite la señal `back_to_menu_requested` y redirige a la escena de menú principal cuando esté creada.

---

## Épica 2 — Modos de Juego

### HU-08 · Modo local 2 jugadores 🔴 · S2
Como **jugador local**, quiero jugar contra un amigo en el mismo teclado, para competir en el mismo equipo.

**Criterios de aceptación**
- [x] P1 usa el mapeo `p1_*` (WASD para movimiento/salto, S para bloqueo, F para ataque, H para transformación).
- [x] P2 usa el mapeo `p2_*` (Flechas del cursor para movimiento/salto, Flecha abajo para bloqueo, K / Numpad 1 para ataque, P / Numpad 3 para transformación).
- [x] Los controles no interfieren entre jugadores (leídos independientemente por `player_id` en `InputManager`).
- [x] `InputManager` auto-registra controles de P2 por defecto sin requerir configuración manual.
- [x] Se puede iniciar desde el menú principal con la opción "Modo local".

---

### HU-09 · Modo historia 🟡 · S3
Como **jugador**, quiero jugar 5 combates en orden creciente de dificultad con pequeños diálogos entre peleas, para tener una experiencia narrativa.

**Criterios de aceptación**
- [ ] Los 5 combates se definen en un array de datos (personaje rival, dificultad, diálogo).
- [ ] Entre cada combate aparece un diálogo de 2–4 líneas antes del siguiente.
- [ ] Al ganar todos los combates se muestra una pantalla de créditos/fin.
- [ ] El progreso (combate alcanzado) se guarda en disco.

---

### HU-10 · IA enemiga con 3 niveles (Fase 6 - Paso 1) 🟡 · S3
Como **jugador**, quiero que la IA tenga 3 niveles de dificultad, para poder aprender y desafiarme progresivamente.

**Criterios de aceptación**
- [x] Fácil: la IA actúa con delays largos (0.8 s) y solo ataca con golpes básicos.
- [x] Normal: la IA usa ataques especiales, mide distancias, se transforma y bloquea ocasionalmente (40%).
- [x] Difícil: la IA reacciona con delays cortos (0.15 s), usa transformación, desata Ultimate al 100% Ki, persigue agresivamente y bloquea ataques con altos reflejos (80%).
- [x] El nivel se configura en GameData (`GameData.ai_difficulty`) antes de iniciar el combate o mediante la propiedad exportada `difficulty`.
- [x] Gobernado por `EnemyAI` simulando inputs virtuales en `InputManager` para respetar la física, frame data y StateMachine del personaje sin saltarse reglas.
- [x] Atajo de prueba con tecla F1 para alternar el control por IA de P2 en cualquier momento durante la partida.

---

## Épica 3 — Interfaz y Menús

### HU-11 · Menú principal (Fase 5 - Paso 1) 🔴 · S2
Como **jugador**, quiero un menú principal estilizado y dinámico al iniciar el juego, para navegar fácilmente entre los modos y opciones disponibles.

**Criterios de aceptación**
- [x] Canvas base 680x400 escalable proporcionalmente a cualquier resolución de ventana.
- [x] Capa 1: Fondo púrpura (`#3A2F55`) con sol naranja (`#E8915A`) y 2 capas de montañas escalonadas (`#5D3F63` y `#46304F`).
- [x] Capa 2: Panel diagonal naranja (`#F28C28`) con trama halftone (`#D9731A`), 3 líneas de velocidad (`#FFC266`) y franjas paralelas negra (`#151515`) y amarilla (`#FFD23F`).
- [x] Capa 3: Personaje en pixel art (Goku idle a escala 3x, filtro Nearest) con animación de respiración suave en bucle y pies apoyados en la barra inferior.
- [x] Capa 4: Banner de título en paralelogramo amarillo inclinado con borde negro de 3 px y texto placeholder personalizable (`game_title`).
- [x] Capa 5: Opciones escalonadas hacia la derecha (16 px offset X, 50 px Y): "Modo historia", "Modo local", "Tienda", "Opciones", "Salir".
  - Opción no seleccionada: texto blanco con contorno negro de 4 px (tamaño 22).
  - Opción seleccionada: texto negro (tamaño 26) sobre franja amarilla con sombra negra desplazada 5 px.
  - Opciones bloqueadas con etiqueta "(Próximamente)" navegables pero no accionables.
- [x] Capa 6: Barra inferior negra de 28 px con teclas amarillas ("↑↓", "Enter", "Esc") y etiquetas de ayuda ("Navegar", "Elegir", "Volver").
- [x] Navegación completa por teclado (flechas / WASD / Enter / Espacio / Esc) y mouse (hover y click).
- [x] Tweens fluidos: entrada de panel desde la izquierda (0.35 s), caída de banner (0.35 s), entrada escalonada de opciones (0.06 s delay) y deslizamiento elástico (`TRANS_BACK`, 0.12 s).
- [x] Soporte graceful para AudioStreamPlayer (SFX mover y seleccionar sin fallar si faltan assets).
- [x] Selección inicial por defecto en "Modo local", que emite `start_local_mode` y transiciona al escenario de combate.

---

### HU-12 · Selección de personaje (Fase 5 - Paso 2) 🔴 · S2
Como **jugadores**, queremos una pantalla de selección simultánea de luchadores estilo manga, para elegir a nuestros personajes antes del combate.

**Criterios de aceptación**
- [x] Canvas base 680x400 con división manga: mitad izquierda naranja (#F28C28) con trama (#D9731A) para J1, y mitad derecha púrpura (#3A2F55) con trama (#4A3D6B) para J2.
- [x] Banner central superior inclinado "Elige tu luchador" en amarillo con borde negro de 3 px.
- [x] Cuadrícula central de 4 columnas, casillas cuadradas de 40 px con 6 px de separación, marco negro de 3 px y fondo #46304F. Casillas vacías (#2A2240) configurables con `show_empty_slots`.
- [x] Casilla "Aleatorio" con signo "?" como última opción que elige al azar entre los personajes desbloqueados.
- [x] Cursores independientes: J1 marco amarillo (#FFD23F) de 3 px y J2 marco blanco (#FFFFFF). Visibles concéntricamente cuando ambos están en la misma casilla.
- [x] Navegación envolvente con wrap-around en filas y columnas para ambos jugadores.
- [x] Luchadores en grande a los lados y retratos de la cuadrícula con animación frontal (sprites sur mirando de frente, idle con respiración suave, pies sobre línea común `y = 290`). J1 y J2 mirando de frente a la pantalla.
- [x] Soporte en `CharacterData` para `sprite_dir_select` y auto-conversión de animaciones frontales GIF -> PNG (Goku y Naruto).
- [x] Paleta alternativa para J2 (`alt_tint`) aplicada automáticamente en caso de mirror match.
- [x] Banner amarillo inclinado con nombre del personaje y 3 barras de stats planas (Vida, Vel., Daño) leídas de `CharacterData`.
- [x] Etiquetas de estado debajo de la cuadrícula: "J1 eligiendo / listo" y "J2 eligiendo / listo".
- [x] Barra inferior de 28 px con etiquetas "J1" y "J2" y sus teclas de control leídas dinámicamente de `InputMap`.
- [x] Al confirmar ambos jugadores, almacena `player1_data` y `player2_data` en `GameData` y transiciona al combate.
- [ ] Selección de mapa entre los desbloqueados.

---

## Épica 4 — Tienda y Guardado

### HU-13 · Ganar monedas en combate 🟡 · S3
Como **jugador**, quiero ganar monedas al finalizar un combate, para poder comprar contenido.

**Criterios de aceptación**
- [ ] Al ganar una ronda se suman monedas proporcionales (ej. 50 por ronda, 100 extra por ganar el combate).
- [ ] Las monedas se suman a `GameData.session_coins` y se guardan con `SaveManager.save_game()`.
- [ ] El total de monedas se muestra en el menú principal y en la tienda.

---

### HU-14 · Tienda de contenido 🟡 · S3
Como **jugador**, quiero comprar personajes y mapas con monedas, para desbloquear contenido nuevo.

**Criterios de aceptación**
- [ ] La tienda muestra Namek, Madara y Vegetto con su precio.
- [ ] Al pulsar "Comprar" y tener saldo suficiente, el ítem se desbloquea y el saldo baja.
- [ ] Si el saldo es insuficiente, aparece un mensaje de error.
- [ ] La compra se guarda en disco inmediatamente.

---

### HU-15 · Guardado y carga de progreso 🟡 · S3
Como **jugador**, quiero que mi progreso se guarde automáticamente, para no perder lo desbloqueado.

**Criterios de aceptación**
- [ ] El guardado ocurre al final de cada combate y en cada compra de tienda.
- [ ] Al iniciar el juego se carga el progreso automáticamente.
- [ ] Si no existe un guardado, se inicia con los valores por defecto (Goku, Naruto, 2 mapas).

---

## Épica 5 — Efectos y Pulido

### HU-16 · Efectos de transformación y ultimate 🟢 · S4
Como **jugador**, quiero ver efectos visuales impactantes al transformarme o usar un ultimate, para que el juego se sienta épico.

**Criterios de aceptación**
- [x] Al transformarse: congelado de pantalla (0.1 s), zoom de cámara, flash blanco, temblor y activación de partículas.
- [x] Al usar el ultimate: secuencia cinemática en 4 fases (~3.5 s) con hitstop, oscurecimiento y bandas de cine (letterbox).
- [x] En el Ultimate de Goku: se transforma en Super Saiyajin durante la cinemática utilizando animación frontal de carga (`ssj_charge_south`), retrato frontal en primer plano con líneas de velocidad (`ssj_select_idle`), postura este de combate al disparar el rayo (`ssj_ultimate_east`), y al concluir permanece en Super Saiyajin con 40 Ki activo.
- [x] Los efectos no afectan negativamente la lógica de combate: invulnerabilidad temporal y drenaje de Ki pausado durante la cinemática.
- [x] Los efectos corren en 60 FPS sin caídas visibles en hardware objetivo.


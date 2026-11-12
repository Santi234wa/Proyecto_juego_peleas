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
- [x] Al llegar a 0 el personaje emite `character_died` y transita a KO.
- [x] La barra nunca baja de 0 ni sube de `max_health`.

---

### HU-06 · Barra de energía y transformación dinámica por Ki 🔴 · S2
Como **jugador**, quiero acumular energía dando y recibiendo golpes para poder transformarme y sostener la forma según mi Ki, para tener una mecánica estratégica de gestión de recursos.

**Criterios de aceptación**
- [x] Fuera de transformación: dar un golpe suma `energy_on_hit_dealt` (+10 Ki) y recibir golpe suma `energy_on_hit_taken` (+5 Ki).
- [x] Al presionar la tecla de transformación con Ki suficiente (≥ `energy_cost_transform`), se inicia la transformación.
- [x] Mientras está transformado, el Ki se drena continuamente cada segundo (`ki_drain_per_second`).
- [x] Mientras está transformado, dar golpes suma solo una fracción del Ki (`ki_gain_hit_mult_transformed`) y recibir daño NO suma Ki.
- [x] La transformación aumenta stats (daño x1.5, velocidad x1.35) y aplica tinte dorado Super Saiyajin.
- [x] La transformación termina automáticamente cuando el Ki llega a 0 (`end_transformation`), restaurando stats normales.
- [x] Tras destransformarse, se activa un enfriamiento (`transform_cooldown`) antes de poder volver a transformarse.

---

### HU-07 · Contador de rondas 🔴 · S2
Como **jugador**, quiero ver cuántas rondas ha ganado cada jugador, para saber quién va ganando el combate.

**Criterios de aceptación**
- [ ] Se muestra un marcador de victorias de ronda (ej. ● ○) para cada jugador.
- [ ] Al terminar una ronda se actualiza el marcador y se muestra una pantalla de "Ronda X".
- [ ] Al ganar 2 rondas se termina el combate y se va a la pantalla de victoria.

---

## Épica 2 — Modos de Juego

### HU-08 · Modo local 2 jugadores 🔴 · S2
Como **jugador local**, quiero jugar contra un amigo en el mismo teclado, para competir en el mismo equipo.

**Criterios de aceptación**
- [ ] P1 usa el mapeo `p1_*` (WASD + teclas cercanas) y P2 usa `p2_*` (flechas + teclado numérico).
- [ ] Los controles no interfieren entre jugadores.
- [ ] Se puede iniciar desde el menú principal con la opción "Local".

---

### HU-09 · Modo historia 🟡 · S3
Como **jugador**, quiero jugar 5 combates en orden creciente de dificultad con pequeños diálogos entre peleas, para tener una experiencia narrativa.

**Criterios de aceptación**
- [ ] Los 5 combates se definen en un array de datos (personaje rival, dificultad, diálogo).
- [ ] Entre cada combate aparece un diálogo de 2–4 líneas antes del siguiente.
- [ ] Al ganar todos los combates se muestra una pantalla de créditos/fin.
- [ ] El progreso (combate alcanzado) se guarda en disco.

---

### HU-10 · IA enemiga con 3 niveles 🟡 · S3
Como **jugador**, quiero que la IA tenga 3 niveles de dificultad, para poder aprender y desafiarme progresivamente.

**Criterios de aceptación**
- [ ] Fácil: la IA actúa con delays largos y solo ataca básico.
- [ ] Normal: la IA usa ataques especiales y bloquea ocasionalmente.
- [ ] Difícil: la IA reacciona más rápido, usa transformación y persigue agresivamente.
- [ ] El nivel se configura en GameData antes de iniciar el combate.

---

## Épica 3 — Interfaz y Menús

### HU-11 · Menú principal 🔴 · S2
Como **jugador**, quiero un menú con opciones claras al iniciar el juego, para navegar fácilmente.

**Criterios de aceptación**
- [ ] Opciones: Historia, Local, Tienda, Salir.
- [ ] Cada botón lleva a la escena correspondiente.
- [ ] Hay música de fondo en el menú.

---

### HU-12 · Selección de personaje y mapa 🔴 · S2
Como **jugador**, quiero seleccionar mi personaje y el mapa antes de combatir, para personalizar la partida.

**Criterios de aceptación**
- [ ] Se muestran solo los personajes desbloqueados.
- [ ] Los personajes bloqueados aparecen con candado y su costo en monedas.
- [ ] Se puede seleccionar el mapa entre los desbloqueados.
- [ ] Los datos elegidos se almacenan en `GameData` antes de cargar el combate.

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
- [ ] Al transformarse: congelado de pantalla (0.1 s), zoom de cámara, flash blanco, temblor y activación de partículas.
- [ ] Al usar el ultimate: secuencia equivalente con duración proporcional.
- [ ] Los efectos no afectan la lógica de juego (el timer de combate se pausa durante el freeze).
- [ ] Los efectos corren en 60 FPS sin caídas visibles en hardware objetivo.


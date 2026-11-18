# Elkünufe — Plan de desarrollo

> **Elkünufe** (mapudungun): «el que guarda o deja cosas», del verbo *elkünun* (guardar, dejar).
> Juego de rompecabezas 2D para macOS, inspirado en el género de empujar cajas creado por Sokoban (Hiroyuki Imabayashi, 1981).

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Plataforma | macOS nativo, solo Apple silicon (arm64); sin versión Intel |
| Tecnología | Swift + SpriteKit (tablero) + SwiftUI (menús) |
| Versión mínima | macOS 14 (Sonoma) |
| Distribución | Firma ad hoc, sin notarización ni App Store; descarga gratis (GitHub Releases) |
| Estética | Minimalista plana, inspiración mapuche sutil (paleta de textiles: rojo, negro, blanco, añil; patrones geométricos sencillos). Sin símbolos sagrados (p. ej. kultrún, rewe) |
| Personaje | Zorro culpeo (*Lycalopex culpaeus*), estilizado y geométrico |
| Niveles | Generador procedural con solucionador que garantiza que cada nivel tiene solución; campaña de 60 niveles |
| Audio | Incluido desde la primera versión (efectos y música) |
| Idiomas | Español + inglés (String Catalog) |
| Licencia | MIT |
| Repositorio | GitHub **privado** hasta nuevo aviso |
| Autor | App-Zilla |

## Reglas del juego

- Vista superior sobre una cuadrícula: suelo, muros, cajas, destinos y el personaje.
- El personaje se mueve en 4 direcciones y **solo empuja** cajas; nunca tira de ellas.
- **Una caja a la vez**: no se pueden empujar dos cajas alineadas.
- Se gana cuando todas las cajas están sobre un destino.
- Cajas en esquinas o pegadas a muros sin destino quedan atascadas → deshacer o reiniciar.

---

## Etapa 0 — Base legal y del proyecto
- [x] Revisar riesgos de derechos de autor y marca (ver sección «Notas legales»).
- [x] `git init`, `.gitignore` para Xcode/Swift.
- [x] `LICENSE` MIT, autor App-Zilla.
- [x] `README.md` con descripción y cómo abrir la app sin notarizar la primera vez (capturas pendientes, Etapa 9).
- [x] Proyecto Xcode generado con XcodeGen (`project.yml`): framework `ElkunufeCore`, app SwiftUI, pruebas con Swift Testing, firma ad hoc, `NSHumanReadableCopyright` = «© 2026 App-Zilla», String Catalog es/en.

## Etapa 1 — Núcleo del juego (lógica, sin gráficos)
- [x] Modelo de datos: `Position`, `Direction`, `Tile`, `Board` (parte fija), `Level` (tablero + cajas + jugador, validado), `GameState`.
- [x] Formato de texto para niveles (estilo XSB estándar: `#` muro, `@` jugador, `$` caja, `.` destino, `*` caja en destino, `+` jugador en destino), lectura y escritura.
- [x] Movimiento y empuje con las reglas anteriores (`outcome(of:)` permite consultar sin mover).
- [x] Detección de victoria (tras ganar no se admiten más movimientos salvo deshacer).
- [x] Deshacer y rehacer ilimitados; reiniciar nivel.
- [x] Contadores de movimientos y empujes; historial en notación LURD.
- [x] Pruebas unitarias con Swift Testing (22 pruebas).

## Etapa 2 — Solucionador
- [x] Búsqueda A* sobre empujes con heurística admisible (suma de empujes mínimos caja→destino).
- [x] Detección de *deadlocks*: casillas muertas (BFS «tirando» desde los destinos) y bloqueos 2×2.
- [x] Tabla de transposición (cajas ordenadas + zona alcanzable del jugador).
- [x] Devuelve la solución óptima en empujes y la secuencia completa de movimientos (LURD).
- [x] Límite de posiciones y cancelación (para usarlo en segundo plano).
- [x] Pruebas con niveles hechos a mano; resultados contrastados con una búsqueda por fuerza bruta.
- Rendimiento medido (Release, Apple silicon): 4 cajas < 1 ms, 6 cajas en sala abierta ≈ 180 ms.
- [ ] Más adelante, si el generador lo necesita: detección de bloqueos por congelamiento más general y emparejamiento caja–destino en la heurística.

## Etapa 3 — Generador procedural
- [x] Forma de la habitación con plantillas propias de 3×3 (rotadas y reflejadas), sin callejones, conectada, sin zonas abiertas de 3×4 y recortada.
- [x] Colocar destinos y cajas con búsqueda en anchura «hacia atrás» (tirando cajas desde los destinos): solución garantizada y mínimo de empujes exacto.
- [x] Validar con el solucionador (secuencia de movimientos) y descartar niveles triviales (cajas que empiezan en su destino, pocos empujes).
- [x] Métrica de dificultad: empujes mínimos + 2 × cambios de caja.
- [x] Niveles reproducibles por **semilla** con un RNG propio (SplitMix64) estable entre versiones; códigos para compartir del tipo `2-9F3A0C1D`.
- [x] Modo campaña: 60 niveles pregenerados en `CampaignLevels.swift` (`Scripts/generate-campaign.sh`), ordenados por dificultad (1 → 4 cajas).
- [x] Modo libre: ajustes fácil / media / difícil (`GeneratorSettings.preset`).
- [x] Generación en segundo plano (`async`, cancelable).
- Rendimiento (Release): fácil < 2 ms, media ≈ 11 ms, difícil ≈ 0,5 s de media (máx. ≈ 1,6 s).
- [ ] Revisar la campaña jugándola (Etapa 8) y regenerar o sustituir niveles poco interesantes.

## Etapa 4 — Gráficos y animación (SpriteKit)
- [x] Paleta en `Theme.swift` (claro y oscuro): rojo, negro, blanco de lana cruda y añil.
- [x] Casillas dibujadas con Core Graphics y rasterizadas a la resolución de pantalla: suelo, muro (zigzag textil que empalma con sus vecinos), destino (rombo), caja (fardo tejido) y caja guardada (roja con rombo blanco).
- [x] Zorro culpeo geométrico en tres vistas (lado —reflejada para la izquierda—, frente y espaldas); reposo (respiración), paso (saltito) y empuje (se agacha).
- [x] Borde decorativo (franjas de triángulos) arriba y abajo de la ventana.
- [x] Animaciones de paso, empuje, choque contra muro, deshacer/reiniciar; chispas al guardar una caja y celebración al completar el nivel.
- [x] Escalado del tablero a la ventana (casilla máx. 72 pt), texturas a la escala Retina; muros lejanos ocultos.
- [x] Modo claro / oscuro, cambio en vivo.
- [x] Respeta «Reducir movimiento» de macOS.
- [x] Suelo en damero de ajedrez con diferencia de tono tenue (pedido del autor, 18-11-2026): `Theme.floorAlt` mezcla el suelo un 40 % con el color de borde; también en los destinos.
- Nota cultural: se evitó el rombo escalonado de 3 escalones porque recuerda a la chakana (símbolo andino sagrado).
- Pantalla de juego provisional (`GameView`) con flechas/WASD, Z deshacer, ⇧Z rehacer, R reiniciar, ↩ siguiente nivel. Para desarrollo: `-startLevel N`.

## Etapa 5 — Controles e interfaz (SwiftUI)
- [x] Teclado: flechas y WASD; Z / ⌘Z deshacer, ⇧Z / ⇧⌘Z rehacer, R / ⌘R reiniciar, H / ⇧⌘H pista, Esc / ⌘P pausa, ↩ siguiente nivel.
- [x] Clic en una casilla para caminar hasta ella (ruta automática, sin empujar); clic en una caja vecina para empujarla.
- [x] Menú principal: Empezar/Continuar campaña, Campaña, Nivel aleatorio, Ayuda y créditos, Ajustes.
- [x] Selector de la campaña (6 grupos de 10) con progreso, marca de óptimo (★) y mejores marcas; se pueden saltar hasta 3 niveles por delante del último completado.
- [x] Nivel aleatorio por dificultad o por código; el código se muestra y se copia para compartir; ⌘N crea uno nuevo.
- [x] Pantalla de victoria (movimientos, empujes, comparación con el mínimo, nueva marca, pistas usadas).
- [x] Pista: resalta la caja y la dirección del siguiente empuje; avisa si el nivel ya no tiene solución.
- [x] Pausa con Continuar / Reiniciar / Elegir nivel.
- [x] Barra de menús de macOS (Archivo, Edición, Juego, Ayuda) con los atajos.
- [x] Ajustes (⌘,): contraste alto, reducir animaciones, zorro más rápido, borrar progreso (con confirmación).
- [x] Localización español / inglés con String Catalog (98 cadenas).
- [x] Accesibilidad: tablero descrito para VoiceOver con acciones para mover, deshacer y pedir pista; aviso al completar; temas de alto contraste (también con «Aumentar contraste» de macOS); «Reducir movimiento».
- [ ] Probar a fondo con VoiceOver activado.

## Etapa 6 — Audio (incluido en la versión 1.0)
- [x] Efectos: paso (4 variantes), empuje, choque contra muro, caja en destino, deshacer, pista y victoria. Sintetizados con código (`SoundSynth.swift`): originales, sin grabaciones ni licencias de terceros.
- [x] Música ambiental en bucle (~46 s, empalme sin corte) con sonoridad andina: drone, cuerdas pulsadas tipo charango (Karplus–Strong), quena con melodía generada por semilla fija y bombo suave (`MusicComposer.swift`). No usa melodías tradicionales.
- [x] Motor con `AVAudioEngine`: 8 reproductores de efectos que se turnan, música en bucle generada en segundo plano (~0,1 s en Release), reinicio al cambiar la salida de audio.
- [x] Ajustes: sonido sí/no, volumen de efectos y de música por separado; menú Juego › Silenciar (⌥⌘M).
- [x] Créditos de audio y licencias en `CREDITS.md`.
- Verificación: picos ≤ 0,6 sin saturación ni valores inválidos; fundido de 10 ms al final de cada efecto. Falta una escucha atenta para ajustar volúmenes y timbres.

## Etapa 7 — Persistencia
- [x] Guardar progreso de campaña, mejores marcas y ajustes (`UserDefaults`; progreso en JSON con `CampaignProgress`).
- [ ] Reanudar el nivel en curso al reabrir la app.

## Etapa 8 — Pulido y pruebas
- [ ] Pruebas de jugabilidad de la curva de dificultad.
- [ ] Rendimiento del generador y solucionador en niveles grandes.
- [ ] Icono de la app.
- [ ] Revisión de textos en mapudungun (significado del nombre) con una fuente confiable o hablante.

## Etapa 9 — Distribución
- [ ] Build Release con firma ad hoc.
- [ ] Empaquetar en `.zip` o `.dmg`.
- [ ] Publicar en GitHub Releases con notas en `CHANGELOG.md`.
- [ ] Capturas y GIF en el README.

## Ideas futuras
- [ ] Editor de niveles.
- [ ] Versión iPad/iPhone compartiendo el núcleo.
- [ ] Desafío diario (semilla basada en la fecha).

---

## Notas legales (derechos de autor y marca)

*Resumen informativo, no es asesoría legal.*

- **Mecánica: libre.** Las reglas de un juego (empujar cajas a destinos en una cuadrícula) son ideas y no están protegidas por derechos de autor. Por eso existen cientos de juegos del género (Boxxle, Boxworld, etc.).
- **Niveles: protegidos.** Los niveles originales de Sokoban y muchas colecciones de terceros son obras con derechos de autor. **No copiar niveles existentes.** Nuestro generador procedural evita este riesgo; los niveles de prueba se diseñan a mano desde cero.
- **Marca: «Sokoban» está registrada** (Falcon Co., que adquirió los derechos de Thinking Rabbit). No usar «Sokoban» en el nombre, el icono ni como título del juego. Mencionarlo solo de forma descriptiva («inspirado en Sokoban») en el README es razonable.
- **Arte, sonido y personajes: todo original** o con licencia CC0/compatible, sin imitar el aspecto de ningún Sokoban oficial.
- **Cultura mapuche:** usar el idioma y la estética con respeto; evitar símbolos ceremoniales y explicar el origen del nombre en el README y los créditos.

---

## Preguntas abiertas
- Ninguna por ahora.

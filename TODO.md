# Elkünufe — Plan de desarrollo

> **Elkünufe** (mapudungun): «el que guarda o deja cosas», del verbo *elkünun* (guardar, dejar).
> Juego de rompecabezas 2D para macOS, inspirado en el género de empujar cajas creado por Sokoban (Hiroyuki Imabayashi, 1981).

## Decisiones tomadas

| Tema | Decisión |
|---|---|
| Plataforma | macOS nativo |
| Tecnología | Swift + SpriteKit (tablero) + SwiftUI (menús), macOS 14+ |
| Distribución | Firma ad hoc, sin notarización ni App Store; descarga gratis (GitHub Releases) |
| Estética | Minimalista plana, inspiración mapuche sutil (paleta de textiles: rojo, negro, blanco, añil; patrones geométricos sencillos). Sin símbolos sagrados (p. ej. kultrún, rewe) |
| Niveles | Generador procedural con solucionador que garantiza que cada nivel tiene solución |
| Idiomas | Español + inglés (String Catalog) |
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
- [ ] Búsqueda (BFS para niveles pequeños; A* con heurística de distancias caja→destino).
- [ ] Detección de *deadlocks* simples (esquinas, muros sin destino) para podar la búsqueda.
- [ ] Tabla de transposición (hash de posición de cajas + región alcanzable del jugador).
- [ ] Devuelve la solución óptima en empujes y su longitud (sirve para medir dificultad).
- [ ] Pruebas con niveles pequeños hechos a mano.

## Etapa 3 — Generador procedural
- [ ] Generar la forma de la habitación (plantillas de bloques 3×3 combinadas al azar, conectividad garantizada).
- [ ] Colocar destinos y cajas; obtener posiciones iniciales jugando «hacia atrás» (tirando cajas desde los destinos) para garantizar solución.
- [ ] Validar con el solucionador y descartar niveles triviales.
- [ ] Métrica de dificultad (empujes mínimos, nº de cajas, cambios de caja, tamaño).
- [ ] Niveles reproducibles por **semilla** (compartir un nivel = compartir un código).
- [ ] Modo campaña: secuencia fija de semillas pregeneradas con dificultad creciente.
- [ ] Modo libre: nivel aleatorio eligiendo dificultad (fácil / media / difícil).
- [ ] Generación en segundo plano para no bloquear la interfaz.

## Etapa 4 — Gráficos y animación (SpriteKit)
- [ ] Definir paleta y guía visual (inspiración textil mapuche, formas planas).
- [ ] Sprites vectoriales/geométricos: suelo, muro, destino, caja, caja en destino, personaje (4 direcciones).
- [ ] Borde decorativo con patrón geométrico sencillo.
- [ ] Animaciones cortas de paso y empuje; efecto al colocar una caja en su destino y al completar el nivel.
- [ ] Escalado del tablero según tamaño de ventana; soporte Retina.
- [ ] Modo claro / oscuro.

## Etapa 5 — Controles e interfaz (SwiftUI)
- [ ] Teclado: flechas y WASD; `Z`/⌘Z deshacer, `R` reiniciar, `Esc` pausa.
- [ ] Clic en una casilla para caminar hasta ella (ruta automática, sin empujar).
- [ ] Menú principal: Campaña, Nivel aleatorio, Introducir semilla, Ajustes, Créditos.
- [ ] Selector de niveles de campaña con progreso y mejores marcas.
- [ ] Pantalla de victoria (movimientos, empujes, comparación con el óptimo).
- [ ] Pista opcional: mostrar el siguiente empuje según el solucionador.
- [ ] Barra de menús de macOS con los atajos.
- [ ] Localización español / inglés con String Catalog.
- [ ] Accesibilidad: VoiceOver básico, contraste alto, reducción de movimiento.

## Etapa 6 — Audio (opcional)
- [ ] Efectos simples (paso, empuje, caja en destino, victoria), originales o con licencia CC0.
- [ ] Música ambiental suave (original o CC0); control de volumen y silencio.

## Etapa 7 — Persistencia
- [ ] Guardar progreso de campaña, mejores marcas y ajustes (`UserDefaults` / JSON en Application Support).
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
- ¿Licencia del código: MIT, GPL u otra? (por defecto MIT)
- ¿Versión mínima de macOS: 14 (Sonoma) está bien?
- ¿Cuántos niveles en la campaña? (propuesta: 60, en 6 grupos de 10)
- ¿Incluir audio en la primera versión o dejarlo para después?
- ¿Diseño del personaje: figura humana estilizada, animal nativo (p. ej. un pudú o un zorro culpeo) o abstracto?

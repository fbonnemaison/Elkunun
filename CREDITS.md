# Créditos y licencias de recursos

Elkünufe © 2026 App-Zilla. Todo el código está bajo la [licencia MIT](LICENSE).

## Gráficos

Todos los gráficos (casillas, zorro culpeo, bordes, iconos del tablero) se dibujan con código en `Sources/Elkunufe/TileArt.swift` y `Sources/Elkunufe/FoxArt.swift`. Son originales de App-Zilla, bajo licencia MIT. Los colores y formas se inspiran con respeto en los textiles mapuches, sin reproducir símbolos ceremoniales.

## Audio

El juego **no usa grabaciones ni archivos de audio**. Todo se sintetiza al abrir la app:

| Recurso | Cómo se genera | Archivo | Autor y licencia |
|---|---|---|---|
| Paso (4 variantes) | Ruido filtrado + tono grave corto | `SoundSynth.swift` | App-Zilla · MIT |
| Empuje | Golpe grave que baja de tono + roce | `SoundSynth.swift` | App-Zilla · MIT |
| Choque contra muro | Golpe sordo corto | `SoundSynth.swift` | App-Zilla · MIT |
| Caja guardada | Dos campanas (La y Mi) | `SoundSynth.swift` | App-Zilla · MIT |
| Deshacer | Blip descendente | `SoundSynth.swift` | App-Zilla · MIT |
| Pista | Dos notas de marimba | `SoundSynth.swift` | App-Zilla · MIT |
| Victoria | Arpegio de flauta tipo quena + rasgueo de cuerdas | `SoundSynth.swift` | App-Zilla · MIT |
| Música ambiental (bucle de ~46 s) | Drone, arpegios de cuerda pulsada (Karplus–Strong), melodía de quena compuesta por un paseo aleatorio con semilla fija y bombo suave | `MusicComposer.swift` | App-Zilla · MIT |

La música usa la escala pentatónica de La menor para evocar la sonoridad andina, pero **no reproduce ninguna melodía tradicional ni obra existente**: la melodía la genera el propio programa.

## Niveles

Los 60 niveles de la campaña y los niveles aleatorios se generan por procedimiento (`Sources/ElkunufeCore/Generator.swift`). El método de plantillas para construir las habitaciones se basa en la idea publicada por Joshua Taylor e Ian Parberry (2011); las plantillas y el código son propios.

## Inspiración

Elkünufe se inspira en el género de rompecabezas de empujar cajas que creó Sokoban (Hiroyuki Imabayashi, 1981). No está afiliado a Sokoban ni a sus titulares, y no usa su nombre, niveles, gráficos ni sonidos.

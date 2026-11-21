# Créditos y licencias de recursos

Elkünun © 2026 App-Zilla. Todo el código está bajo la [licencia MIT](LICENSE).

## El nombre

*Elkünun* (también *elkünün*) es un verbo en mapudungun que significa «ubicar, poner, colocar, situar, dejar puesto», según [mapudungun.cl](https://mapudungun.cl/nemul/el.html#elk%C3%BCn%C3%BCn), que cita a Ñanculef y Huaiquilaf (2022). Describe lo que hace el zorro: dejar cada caja en su lugar.

## Gráficos

Todos los gráficos (casillas, zorro culpeo, araucarias, bordes, iconos del tablero) son pixel art de 16×16 descrito con código en `Sources/Elkunun/TileArt.swift` y `Sources/Elkunun/FoxArt.swift`. Son originales de App-Zilla, bajo licencia MIT. Los colores y formas se inspiran con respeto en los textiles mapuches, sin reproducir símbolos ceremoniales.

## Icono

Zorro culpeo en pixel art junto a una caja guardada, frente a un bosque (`Design/AppIcon-source.png`), aportado por App-Zilla.

## Fuente

| Recurso | Autor | Licencia | Uso en Elkünun |
|---|---|---|---|
| [Public Pixel Font](https://opengameart.org/content/public-pixel-font) (v1.24) | GGBotNet | [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) | Títulos y botones (`Sources/Elkunun/Resources/Fonts/PublicPixel.ttf`) |

La licencia original está en [Licenses/](Licenses). CC0 no obliga a dar crédito, pero lo damos con gusto.

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

Los 60 niveles de la campaña y los niveles aleatorios se generan por procedimiento (`Sources/ElkununCore/Generator.swift`). El método de plantillas para construir las habitaciones se basa en la idea publicada por Joshua Taylor e Ian Parberry (2011); las plantillas y el código son propios.

## Inspiración

Elkünun se inspira en el género de rompecabezas de empujar cajas que creó Sokoban (Hiroyuki Imabayashi, 1981). No está afiliado a Sokoban ni a sus titulares, y no usa su nombre, niveles, gráficos ni sonidos.

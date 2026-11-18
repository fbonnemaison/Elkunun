# Elkünufe

> *Elkünufe* (mapudungun): «el que guarda o deja cosas», del verbo *elkünun* (guardar, dejar).

Juego de rompecabezas 2D y minimalista para macOS. Empuja cada caja hasta su lugar de destino en el almacén, sin quedarte atascado.

Inspirado en el género de empujar cajas que popularizó Sokoban (Hiroyuki Imabayashi, 1981). Elkünufe es un juego independiente: no está afiliado a Sokoban ni a sus titulares, y todos sus niveles, gráficos y sonidos son originales.

> 🚧 En desarrollo. Consulta las etapas en [TODO.md](TODO.md).

## Cómo se juega

- Mueve al personaje con las flechas o con WASD.
- Solo puedes **empujar** las cajas; nunca tirar de ellas.
- Solo puedes empujar **una caja a la vez**.
- Ganas cuando todas las cajas están sobre un destino.
- ¡Ojo con las esquinas! Una caja pegada a una esquina ya no se puede sacar. Deshaz el movimiento (Z) o reinicia el nivel (R).

Los niveles se generan por procedimiento, y cada uno tiene solución garantizada. Cada nivel sale de una semilla que puedes compartir.

## Requisitos

- macOS 14 (Sonoma) o posterior.

## Instalación

1. Descarga la última versión desde la página de *Releases* del repositorio.
2. Descomprime el archivo y arrastra **Elkunufe.app** a la carpeta Aplicaciones.

### Abrir la app por primera vez

Elkünufe es gratis y se distribuye con firma *ad hoc*, sin notarización de Apple. Por eso, la primera vez macOS bloqueará la app:

1. Abre la app con doble clic. macOS mostrará un aviso de que no se puede verificar al desarrollador; pulsa **OK** o **Listo**.
2. Abre **Ajustes del Sistema › Privacidad y seguridad**.
3. Baja hasta la sección **Seguridad**. Verás un mensaje sobre Elkunufe; pulsa **Abrir igualmente**.
4. Confirma con tu contraseña o Touch ID. A partir de entonces la app se abre con normalidad.

## Compilar desde el código

Requiere Xcode 16 o posterior.

```bash
open Elkunufe.xcodeproj
```

El proyecto se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir de `project.yml`. Si cambias `project.yml`, vuelve a generarlo:

```bash
xcodegen generate
```

Compilar y ejecutar las pruebas desde la terminal:

```bash
xcodebuild -project Elkunufe.xcodeproj -scheme Elkunufe test
```

## Estructura

| Carpeta | Contenido |
|---|---|
| `Sources/ElkunufeCore` | Lógica del juego, sin interfaz: reglas, solucionador y generador |
| `Sources/Elkunufe` | App macOS: SwiftUI (menús) y SpriteKit (tablero) |
| `Tests/ElkunufeCoreTests` | Pruebas unitarias del núcleo |

## Créditos

Creado por **App-Zilla**.

El nombre proviene del mapudungun, la lengua del pueblo mapuche. La estética se inspira con respeto en los colores y la geometría de los textiles mapuches.

## Licencia

[MIT](LICENSE) © 2026 App-Zilla

# Elkünun

> *Elkünun* (mapudungun, también *elkünün*): «ubicar, poner, colocar, dejar puesto». Es lo que hace el protagonista del juego: dejar cada caja en su lugar. Fuente: [mapudungun.cl](https://mapudungun.cl/nemul/el.html#elk%C3%BCn%C3%BCn).

Juego de rompecabezas 2D y minimalista para macOS. Eres un zorro culpeo que guarda sus cosas: empuja cada caja hasta su lugar de destino en el almacén, sin quedarte atascado. Incluye una campaña de 60 niveles, niveles aleatorios infinitos, música y efectos de sonido.

Inspirado en el género de empujar cajas que popularizó Sokoban (Hiroyuki Imabayashi, 1981). Elkünun es un juego independiente: no está afiliado a Sokoban ni a sus titulares, y todos sus niveles, gráficos y sonidos son originales.

> Versión 1.1.0. Cambios en [CHANGELOG.md](CHANGELOG.md); plan de desarrollo en [TODO.md](TODO.md).

## Cómo se juega

- Mueve al personaje con las flechas o con WASD.
- Solo puedes **empujar** las cajas; nunca tirar de ellas.
- Solo puedes empujar **una caja a la vez**.
- Ganas cuando todas las cajas están sobre un destino.
- ¡Ojo con las esquinas! Una caja pegada a una esquina ya no se puede sacar. Deshaz el movimiento (Z) o reinicia el nivel (R).

Los niveles se generan por procedimiento, y cada uno tiene solución garantizada. Cada nivel sale de una semilla que puedes compartir.

## Requisitos

- Mac con Apple silicon (M1 o posterior). No hay versión para Mac con Intel.
- macOS 14 (Sonoma) o posterior.

## Instalación

1. Descarga `Elkunun-1.1.0.dmg` (o el `.zip`) de la página de *Releases* del repositorio.
2. Abre el `.dmg` y arrastra **Elkunun.app** a la carpeta Aplicaciones (o descomprime el `.zip` y haz lo mismo).

### Abrir la app por primera vez

Elkünun es gratis y se distribuye con firma *ad hoc*, sin notarización de Apple. Por eso, la primera vez macOS bloqueará la app:

1. Abre la app con doble clic. macOS mostrará un aviso de que no se puede verificar al desarrollador; pulsa **OK** o **Listo**.
2. Abre **Ajustes del Sistema › Privacidad y seguridad**.
3. Baja hasta la sección **Seguridad**. Verás un mensaje sobre Elkunun; pulsa **Abrir igualmente**.
4. Confirma con tu contraseña o Touch ID. A partir de entonces la app se abre con normalidad.

## Compilar desde el código

Requiere Xcode 16 o posterior.

```bash
open Elkunun.xcodeproj
```

El proyecto se genera con [XcodeGen](https://github.com/yonaskolb/XcodeGen) a partir de `project.yml`. Si cambias `project.yml`, vuelve a generarlo:

```bash
xcodegen generate
```

Para regenerar los tamaños del icono a partir del original en pixel art (`Design/AppIcon-source.png`):

```bash
Scripts/generate-icon.sh
```

Compilar y ejecutar las pruebas desde la terminal:

```bash
xcodebuild -project Elkunun.xcodeproj -scheme Elkunun test
```

Los 60 niveles de la campaña están pregenerados en `Sources/ElkununCore/CampaignLevels.swift`. Para regenerarlos (tarda unos 20 segundos):

```bash
Scripts/generate-campaign.sh
```

## Estructura

| Carpeta | Contenido |
|---|---|
| `Sources/ElkununCore` | Lógica del juego, sin interfaz: reglas, solucionador y generador |
| `Sources/Elkunun` | App macOS: SwiftUI (menús) y SpriteKit (tablero) |
| `Tests/ElkununCoreTests` | Pruebas unitarias del núcleo |
| `Tools/CampaignGenerator` | Herramienta que genera los niveles de la campaña |
| `Scripts` | Scripts de desarrollo |

## Créditos

Creado por **App-Zilla**.

El nombre proviene del mapudungun, la lengua del pueblo mapuche. La estética se inspira con respeto en los colores y la geometría de los textiles mapuches.

Los gráficos, la música y los efectos de sonido se generan con código y son originales. Detalle en [CREDITS.md](CREDITS.md).

## Licencia

[MIT](LICENSE) © 2026 App-Zilla

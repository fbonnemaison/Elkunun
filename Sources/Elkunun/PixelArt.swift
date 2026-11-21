// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import CoreText
import Foundation
import SpriteKit
import SwiftUI

/// Un dibujo pixel art descrito como texto: cada carácter es un píxel y `.` es transparente.
/// Los caracteres se traducen a colores del `Theme`, así que el mismo dibujo sirve para los
/// modos claro, oscuro y de alto contraste.
struct PixelArt {
    /// Lado de las casillas y piezas del tablero, en píxeles.
    static let side = 16

    let rows: [String]
    var width: Int { rows.first?.count ?? 0 }
    var height: Int { rows.count }

    init(_ rows: [String]) {
        precondition(!rows.isEmpty && rows.allSatisfy { $0.count == rows[0].count },
                     "Todas las filas de un dibujo pixel art miden lo mismo")
        self.rows = rows
    }

    /// Imagen a 1 píxel por carácter (fila 0 arriba). `color` devuelve `nil` para los transparentes.
    func makeImage(_ color: (Character) -> CGColor?) -> CGImage {
        let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.setShouldAntialias(false)
        for (y, row) in rows.enumerated() {
            for (x, character) in row.enumerated() {
                guard let c = color(character) else { continue }
                ctx.setFillColor(c)
                ctx.fill(CGRect(x: x, y: height - 1 - y, width: 1, height: 1))
            }
        }
        return ctx.makeImage()!
    }

    /// Textura con filtrado `nearest`, para que los píxeles se vean nítidos al escalar.
    func texture(_ color: (Character) -> CGColor?) -> SKTexture {
        let texture = SKTexture(cgImage: makeImage(color))
        texture.filteringMode = .nearest
        return texture
    }
}

extension Theme {
    /// Colores comunes del pixel art:
    /// - `B` fondo, `F` suelo, `E` junta del suelo, `G` destino.
    /// - `W` muro, `H` luz del muro, `S` sombra del muro, `R` tejido rojo del muro.
    /// - `X` caja, `x` contorno de la caja, `L` banda clara, `Q` caja guardada, `q` su rombo.
    /// - `O` pelaje del zorro, `K` zorro oscuro, `C` zorro claro (`o` y `k`: la cola).
    /// - `T` y `t` ramas de araucaria, `N` tronco, `s` sombra.
    func pixelColor(_ character: Character) -> CGColor? {
        switch character {
        case "B": background
        case "F": floor
        case "E": floorEdge
        case "G": goal
        case "W": wall
        case "H": Self.mix(wall, white: 0.22)
        case "S": Self.mix(wall, white: -0.45)
        case "R": wallAccent
        case "X": box
        case "x": boxDark
        case "L": boxLight
        case "Q": boxOnGoal
        case "q": boxOnGoalAccent
        case "O", "o": fox
        case "K", "k": foxDark
        case "C": foxLight
        case "T": treeDark
        case "t": treeLight
        case "N": trunk
        case "s": CGColor(gray: 0, alpha: 0.22)
        default: nil
        }
    }

    /// Aclara (`white` > 0) u oscurece (`white` < 0) un color.
    static func mix(_ color: CGColor, white: CGFloat) -> CGColor {
        let c = color.converted(to: CGColorSpace(name: CGColorSpace.sRGB)!, intent: .defaultIntent, options: nil)?
            .components ?? [0, 0, 0, 1]
        let target: CGFloat = white > 0 ? 1 : 0
        let t = abs(white)
        return CGColor(srgbRed: c[0] + (target - c[0]) * t,
                       green: c[1] + (target - c[1]) * t,
                       blue: c[2] + (target - c[2]) * t,
                       alpha: 1)
    }
}

/// Fuente pixel incluida en la app: Public Pixel, de GGBotNet (CC0).
enum PixelFont {
    /// Nombre PostScript de la fuente.
    static let name = "PublicPixel"

    /// Registra las fuentes `.ttf` del paquete de la app. Se llama al arrancar.
    static func register() {
        let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? []
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}

extension Font {
    /// Fuente pixel Public Pixel (CC0). Se ve nítida en múltiplos de 8 puntos.
    static func pixel(_ size: CGFloat) -> Font {
        .custom(PixelFont.name, fixedSize: size)
    }
}

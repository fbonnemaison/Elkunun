// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import SpriteKit

/// Dibujo vectorial (Core Graphics) de las casillas, rasterizado a la resolución exacta de pantalla.
/// Todo se dibuja en un cuadrado unidad (0…1, eje y hacia arriba) escalado a `pixels`.
enum TileArt {
    enum Kind: CaseIterable {
        case floor, wall, goal, box, boxOnGoal
    }

    static func texture(_ kind: Kind, theme: Theme, pixels: Int) -> SKTexture {
        let image = render(pixels: pixels) { ctx in
            switch kind {
            case .floor: drawFloor(ctx, theme)
            case .wall: drawWall(ctx, theme)
            case .goal: drawGoal(ctx, theme)
            case .box: drawBox(ctx, theme, onGoal: false)
            case .boxOnGoal: drawBox(ctx, theme, onGoal: true)
            }
        }
        let texture = SKTexture(cgImage: image)
        texture.filteringMode = .linear
        return texture
    }

    /// Crea una imagen de `pixels`×`pixels` y dibuja en coordenadas unidad.
    static func render(pixels: Int, _ draw: (CGContext) -> Void) -> CGImage {
        let ctx = CGContext(data: nil, width: pixels, height: pixels, bitsPerComponent: 8, bytesPerRow: 0,
                            space: CGColorSpace(name: CGColorSpace.sRGB)!,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        ctx.scaleBy(x: CGFloat(pixels), y: CGFloat(pixels))
        ctx.setShouldAntialias(true)
        draw(ctx)
        return ctx.makeImage()!
    }

    // MARK: - Formas

    /// Rombo centrado en `c` con semidiagonal `r`.
    static func rhombus(_ c: CGPoint, _ r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        p.move(to: CGPoint(x: c.x, y: c.y + r))
        p.addLine(to: CGPoint(x: c.x + r, y: c.y))
        p.addLine(to: CGPoint(x: c.x, y: c.y - r))
        p.addLine(to: CGPoint(x: c.x - r, y: c.y))
        p.closeSubpath()
        return p
    }

    // MARK: - Casillas

    private static func drawFloor(_ ctx: CGContext, _ t: Theme) {
        ctx.setFillColor(t.floorEdge)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        ctx.setFillColor(t.floor)
        ctx.fill(CGRect(x: 0.03, y: 0.03, width: 0.94, height: 0.94))
    }

    private static func drawWall(_ ctx: CGContext, _ t: Theme) {
        ctx.setFillColor(t.wall)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        // Motivo: zigzag rojo que empalma con los muros vecinos y forma una franja de telar,
        // con un pequeño rombo en cada hueco.
        ctx.setStrokeColor(t.wallAccent)
        ctx.setLineWidth(0.08)
        ctx.setLineJoin(.miter)
        ctx.addLines(between: [CGPoint(x: -0.05, y: 0.465), CGPoint(x: 0.25, y: 0.68),
                               CGPoint(x: 0.75, y: 0.32), CGPoint(x: 1.05, y: 0.535)])
        ctx.strokePath()
        ctx.setFillColor(t.wallAccent)
        ctx.addPath(rhombus(CGPoint(x: 0.72, y: 0.66), 0.075))
        ctx.addPath(rhombus(CGPoint(x: 0.28, y: 0.34), 0.075))
        ctx.fillPath()
    }

    private static func drawGoal(_ ctx: CGContext, _ t: Theme) {
        drawFloor(ctx, t)
        ctx.setStrokeColor(t.goal)
        ctx.setLineWidth(0.06)
        ctx.addPath(rhombus(CGPoint(x: 0.5, y: 0.5), 0.3))
        ctx.strokePath()
        ctx.setFillColor(t.goal)
        ctx.addPath(rhombus(CGPoint(x: 0.5, y: 0.5), 0.1))
        ctx.fillPath()
    }

    /// Caja: un fardo tejido con bandas cruzadas. Sobre el destino se vuelve roja con un rombo blanco.
    private static func drawBox(_ ctx: CGContext, _ t: Theme, onGoal: Bool) {
        let rect = CGRect(x: 0.1, y: 0.1, width: 0.8, height: 0.8)
        let body = CGPath(roundedRect: rect, cornerWidth: 0.08, cornerHeight: 0.08, transform: nil)

        // Sombra.
        ctx.setFillColor(t.boxDark.copy(alpha: 0.35)!)
        ctx.addPath(CGPath(roundedRect: rect.offsetBy(dx: 0, dy: -0.04), cornerWidth: 0.08, cornerHeight: 0.08, transform: nil))
        ctx.fillPath()

        ctx.setFillColor(onGoal ? t.boxOnGoal : t.box)
        ctx.addPath(body)
        ctx.fillPath()

        ctx.saveGState()
        ctx.addPath(body)
        ctx.clip()
        if onGoal {
            ctx.setFillColor(t.boxOnGoalAccent)
            ctx.addPath(rhombus(CGPoint(x: 0.5, y: 0.5), 0.27))
            ctx.fillPath()
            ctx.setFillColor(t.boxOnGoal)
            ctx.addPath(rhombus(CGPoint(x: 0.5, y: 0.5), 0.15))
            ctx.fillPath()
            ctx.setFillColor(t.boxOnGoalAccent)
            ctx.addPath(rhombus(CGPoint(x: 0.5, y: 0.5), 0.06))
            ctx.fillPath()
        } else {
            // Bandas del tejido.
            ctx.setFillColor(t.boxLight)
            for x in [0.32, 0.62] {
                ctx.fill(CGRect(x: x, y: 0.1, width: 0.06, height: 0.8))
            }
            ctx.setFillColor(t.boxDark.copy(alpha: 0.55)!)
            for y in [0.32, 0.62] {
                ctx.fill(CGRect(x: 0.1, y: y, width: 0.8, height: 0.06))
            }
        }
        ctx.restoreGState()

        ctx.setStrokeColor(t.boxDark)
        ctx.setLineWidth(0.05)
        ctx.addPath(body)
        ctx.strokePath()
    }
}

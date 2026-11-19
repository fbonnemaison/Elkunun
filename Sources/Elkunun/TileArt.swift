// © 2026 App-Zilla. Licencia MIT.

import CoreGraphics
import SpriteKit

/// Dibujo vectorial (Core Graphics) de las casillas, rasterizado a la resolución exacta de pantalla.
/// Todo se dibuja en un cuadrado unidad (0…1, eje y hacia arriba) escalado a `pixels`.
enum TileArt {
    enum Kind: CaseIterable {
        case floor, floorAlt, wall, wallAlt, goal, goalAlt, box, boxOnGoal
        case araucaria, araucariaTall, araucariaYoung
    }

    static func texture(_ kind: Kind, theme: Theme, pixels: Int) -> SKTexture {
        let image = render(pixels: pixels) { ctx in
            switch kind {
            case .floor: drawFloor(ctx, theme, alternate: false)
            case .floorAlt: drawFloor(ctx, theme, alternate: true)
            case .wall: drawWall(ctx, theme, alternate: false)
            case .wallAlt: drawWall(ctx, theme, alternate: true)
            case .goal: drawGoal(ctx, theme, alternate: false)
            case .goalAlt: drawGoal(ctx, theme, alternate: true)
            case .box: drawBox(ctx, theme, onGoal: false)
            case .boxOnGoal: drawBox(ctx, theme, onGoal: true)
            case .araucaria: drawAraucaria(ctx, theme, .mature)
            case .araucariaTall: drawAraucaria(ctx, theme, .tall)
            case .araucariaYoung: drawAraucaria(ctx, theme, .young)
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

    // MARK: - Araucarias

    enum AraucariaShape {
        /// Adulta: copa ancha en forma de paraguas (los pisos de ramas se ensanchan hacia arriba).
        case mature
        /// Adulta alta: tronco largo y copa pequeña arriba.
        case tall
        /// Joven: forma cónica, más ancha abajo.
        case young
    }

    /// Araucaria (*Araucaria araucana*, pehuén) de perfil: tronco recto con placas de corteza y
    /// pisos de ramas horizontales que se curvan hacia arriba en las puntas.
    private static func drawAraucaria(_ ctx: CGContext, _ t: Theme, _ shape: AraucariaShape) {
        // (altura del piso, mitad del ancho) de abajo arriba, y altura del tronco.
        let tiers: [(CGFloat, CGFloat)]
        let trunkTop: CGFloat
        switch shape {
        case .mature:
            tiers = [(0.48, 0.24), (0.60, 0.33), (0.72, 0.40), (0.82, 0.30)]
            trunkTop = 0.80
        case .tall:
            tiers = [(0.62, 0.20), (0.72, 0.29), (0.82, 0.33), (0.90, 0.22)]
            trunkTop = 0.88
        case .young:
            tiers = [(0.26, 0.36), (0.38, 0.31), (0.50, 0.25), (0.62, 0.19), (0.73, 0.13), (0.83, 0.07)]
            trunkTop = 0.90
        }

        // Sombra en el suelo.
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.22))
        ctx.fillEllipse(in: CGRect(x: 0.26, y: 0.03, width: 0.48, height: 0.07))

        // Tronco con placas de corteza.
        let trunkRect = CGRect(x: 0.465, y: 0.06, width: 0.07, height: trunkTop - 0.06)
        ctx.setFillColor(t.trunk)
        ctx.fill(trunkRect)
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.25))
        var y: CGFloat = 0.10
        while y < trunkTop - 0.04 {
            ctx.fill(CGRect(x: trunkRect.minX, y: y, width: trunkRect.width, height: 0.012))
            y += 0.055
        }
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.12))
        ctx.fill(CGRect(x: trunkRect.minX, y: trunkRect.minY, width: 0.018, height: trunkRect.height))

        // Pisos de ramas: trazo grueso curvado con las puntas hacia arriba, brillo encima y
        // un mechón en cada punta.
        ctx.setLineCap(.round)
        ctx.setLineJoin(.round)
        for (ty, w) in tiers {
            let branch = CGMutablePath()
            branch.move(to: CGPoint(x: 0.5 - w, y: ty + 0.055))
            branch.addQuadCurve(to: CGPoint(x: 0.5 + w, y: ty + 0.055), control: CGPoint(x: 0.5, y: ty - 0.05))
            ctx.setStrokeColor(t.treeDark)
            ctx.setLineWidth(0.075)
            ctx.addPath(branch)
            ctx.strokePath()

            let shine = CGMutablePath()
            shine.move(to: CGPoint(x: 0.5 - w * 0.85, y: ty + 0.065))
            shine.addQuadCurve(to: CGPoint(x: 0.5 + w * 0.85, y: ty + 0.065), control: CGPoint(x: 0.5, y: ty - 0.02))
            ctx.setStrokeColor(t.treeLight)
            ctx.setLineWidth(0.022)
            ctx.addPath(shine)
            ctx.strokePath()

            ctx.setFillColor(t.treeLight)
            for x in [0.5 - w, 0.5 + w] {
                ctx.fillEllipse(in: CGRect(x: x - 0.03, y: ty + 0.045, width: 0.06, height: 0.05))
            }
        }
        // Brote en la cima.
        ctx.setFillColor(t.treeDark)
        ctx.fillEllipse(in: CGRect(x: 0.455, y: trunkTop - 0.01, width: 0.09, height: 0.07))
    }

    // MARK: - Casillas

    /// Suelo. Las casillas alternas (damero) usan un tono un poco más oscuro.
    private static func drawFloor(_ ctx: CGContext, _ t: Theme, alternate: Bool) {
        ctx.setFillColor(t.floorEdge)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        ctx.setFillColor(alternate ? t.floorAlt : t.floor)
        ctx.fill(CGRect(x: 0.03, y: 0.03, width: 0.94, height: 0.94))
    }

    /// Muro: cada casilla es un bloque independiente, separado de sus vecinos por una junta
    /// del color de fondo y con un bisel suave (luz arriba a la izquierda, sombra abajo a la derecha).
    /// Dentro lleva un zigzag rojo con dos rombos, como un trozo de faja tejida.
    private static func drawWall(_ ctx: CGContext, _ t: Theme, alternate: Bool) {
        // Junta entre bloques.
        ctx.setFillColor(t.background)
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))

        let block = CGRect(x: 0.045, y: 0.045, width: 0.91, height: 0.91)
        let shape = CGPath(roundedRect: block, cornerWidth: 0.07, cornerHeight: 0.07, transform: nil)
        // Damero tenue: los bloques alternos son un poco más claros.
        ctx.setFillColor(alternate ? t.wallAlt : t.wall)
        ctx.addPath(shape)
        ctx.fillPath()

        ctx.saveGState()
        ctx.addPath(shape)
        ctx.clip()
        // Bisel: franja clara arriba e izquierda, oscura abajo y derecha.
        let bevel: CGFloat = 0.07
        ctx.setFillColor(CGColor(gray: 1, alpha: 0.13))
        ctx.fill(CGRect(x: block.minX, y: block.maxY - bevel, width: block.width, height: bevel))
        ctx.fill(CGRect(x: block.minX, y: block.minY, width: bevel, height: block.height))
        ctx.setFillColor(CGColor(gray: 0, alpha: 0.35))
        ctx.fill(CGRect(x: block.minX, y: block.minY, width: block.width, height: bevel))
        ctx.fill(CGRect(x: block.maxX - bevel, y: block.minY, width: bevel, height: block.height))

        // Motivo tejido.
        ctx.setStrokeColor(t.wallAccent)
        ctx.setLineWidth(0.075)
        ctx.setLineJoin(.miter)
        ctx.addLines(between: [CGPoint(x: 0.16, y: 0.46), CGPoint(x: 0.33, y: 0.64),
                               CGPoint(x: 0.67, y: 0.36), CGPoint(x: 0.84, y: 0.54)])
        ctx.strokePath()
        ctx.setFillColor(t.wallAccent)
        ctx.addPath(rhombus(CGPoint(x: 0.68, y: 0.65), 0.07))
        ctx.addPath(rhombus(CGPoint(x: 0.32, y: 0.35), 0.07))
        ctx.fillPath()
        ctx.restoreGState()
    }

    private static func drawGoal(_ ctx: CGContext, _ t: Theme, alternate: Bool) {
        drawFloor(ctx, t, alternate: alternate)
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
